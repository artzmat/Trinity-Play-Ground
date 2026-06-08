#!/usr/bin/env bash
# Right Playground Launcher
# Goal: Eventually run media, games, and file access full-screen on the right monitor
# For now: simple safe placeholder that can be expanded by Grok / Center

# Source shared helpers (defines PCAC_ROOT, logging, detect_outputs, etc.)
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Right Playground — media, games, files / high-engagement layer (targeting right monitor = $PCAC_RIGHT_MONITOR).

Options:
  --help               Show this help
  --detect             Detect display outputs + print env then exit
  --dry-run            (default) Show plan only
  --view-suggestions   View the shared suggestion board written by Left
  --open-shared        Open a file browser / terminal on the shared suggestions folder
  --watch [USER]       Open (or re-open) the full Right screen on DP-2: tmux with
                       git watch (top pane) + interactive chat box (bottom).
                       Use 'center: ... in chat to ask Center. Optional USER label
                       for remote users ("User cursor"). Right can see Center monitor.

Expansion points for Center:
  - Gaming session launcher (Steam Big Picture, Lutris, etc. on right output)
  - Media player / Spotify / local media library full-screen
  - File browser or project explorer isolated to this side (see --open-shared)
  - VM or container session for less-trusted / high-perf workloads
  - Easy "accept suggestion" flow (e.g. one-click launch game/playlist from Left idea)
  - Easy switching / focus management between left (chill) and right (play)
USAGE
}

main() {
  local mode="run"
  local do_view=false
  local do_open_shared=false
  local do_watch=false
  local watch_user=""

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
      --view-suggestions)
        do_view=true
        shift
        ;;
      --open-shared)
        do_open_shared=true
        shift
        ;;
      --watch)
        do_watch=true
        shift
        if [[ $# -gt 0 && "$1" != --* ]]; then
          watch_user="$1"
          shift
        fi
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
  pcac_log INFO "Monitor: Right → $PCAC_RIGHT_MONITOR"
  pcac_log INFO "Purpose: Spotify / Games / Files / Media"
  pcac_show_env

  if [[ "$mode" == "detect" ]]; then
    pcac_list_monitors
    exit 0
  fi

  pcac_log INFO "Status: Ready to consume suggestions from Left + play. Center expands this."

  if $do_view; then
    pcac_show_suggestions
  fi

  if $do_open_shared; then
    local shared
    shared="$PCAC_SHARED_DIR"
    pcac_log INFO "Opening shared suggestions area: $shared/suggestions"
    # Prefer a terminal file manager or just ls + instructions
    if command -v dolphin >/dev/null 2>&1; then
      dolphin "$shared/suggestions" &
    elif command -v nautilus >/dev/null 2>&1; then
      nautilus "$shared/suggestions" &
    else
      ls -l "$shared/suggestions"
      pcac_log INFO "Use your favorite file manager or: cd $shared/suggestions"
    fi
  fi

  if $do_watch; then
    if [[ -n "$watch_user" ]]; then
      pcac_open_watch_right "$watch_user"
    else
      pcac_open_watch_right
    fi
  fi

  # === EXPANSION POINTS (Grok will fill these in over time) ===
  # 1. Launch gaming environment (e.g. steam -bigpicture) targeted at right output.
  # 2. Start media center / music player with nice full-screen UI.
  # 3. File manager or project tree for active work that belongs on the "play" side (see --open-shared).
  # 4. Use pcac_launch_on_output "right" <command...> once real targeting exists.
  # 5. Handle audio routing, controller detection, etc. for games.
  # 6. "Accept suggestion" flows (e.g. if suggestion mentions a game, one-click launch it here).

  # User's typical right daily setup (as of this workflow + cross-convo with Left):
  #   right-daily          # Spotify + Steam + Thunderbird + plasma-systemmonitor (positioned on DP-2) + surfaces Left suggestions
  #   right-daily status   # check the quartet + playground VM viewer
  #   right-daily btop     # quick btop terminal on the edge
  #   right-daily with-vm  # daily apps + entertainment guest VM
  #   right-daily --creative  # compact creative layer (slot machine, music viz, ambient stories) + mood-sync to Left minimalist
  # Script lives at ~/bin/right-daily. First positioning may need a manual assist or KDE Window Rules.
  # New: pcac-start-brains (~/bin too) — start LM Studio + exact Local Server steps for left<->right convos.
  # Creative elements: right-only, compact/idle, protect Center white (HDMI-A-1) with zero visual/mental spill.

  pcac_list_monitors

  pcac_log INFO "Next steps will be added here (gaming session, media player, VM launch, etc.)"

  if [[ "$mode" == "dry" || "$mode" == "run" ]]; then
    pcac_log INFO "(placeholder / dry-run mode — use --view-suggestions or --open-shared to interact with Left)"
  fi

  pcac_log INFO "Right playground launcher complete."
}

main "$@"
