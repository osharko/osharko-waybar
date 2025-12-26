#!/bin/bash
# ML4W-inspired theme switcher for OMArchy

# Get list of themes and use walker (OMArchy's launcher) to select one
theme=$(omarchy-theme-list | walker --dmenu)

# If a theme was selected, apply it
if [ -n "$theme" ]; then
    omarchy-theme-set "$theme"
fi
