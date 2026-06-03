#!/usr/bin/env bash
# PCaC Common Library
# Shared helpers for Left / Center / Right playground launchers
# All heavy data/VMs/logs live under /data (repo itself may live under /data too)

set -euo pipefail

# --- Path resolution ---
# PCAC_ROOT: the playgrounds repo root (directory that contains scripts/)
# We are always sourced from scripts/lib/common.sh, so ../../ from there.
PCAC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PCAC_ROOT

# PCAC_DATA_ROOT: canonical location for all PCaC state, VMs, media, logs, etc.
# Override with env if you mount /data differently.
PCAC_DATA_ROOT="${PCAC_DATA_ROOT:-/data}"
export PCAC_DATA_ROOT

# Logging (var/ is gitignored)
PCAC_LOG_DIR="${PCAC_LOG_DIR:-${PCAC_DATA_ROOT}/var/log/pcac}"
export PCAC_LOG_DIR

# Shared data directory (for suggestions board, files visible to Left + Right, etc.)
# Lives inside the repo for convenience but is gitignored (runtime data only).
PCAC_SHARED_DIR="${PCAC_SHARED_DIR:-${PCAC_ROOT}/shared}"
export PCAC_SHARED_DIR

# --- 3-monitor KDE Plasma Wayland mapping (from kscreen-doctor + xrandr) ---
# Physical layout (left-to-right):
#   DP-3 (left, 0,0)     → Left Playground (chill / suggestions / internet)
#   HDMI-A-1 (center)    → Center / Grok CLI (orchestrator / brain)
#   DP-2 (right, 3840,0) → Right Playground (media / games / files)
#
# Override via environment if your hardware or layout changes.
PCAC_LEFT_MONITOR="${PCAC_LEFT_MONITOR:-DP-3}"
PCAC_CENTER_MONITOR="${PCAC_CENTER_MONITOR:-HDMI-A-1}"
PCAC_RIGHT_MONITOR="${PCAC_RIGHT_MONITOR:-DP-2}"

export PCAC_LEFT_MONITOR PCAC_CENTER_MONITOR PCAC_RIGHT_MONITOR

pcac_ensure_dirs() {
  mkdir -p "$PCAC_LOG_DIR" "$PCAC_SHARED_DIR/suggestions"
}

pcac_log() {
  local level="${1:-INFO}"; shift || true
  local msg="$*"
  local ts
  ts="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
  local line="[$ts] [${level}] ${msg}"
  # Always echo to stderr for the launcher process
  echo "$line" >&2
  # Also append to shared log if possible
  if [ -d "$PCAC_LOG_DIR" ] || mkdir -p "$PCAC_LOG_DIR" 2>/dev/null; then
    printf '%s\n' "$line" >> "$PCAC_LOG_DIR/pcac.log" 2>/dev/null || true
  fi
}

pcac_detect_outputs() {
  pcac_log DEBUG "Detecting display outputs..."
  if command -v wlr-randr >/dev/null 2>&1; then
    wlr-randr 2>/dev/null || true
  elif command -v xrandr >/dev/null 2>&1; then
    if [ -n "${DISPLAY:-}" ]; then
      xrandr --listmonitors 2>/dev/null || xrandr 2>/dev/null || true
    else
      xrandr 2>/dev/null || true
    fi
  else
    pcac_log WARN "No wlr-randr or xrandr found. Running in limited/no-display environment?"
    echo "DISPLAY=${DISPLAY:-<unset>} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
  fi
}

pcac_show_env() {
  pcac_log INFO "PCaC environment:"
  echo "  PCAC_ROOT=$PCAC_ROOT"
  echo "  PCAC_DATA_ROOT=$PCAC_DATA_ROOT"
  echo "  PCAC_LOG_DIR=$PCAC_LOG_DIR"
  echo "  Session: XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unknown}"
  echo "  DISPLAY=${DISPLAY:-<unset>} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"
}

# Placeholder for future: launch something targeted at a specific output
# Example later: pcac_launch_on_output "left" "firefox --kiosk ..."
pcac_launch_on_output() {
  local side="$1"; shift
  local cmd=("$@")
  pcac_log INFO "Would launch on $side output: ${cmd[*]}"
  # Real implementation will use output-specific flags or move windows via WM tools.
}

# Basic trap helper - call from launchers
pcac_install_trap() {
  trap 'pcac_log INFO "Received signal, cleaning up..."; exit 0' INT TERM
}

# Print a nice banner
pcac_banner() {
  local title="$1"
  echo "========================================"
  echo "  $title"
  echo "========================================"
}

# --- Monitor helpers (KDE Plasma / kscreen-doctor aware) ---

pcac_monitor_for_side() {
  local side="$1"
  case "$side" in
    left|Left|L)  echo "$PCAC_LEFT_MONITOR" ;;
    center|Center|C) echo "$PCAC_CENTER_MONITOR" ;;
    right|Right|R) echo "$PCAC_RIGHT_MONITOR" ;;
    *) echo "$PCAC_CENTER_MONITOR" ;;
  esac
}

pcac_list_monitors() {
  pcac_log INFO "PCaC monitor mapping (KDE Plasma Wayland):"
  echo "  Left   Playground → $PCAC_LEFT_MONITOR   (physical left)"
  echo "  Center / Grok      → $PCAC_CENTER_MONITOR (orchestrator)"
  echo "  Right  Playground → $PCAC_RIGHT_MONITOR  (physical right)"
  echo
  if command -v kscreen-doctor >/dev/null 2>&1; then
    pcac_log DEBUG "kscreen-doctor -o (current geometry):"
    kscreen-doctor -o 2>/dev/null | grep -E 'Output:|Geometry:' | head -20 || true
  elif command -v xrandr >/dev/null 2>&1; then
    xrandr --listmonitors 2>/dev/null || true
  fi
}

# --- Suggestion board helpers ---

pcac_suggestions_file() {
  echo "${PCAC_SHARED_DIR}/suggestions/suggestions.txt"
}

pcac_ensure_suggestions() {
  local f
  f="$(pcac_suggestions_file)"
  mkdir -p "$(dirname "$f")"
  touch "$f"
  echo "$f"
}

pcac_append_suggestion() {
  local text="$*"
  local f
  f="$(pcac_ensure_suggestions)"
  local ts
  ts="$(date -Iseconds)"
  printf '[%s] %s\n' "$ts" "$text" >> "$f"
  pcac_log INFO "Suggestion recorded: $text"
}

pcac_show_suggestions() {
  local f
  f="$(pcac_ensure_suggestions)"
  pcac_log INFO "Current suggestions (from $(pcac_suggestions_file)):"
  if [[ -s "$f" ]]; then
    cat "$f"
  else
    echo "(no suggestions yet)"
  fi
}

# --- Web service helpers (for the local suggestion board) ---

pcac_suggestion_service_script() {
  echo "${PCAC_ROOT}/scripts/suggestion_service.py"
}

pcac_suggestion_service_port() {
  echo "${PCAC_SUGGESTION_PORT:-8765}"
}

