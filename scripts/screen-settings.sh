#!/bin/bash
# Screen settings: screensaver & auto-lock configuration via walker dmenu

HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"

main_menu() {
    local choice
    choice=$(printf "🖥 Screensaver Settings\n🔒 Auto-Lock Settings" | walker --dmenu)

    case "$choice" in
        *"Screensaver"*) screensaver_menu ;;
        *"Auto-Lock"*) autolock_menu ;;
    esac
}

screensaver_menu() {
    local choice
    choice=$(printf "5 minuti\n10 minuti\n15 minuti\n30 minuti\n1 ora\nDisabilita screensaver" | walker --dmenu)

    case "$choice" in
        "5 minuti")   apply_screensaver_timeout 300 ;;
        "10 minuti")  apply_screensaver_timeout 600 ;;
        "15 minuti")  apply_screensaver_timeout 900 ;;
        "30 minuti")  apply_screensaver_timeout 1800 ;;
        "1 ora")      apply_screensaver_timeout 3600 ;;
        "Disabilita screensaver") disable_screensaver ;;
    esac
}

autolock_menu() {
    local choice
    choice=$(printf "5 minuti\n10 minuti\n15 minuti\n30 minuti\n1 ora\nDisabilita auto-lock" | walker --dmenu)

    case "$choice" in
        "5 minuti")   apply_timeout 300 301 600 ;;
        "10 minuti")  apply_timeout 600 601 900 ;;
        "15 minuti")  apply_timeout 900 901 1200 ;;
        "30 minuti")  apply_timeout 1800 1801 2100 ;;
        "1 ora")      apply_timeout 3600 3601 3900 ;;
        "Disabilita auto-lock") disable_idle ;;
    esac
}

# Read current screensaver timeout from config, default 300
get_current_screensaver_timeout() {
    local t
    t=$(grep -A1 'omarchy-launch-screensaver' "$HYPRIDLE_CONF" 2>/dev/null | grep -oP 'timeout\s*=\s*\K[0-9]+' | head -1)
    # Try alternative: look for screensaver listener
    if [ -z "$t" ]; then
        t=$(awk '/omarchy-launch-screensaver/{found=1} found && /timeout/{match($0,/[0-9]+/,a); print a[0]; exit}' "$HYPRIDLE_CONF" 2>/dev/null)
    fi
    echo "${t:-300}"
}

# Read current lock timeout from config
get_current_lock_timeout() {
    local t
    t=$(awk '/loginctl lock-session/ && !/before_sleep/{found=1} found && /timeout/{match($0,/[0-9]+/,a); print a[0]; exit}' "$HYPRIDLE_CONF" 2>/dev/null)
    if [ -z "$t" ]; then
        t=$(grep -B1 'loginctl lock-session' "$HYPRIDLE_CONF" 2>/dev/null | grep -v 'before_sleep' | grep -oP 'timeout\s*=\s*\K[0-9]+' | head -1)
    fi
    echo "${t:-301}"
}

apply_screensaver_timeout() {
    local ss_t=$1
    local lock_t
    lock_t=$(get_current_lock_timeout)

    # If lock timeout is less than new screensaver timeout, bump it
    if [ "$lock_t" -le "$ss_t" ]; then
        lock_t=$((ss_t + 1))
    fi

    local dpms_t=$((lock_t + 299))

    write_config "$ss_t" "$lock_t" "$dpms_t"
    restart_hypridle
    notify-send "Screensaver" "Screensaver dopo $((ss_t / 60)) minuti" -i preferences-system
}

apply_timeout() {
    local ss_t
    ss_t=$(get_current_screensaver_timeout)
    local lock_t=$2
    local dpms_t=$3

    # If screensaver timeout >= lock timeout, set screensaver 1s before lock
    if [ "$ss_t" -ge "$lock_t" ]; then
        ss_t=$((lock_t - 1))
    fi

    write_config "$ss_t" "$lock_t" "$dpms_t"
    restart_hypridle
    notify-send "Auto-Lock" "Lock dopo $((lock_t / 60)) minuti" -i preferences-system
}

write_config() {
    local ss_t=$1
    local lock_t=$2
    local dpms_t=$3

    cat > "$HYPRIDLE_CONF" << EOF
general {
    lock_cmd = omarchy-lock-screen                         # lock screen and 1password
    before_sleep_cmd = loginctl lock-session               # lock before suspend.
    after_sleep_cmd = sleep 1 && hyprctl dispatch dpms on  # delay for PAM readiness, then turn on display.
    inhibit_sleep = 3                                      # wait until screen is locked
}

listener {
    timeout = ${ss_t}
    on-timeout = pidof hyprlock || omarchy-launch-screensaver # start screensaver
}

listener {
    timeout = ${lock_t}
    on-timeout = loginctl lock-session # lock screen
}

listener {
    timeout = ${dpms_t}
    on-timeout = brightnessctl -sd '*::kbd_backlight' set 0  # turn off keyboard backlight
    on-resume = brightnessctl -rd '*::kbd_backlight'         # restore keyboard backlight
}

listener {
    timeout = ${dpms_t}
    on-timeout = hyprctl dispatch dpms off                   # screen off
    on-resume = hyprctl dispatch dpms on && brightnessctl -r # screen on
}
EOF
}

disable_screensaver() {
    local lock_t
    lock_t=$(get_current_lock_timeout)
    local dpms_t=$((lock_t + 299))

    cat > "$HYPRIDLE_CONF" << EOF
general {
    lock_cmd = omarchy-lock-screen                         # lock screen and 1password
    before_sleep_cmd = loginctl lock-session               # lock before suspend.
    after_sleep_cmd = sleep 1 && hyprctl dispatch dpms on  # delay for PAM readiness, then turn on display.
    inhibit_sleep = 3                                      # wait until screen is locked
}

listener {
    timeout = ${lock_t}
    on-timeout = loginctl lock-session # lock screen
}

listener {
    timeout = ${dpms_t}
    on-timeout = brightnessctl -sd '*::kbd_backlight' set 0  # turn off keyboard backlight
    on-resume = brightnessctl -rd '*::kbd_backlight'         # restore keyboard backlight
}

listener {
    timeout = ${dpms_t}
    on-timeout = hyprctl dispatch dpms off                   # screen off
    on-resume = hyprctl dispatch dpms on && brightnessctl -r # screen on
}
EOF

    restart_hypridle
    notify-send "Screensaver" "Screensaver disabilitato" -i preferences-system
}

disable_idle() {
    cat > "$HYPRIDLE_CONF" << 'EOF'
general {
    lock_cmd = omarchy-lock-screen                         # lock screen and 1password
    before_sleep_cmd = loginctl lock-session               # lock before suspend.
    after_sleep_cmd = sleep 1 && hyprctl dispatch dpms on  # delay for PAM readiness, then turn on display.
    inhibit_sleep = 3                                      # wait until screen is locked
}
EOF

    restart_hypridle
    notify-send "Auto-Lock" "Auto-lock disabilitato" -i preferences-system
}

restart_hypridle() {
    killall hypridle 2>/dev/null
    uwsm-app -- hypridle &
    disown
}

main_menu
