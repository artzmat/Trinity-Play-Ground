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

pcac_ensure_dirs() {
  mkdir -p "$PCAC_LOG_DIR"
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
