#!/bin/bash
# mood-sync-trigger.sh — Background Task Queue for Left workspace from Right mood-sync
# Called by right-daily --creative or right-suggest-slot when play layer activates.
# Triggers setup_left_workspace.sh (or specific steps) silently. Zero impact on Center white HQ.
set -euo pipefail

source /data/PCaC-Playgrounds/scripts/lib/common.sh 2>/dev/null || true

MODE="${1:-full}"   # full | openrgb | firefox | lm

pcac_log "mood-sync-trigger: received mode=$MODE from right-daily --creative"

case "$MODE" in
    full|all|play-start)
        SIGNAL="MOOD-SYNC:play-start:openrgb,firefox,lm"
        ;;
    openrgb)
        SIGNAL="MOOD-SYNC:play-start:openrgb"
        ;;
    firefox)
        SIGNAL="MOOD-SYNC:play-start:firefox"
        ;;
    lm|lmstudio)
        SIGNAL="MOOD-SYNC:play-start:lm"
        ;;
    *)
        SIGNAL="MOOD-SYNC:remind:journalctl"
        ;;
esac

# Post as signal to left-chat.log so Left watcher can process and confirm structured/minimal (per cross-convo)
bash -c '
  source /data/PCaC-Playgrounds/scripts/lib/common.sh 2>/dev/null || true
  pcac_post_chat left "Right-Brain (mood-sync)" "'"$SIGNAL"'" "mood-sync" 2>/dev/null || echo "[$(date)] MOOD-SYNC signal: '"$SIGNAL"'" >> /data/PCaC-Playgrounds/shared/left-chat.log
' 

pcac_log "mood-sync-trigger: posted signal $SIGNAL (background queue style, Center untouched, DP-2 only)"

pcac_log "mood-sync-trigger: completed mode=$MODE (background, Center untouched)"
