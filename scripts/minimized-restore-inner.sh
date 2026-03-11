#!/bin/bash
# Runs inside a floating ghostty terminal. Lets user pick a minimized window to restore.

CLIENTS=$(hyprctl clients -j 2>/dev/null | \
  jq -r '.[] | select(.workspace.name == "special:minimized") | .address + "|" + .class + " — " + .title' \
  2>/dev/null)

[ -z "$CLIENTS" ] && exit 0

CHOICE=$(echo "$CLIENTS" | awk -F'|' '{print $2}' | fzf \
  --no-info \
  --prompt="  Ripristina  " \
  --height=100% \
  --border=none \
  --color="bg+:-1,fg+:white,hl+:cyan,hl:cyan,pointer:cyan,prompt:cyan")

[ -z "$CHOICE" ] && exit 0

ADDR=$(echo "$CLIENTS" | awk -F'|' -v choice="$CHOICE" '$2 == choice {print $1}')
[ -n "$ADDR" ] && hyprctl dispatch movetoworkspace "e+0,address:$ADDR"
