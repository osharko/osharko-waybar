#!/bin/bash
# Brightness control via ddcutil (DDC/CI hardware backlight su tutti i monitor).
# Agnostico al numero di schermi: enumera via `ddcutil detect` e applica a tutti.
# Usage: brightness.sh [status|slider|up|down|set N|init]

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"
VAL_FILE="$CACHE_DIR/waybar-brightness"
DISP_FILE="$CACHE_DIR/waybar-ddcutil-displays"
CMD_FILE="$CACHE_DIR/waybar-ddcutil-cmd"

# --- ddcutil command resolution (with/without sudo, cached) ----------------

resolve_cmd() {
  # Returns the working ddcutil invocation, or empty string if none.
  if [ -s "$CMD_FILE" ]; then
    cat "$CMD_FILE"
    return
  fi
  if ! command -v ddcutil >/dev/null 2>&1; then
    : > "$CMD_FILE"; echo ""; return
  fi
  if ddcutil detect --terse >/dev/null 2>&1; then
    printf 'ddcutil' | tee "$CMD_FILE"
  elif sudo -n ddcutil detect --terse >/dev/null 2>&1; then
    printf 'sudo -n ddcutil' | tee "$CMD_FILE"
  else
    : > "$CMD_FILE"; echo ""
  fi
}

ddc() {
  local cmd
  cmd=$(resolve_cmd)
  [ -z "$cmd" ] && return 1
  # shellcheck disable=SC2086
  $cmd "$@"
}

# --- Display enumeration ---------------------------------------------------

detect_displays() {
  # Store I2C bus numbers (faster than --display N: no re-detection)
  ddc detect --terse 2>/dev/null \
    | awk '/I2C bus:/ {gsub("/dev/i2c-",""); print $NF}' > "$DISP_FILE"
}

get_displays() {
  [ -s "$DISP_FILE" ] || detect_displays
  cat "$DISP_FILE" 2>/dev/null
}

# --- Brightness state ------------------------------------------------------

DDC_FAST_OPTS="--noverify --sleep-multiplier 0.1"

read_hw_brightness() {
  local d v
  for d in $(get_displays); do
    # shellcheck disable=SC2086
    v=$(ddc --bus "$d" $DDC_FAST_OPTS getvcp 10 2>/dev/null \
        | grep -oE 'current value =[[:space:]]*[0-9]+' \
        | grep -oE '[0-9]+' | head -1)
    if [[ "$v" =~ ^[0-9]+$ ]]; then
      echo "$v"; return 0
    fi
  done
  return 1
}

get_brightness() {
  if [ -s "$VAL_FILE" ]; then
    cat "$VAL_FILE"
  else
    # First run: write a placeholder so waybar gets something fast, then
    # read the real HW value in background and refresh waybar when done
    # (getvcp is slow ~500ms — never block the bar on it)
    echo 100 > "$VAL_FILE"
    (
      v=$(read_hw_brightness 2>/dev/null)
      if [[ "$v" =~ ^[0-9]+$ ]]; then
        echo "$v" > "$VAL_FILE"
        pkill -RTMIN+9 waybar 2>/dev/null
      fi
    ) >/dev/null 2>&1 &
    echo 100
  fi
}

# Show OSD via omarchy-swayosd-brightness (used by hardware keys / scroll / reset)
show_osd() {
  command -v omarchy-swayosd-brightness >/dev/null 2>&1 || return 0
  omarchy-swayosd-brightness "$1" >/dev/null 2>&1 &
}

set_brightness() {
  local v=$1
  (( v < 0   )) && v=0
  (( v > 100 )) && v=100
  echo "$v" > "$VAL_FILE"
  local d any=0
  for d in $(get_displays); do
    any=1
    # shellcheck disable=SC2086
    ddc --bus "$d" $DDC_FAST_OPTS setvcp 10 "$v" >/dev/null 2>&1 &
  done
  wait
  pkill -RTMIN+9 waybar 2>/dev/null
  return $((1 - any))
}

step() {
  local cur new
  cur=$(get_brightness)
  new=$((cur + ${1:-0}))
  (( new < 0 ))   && new=0
  (( new > 100 )) && new=100
  set_brightness "$new"
  show_osd "$new"
}

reset() {
  local target=${1:-100}
  set_brightness "$target"
  show_osd "$target"
}

# --- Output ----------------------------------------------------------------

status() {
  if ! command -v ddcutil >/dev/null 2>&1; then
    printf '{"text":"󰃟 ?","tooltip":"ddcutil non installato.\\nEsegui: scripts/setup-ddcutil.sh","class":"brightness error"}\n'
    return
  fi
  local cmd; cmd=$(resolve_cmd)
  if [ -z "$cmd" ]; then
    printf '{"text":"󰃟 !","tooltip":"Permessi DDC/CI mancanti.\\nEsegui: scripts/setup-ddcutil.sh","class":"brightness error"}\n'
    return
  fi
  local g idx bar
  g=$(get_brightness)
  # 8-level proportional bar (replaces the 4-level icon — more granular and
  # still fits in the same width). Glyphs: ▁ ▂ ▃ ▄ ▅ ▆ ▇ █
  idx=$((g * 8 / 100))
  (( idx > 7 )) && idx=7
  (( idx < 0 )) && idx=0
  local glyphs=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
  bar=${glyphs[$idx]}
  printf '{"text":"%s %s%%","tooltip":"Luminosità schermi (DDC/CI): %s%%\\nClick: slider\\nScroll: ±5%%\\nClick destro: reset 100%%","class":"brightness"}\n' \
    "$bar" "$g" "$g"
}

LOG_FILE="${TMPDIR:-/tmp}/brightness.log"
log() { [ -f "${LOG_FILE}.enable" ] && echo "$(date +%H:%M:%S.%N) [$$] $*" >> "$LOG_FILE"; }

slider() {
  # If a popup is already open, do nothing — DON'T kill it (killing triggers
  # rc!=0 → restore, which made multi-click feel like "salva sempre la prima")
  if pgrep -f 'zenity --scale --title=brightness-slider' >/dev/null; then
    log "slider: already open, exit"
    exit 0
  fi
  local orig rc cx cy mx mw tx ty
  orig=$(get_brightness)
  log "slider: start orig=$orig"

  # Capture cursor position BEFORE opening zenity
  IFS=', ' read -r cx cy < <(hyprctl cursorpos)

  # Find the monitor under cursor for clamping
  read -r mx mw < <(hyprctl monitors -j | python3 -c "
import json, sys
cx = $cx
for m in json.load(sys.stdin):
    if m['x'] <= cx < m['x'] + m['width']:
        print(m['x'], m['width']); break
" 2>/dev/null)
  : "${mx:=0}" "${mw:=2560}"
  tx=$((cx - 150))
  (( tx < mx + 8 ))         && tx=$((mx + 8))
  (( tx > mx + mw - 308 ))  && tx=$((mx + mw - 308))
  ty=42  # just below waybar (height 34 + margin)
  log "slider: cursor=$cx,$cy → target=$tx,$ty"

  # Background: position popup once it appears
  (
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      sleep 0.04
      if hyprctl clients -j 2>/dev/null | grep -q '"title": "brightness-slider"'; then
        hyprctl dispatch movewindowpixel "exact $tx $ty,title:^(brightness-slider)$" >/dev/null 2>&1
        break
      fi
    done
  ) &

  # Simple pipe approach: zenity → while-read with coalescing.
  # PIPESTATUS[0] is set in the parent shell after the pipeline ends and gives
  # the REAL zenity exit code (0=Conferma, 1=Ripristina/ESC/close).
  stdbuf -oL zenity --scale --title="brightness-slider" \
    --text="Luminosità schermi (DDC/CI) — Conferma per applicare, Ripristina per tornare a ${orig}%" \
    --min-value=0 --max-value=100 --value="$orig" --step=1 \
    --ok-label="Conferma" --cancel-label="Ripristina" \
    --print-partial 2>/dev/null \
  | {
      while IFS= read -r v; do
        # Coalesce: drain queued values, keep only the latest
        while IFS= read -r -t 0.005 next; do v="$next"; done
        if [[ "$v" =~ ^[0-9]+$ ]]; then
          log "  apply $v"
          set_brightness "$v"
        fi
      done
    }
  rc=${PIPESTATUS[0]}
  log "slider: zenity rc=$rc"

  # rc=0 → Confirm (keep); anything else → Restore
  if [[ "$rc" != "0" ]]; then
    log "slider: restore to $orig"
    set_brightness "$orig"
  else
    log "slider: confirm (keep $(get_brightness))"
  fi
}

# --- Dispatch --------------------------------------------------------------

case "${1:-status}" in
  slider) slider ;;
  up)     step 5 ;;
  down)   step -5 ;;
  set)    set_brightness "${2:-100}"; show_osd "${2:-100}" ;;
  reset)  reset "${2:-100}" ;;
  init)   rm -f "$DISP_FILE" "$CMD_FILE" "$VAL_FILE"
          resolve_cmd >/dev/null
          detect_displays
          echo "Command: $(cat "$CMD_FILE")"
          echo "Displays: $(get_displays | tr '\n' ' ')"
          v=$(read_hw_brightness) && { echo "$v" > "$VAL_FILE"; echo "Current: $v%"; } || echo "Current: unknown (cache=100)"
          ;;
  status|*) status ;;
esac
