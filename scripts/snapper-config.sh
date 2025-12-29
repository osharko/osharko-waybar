#!/bin/bash
# Snapper configuration

# Update root config to enable timeline snapshots
sudo sed -i 's/TIMELINE_CREATE="no"/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_MIN_AGE="3600"/TIMELINE_MIN_AGE="1800"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="6"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="20"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="3"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="2"/' /etc/snapper/configs/root
sudo sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

# Update home config to enable timeline snapshots
sudo sed -i 's/TIMELINE_CREATE="no"/TIMELINE_CREATE="yes"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_MIN_AGE="3600"/TIMELINE_MIN_AGE="1800"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="6"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="20"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="3"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="2"/' /etc/snapper/configs/home
sudo sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/home


# Create the polkit rules directory if it doesn't exist
sudo mkdir -p /etc/polkit-1/rules.d

# Create the rule file
sudo tee /etc/polkit-1/rules.d/49-btrfs-assistant.rules > /dev/null << 'EOF'
/* Allow wheel group members to run btrfs-assistant without password */
polkit.addRule(function(action, subject) {
    if (action.id == "org.btfrs-assistant.pkexec.policy.run" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF