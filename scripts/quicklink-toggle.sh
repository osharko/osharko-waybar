#!/bin/bash
# quicklink-toggle.sh <class-pattern> <launch-command...>
# Focus the app if it has open windows, otherwise launch it.

CLASS_PATTERN="$1"
shift
LAUNCH_CMD="$@"

ADDR=$(hyprctl clients -j 2>/dev/null | jq -r --arg pat "$CLASS_PATTERN" \
  '[.[] | select(.class | ascii_downcase | contains($pat))][0].address // ""' 2>/dev/null)

if [ -n "$ADDR" ]; then
  hyprctl dispatch focuswindow "address:$ADDR"
else
  $LAUNCH_CMD &
fi

# Immediate badge refresh
kill -35 $(pidof waybar 2>/dev/null) 2>/dev/null
