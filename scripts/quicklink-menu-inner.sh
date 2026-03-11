#!/bin/bash
# Runs inside a floating ghostty terminal as a fzf context menu.
# Called by quicklink-menu.sh with env vars: QM_CLASS, QM_APP, QM_CMD, QM_COUNT

if [ "$QM_COUNT" -gt 0 ]; then
  OPTIONS=$'Apri nuovo\nRiduci a icona\nChiudi tutto'
else
  OPTIONS='Apri nuovo'
fi

CHOICE=$(printf '%s' "$OPTIONS" | fzf \
  --no-info \
  --no-bold \
  --prompt="  $QM_APP  " \
  --height=100% \
  --border=none \
  --color="bg+:-1,fg+:white,hl+:cyan,hl:cyan,pointer:cyan,prompt:cyan")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  "Apri nuovo")
    $QM_CMD &
    ;;
  "Riduci a icona")
    hyprctl clients -j | jq -r --arg pat "$QM_CLASS" \
      '.[] | select(.class | ascii_downcase | contains($pat)) | .address' \
    | while read -r addr; do
        hyprctl dispatch movetoworkspacesilent "special:minimized,address:$addr"
      done
    ;;
  "Chiudi tutto")
    hyprctl clients -j | jq -r --arg pat "$QM_CLASS" \
      '.[] | select(.class | ascii_downcase | contains($pat)) | .address' \
    | while read -r addr; do
        hyprctl dispatch closewindow "address:$addr"
      done
    ;;
esac

kill -35 $(pidof waybar 2>/dev/null) 2>/dev/null
