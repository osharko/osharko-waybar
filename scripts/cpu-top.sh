#!/usr/bin/env bash
# cpu-top.sh — CPU usage + top 5 processi per waybar

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-cache"
mkdir -p "$CACHE_DIR"
STAT_FILE="$CACHE_DIR/cpu.stat"
NL=$'\n'

# Delta /proc/stat
prev_stat=""
[[ -f "$STAT_FILE" ]] && prev_stat=$(cat "$STAT_FILE")
curr_stat=$(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8; exit}' /proc/stat)
echo "$curr_stat" > "$STAT_FILE"

cpu_pct=0
if [[ -n "$prev_stat" ]]; then
  read -r pu ps pn pi pw pi2 ph <<< "$prev_stat"
  read -r cu cs cn ci cw ci2 ch <<< "$curr_stat"
  prev_idle=$(( pi + pw ))
  curr_idle=$(( ci + cw ))
  prev_total=$(( pu + ps + pn + pi + pw + pi2 + ph ))
  curr_total=$(( cu + cs + cn + ci + cw + ci2 + ch ))
  delta_idle=$(( curr_idle - prev_idle ))
  delta_total=$(( curr_total - prev_total ))
  (( delta_total > 0 )) && cpu_pct=$(( (delta_total - delta_idle) * 100 / delta_total ))
fi

# Frequenza media
freq_mhz=$(awk '/^cpu MHz/{sum+=$4; n++} END{if(n>0) printf "%.0f", sum/n}' /proc/cpuinfo 2>/dev/null)
freq_line=""
[[ -n "$freq_mhz" ]] && freq_line=" | Freq: $(awk "BEGIN{printf \"%.1f\", $freq_mhz/1000}") GHz"

# Classe CSS
if   (( cpu_pct >= 85 )); then css_class="high"
elif (( cpu_pct >= 40 )); then css_class="medium"
else                           css_class="low"
fi

# Top 5 processi
top_procs=$(ps aux --sort=-%cpu 2>/dev/null | awk '
  NR>1 && NR<=6 {
    name=$11; sub(".*/","",name)
    printf "  %-20s %5.1f%%\n", substr(name,1,20), $3
  }
')

tooltip="CPU: ${cpu_pct}%${freq_line}${NL}━━━━━━━━━━━━━━━━━━━━━━━${NL}Top CPU:${NL}${top_procs}"

jq -cn \
  --arg text "󰍛 ${cpu_pct}%" \
  --arg tooltip "$tooltip" \
  --arg class "$css_class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
