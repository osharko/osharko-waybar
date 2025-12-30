#!/bin/bash
# Base packages installer

sudo pacman -Syyu --noconfirm go btrfs-assistant visual-studio-code-bin telegram-desktop rsync nano flatpak #gnome-online-accounts gvfs-google gvfs-onedrive
yay -Syy --noconfirm hyprmon-bin brave-bin microsoft-edge-stable-bin

# Customize some apps as floating
./scripts/configure_hyprland.sh

# Installing virtualization-manager
sudo pacman -S --needed qemu-full virt-manager libvirt dnsmasq ebtables
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)
