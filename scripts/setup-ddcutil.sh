#!/bin/bash
# Setup ddcutil per il controllo DDC/CI senza prompt password.
# Idempotente: rieseguibile in sicurezza.
set -e

echo "==> Installing ddcutil..."
sudo pacman -S --needed --noconfirm ddcutil

echo "==> Loading i2c-dev module at boot..."
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev || true

echo "==> Creating i2c group..."
getent group i2c >/dev/null || sudo groupadd i2c

echo "==> Adding $USER to i2c group..."
sudo usermod -aG i2c "$USER"

echo "==> Installing udev rule for /dev/i2c-*..."
sudo tee /etc/udev/rules.d/45-ddcutil-i2c.rules >/dev/null <<'EOF'
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=i2c-dev --action=change

echo "==> Installing sudoers NOPASSWD entry for ddcutil (immediate fallback)..."
sudo tee /etc/sudoers.d/ddcutil >/dev/null <<EOF
$USER ALL=(root) NOPASSWD: /usr/bin/ddcutil
EOF
sudo chmod 0440 /etc/sudoers.d/ddcutil

echo "==> Detecting displays..."
sudo ddcutil detect --terse 2>/dev/null | grep "^Display" || true

# Reset cache so the brightness script re-detects
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-ddcutil-cmd" \
      "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-ddcutil-displays" \
      "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-brightness"

cat <<'MSG'

Setup completato.

Modalità di accesso a /dev/i2c-*:
  - Sudoers NOPASSWD per ddcutil  → funziona SUBITO senza relogin
  - Group i2c (clean)              → richiede logout/login per essere attivo

Test rapido:
  ~/.config/waybar/scripts/brightness.sh init
  ~/.config/waybar/scripts/brightness.sh set 80
  ~/.config/waybar/scripts/brightness.sh set 100
MSG
