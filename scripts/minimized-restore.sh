#!/bin/bash
# Opens a floating fzf picker to restore windows from special:minimized

ghostty \
  --class=waybar-quickmenu \
  --title="Ripristina finestre" \
  --command="~/.config/waybar/scripts/minimized-restore-inner.sh" \
  2>/dev/null &
