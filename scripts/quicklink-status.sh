#!/bin/bash
# quicklink-status.sh <icon> <class-pattern> <app-name> [keybind]
# Outputs JSON for waybar with window count badge if app has open windows.

ICON="$1"
CLASS_PATTERN="$2"
APP_NAME="$3"
KEYBIND="${4:-}"

COUNT=$(hyprctl clients -j 2>/dev/null | jq --arg pat "$CLASS_PATTERN" '[.[] | select(.class | ascii_downcase | contains($pat))] | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
  WIN_TEXT=$([ "$COUNT" -eq 1 ] && echo "1 finestra aperta" || echo "$COUNT finestre aperte")
  TOOLTIP="$APP_NAME — $WIN_TEXT"
  [ -n "$KEYBIND" ] && TOOLTIP="$TOOLTIP\n\n$KEYBIND"
  if [ "$COUNT" -gt 1 ]; then
    TEXT="${ICON}<span size='x-small'> ${COUNT}</span>"
  else
    TEXT="${ICON}"
  fi
  CLASS="open"
else
  TOOLTIP="$APP_NAME"
  [ -n "$KEYBIND" ] && TOOLTIP="$TOOLTIP\n\n$KEYBIND"
  TEXT="$ICON"
  CLASS=""
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
