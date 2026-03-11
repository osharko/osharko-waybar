#!/bin/bash
# Listens to Hyprland window events and signals waybar to refresh quicklinks instantly.
# Uses SIGRTMIN+1 (signal 35). Add to hyprland autostart:
#   exec-once = ~/.config/waybar/scripts/quicklink-watcher.sh

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -u UNIX-CONNECT:"$SOCKET" STDOUT 2>/dev/null | while IFS= read -r line; do
  case "$line" in
    openwindow*|closewindow*|movewindow*)
      pkill -RTMIN+1 waybar
      ;;
  esac
done
