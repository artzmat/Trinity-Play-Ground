#!/usr/bin/env bash
# Center Playground / Grok Center Launcher
# Goal: The main control surface + "controlled chill layer" orchestrator.
#       This is where suggestions live, where Grok interacts, and from which
#       Left and Right playgrounds can be launched / monitored / coordinated.
# For now: hardened placeholder + some coordination hooks.

# Source shared helpers
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Center / Grok Center — main PCaC control + controlled chill layer (monitor: $PCAC_CENTER_MONITOR).

This is the "brain" / orchestrator. From here you control Left (chill/suggestions) and Right (play).

Options:
  --help               Show this help
  --detect             Detect outputs + env + monitor mapping then exit
  --dry-run            Show plan (default)
  --launch-left        Also invoke left-playground.sh (with its defaults)
  --launch-right       Also invoke right-playground.sh (with its defaults)
  --start-suggestions  Start the shared local suggestion web service (via left)
  --view-suggestions   Show suggestions from the shared board

The suggestion board (simple Python + HTML) is the first real shared feature:
  Left  → can submit via kiosk form
  Right → can view / "accept" ideas (file browser or mpv/steam integration later)
  Center → review history, process with Grok, write back recommendations

All persistent state stays under \$PCAC_DATA_ROOT and \$PCAC_SHARED_DIR.
USAGE
}

launch_left() {
  pcac_log INFO "Center: delegating to left-playground.sh"
  # Use the sibling script
  "${PCAC_ROOT}/scripts/left-playground.sh" --dry-run "$@"
}

launch_right() {
  pcac_log INFO "Center: delegating to right-playground.sh"
  "${PCAC_ROOT}/scripts/right-playground.sh" --dry-run "$@"
}

start_suggestions_from_center() {
  pcac_log INFO "Center: asking Left to start the suggestion service"
  "${PCAC_ROOT}/scripts/left-playground.sh" --start-suggestions
}

view_suggestions_from_center() {
  pcac_log INFO "Center: showing shared suggestions"
  "${PCAC_ROOT}/scripts/left-playground.sh" --view-suggestions
}

main() {
  local mode="run"
  local do_left=false
  local do_right=false
  local do_start_suggestions=false
  local do_view=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --detect)
        mode="detect"
        shift
        ;;
      --dry-run)
        mode="dry"
        shift
        ;;
      --launch-left)
        do_left=true
        shift
        ;;
      --launch-right)
        do_right=true
        shift
        ;;
      --start-suggestions)
        do_start_suggestions=true
        shift
        ;;
      --view-suggestions)
        do_view=true
        shift
        ;;
      *)
        pcac_log WARN "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  pcac_ensure_dirs
  pcac_install_trap

  pcac_banner "GROK CENTER / PCaC CENTER PLAYGROUND"
  pcac_log INFO "Monitor: Center (primary / control)"
  pcac_log INFO "Purpose: Orchestrator + controlled chill layer + Grok interface"
  pcac_show_env

  if [[ "$mode" == "detect" ]]; then
    pcac_detect_outputs
    exit 0
  fi

  pcac_log INFO "Status: Orchestrator ready. Suggestion board is the first shared concrete feature."

  # === CENTER-SPECIFIC EXPANSION POINTS ===
  # - Run a persistent Grok chat / suggestion TUI or web UI here.
  # - Provide commands to "send to left", "send to right", "focus monitor X".
  # - Maintain safe defaults, profiles, allow/deny lists for the chill layer.
  # - Health checks / status of left and right sides.
  # - Central logging aggregation + simple dashboard.
  # - Possibly the only place that talks to external "smart" services.

  pcac_list_monitors

  if $do_start_suggestions; then
    start_suggestions_from_center
  fi
  if $do_view; then
    view_suggestions_from_center
  fi

  if $do_left; then
    launch_left
  fi
  if $do_right; then
    launch_right
  fi

  pcac_log INFO "Next steps for Center: orchestration, Grok UI surface, monitor routing, state machine."

  if [[ "$mode" == "dry" || "$mode" == "run" ]]; then
    pcac_log INFO "(placeholder / dry-run mode — center is the conductor, not the band yet)"
  fi

  pcac_log INFO "Center launcher complete."
}

main "$@"
