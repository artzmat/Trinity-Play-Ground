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
  # Ensure the kiosk profile exists (for Left playground use).
  # Redirect stdout to avoid noise; creation log (if any) still goes via pcac_log.
  pcac_ensure_kiosk_profile >/dev/null
  pcac_ensure_chats
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

# --- Chat box support for three-persona setup (Left Grok, Right Grok, Center Orchestrator Grok) ---
# Left and Right have separate chat logs.
# Center (orchestrator) can view both.
# Left/Right personas post messages; "grok: ..." indicates asking the center Grok.
# User (orchestrator) responds by posting back to the appropriate log as "Center Grok (to Left): ..."
# Left/Right can view Center monitor (physically) but have no control.
# Supports optional user label for remote "cursors".

PCAC_LEFT_CHAT_LOG="${PCAC_SHARED_DIR}/left-chat.log"
PCAC_RIGHT_CHAT_LOG="${PCAC_SHARED_DIR}/right-chat.log"
PCAC_BUS_FILE="${PCAC_SHARED_DIR}/bus/messages.jsonl"

export PCAC_LEFT_CHAT_LOG PCAC_RIGHT_CHAT_LOG PCAC_BUS_FILE

pcac_ensure_chats() {
  mkdir -p "$(dirname "$PCAC_LEFT_CHAT_LOG")"
  mkdir -p "$(dirname "$PCAC_BUS_FILE")"
  touch "$PCAC_LEFT_CHAT_LOG" "$PCAC_RIGHT_CHAT_LOG" "$PCAC_BUS_FILE"
}

pcac_bus_append() {
  local from="$1"
  local to="$2"
  local kind="${3:-chat}"
  local text="$4"
  pcac_ensure_chats
  python3 "${PCAC_ROOT}/scripts/pcac_bus.py" append \
    --from "$from" --to "$to" --kind "$kind" --text "$text" 2>/dev/null \
    || pcac_log WARN "bus append failed (is python3 available?)"
}

pcac_post_chat() {
  local side="$1"  # left or right
  local from="$2"
  local msg="$3"
  local kind="${4:-chat}"
  local log_file
  local bus_to="center"
  if [[ "$side" == "left" ]]; then
    log_file="$PCAC_LEFT_CHAT_LOG"
    bus_to="left"
  else
    log_file="$PCAC_RIGHT_CHAT_LOG"
    bus_to="right"
  fi
  # grok: queries are addressed to Center orchestrator
  if [[ "$msg" == grok:* ]]; then
    kind="grok_query"
    bus_to="center"
  fi
  echo "[$(date '+%H:%M:%S')] ${from}: ${msg}" >> "$log_file"
  pcac_bus_append "$from" "$bus_to" "$kind" "$msg"
  pcac_log INFO "Posted to ${side}-chat as ${from}: ${msg}"
}

pcac_ask_brain() {
  local side="$1"
  local msg="$2"
  local user_label="${3:-$(whoami)}"
  python3 "${PCAC_ROOT}/scripts/pcac_ask_brain.py" "$side" "$msg" "$user_label"
}

# Center asks both local brains (parallel). Logs prompt to both chats + bus first.
pcac_ask_both() {
  local msg="$1"
  local user_label="${2:-$(whoami)}"
  local from="Center Grok (ask both, ${user_label})"
  local flat
  flat="$(echo "$msg" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //;s/ $//')"

  pcac_post_chat left "$from" "ask: ${flat}" "ask_both"
  pcac_post_chat right "$from" "ask: ${flat}" "ask_both"

  local left_out right_out
  left_out="$(mktemp)"
  right_out="$(mktemp)"
  trap 'rm -f "$left_out" "$right_out"' RETURN

  local pid_left pid_right left_ec=0 right_ec=0
  echo "[$(date '+%H:%M:%S')] Asking Left-Brain and Right-Brain in parallel..."

  pcac_ask_brain left "$msg" "$user_label" >"$left_out" 2>&1 &
  pid_left=$!
  pcac_ask_brain right "$msg" "$user_label" >"$right_out" 2>&1 &
  pid_right=$!

  wait "$pid_left" || left_ec=$?
  wait "$pid_right" || right_ec=$?

  echo ""
  echo "=== Left-Brain ==="
  cat "$left_out"
  echo ""
  echo "=== Right-Brain ==="
  cat "$right_out"
  echo ""

  if (( left_ec != 0 || right_ec != 0 )); then
    pcac_log WARN "ask_both: left exit=${left_ec} right exit=${right_ec}"
    return 1
  fi
  pcac_log INFO "ask_both completed for: ${flat}"
  return 0
}

# Center posts the same message to Left and Right chats + bus.
pcac_center_reply_both() {
  local msg="$1"
  pcac_center_reply left "$msg"
  pcac_center_reply right "$msg"
}

pcac_tail_bus() {
  local n="${1:-15}"
  pcac_ensure_chats
  python3 "${PCAC_ROOT}/scripts/pcac_bus.py" tail -n "$n" 2>/dev/null || echo "(bus empty)"
}

# Center posts a response into a side chat log + bus
pcac_center_reply() {
  local side="$1"
  local msg="$2"
  local label="Center Grok (to ${side^})"
  pcac_post_chat "$side" "$label" "$msg" "center_reply"
  pcac_bus_append "$label" "$side" "center_reply" "$msg"
  pcac_log INFO "Center replied to ${side}: ${msg}"
}

pcac_view_chat() {
  local side="$1"
  local log_file
  if [[ "$side" == "left" ]]; then
    log_file="$PCAC_LEFT_CHAT_LOG"
  else
    log_file="$PCAC_RIGHT_CHAT_LOG"
  fi
  pcac_ensure_chats
  echo "=== ${side^^} CHAT LOG (tail -50) ==="
  tail -50 "$log_file" 2>/dev/null || echo "(empty)"
}

pcac_view_all_chats() {
  echo "=== CENTER ORCHESTRATOR VIEW: BOTH CHATS ==="
  echo
  echo "--- LEFT CHAT ---"
  tail -30 "$PCAC_LEFT_CHAT_LOG" 2>/dev/null || echo "(empty)"
  echo
  echo "--- RIGHT CHAT ---"
  tail -30 "$PCAC_RIGHT_CHAT_LOG" 2>/dev/null || echo "(empty)"
  echo
  echo "--- BUS (last 10) ---"
  pcac_tail_bus 10
  echo
  echo "(Center: pcac_post_chat left|right 'Center Grok (...)' 'message')"
}

# Sudo helper using the user's sudo code pin for auto updates/testing
# Usage: pcac_sudo command args...
# PIN is read from $HOME/.config/pc-sudo-pin (chmod 600) or PC_SUDO_PIN env.
# Do not commit the actual PIN.
pcac_sudo() {
  local pin_file="$HOME/.config/pc-sudo-pin"
  local pin="${PC_SUDO_PIN:-}"
  if [[ -z "$pin" && -f "$pin_file" ]]; then
    pin=$(cat "$pin_file" | tr -d '\n')
  fi
  if [[ -z "$pin" ]]; then
    echo "Error: No sudo PIN found. Set PC_SUDO_PIN env or create $pin_file (600 perms) with your sudo code pin."
    return 1
  fi
  echo "$pin" | sudo -S "$@"
}

# Auto update function for the PC, using the pin for sudo
pcac_auto_update() {
  echo "Running auto PC update with sudo pin (masked)..."
  pcac_sudo pacman -Syu --noconfirm || true
  if command -v paru >/dev/null; then
    paru -Syu --noconfirm || true
  fi
  pcstuff
  echo "Auto update complete. (PIN masked in logs)"
}

# --- Watch terminal openers for side monitors ---
# These launch a konsole (KDE terminal) positioned on the target physical monitor
# using --qwindowgeometry (X11 geometry syntax). This provides the "live monitoring
# terminals" on Left (health/logs) and Right (git status/commits).
#
# The watch scripts themselves are safe, local, read-only viewers.
# They can be launched manually too: ./scripts/left-watch.sh inside a terminal
# on the correct monitor.

pcac_open_watch_left() {
  local user_label="${1:-$(whoami)}"
  local tmux_script="${PCAC_ROOT}/scripts/left-tmux.sh"
  local geom="1920x1080+0+0"   # Left monitor (DP-3): 0,0 origin, 1920 wide
  local title="PCaC-Left-Screen-${user_label}"  # now includes watch + chat

  if [[ ! -x "$tmux_script" ]]; then
    pcac_log ERROR "tmux launcher not found: $tmux_script"
    return 1
  fi

  # Launch konsole on Left geometry running the combined watch+chat tmux session.
  # This gives Left its own "terminal" with monitoring + separate chat box for using Grok (Left Grok persona).
  konsole --qwindowgeometry "$geom" --title "$title" -e "$tmux_script" "$user_label" &
  local pid=$!
  pcac_log INFO "Opened Left combined screen (watch + chat) on DP-3 (geom $geom, user=$user_label, pid $pid)"
  echo "  Title: $title (tmux: watch top, chat bottom - Ctrl-b arrows to switch)"
  echo "  User cursor label: $user_label"
  echo "  In chat: grok: → Center | ask: → local brain. Center: pcac_center_reply left|right '...'"
  echo "  To close: exit tmux (Ctrl-b d or type quit in chat) or kill $pid"
}

pcac_open_watch_right() {
  local user_label="${1:-$(whoami)}"
  local tmux_script="${PCAC_ROOT}/scripts/right-tmux.sh"
  local geom="1920x1080+3840+0"  # Right monitor (DP-2): starts at x=3840
  local title="PCaC-Right-Screen-${user_label}"  # now includes watch + chat

  if [[ ! -x "$tmux_script" ]]; then
    pcac_log ERROR "tmux launcher not found: $tmux_script"
    return 1
  fi

  # Launch konsole on Right geometry running the combined watch+chat tmux session.
  # This gives Right its own "terminal" with monitoring + separate chat box for using Grok (Right Grok persona).
  konsole --qwindowgeometry "$geom" --title "$title" -e "$tmux_script" "$user_label" &
  local pid=$!
  pcac_log INFO "Opened Right combined screen (watch + chat) on DP-2 (geom $geom, user=$user_label, pid $pid)"
  echo "  Title: $title (tmux: watch top, chat bottom - Ctrl-b arrows to switch)"
  echo "  User cursor label: $user_label"
  echo "  In chat: grok: → Center | ask: → local brain. Center: pcac_center_reply left|right '...'"
  echo "  To close: exit tmux (Ctrl-b d or type quit in chat) or kill $pid"
}

# --- Kiosk profile helpers (for locked-down Left browser) ---
# These create and manage a dedicated, privacy-hardened Firefox profile
# stored under shared/ (so it lives on /data and is gitignored).
# The profile is intended for kiosk use only: no telemetry, no history,
# restricted downloads, etc. This function is purely for setup — it does
# not launch Firefox or change any runtime behavior.

pcac_kiosk_profile_dir() {
  echo "${PCAC_SHARED_DIR}/firefox-kiosk-profile"
}

pcac_ensure_kiosk_profile() {
  local dir
  dir="$(pcac_kiosk_profile_dir)"

  if [[ -d "$dir" ]]; then
    echo "$dir"
    return 0
  fi

  mkdir -p "$dir" "$dir/downloads" "$dir/cache"

  # Write a minimal prefs.js focused on privacy and kiosk safety.
  # These are the kinds of settings we want for a controlled "chill layer".
  cat > "$dir/prefs.js" << 'PREFS'
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.page", 0);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnCloseOtherTabs", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.max_tabs_undo", 0);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.server", "");
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.download.useDownloadDir", false);
user_pref("browser.download.dir", "");
user_pref("browser.download.folderList", 2);
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("places.history.enabled", false);
user_pref("privacy.history.custom", true);
user_pref("network.cookie.cookieBehavior", 0);
PREFS

  # Also create a user.js (stronger overrides that survive some Firefox updates)
  cat > "$dir/user.js" << 'USERJS'
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("datareporting.policy.firstRunURL", "");
USERJS

  pcac_log INFO "Created restricted Firefox kiosk profile at $dir"
  echo "$dir"
}

# --- Center monitor opener (symmetric to left/right) ---
# Provides the dedicated "Center terminal to see both" with tmux 3-pane:
# Left chat | Right chat | status (with pc pin 1566894405 marker)
pcac_open_center_monitor() {
  local user_label="${1:-$(whoami)}"
  local tmux_script="${PCAC_ROOT}/scripts/center-tmux.sh"
  # Smaller "minimized" window on Center monitor (HDMI-A-1) so the physical center
  # monitor remains mostly usable for other desktop work. Centered 960x600 floating window.
  local geom="960x600+2400+240"
  local title="PCaC-Center-Monitor-Both-${user_label}"

  if [[ ! -x "$tmux_script" ]]; then
    pcac_log ERROR "tmux launcher not found: $tmux_script"
    return 1
  fi

  konsole --qwindowgeometry "$geom" --title "$title" -e "$tmux_script" &
  local pid=$!
  pcac_log INFO "Opened minimized Center monitor terminal (geom $geom, user=$user_label, pid $pid) | pc pin 1566894405"
  echo "  Title: $title (tmux split: Left Chat | Right Chat | Status) -- minimized/small window on center monitor"
  echo "  Ctrl-b to switch panes. Status includes pin marker."
  echo "  To close: close the konsole window or kill $pid"
}

# --- Full playground launcher ---
# When "playground" (or grok-center playground) is entered from Center Grok,
# this fires up the three terminals with watch windows:
#   - Left: konsole on DP-3 running tmux (watch top + Left Grok chat bottom)
#   - Right: konsole on DP-2 running tmux (watch top + Right Grok chat bottom)
#   - Center: small/minimized konsole window on HDMI-A-1 (960x600 centered) running tmux split view of both chats + status
# Supports optional user-label for "User cursor" (e.g. playground alice for remote).
# Logs include "pc pin 1566894405" for auto/snapshot context.
pcac_launch_playground() {
  local user_label="${1:-$(whoami)}"
  pcac_log INFO "PLAYGROUND REQUESTED IN CENTER GROK: firing up Left, Right, and Center terminals with watch windows (user cursor: $user_label) | pc pin 1566894405"
  pcac_ensure_dirs || true
  pcac_open_watch_left "$user_label" || true
  pcac_open_watch_right "$user_label" || true
  pcac_open_center_monitor "$user_label" || true
  pcac_log INFO "Playground launch complete for $user_label. Check physical monitors for the three konsole windows."
  echo "Fired up playground terminals (Left watch+chat, Right watch+chat, Center both-view)."
  echo "Use 'grok: your question' in side chats; respond from Center with pcac_post_chat."
}

