#!/bin/bash

profile=$(powerprofilesctl get 2>/dev/null)

case "$profile" in
  performance)
    icon="󰓅"
    class="performance"
    ;;
  balanced)
    icon="󰈐"
    class="balanced"
    ;;
  power-saver)
    icon="󰌪"
    class="power-saver"
    ;;
  *)
    icon="󰓅"
    class=""
    profile="unknown"
    ;;
esac

echo "{\"text\": \"$icon\", \"tooltip\": \"Power profile: $profile\", \"class\": \"$class\"}"
