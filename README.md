# Osharko Waybar - ML4W-Inspired Configuration for OMArchy

A modern, feature-rich Waybar configuration inspired by ML4W dotfiles, designed specifically for OMArchy Linux.

## Features

### 🚀 Quicklinks
6 customizable app launchers in the left section:
- 🌐 Brave Browser
- 📁 File Manager (Nautilus)
- 📝 VS Code
- 💬 Telegram
- 📓 Obsidian
- 💾 Btrfs Assistant

### 🎨 Theme Switcher
Integrated theme switcher button to quickly change OMArchy themes without opening the menu.

### 📊 System Monitoring
- **CPU** usage with colored indicator
- **Memory/RAM** usage monitoring
- **Battery** status with adaptive icons
- Click on any module to open btop for detailed stats

### 🔌 Connectivity
- Bluetooth status
- Network status with bandwidth info
- Audio volume control with fixed width formatting
- Microphone status indicator (󰍬 MIC when active, 󰍭 MIC when muted)

### 🎯 Module Groups
Organized modules in expandable groups:
- System Info (CPU, Memory, Battery)
- Connectivity (Bluetooth, Network, Audio)
- System Tray (always visible)

### ✨ Visual Enhancements
- Rounded corners on all modules
- Soft shadows for depth
- Smooth hover effects
- Gradient effects on clock and theme switcher
- Responsive tooltips
- Adaptive colors based on OMArchy theme

## Recent Updates (2025-12-27)

### ✅ Implemented
- ✅ Added File Manager quicklink (Nautilus)
- ✅ Added microphone status indicator with icons
- ✅ Fixed audio volume formatting with fixed width (prevents shifting at 100%)
- ✅ Removed battery tooltip from CPU hover (battery always visible separately)
- ✅ Battery now shows percentage alongside icon

### 🔧 TODO / Known Issues
- ⚠️ **Dynamic battery colors not working** - Battery should change color based on charge level:
  - 🔴 Red (0-25%)
  - 🟡 Yellow (25-40%)
  - 🟢 Green (40-100%)
  - Currently stays white - CSS color states not applying correctly

- ⚠️ **Microphone colors not working** - Microphone should change color based on status:
  - 🟢 Green when active
  - 🔴 Red when muted
  - Currently stays white - CSS source-muted class not applying correctly

These issues likely require investigating waybar's class assignment mechanism or using a different approach (e.g., custom scripts).

## Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ [Omarchy] [Workspaces] [📝💬🌐📓💾] ... [Clock] ... [🎨][System][Net][Tray] │
└──────────────────────────────────────────────────────────────────┘
```

## Installation

### Requirements
- OMArchy Linux
- Waybar
- Optional: VS Code, Telegram, Brave, Obsidian, Btrfs Assistant

### Quick Install

```bash
# Clone the repository
git clone git@github.com:osharko/osharko-waybar.git ~/.config/osharko-waybar

# Run the installation script
cd ~/.config/osharko-waybar
./install.sh

# Reload waybar
omarchy-restart-waybar
```

### Manual Install

```bash
# Backup your current configuration
cp ~/.config/waybar/config.jsonc ~/.config/waybar/config.jsonc.backup
cp ~/.config/waybar/style.css ~/.config/waybar/style.css.backup

# Copy configuration files
cp config.jsonc ~/.config/waybar/
cp style.css ~/.config/waybar/
cp -r scripts ~/.config/waybar/

# Make scripts executable
chmod +x ~/.config/waybar/scripts/*.sh

# Reload waybar
omarchy-restart-waybar
```

## Customization

### Quicklinks

Edit `config.jsonc` to customize quicklinks:

```jsonc
"custom/quicklink1": {
  "format": "🎵",  // Change icon (use Nerd Font icons)
  "on-click": "spotify",  // Change command
  "tooltip-format": "Spotify"  // Change tooltip
}
```

Available Nerd Font icons:
-  VS Code
- 󰭹 Telegram
- 󰊯 Brave
- 󱓷 Obsidian
- 󰁯 Btrfs Assistant
- 🌐 Browser
- 📁 Files
- 💻 Terminal
- 📧 Email

### Colors

Colors automatically adapt to your OMArchy theme. For manual customization, edit `style.css`:

```css
#cpu {
  color: #89dceb;  /* Customize CPU color */
}

#memory {
  color: #a6e3a1;  /* Customize Memory color */
}
```

### Module Order

Reorder modules by editing `modules-left`, `modules-center`, `modules-right` in `config.jsonc`.

### Add More Quicklinks

You can add up to 10 quicklinks:

1. Add module definition in `config.jsonc`:
```jsonc
"custom/quicklink6": {
  "format": "🎵",
  "on-click": "spotify",
  "tooltip-format": "Spotify"
}
```

2. Add module name to `group/quicklinks`:
```jsonc
"group/quicklinks": {
  "modules": [
    "custom/quicklink1",
    "custom/quicklink2",
    "custom/quicklink3",
    "custom/quicklink4",
    "custom/quicklink5",
    "custom/quicklink6"  // Add here
  ]
}
```

3. Add styling in `style.css`:
```css
#custom-quicklink6 {
  padding: 4px 10px;
  margin: 4px 2px;
  font-size: 14px;
  min-width: 24px;
}
```

## Configuration Files

- `config.jsonc` - Main waybar configuration
- `style.css` - Visual styling
- `scripts/theme-switcher.sh` - Theme switching script

## Keybindings & Interactions

- **Click theme switcher icon** (🎨): Change OMArchy theme
- **Click CPU/Memory**: Open btop
- **Click network**: Open network manager
- **Click bluetooth**: Open bluetooth manager
- **Click audio**: Open audio mixer (wiremix)
- **Right-click audio**: Toggle mute
- **Click microphone**: Open audio mixer (wiremix)
- **Right-click microphone**: Toggle microphone mute
- **Click quicklinks**: Launch respective applications

## Troubleshooting

### Waybar doesn't appear

```bash
pkill waybar
waybar &
```

### Scripts don't work

```bash
chmod +x ~/.config/waybar/scripts/*.sh
```

### Quicklink app doesn't launch

Check if the app is installed:
```bash
which code Telegram brave obsidian btrfs-assistant-launcher
```

Install missing apps using OMArchy package manager or edit quicklinks in `config.jsonc`.

### Restore original configuration

```bash
cp ~/.config/waybar/config.jsonc.backup ~/.config/waybar/config.jsonc
cp ~/.config/waybar/style.css.backup ~/.config/waybar/style.css
omarchy-restart-waybar
```

## Compatibility

- ✅ All OMArchy themes
- ✅ OMArchy commands and scripts
- ✅ Existing keybindings
- ✅ Auto-updates colors on theme change

## File Structure

```
osharko-waybar/
├── config.jsonc          # Main configuration
├── style.css             # Styling
├── scripts/
│   └── theme-switcher.sh # Theme switcher script
├── README.md             # This file
├── install.sh            # Installation script
├── .gitignore
└── LICENSE
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See LICENSE file for details

## Credits

- Inspired by [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles)
- Built for [OMArchy Linux](https://omarchy.org)
- Created with Claude Code 🤖

## Support

If you encounter any issues, please open an issue on GitHub.

---

Made with ❤️ for the OMArchy community
