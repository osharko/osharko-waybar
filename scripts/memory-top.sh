#!/usr/bin/env bash
# memory-top.sh — RAM + Swap usage + top 5 processi per waybar

NL=$'\n'

declare -A meminfo
while IFS=': ' read -r key value _; do
  meminfo["$key"]=$value
done < /proc/meminfo

mem_total_kb=${meminfo[MemTotal]:-0}
mem_avail_kb=${meminfo[MemAvailable]:-0}
swap_total_kb=${meminfo[SwapTotal]:-0}
swap_free_kb=${meminfo[SwapFree]:-0}

mem_used_kb=$(( mem_total_kb - mem_avail_kb ))
swap_used_kb=$(( swap_total_kb - swap_free_kb ))

kb2g() { awk "BEGIN{printf \"%.1f\", $1/1048576}"; }

mem_used_g=$(kb2g "$mem_used_kb")
mem_total_g=$(kb2g "$mem_total_kb")
swap_used_g=$(kb2g "$swap_used_kb")
swap_total_g=$(kb2g "$swap_total_kb")

mem_pct=0
(( mem_total_kb > 0 )) && mem_pct=$(( mem_used_kb * 100 / mem_total_kb ))

# Classe CSS
if   (( mem_pct >= 85 )); then css_class="high"
elif (( mem_pct >= 40 )); then css_class="medium"
else                           css_class="low"
fi

# Top 5 processi
top_procs=$(ps aux --sort=-%mem 2>/dev/null | awk '
  NR>1 && NR<=6 {
    name=$11; sub(".*/","",name)
    printf "  %-20s %5.1f%%\n", substr(name,1,20), $4
  }
')

tooltip="RAM: ${mem_used_g}G / ${mem_total_g}G (${mem_pct}%)"
(( swap_total_kb > 0 )) && tooltip+="${NL}Swap: ${swap_used_g}G / ${swap_total_g}G"
tooltip+="${NL}━━━━━━━━━━━━━━━━━━━━━━━${NL}Top RAM:${NL}${top_procs}"

jq -cn \
  --arg text " ${mem_used_g}G" \
  --arg tooltip "$tooltip" \
  --arg class "$css_class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
