#!/usr/bin/env bash
# Right Playground Launcher
# Goal: Eventually run media, games, and file access full-screen on the right monitor
# For now: simple safe placeholder that can be expanded by Grok / Grok Center

# Source shared helpers (defines PCAC_ROOT, logging, detect_outputs, etc.)
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--help] [--detect] [--dry-run]

Right Playground — media, games, files / high-engagement layer (targeting right monitor).

Options:
  --help     Show this help
  --detect   Detect display outputs + print env then exit
  --dry-run  (default behavior for placeholder) Show plan only

Expansion points for Grok Center:
  - Gaming session launcher (Steam Big Picture, Lutris, etc. on right output)
  - Media player / Spotify / local media library full-screen
  - File browser or project explorer isolated to this side
  - VM or container session for less-trusted / high-perf workloads
  - Easy switching / focus management between left (chill) and right (play)
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

  pcac_banner "RIGHT PLAYGROUND"
  pcac_log INFO "Monitor: Right"
  pcac_log INFO "Purpose: Spotify / Games / Files / Media"
  pcac_show_env

  if [[ "$mode" == "detect" ]]; then
    pcac_detect_outputs
    exit 0
  fi

  pcac_log INFO "Status: Placeholder ready. Grok Center will expand this."

  # === EXPANSION POINTS (Grok will fill these in over time) ===
  # 1. Launch gaming environment (e.g. steam -bigpicture) targeted at right output.
  # 2. Start media center / music player with nice full-screen UI.
  # 3. File manager or project tree for active work that belongs on the "play" side.
  # 4. Use pcac_launch_on_output "right" <command...> once real targeting exists.
  # 5. Handle audio routing, controller detection, etc. for games.

  pcac_detect_outputs

  pcac_log INFO "Next steps will be added here (gaming session, media player, VM launch, etc.)"

  if [[ "$mode" == "dry" || "$mode" == "run" ]]; then
    pcac_log INFO "(placeholder / dry-run mode — no real full-screen app launched yet)"
  fi

  pcac_log INFO "Right playground launcher complete (placeholder)."
}

main "$@"
