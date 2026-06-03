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
Usage: $(basename "$0") [options]

Left Playground — locked-down internet / suggestions / PCaC chill layer (targeting left monitor = $PCAC_LEFT_MONITOR).

Options:
  --help               Show this help
  --detect             Detect display outputs + print env then exit
  --dry-run            (default) Show plan only
  --start-suggestions  Start the local suggestion web service (background)
  --view-suggestions   Show current suggestions from the shared board
  --kiosk              Launch (or show command for) a locked-down browser kiosk
                       on the left monitor pointing at the suggestion board
  --watch [USER]       Open (or re-open) the live system health & logs watch terminal
                       on the left monitor (DP-3). Optional USER label for remote
                       users (shows as "User cursor: USER" in the TUI)

The suggestion board is a simple local web form. It writes to:
  $(pcac_suggestions_file)

Expansion points for Grok Center:
  - Browser kiosk (restricted profile, no downloads, no history, kiosk on left output)
  - Local web service / suggestion UI / chill dashboard (already started here)
  - Targeted launch on specific Wayland/X11 output using kscreen-doctor / KWin rules
  - VM or container session isolated to this side
  - Integration with Grok for contextual suggestions
USAGE
}

main() {
  local mode="run"
  local do_start_suggestions=false
  local do_view=false
  local do_kiosk=false
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
      --start-suggestions)
        do_start_suggestions=true
        shift
        ;;
      --view-suggestions)
        do_view=true
        shift
        ;;
      --kiosk)
        do_kiosk=true
        shift
        ;;
      --watch)
        do_watch=true
        shift
        # optional next arg as user label
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

  pcac_banner "LEFT PLAYGROUND"
  pcac_log INFO "Monitor: Left → $PCAC_LEFT_MONITOR"
  pcac_log INFO "Purpose: Internet / Suggestions / PCaC chill layer"
  pcac_show_env

  if [[ "$mode" == "detect" ]]; then
    pcac_list_monitors
    exit 0
  fi

  pcac_log INFO "Status: Suggestion board + kiosk stubs ready. Grok Center expands this."

  # Always ensure suggestions file exists
  pcac_ensure_suggestions

  if $do_view; then
    pcac_show_suggestions
  fi

  if $do_start_suggestions; then
    local script
    script="$(pcac_suggestion_service_script)"
    local port
    port="$(pcac_suggestion_service_port)"
    pcac_log INFO "Starting suggestion service on port $port (localhost only)..."
    # Launch in background, disown so it survives the launcher exit if desired
    nohup python3 "$script" "$port" > "$PCAC_LOG_DIR/suggestion-service.log" 2>&1 &
    local pid=$!
    pcac_log INFO "Suggestion service started (pid $pid). Access at http://127.0.0.1:$port"
    echo "  View logs: tail -f $PCAC_LOG_DIR/suggestion-service.log"
  fi

  if $do_kiosk; then
    local port
    port="$(pcac_suggestion_service_port)"
    local url="http://127.0.0.1:$port"
    local target_monitor
    target_monitor="$(pcac_monitor_for_side left)"

    pcac_log INFO "Left kiosk target monitor: $target_monitor"
    pcac_log INFO "Suggested kiosk command (run this or enhance the script):"

    cat <<KIOSK

# Example locked-down Firefox kiosk on LEFT monitor ($target_monitor)
# (You may need to configure KWin window rules for "firefox" to open on $target_monitor
#  or use a tool to move the window after launch.)

firefox \\
  --kiosk \\
  --new-instance \\
  --profile "$PCAC_SHARED_DIR/firefox-kiosk-profile" \\
  "$url" &

# Alternative with chromium:
# chromium --kiosk --new-window --user-data-dir="$PCAC_SHARED_DIR/chromium-kiosk" "$url"

# After launching, you can use kscreen-doctor or KWin shortcuts to ensure it's on the left screen.
# For full automation later we can integrate kdotool / ydotool / KWin scripting.

KIOSK
  fi

  if $do_watch; then
    if [[ -n "$watch_user" ]]; then
      pcac_open_watch_left "$watch_user"
    else
      pcac_open_watch_left
    fi
  fi

  # === EXPANSION POINTS (Grok will fill these in over time) ===
  # 1. Launch a locked-down browser kiosk pinned to the left output (see --kiosk).
  # 2. Start (or connect to) a local service providing suggestions / PCaC interface (see --start-suggestions).
  # 3. Use pcac_launch_on_output "left" <command...> + real monitor targeting (kscreen-doctor + KWin).
  # 4. Support "chill mode" (low stimulation UI, music suggestions, etc.).

  pcac_list_monitors

  pcac_log INFO "Next steps will be added here (browser kiosk, local web service, VM launch, etc.)"

  if [[ "$mode" == "dry" || "$mode" == "run" ]]; then
    pcac_log INFO "(placeholder / dry-run mode — use --start-suggestions or --kiosk to try real pieces)"
  fi

  pcac_log INFO "Left playground launcher complete."
}

main "$@"
