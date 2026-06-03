#!/usr/bin/env bash
# PCaC Left Watch Terminal
# Live system health, sensors, and logs - intended to run full-time on Left monitor (DP-3)
# Safe, local, no network. Reversible: just Ctrl-C or kill the terminal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common for PCAC_* vars if available (for log dir etc)
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
else
  PCAC_LOG_DIR="${PCAC_LOG_DIR:-/data/var/log/pcac}"
fi

# Optional user label for remote users / multi-user "cursor" distinction
USER_LABEL="${1:-$(whoami)}"
if [[ "$USER_LABEL" != "$(whoami)" ]]; then
  echo "Running as remote user label: $USER_LABEL"
fi

echo "=== PCaC Left Watch starting on $(hostname) ==="
echo "Monitoring: system health + recent logs"
echo "Log dir: $PCAC_LOG_DIR"
echo "User cursor: $USER_LABEL"
echo "Press Ctrl-C to stop this watch."
echo

# Use watch for live updating display
exec watch -n 2 -t "
echo '=== PCaC LEFT MONITOR - System Health & Logs ==='
date '+%Y-%m-%d %H:%M:%S'
echo "User cursor: $USER_LABEL"
echo
echo '=== Uptime / Load ==='
uptime
echo
echo '=== Memory ==='
free -h
echo
echo '=== Top processes (CPU) ==='
top -b -n1 | head -7
echo
echo '=== Sensors (temperature/fans if available) ==='
sensors 2>/dev/null || echo '  (lm_sensors not installed or no output)'
echo
echo '=== Recent PCaC Logs (last 12 lines) ==='
tail -12 \"${PCAC_LOG_DIR}/pcac.log\" 2>/dev/null || echo '  (no pcac.log yet - run a launcher first)'
echo
echo '--- (auto-refresh every 2s - Ctrl-C to exit) ---'
"