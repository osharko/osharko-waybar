#!/bin/bash
# Claude Code usage monitor for Waybar
# Shows 5h and weekly context consumption with time to refresh

CREDS_FILE="$HOME/.claude/.credentials.json"

# Exit silently if no Claude config
if [[ ! -f "$CREDS_FILE" ]]; then
    echo ""
    exit 0
fi

# Extract token
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
if [[ -z "$TOKEN" ]]; then
    echo ""
    exit 0
fi

# Fetch usage data
RESPONSE=$(curl -s --max-time 5 \
    "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" 2>/dev/null)

if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | jq -e '.error' &>/dev/null; then
    echo ""
    exit 0
fi

# Parse values
FIVE_H_UTIL=$(echo "$RESPONSE" | jq -r '.five_hour.utilization // 0')
FIVE_H_RESET=$(echo "$RESPONSE" | jq -r '.five_hour.resets_at // empty')
SEVEN_D_UTIL=$(echo "$RESPONSE" | jq -r '.seven_day.utilization // 0')
SEVEN_D_RESET=$(echo "$RESPONSE" | jq -r '.seven_day.resets_at // empty')

# Calculate time remaining
time_remaining() {
    local reset_at="$1"
    if [[ -z "$reset_at" ]]; then
        echo "?"
        return
    fi
    local now=$(date +%s)
    local reset=$(date -d "$reset_at" +%s 2>/dev/null)
    if [[ -z "$reset" ]] || [[ "$reset" -le "$now" ]]; then
        echo "now"
        return
    fi
    local diff=$((reset - now))
    local hours=$((diff / 3600))
    local mins=$(( (diff % 3600) / 60 ))
    if [[ $hours -gt 24 ]]; then
        local days=$((hours / 24))
        hours=$((hours % 24))
        echo "${days}d ${hours}h"
    elif [[ $hours -gt 0 ]]; then
        echo "${hours}h ${mins}m"
    else
        echo "${mins}m"
    fi
}

FIVE_H_TIME=$(time_remaining "$FIVE_H_RESET")
SEVEN_D_TIME=$(time_remaining "$SEVEN_D_RESET")

# Format integers for display
FIVE_H_INT=${FIVE_H_UTIL%.*}
SEVEN_D_INT=${SEVEN_D_UTIL%.*}

# Determine urgency class
CLASS="normal"
if (( FIVE_H_INT >= 80 )); then
    CLASS="critical"
elif (( FIVE_H_INT >= 50 )); then
    CLASS="warning"
fi

# Build waybar JSON output
TEXT="󰧑 ${FIVE_H_INT}%"
TOOLTIP="Claude Usage (Max 20x)\n\n5h: ${FIVE_H_INT}% \u2022 resets in ${FIVE_H_TIME}\nWeekly: ${SEVEN_D_INT}% \u2022 resets in ${SEVEN_D_TIME}"

# Add extra usage info if enabled
EXTRA_ENABLED=$(echo "$RESPONSE" | jq -r '.extra_usage.is_enabled // false')
if [[ "$EXTRA_ENABLED" == "true" ]]; then
    EXTRA_UTIL=$(echo "$RESPONSE" | jq -r '.extra_usage.utilization // 0')
    EXTRA_INT=${EXTRA_UTIL%.*}
    TOOLTIP="${TOOLTIP}\nExtra usage: ${EXTRA_INT}%"
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
