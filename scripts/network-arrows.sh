#!/usr/bin/env bash
# network-arrows.sh — icona WiFi + frecce colorate per waybar

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-cache"
mkdir -p "$CACHE_DIR"

# Interfaccia default
iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

if [[ -z "$iface" ]]; then
  jq -cn \
    --arg text "󰤮" \
    --arg tooltip "Disconnesso" \
    --arg class "disconnected" \
    '{text: $text, tooltip: $tooltip, class: $class}'
  exit 0
fi

# Determina tipo interfaccia
is_wifi=false
[[ "$iface" == wl* ]] && is_wifi=true

# Velocità da /proc/net/dev
STAT_FILE="$CACHE_DIR/network-${iface}.stat"
now_ns=$(date +%s%N)

net_line=$(awk -v iface="$iface:" '$1==iface{print}' /proc/net/dev 2>/dev/null)
rx_bytes=$(echo "$net_line" | awk '{print $2}')
tx_bytes=$(echo "$net_line" | awk '{print $10}')

down_bps=0
up_bps=0

if [[ -f "$STAT_FILE" ]]; then
  read -r p_ts p_rx p_tx <<< "$(cat "$STAT_FILE")"
  delta_ns=$(( now_ns - p_ts ))
  if (( delta_ns > 0 )); then
    delta_rx=$(( rx_bytes - p_rx ))
    delta_tx=$(( tx_bytes - p_tx ))
    down_bps=$(awk "BEGIN{printf \"%.0f\", $delta_rx * 1000000000 / $delta_ns}")
    up_bps=$(awk "BEGIN{printf \"%.0f\", $delta_tx * 1000000000 / $delta_ns}")
  fi
fi

echo "$now_ns $rx_bytes $tx_bytes" > "$STAT_FILE"

# Colore freccia basato su velocità (bytes/s)
speed_color() {
  local bps=$1
  if   (( bps >= 52428800 )); then echo "#f38ba8"   # rosso ≥50 MB/s
  elif (( bps >= 10485760 )); then echo "#f9e2af"   # giallo ≥10 MB/s
  elif (( bps >= 102400   )); then echo "#a6e3a1"   # verde ≥100 KB/s
  else                              echo "#E0E0E0"   # bianco < 100 KB/s
  fi
}

up_color=$(speed_color "$up_bps")
down_color=$(speed_color "$down_bps")

# Formatta velocità
format_speed() {
  local bps=$1
  awk "BEGIN{
    b=$bps
    if(b>=1073741824) printf \"%.1f GB/s\", b/1073741824
    else if(b>=1048576) printf \"%.1f MB/s\", b/1048576
    else if(b>=1024) printf \"%.0f KB/s\", b/1024
    else printf \"%d B/s\", b
  }"
}

down_str=$(format_speed "$down_bps")
up_str=$(format_speed "$up_bps")

# Icona WiFi
if $is_wifi; then
  # Signal strength: try /proc/net/wireless, then iw, then iwconfig
  signal_raw=$(awk -v iface="$iface:" '$1==iface{print $3}' /proc/net/wireless 2>/dev/null | tr -d '.')
  if [[ -n "$signal_raw" ]] && [[ "$signal_raw" != "0" ]]; then
    signal_raw=$(awk "BEGIN{printf \"%.0f\", $signal_raw * 100 / 70}")
  else
    # iw dev link fallback (dBm)
    signal_dbm=$(iw dev "$iface" link 2>/dev/null | awk '/signal/{print $2}')
    if [[ -z "$signal_dbm" ]]; then
      signal_dbm=$(iwconfig "$iface" 2>/dev/null | awk '/Signal level/{gsub(/.*Signal level=/,""); gsub(/ .*/,""); print}')
    fi
    if [[ "$signal_dbm" =~ ^-?[0-9]+ ]]; then
      signal_raw=$(awk "BEGIN{
        dbm=$signal_dbm
        if(dbm>=-50) pct=100
        else if(dbm<=-90) pct=0
        else pct=int((dbm+90)*2.5)
        print pct
      }")
    else
      signal_raw=0
    fi
  fi

  signal_pct=${signal_raw:-0}
  if   (( signal_pct >= 81 )); then wifi_icon="󰤨"
  elif (( signal_pct >= 61 )); then wifi_icon="󰤥"
  elif (( signal_pct >= 41 )); then wifi_icon="󰤢"
  elif (( signal_pct >= 21 )); then wifi_icon="󰤟"
  else                               wifi_icon="󰤯"
  fi

  # ESSID e frequenza per tooltip
  essid=$(iwconfig "$iface" 2>/dev/null | awk '/ESSID/{gsub(/.*ESSID:"/,""); gsub(/".*/,""); print}')
  [[ -z "$essid" ]] && essid=$(iw dev "$iface" info 2>/dev/null | awk '/ssid/{print $2}')
  freq=$(iwconfig "$iface" 2>/dev/null | awk '/Frequency/{gsub(/.*Frequency:/,""); gsub(/ .*/,""); print}')
  ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet /{print $2; exit}')

  tooltip="${wifi_icon} ${essid:-N/A}"
  [[ -n "$freq" ]] && tooltip+=$'\n'"Freq: ${freq} GHz"
  [[ -n "$ip" ]] && tooltip+=$'\n'"IP: ${ip}"
  tooltip+=$'\n'"━━━━━━━━━━━━━━━━━━━━━━━"
  tooltip+=$'\n'"⇣ Down: ${down_str}"
  tooltip+=$'\n'"⇡ Up:   ${up_str}"
else
  wifi_icon="󰀂"
  ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet /{print $2; exit}')
  tooltip="󰀂 Ethernet (${iface})"
  [[ -n "$ip" ]] && tooltip+=$'\n'"IP: ${ip}"
  tooltip+=$'\n'"━━━━━━━━━━━━━━━━━━━━━━━"
  tooltip+=$'\n'"⇣ Down: ${down_str}"
  tooltip+=$'\n'"⇡ Up:   ${up_str}"
fi

# Testo con Pango markup
text="${wifi_icon} <span color='${up_color}'>↑</span><span color='${down_color}'>↓</span>"

jq -cn \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  --arg class "connected" \
  '{text: $text, tooltip: $tooltip, class: $class}'
