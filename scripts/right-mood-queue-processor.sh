#!/usr/bin/env bash
# right-mood-queue-processor.sh — Simple background processor for Right's mood queue.
# Run in right watch pane or nohup: nice -n 10 ionice -c3 this-script &
# Tails the queue file, posts signals via proper chat (so Left watcher sees them), marks done.
# Strictly DP-2, zero cues on Center white HQ. Fully logged/auditable/reversible.
set -euo pipefail

source /data/PCaC-Playgrounds/scripts/lib/common.sh 2>/dev/null || true

QUEUE_FILE="/data/PCaC-Playgrounds/shared/right-mood-queue.txt"
DONE_FILE="${QUEUE_FILE}.done"
mkdir -p "$(dirname "$QUEUE_FILE")" 2>/dev/null || true
touch "$QUEUE_FILE" "$DONE_FILE"

pcac_log "right-mood-queue-processor: starting (low priority, Center protected)"

# Low impact
if command -v nice >/dev/null; then renice -n 10 $$ >/dev/null 2>&1 || true; fi

tail -n 0 -F "$QUEUE_FILE" | while read -r line; do
  [[ -z "$line" ]] && continue
  SIGNAL=$(echo "$line" | sed 's/^[0-9- :]*//')  # strip timestamp if present
  pcac_log "right-mood-queue-processor: processing $SIGNAL"
  
  # Post the signal so Left's watcher can handle + confirm
  pcac_post_chat left "Right-Brain (mood-sync)" "$SIGNAL" "mood-sync" 2>/dev/null || \
    echo "[$(date)] MOOD-SYNC signal: $SIGNAL" >> /data/PCaC-Playgrounds/shared/left-chat.log

  # Mark done (append to .done for audit)
  echo "$line" >> "$DONE_FILE"
  
  # Optional: remove the line from queue (simple for this demo; for production use a proper queue lib or sqlite)
  # For now, we leave it (or user can truncate periodically)
done
