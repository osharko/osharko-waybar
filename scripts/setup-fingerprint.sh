#!/bin/bash
# Fingerprint Reader Setup - Dell Pro Max 16 MC16255 (Broadcom CV3+)
# Arch Linux / Omarchy (Hyprland + hyprlock)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] && error "Non eseguire come root"

# ── 1. Rimozione pacchetti in conflitto ──────────────────────────────────────
info "Rimozione pacchetti in conflitto con libfprint-tod..."
if pacman -Q libfprint &>/dev/null; then
    sudo pacman -Rn --noconfirm libfprint
    info "libfprint rimosso"
else
    info "Nessun conflitto trovato"
fi

# ── 2. Installazione libfprint-tod ───────────────────────────────────────────
# Il PKGBUILD ufficiale AUR ha un checksum non aggiornato sul sorgente git,
# quindi si clona e si usa --skipinteg
info "Installazione libfprint-tod (con --skipinteg per bug AUR checksum)..."
if pacman -Q libfprint-tod &>/dev/null; then
    info "libfprint-tod già installato, skip"
else
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/libfprint-tod.git "$tmpdir/libfprint-tod"
    cd "$tmpdir/libfprint-tod"
    makepkg -si --skipinteg
    cd - > /dev/null
    rm -rf "$tmpdir"
fi

# ── 3. Installazione driver Broadcom CV3+ ────────────────────────────────────
info "Installazione libfprint-2-tod1-broadcom-cv3plus..."
if pacman -Q libfprint-2-tod1-broadcom-cv3plus &>/dev/null; then
    info "Driver già installato, skip"
else
    yay -S libfprint-2-tod1-broadcom-cv3plus
fi

# ── 4. Riavvio fprintd e verifica device ─────────────────────────────────────
info "Riavvio fprintd..."
sudo systemctl restart fprintd
sleep 1

if fprintd-list "$USER" 2>&1 | grep -q "Device at"; then
    info "Device Broadcom CV3+ rilevato correttamente"
else
    error "Device non rilevato. Verifica che il fingerprint reader sia abilitato nel BIOS e che il driver sia caricato."
fi

# ── 5. Enrollment fingerprint ────────────────────────────────────────────────
echo ""
info "Avvio enrollment fingerprint (striscia il dito più volte quando richiesto)..."
fprintd-enroll "$USER"

# ── 6. PAM - sudo ────────────────────────────────────────────────────────────
info "Configurazione /etc/pam.d/sudo..."
sudo tee /etc/pam.d/sudo > /dev/null <<'EOF'
#%PAM-1.0
auth        sufficient  pam_fprintd.so timeout=10
auth        include     system-auth
account     include     system-auth
session     include     system-auth
EOF

# ── 7. PAM - polkit-1 (symlink a sudo) ──────────────────────────────────────
info "Configurazione /etc/pam.d/polkit-1 come symlink di sudo..."
sudo ln -sf /etc/pam.d/sudo /etc/pam.d/polkit-1

# ── 8. PAM - hyprlock ────────────────────────────────────────────────────────
info "Configurazione /etc/pam.d/hyprlock..."
sudo tee /etc/pam.d/hyprlock > /dev/null <<'EOF'
auth        sufficient  pam_fprintd.so
auth        sufficient  pam_unix.so try_first_pass nullok
auth        required    pam_deny.so
EOF

# ── 9. hyprlock.conf - abilita fingerprint ───────────────────────────────────
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
if [[ -f "$HYPRLOCK_CONF" ]]; then
    if grep -q "fingerprint:enabled = false" "$HYPRLOCK_CONF"; then
        sed -i 's/fingerprint:enabled = false/fingerprint:enabled = true/' "$HYPRLOCK_CONF"
        info "Fingerprint abilitato in hyprlock.conf"
    else
        info "hyprlock.conf già configurato correttamente"
    fi
else
    warn "hyprlock.conf non trovato in $HYPRLOCK_CONF, skip"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup completato!${NC}"
echo ""
echo "  Riepilogo:"
echo "  - libfprint-tod installato (TOD framework)"
echo "  - Driver Broadcom CV3+ (0a5c:586x) installato"
echo "  - Fingerprint enrollato per $USER"
echo "  - PAM configurato: sudo, polkit-1, hyprlock"
echo "  - hyprlock.conf aggiornato (fingerprint:enabled = true)"
echo ""
echo "  sudo:     fingerprint o password (timeout 10s)"
echo "  hyprlock: fingerprint o password in parallelo"
