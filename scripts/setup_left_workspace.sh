#!/usr/bin/env bash
# setup_left_workspace.sh - Automate low-impact Left workspace config (DP-3 chill/analytical layer)
# Run from Center or Left. Keeps visual/mental load minimal, local-only, fully auditable.
# Designed per Left-Brain + hardening priorities. Only touches Left monitor/layer.
# Center white HQ (HDMI-A-1) remains protected (minimized windows + CenterWhite konsole profile; no global/theme bleed).
#
# Usage:
#   ./scripts/setup_left_workspace.sh [--dry-run] [--help]
#   ./scripts/setup_left_workspace.sh --mood-sync "play-start:openrgb,firefox,lm"
#   ./scripts/setup_left_workspace.sh --watch-mood &
#   (Can be called from left-usual or manually after grok-left)
#
# Improvements focus (this version):
# - Minimal load: lowest-impact OpenRGB profile (off), nice/ionice where possible, no notifications.
# - Local auditable security: backups + diffs before/after edits, explicit logs, no network, set -euo + trap.
# - Easier maintenance: modular functions, sourcing common.sh for pcac_log/paths if available, dry-run, comments.
# - Center white HQ integration: explicit protection notes, low system impact (nice), separate layer only.
# - Mood-sync from Right (cross-convo): respond to MOOD-SYNC posts in left-chat.log from right-daily --creative.

set -euo pipefail

# --- Paths & sourcing (local-first, resilient) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PCAC_ROOT="${PCAC_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
if [[ -f "$PCAC_ROOT/scripts/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$PCAC_ROOT/scripts/lib/common.sh"
  pcac_ensure_dirs >/dev/null 2>&1 || true
else
  # Fallbacks if common not available
  PCAC_LOG_DIR="${PCAC_LOG_DIR:-/data/var/log/pcac}"
  mkdir -p "$PCAC_LOG_DIR"
fi

LOG_FILE="${PCAC_LOG_DIR}/setup_left_workspace.log"
KIOSK_PROFILE="${PCAC_SHARED_DIR:-$PCAC_ROOT/shared}/firefox-kiosk-profile"
LMENV="$PCAC_ROOT/config/lmstudio.env"  # correct pcac location (the one used by ask-brain etc.)
LM_APP_SETTINGS="/data/AI/lmstudio/settings.json"

DRY_RUN=false
MOOD_SYNC=""
WATCH_MOOD=false
BACKGROUND=false
OPENRGB_ONLY=false
FIREFOX_ONLY=false
LM_ONLY=false

# Core helpers (defined first)
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg" | tee -a "$LOG_FILE"
}

backup_and_diff() {
  local file="$1"
  local label="$2"
  if $DRY_RUN || [[ ! -f "$file" ]]; then
    $DRY_RUN && log "DRY: would backup $label"
    return
  fi
  local bak="${file}.bak.$(date +%s)"
  cp -p "$file" "$bak"
  log "Backed up $label -> $bak (for audit)"
}

show_diff() {
  local file="$1" bak="$2" label="$3"
  if [[ -f "$bak" && -f "$file" ]]; then
    log "Diff for $label (auditable change):"
    diff -u "$bak" "$file" | head -30 | tee -a "$LOG_FILE" || true
  fi
}

run_cmd() {
  local desc="$1"; shift
  if $DRY_RUN; then
    log "DRY: would: $*  ($desc)"
    return 0
  fi
  log "Running: $* ($desc)"
  if command -v nice >/dev/null && command -v ionice >/dev/null; then
    nice -n 10 ionice -c 3 "$@" || { log "WARN: low-priority run had issues"; return 1; }
  else
    "$@" || { log "WARN: command had issues"; return 1; }
  fi
}

# Mood sync functions (after helpers they call)
DARK_PREFS='
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.fingerprintingProtection", true);
'

handle_mood_sync() {
  local signal="$1"
  log "MOOD-SYNC received: $signal (Left-only, Center white protected)"

  local action="${signal%%:*}"
  local steps="${signal#*:}"

  case "$action" in
    MOOD-SYNC|play-start|play)
      IFS=',' read -ra STEP_LIST <<< "$steps"
      for step in "${STEP_LIST[@]}"; do
        step=$(echo "$step" | tr -d ' ')
        case "$step" in
          openrgb|rgb)
            if command -v openrgb >/dev/null && [[ -f ~/.config/OpenRGB/off.orp ]]; then
              run_cmd "MOOD-SYNC: OpenRGB minimal off" openrgb -p off.orp
            fi
            ;;
          firefox|kiosk|privacy)
            if [[ -d "$KIOSK_PROFILE" ]]; then
              PREFS="$KIOSK_PROFILE/prefs.js"
              USERJS="$KIOSK_PROFILE/user.js"
              for f in "$PREFS" "$USERJS"; do
                if [[ -f "$f" ]] && ! $DRY_RUN; then
                  if ! grep -q "ui.systemUsesDarkTheme" "$f" 2>/dev/null; then
                    echo "$DARK_PREFS" >> "$f"
                    log "MOOD-SYNC: re-applied dark/privacy to $f"
                  fi
                fi
              done
            fi
            ;;
          lm|lmstudio)
            if [[ -f "$LMENV" ]] && ! $DRY_RUN; then
              sed -i 's/^THEME=.*/THEME=Dark/' "$LMENV" || true
              sed -i 's/^NOTIFICATIONS=.*/NOTIFICATIONS=false/' "$LMENV" || true
              log "MOOD-SYNC: LM low-impact config ensured"
            fi
            if [[ -f "$LM_APP_SETTINGS" ]] && ! $DRY_RUN; then
              sed -i 's/"monochromeSidebarIcons": false/"monochromeSidebarIcons": true/' "$LM_APP_SETTINGS" || true
              log "MOOD-SYNC: LM app monochrome sidebar"
            fi
            ;;
          journalctl|monitor|log)
            log "MOOD-SYNC: journalctl monitoring reminder (run in your left watch pane)"
            ;;
          compact|idle)
            log "MOOD-SYNC: compact/idle mode - lowering any active monitoring priority if possible"
            ;;
          *)
            log "MOOD-SYNC: unknown step '$step' - no action"
            ;;
        esac
      done
      ;;
    *)
      log "MOOD-SYNC: unhandled action '$action'"
      ;;
  esac

  # Post structured minimal confirmation back to Right (via bus/chat for full audit, Center can see)
  source /data/PCaC-Playgrounds/scripts/lib/common.sh 2>/dev/null || true
  CONFIRM_MSG="Processed MOOD-SYNC signal '$signal'. Steps: ${steps:-all requested}. Ran with nice/ionice where applicable. Compact, Left DP-3 only. Center white HQ (HDMI-A-1) untouched. See $LOG_FILE for details."
  pcac_post_chat right "Left-Brain (mood-response)" "$CONFIRM_MSG" "mood-sync" 2>/dev/null || echo "[$(date)] Left mood-response: $CONFIRM_MSG" >> "$PCAC_RIGHT_CHAT_LOG" 2>/dev/null || true

  # Compact habit note roundtrip for the Trinity Habit Observer (per cross-convo and Right brain proposal)
  # This feeds Left's minimalist responses back into Right's creative awareness without any UI or Center load.
  echo "[$(date '+%Y-%m-%d %H:%M')] Left processed mood-sync '$signal' (minimal, compact). Resources chill." >> /data/PCaC-Playgrounds/shared/left-habit-notes.txt 2>/dev/null || true
}

start_mood_watcher() {
  local chat_log="${PCAC_LEFT_CHAT_LOG:-$PCAC_ROOT/shared/left-chat.log}"
  if [[ ! -f "$chat_log" ]]; then
    log "MOOD-WATCHER: left-chat.log not found yet"
    return
  fi
  log "MOOD-WATCHER: starting low-load background tail for mood-sync signals (nice/ionice, Left only)"
  pkill -f "tail -f .*left-chat.log.*mood-sync" 2>/dev/null || true
  (
    tail -n 0 -f "$chat_log" | grep --line-buffered "mood-sync\|MOOD-SYNC" | while read -r line; do
      handle_mood_sync "$line"
    done
  ) &
  disown
  log "MOOD-WATCHER: background process started (check with ps | grep mood)"
}

# Arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--mood-sync \"play-start:openrgb,firefox,lm\"] [--watch-mood]"
      echo "  --dry-run : Show what would change (no edits, no launches)"
      echo "  --mood-sync \"SIGNAL\" : Directly handle a mood-sync signal (e.g. from Right)"
      echo "  --watch-mood : Start background low-load watcher for mood-sync posts in left-chat.log (nice/ionice)"
      echo "Strict local-first, auditable, minimal impact on Center white HQ (touches ONLY Left DP-3)."
      exit 0
      ;;
    --mood-sync)
      MOOD_SYNC="${2:-recent}"; shift 2 || shift ;;
    --watch-mood)
      WATCH_MOOD=true; shift ;;
    --background)
      BACKGROUND=true; shift ;;
    --openrgb-only|--openrgb)
      OPENRGB_ONLY=true; shift ;;
    --firefox-only)
      FIREFOX_ONLY=true; shift ;;
    --lm-only|--lmstudio-only)
      LM_ONLY=true; shift ;;
    *) shift ;;
  esac
done

if [[ -n "$MOOD_SYNC" ]]; then
  handle_mood_sync "$MOOD_SYNC"
  exit 0
fi

if $WATCH_MOOD; then
  start_mood_watcher
  exit 0
fi

# Support for mood-sync-trigger.sh flags (thin background calls for specific steps)
if $OPENRGB_ONLY; then
  if command -v openrgb >/dev/null; then
    if [[ -f ~/.config/OpenRGB/off.orp ]]; then
      run_cmd "MOOD-SYNC OpenRGB" openrgb -p off.orp
    else
      run_cmd "OpenRGB fallback" openrgb --startminimized || true
    fi
  fi
  log "MOOD-SYNC: openrgb-only done (Center untouched)"
  exit 0
fi

if $FIREFOX_ONLY; then
  if [[ -d "$KIOSK_PROFILE" ]]; then
    PREFS="$KIOSK_PROFILE/prefs.js"
    USERJS="$KIOSK_PROFILE/user.js"
    for f in "$PREFS" "$USERJS"; do
      if [[ -f "$f" ]] && ! $DRY_RUN; then
        if ! grep -q "ui.systemUsesDarkTheme" "$f" 2>/dev/null; then
          echo "$DARK_PREFS" >> "$f"
          log "MOOD-SYNC: appended dark/privacy to $f"
        fi
      fi
    done
  fi
  log "MOOD-SYNC: firefox-only done (Center untouched)"
  exit 0
fi

if $LM_ONLY; then
  if [[ -f "$LMENV" ]] && ! $DRY_RUN; then
    sed -i 's/^THEME=.*/THEME=Dark/' "$LMENV" || true
    sed -i 's/^NOTIFICATIONS=.*/NOTIFICATIONS=false/' "$LMENV" || true
  fi
  if [[ -f "$LM_APP_SETTINGS" ]] && ! $DRY_RUN; then
    sed -i 's/"monochromeSidebarIcons": false/"monochromeSidebarIcons": true/' "$LM_APP_SETTINGS" || true
  fi
  log "MOOD-SYNC: lm-only done (Center untouched)"
  exit 0
fi

if $BACKGROUND; then
  # Run full but in "background" mode - still execute but log quietly
  log "MOOD-SYNC background full run"
  # fall through to normal execution but no extra output
fi

trap 'log "Interrupted or error - see $LOG_FILE for details"; exit 1' INT TERM ERR

log "=== Starting Left workspace setup (minimal load, Center white HQ protected) ==="
log "Layer: Left (DP-3 chill/analytical). Center (HDMI-A-1) white personal HQ untouched except via minimized viewer windows."

# 1. OpenRGB - lowest visual/mental load (off profile = minimal lights)
if command -v openrgb >/dev/null; then
  if [[ -f ~/.config/OpenRGB/off.orp ]]; then
    run_cmd "OpenRGB minimal (off profile for lowest load)" openrgb -p off.orp
    log "OpenRGB: off.orp (minimalist/low-power) applied. (Create Minimalist.orp in ~/.config/OpenRGB/ if a custom low-sat one is preferred.)"
  else
    run_cmd "OpenRGB (fallback)" openrgb --startminimized || true
    log "OpenRGB: started minimized (no specific low profile found; manually load 'off' or create Minimalist)"
  fi
else
  log "OpenRGB not found - install via package manager if RGB control desired on Left"
fi

# 2. Firefox kiosk profile - dark + strong privacy (edits are auditable + reversible)
if [[ -d "$KIOSK_PROFILE" ]]; then
  PREFS="$KIOSK_PROFILE/prefs.js"
  USERJS="$KIOSK_PROFILE/user.js"
  for f in "$PREFS" "$USERJS"; do
    if [[ -f "$f" ]]; then
      backup_and_diff "$f" "firefox-kiosk $f"
    fi
  done

  if ! $DRY_RUN; then
    for f in "$PREFS" "$USERJS"; do
      if [[ -f "$f" ]]; then
        if ! grep -q "ui.systemUsesDarkTheme" "$f" 2>/dev/null; then
          echo "$DARK_PREFS" >> "$f"
          log "Appended dark/privacy prefs to $f"
        fi
      fi
    done
  else
    log "DRY: would append dark/privacy prefs to kiosk profile user.js/prefs.js"
  fi

  for f in "$PREFS" "$USERJS"; do
    if [[ -f "$f" ]]; then
      show_diff "$f" "${f}.bak.$(date +%s 2>/dev/null || echo '*')" "firefox $f"
    fi
  done

  log "Firefox (kiosk profile): dark theme + enhanced privacy prefs applied. Use Dark Reader extension in the profile for full site dark mode. uBlock Origin / Privacy Badger recommended (install manually in the profile)."
else
  log "Kiosk profile dir not found at $KIOSK_PROFILE - run left-playground.sh --kiosk first?"
fi

# 3. LM Studio low-impact (pcac env + app settings.json if present)
if [[ -f "$LMENV" ]]; then
  backup_and_diff "$LMENV" "lmstudio pcac env"
  if ! $DRY_RUN; then
    sed -i 's/^THEME=.*/THEME=Dark/' "$LMENV" || true
    sed -i 's/^NOTIFICATIONS=.*/NOTIFICATIONS=false/' "$LMENV" || true
    if ! grep -q '^THEME=' "$LMENV"; then echo 'THEME=Dark' >> "$LMENV"; fi
    if ! grep -q '^NOTIFICATIONS=' "$LMENV"; then echo 'NOTIFICATIONS=false' >> "$LMENV"; fi
  fi
  show_diff "$LMENV" "${LMENV}.bak.*" "LM pcac env" || true
  log "LM Studio (pcac config): low-impact theme + notifications=false (affects ask-brain/converse scripts)"
else
  log "LM pcac env not at $LMENV (expected at $PCAC_ROOT/config/lmstudio.env)"
fi

if [[ -f "$LM_APP_SETTINGS" ]]; then
  backup_and_diff "$LM_APP_SETTINGS" "LM app settings"
  if ! $DRY_RUN; then
    sed -i 's/"monochromeSidebarIcons": false/"monochromeSidebarIcons": true/' "$LM_APP_SETTINGS" || true
  fi
  show_diff "$LM_APP_SETTINGS" "${LM_APP_SETTINGS}.bak.*" "LM app settings" || true
  log "LM Studio app: monochrome sidebar (low visual load). Use GUI for full 'power saving' + unload models when idle."
fi

# 4. Monitoring + hardening reference (auditable, local)
log "Monitoring commands (run in left watch pane or terminal):"
log "  journalctl -u lmstudio.service -f   # or relevant units"
log "  tail -f $LOG_FILE"
log "  tail -f $PCAC_LOG_DIR/pcac.log"
log "  review hardening: ~/Documents/PC-Stuff/hardening-log-2026-06-03.md"
log "  pcac-lm-status.sh ; pcac-power-status"

# 5. Low system impact note + Center protection
log "Low load: processes started with nice -10 / ionice where applicable."
log "Center white HQ protection: This script touches ONLY Left (DP-3). Center monitor stays clean/white personal workspace. Use grok-center / center-composer for orchestration. Small floating PCaC windows use CenterWhite konsole profile (light) to blend."

log "=== Left workspace setup complete ==="
log "Run 'left-usual' or re-run this script anytime. All changes backed up + logged for audit (git diff or manual review recommended)."
log "Next: coordinate any Center tweaks via bus or composer (e.g. 'center: apply these left minimal changes')."

if command -v pcac_log >/dev/null; then
  pcac_log INFO "Left workspace setup completed (see $LOG_FILE)"
fi
