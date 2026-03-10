#!/bin/bash
# Snapper configuration
# Match on key name (not value) so the script is idempotent and can be re-run safely

set -e

set_snapper_value() {
    local config="$1"
    local key="$2"
    local value="$3"
    sudo sed -i "s|^${key}=.*|${key}=\"${value}\"|" "/etc/snapper/configs/${config}"
}

apply_config() {
    local config="$1"
    echo "Configuring snapper: $config"
    set_snapper_value "$config" TIMELINE_CREATE        "yes"
    set_snapper_value "$config" TIMELINE_MIN_AGE       "1800"
    set_snapper_value "$config" TIMELINE_LIMIT_HOURLY  "3"
    set_snapper_value "$config" TIMELINE_LIMIT_DAILY   "7"
    set_snapper_value "$config" TIMELINE_LIMIT_WEEKLY  "2"
    set_snapper_value "$config" TIMELINE_LIMIT_MONTHLY "1"
    set_snapper_value "$config" TIMELINE_LIMIT_YEARLY  "0"
}

setup_qgroups() {
    echo "Setting up btrfs qgroups..."
    local mount="/"

    # Detect subvolume IDs dynamically by name
    local root_id home_id
    root_id=$(sudo btrfs subvolume list "$mount" | awk '$NF == "@" {print $2}')
    home_id=$(sudo btrfs subvolume list "$mount" | awk '$NF == "@home" {print $2}')

    if [ -z "$root_id" ] || [ -z "$home_id" ]; then
        echo "  WARNING: could not detect @ or @home subvolume IDs, skipping qgroup setup"
        return
    fi

    echo "  Found: @ = 0/${root_id}, @home = 0/${home_id}"

    # Create qgroup 1/0 for root if missing
    if ! sudo btrfs qgroup show "$mount" 2>/dev/null | grep -q "^1/0"; then
        sudo btrfs qgroup create 1/0 "$mount"
        echo "  Created qgroup 1/0"
    fi
    sudo btrfs qgroup assign "0/${root_id}" 1/0 "$mount" 2>/dev/null || true

    # Create qgroup 1/1 for home if missing
    if ! sudo btrfs qgroup show "$mount" 2>/dev/null | grep -q "^1/1"; then
        sudo btrfs qgroup create 1/1 "$mount"
        echo "  Created qgroup 1/1"
    fi
    sudo btrfs qgroup assign "0/${home_id}" 1/1 "$mount" 2>/dev/null || true

    set_snapper_value root QGROUP "1/0"
    set_snapper_value home QGROUP "1/1"
    echo "  QGROUP: root=1/0, home=1/1"
}

apply_config root
apply_config home
setup_qgroups

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
