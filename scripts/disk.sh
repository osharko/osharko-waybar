#!/usr/bin/env bash
# disk.sh — disco unificato (btrfs-aware) per waybar

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-cache"
mkdir -p "$CACHE_DIR"
NL=$'\n'

# Info totale da /
df_out=$(df -P --block-size=1 / 2>/dev/null | awk 'NR==2')
dev=$(echo "$df_out" | awk '{print $1}')
size_bytes=$(echo "$df_out" | awk '{print $2}')
used_bytes=$(echo "$df_out" | awk '{print $3}')
avail_bytes=$(echo "$df_out" | awk '{print $4}')
use_pct=$(echo "$df_out" | awk '{print $5}' | tr -d '%')

# Resolve device name (es. /dev/mapper/root → dm-0)
dev_name=$(basename "$dev")
if [[ "$dev" == /dev/mapper/* ]]; then
  dm_real=$(ls -la /dev/mapper/ 2>/dev/null | awk -v name="$dev_name" '$9==name{gsub(".*/","",$NF); print $NF}')
  [[ -n "$dm_real" ]] && dev_name="$dm_real"
fi

STAT_FILE="$CACHE_DIR/disk-${dev_name}.stat"

# Human readable
b2h() {
  awk "BEGIN{
    b=$1
    if(b>=1073741824) printf \"%.1fG\", b/1073741824
    else if(b>=1048576) printf \"%.1fM\", b/1048576
    else if(b>=1024) printf \"%.0fK\", b/1024
    else printf \"%dB\", b
  }"
}

size_h=$(b2h "$size_bytes")
used_h=$(b2h "$used_bytes")
avail_h=$(b2h "$avail_bytes")

# Icona fill (▁▂▃▄▅▆▇█)
if   (( use_pct <= 12 )); then fill="▁"
elif (( use_pct <= 25 )); then fill="▂"
elif (( use_pct <= 37 )); then fill="▃"
elif (( use_pct <= 50 )); then fill="▄"
elif (( use_pct <= 62 )); then fill="▅"
elif (( use_pct <= 75 )); then fill="▆"
elif (( use_pct <= 87 )); then fill="▇"
else                            fill="█"
fi

# CSS class
if   (( use_pct >= 90 )); then css_class="critical"
elif (( use_pct >= 80 )); then css_class="high"
elif (( use_pct >= 50 )); then css_class="medium"
else                           css_class="low"
fi

# I/O speed da /proc/diskstats
now_ns=$(date +%s%N)
diskstats_line=$(awk -v dev="$dev_name" '$3==dev{print}' /proc/diskstats 2>/dev/null)
read_speed=0; write_speed=0; read_await=0; write_await=0

if [[ -n "$diskstats_line" ]]; then
  rd_ops=$(echo "$diskstats_line"   | awk '{print $4}')
  rd_sectors=$(echo "$diskstats_line" | awk '{print $6}')
  rd_ms=$(echo "$diskstats_line"    | awk '{print $7}')
  wr_ops=$(echo "$diskstats_line"   | awk '{print $8}')
  wr_sectors=$(echo "$diskstats_line" | awk '{print $10}')
  wr_ms=$(echo "$diskstats_line"    | awk '{print $11}')

  curr_stat="${now_ns} ${rd_sectors} ${rd_ms} ${wr_sectors} ${wr_ms} ${rd_ops} ${wr_ops}"

  if [[ -f "$STAT_FILE" ]]; then
    read -r p_ts p_rd_s p_rd_ms p_wr_s p_wr_ms p_rd_ops p_wr_ops < "$STAT_FILE"
    delta_ns=$(( now_ns - p_ts ))
    if (( delta_ns > 100000000 )); then
      delta_s=$(awk "BEGIN{printf \"%.6f\", $delta_ns/1000000000}")
      delta_rd=$(( rd_sectors - p_rd_s ))
      delta_wr=$(( wr_sectors - p_wr_s ))
      delta_rd_ms=$(( rd_ms - p_rd_ms ))
      delta_wr_ms=$(( wr_ms - p_wr_ms ))
      delta_rd_ops=$(( rd_ops - p_rd_ops ))
      delta_wr_ops=$(( wr_ops - p_wr_ops ))
      read_speed=$(awk "BEGIN{printf \"%.0f\", ($delta_rd*512)/$delta_s}")
      write_speed=$(awk "BEGIN{printf \"%.0f\", ($delta_wr*512)/$delta_s}")
      (( delta_rd_ops > 0 )) && read_await=$(awk "BEGIN{printf \"%.1f\", $delta_rd_ms/$delta_rd_ops}")
      (( delta_wr_ops > 0 )) && write_await=$(awk "BEGIN{printf \"%.1f\", $delta_wr_ms/$delta_wr_ops}")
    fi
  fi
  echo "$curr_stat" > "$STAT_FILE"
fi

fmt_speed() {
  awk "BEGIN{b=$1; if(b>=1073741824) printf \"%.1f GB/s\",b/1073741824; else if(b>=1048576) printf \"%.1f MB/s\",b/1048576; else if(b>=1024) printf \"%.0f KB/s\",b/1024; else printf \"%d B/s\",b}"
}

# ── Subvolumi da /proc/mounts ──
root_subvol=$(awk '$2=="/" {match($4,/subvol=\/([^,)]+)/,a); print a[1]}' /proc/mounts 2>/dev/null)
home_subvol=$(awk '$2=="/home" {match($4,/subvol=\/([^,)]+)/,a); print a[1]}' /proc/mounts 2>/dev/null)

# Label subvol (es. "/@ " oppure vuoto se non btrfs)
root_label=""
home_label=""
[[ -n "$root_subvol"  ]] && root_label=" (subvol ${root_subvol})"
[[ -n "$home_subvol"  ]] && home_label=" (subvol ${home_subvol})"

# ── Dimensioni per subvol via btrfs qgroup (opzionale) ──
root_qsize=""
home_qsize=""

if command -v btrfs &>/dev/null; then
  root_id=$(awk '$2=="/" {match($4,/subvolid=([0-9]+)/,a); print a[1]}' /proc/mounts 2>/dev/null)
  home_id=$(awk '$2=="/home" {match($4,/subvolid=([0-9]+)/,a); print a[1]}' /proc/mounts 2>/dev/null)

  if [[ -n "$root_id" || -n "$home_id" ]]; then
    qgroup=$(timeout 2 btrfs qgroup show -re --sync / 2>/dev/null)
    if [[ -n "$qgroup" ]]; then
      [[ -n "$root_id" ]] && root_qsize=$(echo "$qgroup" | awk -v id="0/$root_id" '$1==id{print $2}')
      [[ -n "$home_id" ]] && home_qsize=$(echo "$qgroup" | awk -v id="0/$home_id" '$1==id{print $2}')
    fi
  fi
fi

# Formatta righe subvol nel tooltip
root_line="/     ${root_label}"
home_line="/home ${home_label}"
[[ -n "$root_qsize" ]] && root_line+=" → ${root_qsize}"
[[ -n "$home_qsize" ]] && home_line+=" → ${home_qsize}"

# ── Snapshot (opzionale) ──
snap_section=""
for snap_dir in "/.snapshots" "/home/.snapshots"; do
  if [[ -d "$snap_dir" ]]; then
    n=$(ls -1 "$snap_dir" 2>/dev/null | grep -c .)
    if (( n > 0 )); then
      sz=$(timeout 3 du -sh "$snap_dir" 2>/dev/null | awk '{print $1}')
      snap_section+="${NL}  ${snap_dir}: ${n} snapshot"
      [[ $n -gt 1 ]] && snap_section+="s"
      [[ -n "$sz" ]] && snap_section+=" (~${sz})"
    fi
  fi
done

# ── Build tooltip ──
tooltip="${dev_name}"
[[ -n "$root_subvol" ]] && tooltip+=" — btrfs"
tooltip+="${NL}━━━━━━━━━━━━━━━━━━━━━━━"
tooltip+="${NL}Totale:      ${used_h} / ${size_h} (${use_pct}%)"
tooltip+="${NL}Disponibile: ${avail_h}"
tooltip+="${NL}━━━━━━━━━━━━━━━━━━━━━━━"
tooltip+="${NL}${root_line}"
[[ -n "$home_subvol" ]] && tooltip+="${NL}${home_line}"
if [[ -n "$snap_section" ]]; then
  tooltip+="${NL}━━━━━━━━━━━━━━━━━━━━━━━"
  tooltip+="${NL}Snapshot:${snap_section}"
fi
tooltip+="${NL}━━━━━━━━━━━━━━━━━━━━━━━"
tooltip+="${NL}Read:  $(fmt_speed $read_speed)  await: ${read_await}ms"
tooltip+="${NL}Write: $(fmt_speed $write_speed)  await: ${write_await}ms"

jq -cn \
  --arg text "󰋊${fill}" \
  --arg tooltip "$tooltip" \
  --arg class "$css_class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
