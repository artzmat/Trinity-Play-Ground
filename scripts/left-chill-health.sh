#!/usr/bin/env bash
# left-chill-health.sh — Low-stimulation, low-resource health snapshot for Left-Brain.
# Runs with nice/ionice. Appends structured text to left-chat.log so the local Qwen brain sees it via recent context.
# Zero impact on Center white HQ. Safe to run periodically from Left tmux or via mood-sync.
# Part of ongoing Left-Brain Qwen / PCaC chill layer improvements (headroom allows this).

set -euo pipefail

# Low priority always
if command -v nice >/dev/null && command -v ionice >/dev/null; then
  exec nice -n 15 ionice -c 3 "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null || true

CHAT_LOG="${PCAC_LEFT_CHAT_LOG:-$PCAC_ROOT/shared/left-chat.log}"
mkdir -p "$(dirname "$CHAT_LOG")"

ts=$(date '+%H:%M:%S')
{
  echo "[$ts] Left-Brain (health):"
  echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
  echo "  Memory: $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
  echo "  Disk /data: $(df -h /data | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
  echo "  LM Studio API: $(curl -sI --max-time 2 http://127.0.0.1:1234/v1/models | head -1 || echo 'down')"
  echo "  SearXNG: $(curl -sI --max-time 2 http://127.0.0.1:8080 | head -1 || echo 'down')"
  echo "  Suggestion board: $(curl -sI --max-time 2 http://127.0.0.1:8765 | head -1 || echo 'down')"
  echo "  OpenRGB: $(pgrep -c openrgb || echo 0) process(es)"
  echo "  Recent mood signals (last 5 min): $(grep -i 'MOOD-SYNC' "$CHAT_LOG" 2>/dev/null | tail -3 | wc -l || echo 0)"
  echo "  Recommendation: All services look chill. Left layer ready for more analytical tasks or mood-triggered minimalism."
} >> "$CHAT_LOG"

echo "Left chill health snapshot appended to $CHAT_LOG (low priority, Center untouched)."
