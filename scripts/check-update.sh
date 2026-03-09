#!/bin/bash
# Wrapper for omarchy-update-available that outputs JSON for waybar

output=$(omarchy-update-available)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    # Update available
    printf '{"text": "", "tooltip": "%s", "class": "warning"}\n' "$output"
else
    # No update available or error
    printf '{"text": "", "tooltip": "%s", "class": "normal"}\n' "$output"
fi
