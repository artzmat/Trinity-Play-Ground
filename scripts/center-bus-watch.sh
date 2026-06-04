#!/usr/bin/env bash
# Center monitor: live tail of shared/bus/messages.jsonl with grok_query highlights
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

pcac_ensure_chats

echo "=== PCaC BUS WATCH (Center) ==="
echo "File: $PCAC_BUS_FILE"
echo "grok_query → needs Center response (pcac_center_reply left|right '...')"
echo "Ctrl-C to exit"
echo "=============================="
echo "Current hardware/power (use /power in center-composer for live):"
~/.local/bin/pcac-power-status 2>/dev/null | head -8 || /data/PCaC-Playgrounds/scripts/pcac-power-status.sh | head -8 || echo "(power status script not found)"
echo "=============================="

if [[ ! -s "$PCAC_BUS_FILE" ]]; then
  echo "(waiting for first message...)"
fi

tail -n 15 -f "$PCAC_BUS_FILE" 2>/dev/null | while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! echo "$line" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    echo "$line"
    continue
  fi
  kind=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('kind',''))")
  ts=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('ts',''))")
  from_=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('from',''))")
  to=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('to',''))")
  text=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('text',''))")
  if [[ "$kind" == "grok_query" ]]; then
    echo ""
    echo ">>> GROK QUERY for Center [$ts] from $from_ >>>"
    echo "    $text"
    echo ">>> Reply: pcac_center_reply left|right \"your answer\" <<<"
    echo ""
  else
    echo "[$ts] $kind | $from_ → $to | ${text:0:120}"
  fi
done