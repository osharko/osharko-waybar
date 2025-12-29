#!/bin/bash
# Base packages installer

sudo pacman -Syyu --noconfirm go btrfs-assistant visual-studio-code-bin telegram-desktop rsync nano flatpak
yay -Syy --noconfirm hyprmon-bin brave-bin microsoft-edge-stable-bin calcure

# Add telegram as floating
echo '' >> ~/.config/hypr/hyprland.conf
echo 'windowrule = float, class:org.telegram.desktop' >> ~/.config/hypr/hyprland.conf
echo 'windowrule = size 400 600, class:org.telegram.desktop' >> ~/.config/hypr/hyprland.conf

# Installing virtualization-manager
sudo pacman -S --needed qemu-full virt-manager libvirt dnsmasq ebtables
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)
