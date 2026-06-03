#!/usr/bin/env bash
# Left Playground Launcher
# Goal: Eventually run a locked-down internet/suggestion interface full-screen on the left monitor
# For now: simple safe placeholder that can be expanded by Grok / Grok Center

# Source shared helpers (defines PCAC_ROOT, logging, detect_outputs, etc.)
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--help] [--detect] [--dry-run]

Left Playground — locked-down internet / suggestions / PCaC chill layer (targeting left monitor).

Options:
  --help     Show this help
  --detect   Detect display outputs + print env then exit
  --dry-run  (default behavior for placeholder) Show plan only

Expansion points for Grok Center:
  - Browser kiosk (restricted profile, no downloads, no history)
  - Local web service / suggestion UI / chill dashboard
  - Targeted launch on specific Wayland/X11 output
  - VM or container session isolated to this side
  - Integration with Grok for contextual suggestions
USAGE
}

main() {
  local mode="run"

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
      *)
        pcac_log WARN "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  pcac_ensure_dirs
  pcac_install_trap

  pcac_banner "LEFT PLAYGROUND"
  pcac_log INFO "Monitor: Left"
  pcac_log INFO "Purpose: Internet / Suggestions / PCaC chill layer"
  pcac_show_env

  if [[ "$mode" == "detect" ]]; then
    pcac_detect_outputs
    exit 0
  fi

  pcac_log INFO "Status: Placeholder ready. Grok Center will expand this."

  # === EXPANSION POINTS (Grok will fill these in over time) ===
  # 1. Launch a locked-down browser kiosk pinned to the left output.
  # 2. Start (or connect to) a local service providing suggestions / PCaC interface.
  # 3. Use pcac_launch_on_output "left" <command...> once real targeting exists.
  # 4. Support "chill mode" (low stimulation UI, music suggestions, etc.).

  pcac_detect_outputs

  pcac_log INFO "Next steps will be added here (browser kiosk, local web service, VM launch, etc.)"

  if [[ "$mode" == "dry" || "$mode" == "run" ]]; then
    pcac_log INFO "(placeholder / dry-run mode — no real full-screen app launched yet)"
  fi

  pcac_log INFO "Left playground launcher complete (placeholder)."
}

main "$@"
