#!/bin/bash
# Outputs JSON for waybar: count of windows in special:minimized workspace

COUNT=$(hyprctl clients -j 2>/dev/null | \
  jq '[.[] | select(.workspace.name == "special:minimized")] | length' 2>/dev/null)
COUNT=${COUNT:-0}

if [ "$COUNT" -gt 0 ]; then
  LABEL=$([ "$COUNT" -eq 1 ] && echo "1 finestra" || echo "$COUNT finestre")
  printf '{"text": "󰖰 %s", "tooltip": "%s ridotte a icona", "class": "active"}\n' \
    "$COUNT" "$LABEL"
else
  printf '{"text": "", "tooltip": "", "class": ""}\n'
fi
