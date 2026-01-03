#!/bin/bash
# Base packages installer

sudo pacman -Syyu --noconfirm go btrfs-assistant visual-studio-code-bin telegram-desktop rsync nano flatpak blanket gnome-calendar gnome-clocks gnome-online-accounts gnome-control-center gvfs-goa gvfs-onedrive gvfs-google gvfs-smb gvfs-nfs gvfs-mtp
yay -Syy --noconfirm hyprmon-bin brave-bin microsoft-edge-stable-bin

# Customize some apps as floating
./scripts/configure_hyprland.sh

# Installing virtualization-manager
sudo pacman -S --needed qemu-full virt-manager libvirt dnsmasq ebtables networkmanager
sudo systemctl enable --now libvirtd
sudo systemctl enable --now NetworkManager
sudo usermod -aG libvirt $(whoami)

#
# sudo nmcli con add type bridge con-name br0 ifname br0
# sudo nmcli con modify br0 ipv4.method auto
# sudo nmcli con add type bridge-slave con-name br0-slave ifname NOME_INTERFACCIA master br0
# sudo nmcli con up br0
#
