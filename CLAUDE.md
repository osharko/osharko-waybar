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

## Brightness (custom/brightness)

Controllo luminosità **hardware reale** con **due backend** auto-selezionati:
- **`sysfs`** (via `brightnessctl` su `/sys/class/backlight/*`) per laptop senza monitor esterni DDC — unico safe su pannelli eDP
- **`ddc`** (via `ddcutil setvcp 10`) per fissi con monitor esterni, in parallelo su tutti

Selezione in `resolve_backend()`: se esiste `/sys/class/backlight/*` **e** non ci sono monitor `HDMI-*`/`DP-*` in `hyprctl monitors` → `sysfs`, altrimenti `ddc`. Cache in `~/.cache/waybar-brightness-backend`, reset con `brightness.sh init`.

**IMPORTANTE — perché due backend:** `ddcutil setvcp` sui bus i2c che servono un pannello eDP interno (via amdgpu/i915) può **freezare il driver GPU → crash del compositor wayland** (Teams in bg continua perché audio è indipendente). Su laptop Dell Pro Max 16 confermato crash con `ddcutil --bus 2/10 setvcp 10`: quei bus i2c appartengono ad amdgpu e servono l'eDP interno. Mai lanciare ddcutil se non ci sono monitor esterni reali.

- **Script**: `scripts/brightness.sh` (subcommands: `status` default, `slider`, `up`, `down`, `set N`, `init`)
- **Setup**: `scripts/setup-ddcutil.sh` — installa ddcutil, modulo i2c-dev permanente, group i2c + udev rule, sudoers NOPASSWD per ddcutil (fallback immediato)
- **Backend**: `ddcutil --display N --noverify setvcp 10 <0-100>` per ogni display in parallelo (`&` + `wait`)
- **Permessi**: lo script prova prima `ddcutil` diretto, poi `sudo -n ddcutil`. Cache della modalità in `~/.cache/waybar-ddcutil-cmd`
- **Cache**: valore corrente in `~/.cache/waybar-brightness` (default 100), display IDs in `~/.cache/waybar-ddcutil-displays`. `brightness.sh init` resetta tutto e rilegge dall'hardware
- **Click**: zenity scale popup contestuale con `--print-partial` → applica live mentre si trascina. Bottoni: **Conferma** (rc=0, mantiene) / **Ripristina** (rc=1, torna a `orig`)
- **Stream values**: `stdbuf -oL zenity ... | { while read v; ... }` — line-buffering forzato (altrimenti glibc block-buffera quando stdout è una pipe → niente live update). NON usare `coproc` né FIFO+`wait`: bash auto-reapa il subshell e l'exit code è inaffidabile. Usare invece `${PIPESTATUS[0]}` nel parent shell dopo la pipeline → exit code REALE di zenity
- **Coalescing**: dentro il while-read, drain dei valori in coda con `read -r -t 0.005 next` → applica solo l'ultimo, evita la queue buildup di setvcp
- **Single instance**: se zenity è già aperto, il secondo click sull'icona non fa nulla. NON killarlo (SIGTERM → rc≠0 → restore involontario, fa "salva sempre la prima")
- **Popup contestuale**: window rule fa solo `float on, pin on, decorate 0, match:title ^(brightness-slider)$`. Il **posizionamento è fatto dallo script**: cattura `hyprctl cursorpos` PRIMA di aprire zenity, calcola `tx=cx-150, ty=42` (clamp ai bordi del monitor sotto il cursore via `hyprctl monitors -j`), poi loop bg che polla `hyprctl clients` per il titolo e dispatcha `movewindowpixel exact $tx $ty,title:^(brightness-slider)$` appena la finestra appare
- **Debug log opzionale**: `touch /tmp/brightness.log.enable` → log delle operazioni in `/tmp/brightness.log`
- **Scroll**: ±5% direttamente sul modulo
- **Range**: 0–100 (DDC VCP 0x10 standard)
- **Signal**: 9 (SIGRTMIN+9) — `pkill -RTMIN+9 waybar` per refresh immediato dopo set
- **Icone**: 󰃞 (<25) 󰃝 (25-49) 󰃟 (50-74) 󰃠 (≥75)
- **Performance**: setvcp parallelo su 3 monitor ≈ 700ms; getvcp evitato (lento), si usa la cache

Note:
- DDC/CI è agnostico dal numero di monitor: aggiungi/rimuovi schermi → basta `brightness.sh init` per ridetectare
- Funziona solo su monitor che supportano DDC/CI (LG HDR 4K, ViewSonic XG2705-2K confermati OK)

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
