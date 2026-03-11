#!/bin/bash
# quicklink-menu.sh <class-pattern> <app-name> <launch-command...>

CLASS_PATTERN="$1"
APP_NAME="$2"
shift 2
LAUNCH_CMD="$@"

COUNT=$(hyprctl clients -j 2>/dev/null | jq --arg pat "$CLASS_PATTERN" \
  '[.[] | select(.class | ascii_downcase | contains($pat))] | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
  OPTIONS=$'Apri nuovo\nRiduci a icona\nChiudi tutto'
else
  OPTIONS='Apri nuovo'
fi

CHOICE=$(printf '%s' "$OPTIONS" | walker --dmenu \
  --placeholder "$APP_NAME" \
  --width 240 \
  --maxheight 120 2>/dev/null)

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  "Apri nuovo")
    $LAUNCH_CMD &
    ;;
  "Riduci a icona")
    hyprctl clients -j | jq -r --arg pat "$CLASS_PATTERN" \
      '.[] | select(.class | ascii_downcase | contains($pat)) | .address' \
    | while read -r addr; do
        hyprctl dispatch movetoworkspacesilent "special:minimized,address:$addr"
      done
    ;;
  "Chiudi tutto")
    hyprctl clients -j | jq -r --arg pat "$CLASS_PATTERN" \
      '.[] | select(.class | ascii_downcase | contains($pat)) | .address' \
    | while read -r addr; do
        hyprctl dispatch closewindow "address:$addr"
      done
    ;;
esac
