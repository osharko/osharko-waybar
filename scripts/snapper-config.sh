#!/bin/bash
# Snapper configuration
# Match on key name (not value) so the script is idempotent and can be re-run safely

set_snapper_value() {
    local config="$1"
    local key="$2"
    local value="$3"
    sudo sed -i "s|^${key}=.*|${key}=\"${value}\"|" "/etc/snapper/configs/${config}"
}

apply_config() {
    local config="$1"
    echo "Configuring snapper: $config"
    set_snapper_value "$config" TIMELINE_CREATE       "yes"
    set_snapper_value "$config" TIMELINE_MIN_AGE      "1800"
    set_snapper_value "$config" TIMELINE_LIMIT_HOURLY "3"
    set_snapper_value "$config" TIMELINE_LIMIT_DAILY  "7"
    set_snapper_value "$config" TIMELINE_LIMIT_WEEKLY "2"
    set_snapper_value "$config" TIMELINE_LIMIT_MONTHLY "1"
    set_snapper_value "$config" TIMELINE_LIMIT_YEARLY "0"

    # Set qgroup for space-aware cleanup (snapper standard: 1/0)
    local mount
    mount=$(sudo snapper -c "$config" get-config 2>/dev/null | awk '/^SUBVOLUME/ {print $3}')
    local qgroup
    qgroup=$(sudo btrfs qgroup show "$mount" 2>/dev/null | awk '/^1\// {print $1; exit}')
    if [ -n "$qgroup" ]; then
        set_snapper_value "$config" QGROUP "$qgroup"
        echo "  QGROUP set to $qgroup"
    else
        echo "  QGROUP: no level-1 qgroup found, skipping (run 'sudo btrfs quota enable $mount' first)"
    fi
}

apply_config root
apply_config home

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

echo "Done. Verify with: sudo snapper -c root get-config"
