# ML4W-Inspired Waybar Configuration for OMArchy

Questa configurazione personalizzata aggiunge funzionalità in stile ML4W alla tua waybar OMArchy.

## Nuove Funzionalità

### 1. Quicklinks (Lato Sinistro)
5 icone cliccabili per lanciare rapidamente le tue app preferite:
- 🌐 Browser
- 📁 File Manager
- 💻 Terminal
- 📝 VS Code
- 📧 Email

**Personalizzare i quicklinks:**
Modifica il file `~/.config/waybar/config.jsonc` nelle sezioni `custom/quicklink1-5`:
```jsonc
"custom/quicklink1": {
  "format": "🎵",  // Cambia icona (usa Nerd Font icons)
  "on-click": "spotify",  // Cambia comando
  "tooltip-format": "Spotify"  // Cambia tooltip
}
```

### 2. Theme Switcher (Lato Destro)
Icona 🎨 per cambiare rapidamente tema OMArchy:
- Clicca l'icona
- Seleziona il tema da walker
- Il tema verrà applicato immediatamente

### 3. Memory Monitor
Nuovo modulo RAM accanto alla CPU che mostra:
- Percentuale utilizzo
- Tooltip con info dettagliate
- Click per aprire btop

### 4. Gruppi di Moduli Avanzati
I moduli sono organizzati in gruppi espandibili:
- **System Info**: CPU, Memory, Battery (clicca per espandere)
- **Connectivity**: Bluetooth, Network, Audio
- **Tray**: Icone di sistema

### 5. Stili Visuali Avanzati
- ✅ Bordi arrotondati su tutti i moduli
- ✅ Ombre morbide
- ✅ Effetti hover con animazioni
- ✅ Transizioni fluide
- ✅ Gradienti sul clock e theme switcher
- ✅ Animazioni per batteria critica e screen recording

## Layout della Barra

```
┌─────────────────────────────────────────────────────────────────┐
│ [Omarchy] [Workspaces] [🌐📁💻📝📧] ... [Clock] ... [🎨][System][Net][Tray] │
└─────────────────────────────────────────────────────────────────┘
```

## File della Configurazione

- **Config principale**: `~/.config/waybar/config.jsonc`
- **Stili CSS**: `~/.config/waybar/style.css`
- **Script theme switcher**: `~/.config/waybar/scripts/theme-switcher.sh`
- **Backup originale**:
  - `~/.config/waybar/config.jsonc.backup`
  - `~/.config/waybar/style.css.backup`

## Comandi Utili

```bash
# Ricarica waybar
omarchy-restart-waybar

# Ripristina configurazione originale
cp ~/.config/waybar/config.jsonc.backup ~/.config/waybar/config.jsonc
cp ~/.config/waybar/style.css.backup ~/.config/waybar/style.css
omarchy-restart-waybar
```

## Personalizzazione Avanzata

### Aggiungere più quicklinks
Puoi aggiungere fino a 10 quicklinks modificando:
1. Il gruppo `group/quicklinks` in config.jsonc
2. Creando nuovi moduli `custom/quicklink6`, `custom/quicklink7`, etc.
3. Aggiungendo gli stili in style.css

### Modificare i colori
I colori si adattano automaticamente al tema OMArchy attivo.
Per personalizzarli, modifica le sezioni colorate in `style.css`:
```css
#cpu {
  color: #89dceb;  /* Cambia questo colore */
}
```

### Riordinare i moduli
Modifica le sezioni `modules-left`, `modules-center`, `modules-right` in config.jsonc.

## Compatibilità

- ✅ Compatibile con tutti i temi OMArchy
- ✅ Mantiene i comandi e script OMArchy
- ✅ Funziona con i keybindings esistenti
- ✅ Aggiorna automaticamente i colori al cambio tema

## Troubleshooting

**La waybar non appare:**
```bash
pkill waybar
waybar &
```

**Gli script non funzionano:**
```bash
chmod +x ~/.config/waybar/scripts/*.sh
```

**Ripristinare configurazione originale:**
```bash
cp ~/.config/waybar/config.jsonc.backup ~/.config/waybar/config.jsonc
cp ~/.config/waybar/style.css.backup ~/.config/waybar/style.css
omarchy-restart-waybar
```

---

Configurazione creata con Claude Code 🤖
