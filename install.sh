#!/bin/bash

# Osharko Waybar Installation Script
# ML4W-Inspired Configuration for OMArchy

set -e

WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo " Osharko Waybar - Installation Script"
echo "========================================="
echo ""

# Check if waybar config directory exists
if [ ! -d "$WAYBAR_CONFIG_DIR" ]; then
    echo "Creating waybar config directory..."
    mkdir -p "$WAYBAR_CONFIG_DIR"
fi

# Backup existing configuration
if [ -f "$WAYBAR_CONFIG_DIR/config.jsonc" ]; then
    echo "Backing up existing config.jsonc..."
    cp "$WAYBAR_CONFIG_DIR/config.jsonc" "$WAYBAR_CONFIG_DIR/config.jsonc.backup.$(date +%s)"
fi

if [ -f "$WAYBAR_CONFIG_DIR/style.css" ]; then
    echo "Backing up existing style.css..."
    cp "$WAYBAR_CONFIG_DIR/style.css" "$WAYBAR_CONFIG_DIR/style.css.backup.$(date +%s)"
fi

# Copy configuration files
echo "Installing configuration files..."
cp "$SCRIPT_DIR/config.jsonc" "$WAYBAR_CONFIG_DIR/"
cp "$SCRIPT_DIR/style.css" "$WAYBAR_CONFIG_DIR/"

# Copy scripts directory
if [ -d "$SCRIPT_DIR/scripts" ]; then
    echo "Installing scripts..."
    mkdir -p "$WAYBAR_CONFIG_DIR/scripts"
    cp -r "$SCRIPT_DIR/scripts/"* "$WAYBAR_CONFIG_DIR/scripts/"
    chmod +x "$WAYBAR_CONFIG_DIR/scripts/"*.sh
fi

echo ""
echo "========================================="
echo " Installation Complete!"
echo "========================================="
echo ""
echo "Your previous configuration has been backed up."
echo ""
echo "To apply changes, run:"
echo "  omarchy-restart-waybar"
echo ""
echo "To restore your previous configuration:"
echo "  cp $WAYBAR_CONFIG_DIR/config.jsonc.backup.* $WAYBAR_CONFIG_DIR/config.jsonc"
echo "  cp $WAYBAR_CONFIG_DIR/style.css.backup.* $WAYBAR_CONFIG_DIR/style.css"
echo "  omarchy-restart-waybar"
echo ""
