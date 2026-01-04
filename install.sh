#!/bin/bash

# Configure bash with https://gist.github.com/3ayazaya/d87c70c5f30a6e28f15dfc84ca95fc68
cp -r .config/* ~/.config/

# Configure hypridle for more time before sleep
cp -r .config/hypr/hypridle.conf ~/.config/hypr/hypridle.conf

./scripts/snapper-config.sh
./scripts/package-install.sh
./scripts/ssh.sh
./scripts/gnome_online_accounts.sh
