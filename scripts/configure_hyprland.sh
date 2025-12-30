#!/bin/bash
# Hyprland configurator

# Customize some apps as floating
old_content=$(cat ./scripts/old_hyprland.conf)
new_content=$(cat ./scripts/new_hyprland.conf)
file_location="$HOME/.config/hypr/hyprland.conf"
target_content=$(<"$file_location")
result="${target_content//"$old_content"/"$new_content"}"
echo "$result" > "$file_location"