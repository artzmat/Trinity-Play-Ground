#!/usr/bin/env bash
# Center Chat Viewer - for the Orchestrator Grok (Center)
# Tails both Left and Right chats in one view.
# Use this on Center monitor to see what Left and Right personas are saying.
# Post responses using the pcac_post_chat helper or manually echo to the logs.
# Left/Right personas can view this Center monitor physically but have no control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
else
  PCAC_LEFT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/left-chat.log"
  PCAC_RIGHT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/right-chat.log"
fi

pcac_ensure_chats

echo "=== CENTER ORCHESTRATOR CHAT VIEW ==="
echo "Watching Left and Right chats + bus (JSONL). Press Ctrl-C to exit."
echo "Respond: pcac_post_chat left 'Center Grok (to Left)' 'text'"
echo "Bus tail: pcac_tail_bus 20   file: $PCAC_BUS_FILE"
echo "=========================================="
pcac_tail_bus 8 2>/dev/null || true
echo "------------------------------------------"

# Use multitail if available, else simple loop with two tails
if command -v multitail >/dev/null 2>&1; then
  multitail -l "tail -f $PCAC_LEFT_CHAT_LOG" -l "tail -f $PCAC_RIGHT_CHAT_LOG" --no-repeat --follow-all
else
  # Fallback: simple combined tail (not perfect split but works)
  echo "(multitail not found, using combined tail - install with paru -S multitail for better split view)"
  tail -f "$PCAC_LEFT_CHAT_LOG" "$PCAC_RIGHT_CHAT_LOG"
fi
