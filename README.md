# Osharko Waybar - ML4W-Inspired Configuration for OMArchy

A modern, feature-rich Waybar configuration inspired by ML4W dotfiles, designed specifically for OMArchy Linux.

## Features

### Quicklinks
6 customizable app launchers in the left section:
- Brave Browser
- File Manager (Nautilus)
- VS Code
- Telegram
- Obsidian
- Btrfs Assistant

### Theme Switcher
Integrated theme switcher button to quickly change OMArchy themes without opening the menu.

### System Monitoring
- **CPU** usage with colored indicator
- **Memory/RAM** usage monitoring
- **Battery** status with adaptive icons
- Click on any module to open btop for detailed stats

### Connectivity
- Bluetooth status
- Network status with bandwidth info
- Audio volume control with fixed width formatting
- Microphone status indicator (󰍬 MIC when active, 󰍭 MIC when muted)

### Gnome Online Accounts
Run the "Gnome Online Accounts" app to connect online accounts. File manager and calendar will sync from that.

---

## Claude Code Usage Monitor

Custom module (`scripts/claude-usage.sh`) that shows Claude Code usage directly in the bar.

### What it shows

In the bar: `󰧑 O:45% ∙ M:78%`
— one entry per configured account, with label and current 5h window usage.

On hover, an expanded tooltip per account:
```
Claude Code Usage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ = active limit (binding constraint)

[O] ─────────────────────────────────────────
  󰔟 5h window  45%    → resets in 3h 22m
  󰃰 Weekly     78% ⚡  → resets in 4d 2h

[M] ─────────────────────────────────────────
  󰔟 5h window  12%    → resets in 3h 22m
  󰃰 Weekly     5%     → resets in 4d 2h
```

### Weekly limit vs 5-hour lockout

Claude Code has two separate rate limits:

- **5h window** — rolling window starting from your first message. Resets ~5 hours later. Hitting it causes a temporary lockout until the window expires.
- **Weekly cap** — hard limit that resets every 7 days. Even if the 5h window resets, you stay locked if the weekly cap is reached.

The `⚡` marker shows the **active limit** (binding constraint): whichever of the two has higher utilization and is thus the one most likely to lock you out next.

### Multi-account support

Accounts are defined in `scripts/claude-accounts.conf` (gitignored, never pushed).
Copy the example file to get started:

```bash
cp scripts/claude-accounts.conf.example scripts/claude-accounts.conf
```

Format:
```
# LABEL|PATH_TO_DOT_CLAUDE_DIR
O|~/.claude
M|~/.claude-matrone
```

- **LABEL**: 1–2 chars shown in the bar to identify the account
- **PATH**: directory containing `.credentials.json`

If the file doesn't exist, the script falls back to `~/.claude` with label `C`.

### Color states

| State    | Threshold         | Color  |
|----------|-------------------|--------|
| normal   | < 50%             | Claude orange `#D97757` |
| warning  | ≥ 50% (any limit) | amber `#E8A040` |
| critical | ≥ 80% (any limit) | red `#f38ba8` (bold) |

Worst state across all accounts is used for the module color.

---

## Credits

- Inspired by [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles)
- Built for [OMArchy Linux](https://omarchy.org)
- Created with Claude Code

---

Made with love for the OMArchy community
