# Waybar / Linux Management Project

Configurazione Waybar e script di gestione sistema per Arch Linux / Omarchy (Hyprland).

## Struttura

- `config.jsonc` — configurazione Waybar
- `style.css` — stili Waybar
- `install.sh` — script di installazione del progetto
- `scripts/` — script di sistema e moduli Waybar

## Macchina

- **Modello**: Dell Pro Max 16 MC16255 (Service Tag: 5NZ47F4)
- **OS**: Arch Linux + Omarchy (Hyprland, hyprlock, waybar)
- **Shell**: bash/zsh

---

## Power Profile

Modulo `custom/power-profile` separato dalla batteria, sempre visibile (anche su PC senza batteria).

- **Script**: `scripts/power-profile.sh` — output JSON con icona, tooltip e classe CSS
- **Icone**: 󰓅 performance, 󰈐 balanced, 󰌪 power-saver
- **Colori CSS**: rosso (performance), verde (balanced), blu (power-saver)
- **Click**: apre `omarchy-menu power` (preseleziona il profilo attivo)
- **Interval**: 30s
- **Backend**: `powerprofilesctl get` / `powerprofilesctl set`

La batteria mostra solo info batteria (percentuale, tempo rimanente), senza on-click.

---

## Fingerprint Reader

### Hardware
- **Device**: Broadcom ControlVault3 Plus
- **USB ID**: `0a5c:5865` — visibile in `lsusb -t` come "Application Specific Interface, Driver=[none]" senza driver nativo

### Pacchetti richiesti
- `libfprint-tod` — versione TOD di libfprint (sostituisce `libfprint`, con cui è in conflitto)
  - Il PKGBUILD AUR ha un checksum non aggiornato: installare con `makepkg -si --skipinteg`
- `libfprint-2-tod1-broadcom-cv3plus` — driver proprietario per `0a5c:586x`

### PAM configurato
- `/etc/pam.d/hyprlock` — fingerprint || password (gestito in parallelo da hyprlock)
- `/etc/pam.d/sudo` — fingerprint (timeout=10s) || password
- `/etc/pam.d/polkit-1` — symlink a `/etc/pam.d/sudo`

### hyprlock
- `~/.config/hypr/hyprlock.conf`: `fingerprint:enabled = true` (nella sezione `auth {}`)
- Su Linux PAM è sequenziale (non parallelo come macOS): il `timeout=10s` su pam_fprintd permette il fallback alla password

### Script di setup
`scripts/setup-fingerprint.sh` — automatizza l'intera procedura da zero:
1. Rimuove `libfprint` (conflitto)
2. Installa `libfprint-tod` via git + `--skipinteg`
3. Installa il driver Broadcom da AUR
4. Verifica rilevamento device
5. Enrollment interattivo
6. Configura PAM (sudo, polkit-1, hyprlock)
7. Aggiorna `hyprlock.conf`

```bash
cd ~/.config/waybar
bash scripts/setup-fingerprint.sh
```
