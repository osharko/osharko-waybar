#!/bin/bash
# Claude Code usage monitor for Waybar
# Supports multiple accounts via scripts/claude-accounts.conf (gitignored)
# Shows 5h window and weekly limit with active-limit detection

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACCOUNTS_CONF="${SCRIPT_DIR}/claude-accounts.conf"

# ── Load accounts ────────────────────────────────────────────────────────────
declare -a ACCOUNT_LABELS=()
declare -a ACCOUNT_PATHS=()

if [[ -f "$ACCOUNTS_CONF" ]]; then
    while IFS='|' read -r label path; do
        [[ "$label" =~ ^[[:space:]]*# ]] && continue   # skip comments
        [[ -z "${label// }" ]]           && continue   # skip blank lines
        path="${path// /}"                              # trim spaces
        path="${path/#\~/$HOME}"                        # expand ~
        ACCOUNT_LABELS+=("$label")
        ACCOUNT_PATHS+=("$path")
    done < "$ACCOUNTS_CONF"
fi

# Fallback to a single default account
if [[ ${#ACCOUNT_PATHS[@]} -eq 0 ]]; then
    ACCOUNT_LABELS+=("C")
    ACCOUNT_PATHS+=("$HOME/.claude")
fi

# ── Helpers ──────────────────────────────────────────────────────────────────
time_remaining() {
    local reset_at="$1"
    [[ -z "$reset_at" ]] && { echo "?"; return; }
    local now reset diff hours mins
    now=$(date +%s)
    reset=$(date -d "$reset_at" +%s 2>/dev/null)
    [[ -z "$reset" || "$reset" -le "$now" ]] && { echo "now"; return; }
    diff=$((reset - now))
    hours=$((diff / 3600))
    mins=$(( (diff % 3600) / 60 ))
    if   (( hours > 24 )); then echo "$((hours / 24))d $((hours % 24))h"
    elif (( hours > 0  )); then echo "${hours}h ${mins}m"
    else                        echo "${mins}m"
    fi
}

# Which limit is the binding constraint (the one closest to 100%)
active_limit() {
    local five_h="$1" seven_d="$2"
    (( seven_d >= five_h )) && echo "weekly" || echo "5h"
}

# ── Per-account fetch ────────────────────────────────────────────────────────
TEXT_PARTS=()
TOOLTIP_SECTIONS=()
WORST_CLASS="normal"

for i in "${!ACCOUNT_PATHS[@]}"; do
    label="${ACCOUNT_LABELS[$i]}"
    claude_path="${ACCOUNT_PATHS[$i]}"
    creds_file="${claude_path}/.credentials.json"

    if [[ ! -f "$creds_file" ]]; then
        TEXT_PARTS+=("${label}:?")
        TOOLTIP_SECTIONS+=("[${label}] No credentials found at ${creds_file}")
        continue
    fi

    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null)
    if [[ -z "$TOKEN" ]]; then
        TEXT_PARTS+=("${label}:?")
        TOOLTIP_SECTIONS+=("[${label}] No access token in credentials")
        continue
    fi

    RESPONSE=$(curl -s --max-time 5 \
        "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" 2>/dev/null)

    if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | jq -e '.error' &>/dev/null; then
        TEXT_PARTS+=("${label}:err")
        TOOLTIP_SECTIONS+=("[${label}] API error or no response")
        continue
    fi

    FIVE_H_UTIL=$(echo "$RESPONSE" | jq -r '.five_hour.utilization  // 0')
    FIVE_H_RESET=$(echo "$RESPONSE" | jq -r '.five_hour.resets_at   // empty')
    SEVEN_D_UTIL=$(echo "$RESPONSE" | jq -r '.seven_day.utilization // 0')
    SEVEN_D_RESET=$(echo "$RESPONSE" | jq -r '.seven_day.resets_at  // empty')

    FIVE_H_INT=${FIVE_H_UTIL%.*}
    SEVEN_D_INT=${SEVEN_D_UTIL%.*}
    FIVE_H_TIME=$(time_remaining "$FIVE_H_RESET")
    SEVEN_D_TIME=$(time_remaining "$SEVEN_D_RESET")

    BINDING=$(active_limit "$FIVE_H_INT" "$SEVEN_D_INT")

    # Urgency class (take worst across all accounts)
    if   (( FIVE_H_INT >= 80 || SEVEN_D_INT >= 80 )); then
        WORST_CLASS="critical"
    elif (( FIVE_H_INT >= 50 || SEVEN_D_INT >= 50 )); then
        [[ "$WORST_CLASS" != "critical" ]] && WORST_CLASS="warning"
    fi

    TEXT_PARTS+=("${label}:${FIVE_H_INT}%")

    # Active-limit markers
    FIVE_H_MARKER="  "
    SEVEN_D_MARKER="  "
    if [[ "$BINDING" == "5h"     ]]; then FIVE_H_MARKER=" ⚡"; fi
    if [[ "$BINDING" == "weekly" ]]; then SEVEN_D_MARKER=" ⚡"; fi

    # Lockout state labels
    FIVE_H_STATE=""
    SEVEN_D_STATE=""
    (( FIVE_H_INT  >= 100 )) && FIVE_H_STATE="  ✗ LOCKED OUT"
    (( SEVEN_D_INT >= 100 )) && SEVEN_D_STATE="  ✗ LOCKED OUT"

    SECTION="[${label}] ─────────────────────────────────────────\n"
    SECTION+="  󰔟 5h window  ${FIVE_H_INT}%${FIVE_H_MARKER}${FIVE_H_STATE}   → resets in ${FIVE_H_TIME}\n"
    SECTION+="  󰃰 Weekly     ${SEVEN_D_INT}%${SEVEN_D_MARKER}${SEVEN_D_STATE}   → resets in ${SEVEN_D_TIME}"

    EXTRA_ENABLED=$(echo "$RESPONSE" | jq -r '.extra_usage.is_enabled // false')
    if [[ "$EXTRA_ENABLED" == "true" ]]; then
        EXTRA_INT=$(echo "$RESPONSE" | jq -r '.extra_usage.utilization // 0')
        EXTRA_INT=${EXTRA_INT%.*}
        SECTION+="\n  ＋ Extra      ${EXTRA_INT}%"
    fi

    TOOLTIP_SECTIONS+=("$SECTION")
done

# ── Build final output ───────────────────────────────────────────────────────
if [[ ${#TEXT_PARTS[@]} -eq 1 ]]; then
    TEXT="󰧑 ${TEXT_PARTS[0]}"
else
    TEXT="󰧑 $(IFS=' ∙ '; echo "${TEXT_PARTS[*]}")"
fi

TOOLTIP="Claude Code Usage\n"
TOOLTIP+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
TOOLTIP+="⚡ = active limit (binding constraint)\n"
for section in "${TOOLTIP_SECTIONS[@]}"; do
    TOOLTIP+="\n${section}"
done

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' \
    "$TEXT" "$TOOLTIP" "$WORST_CLASS"
