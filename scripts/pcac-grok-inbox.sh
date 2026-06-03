#!/usr/bin/env bash
# List recent grok_query messages from the bus (Center inbox)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

N="${1:-20}"
pcac_ensure_chats

if [[ ! -s "$PCAC_BUS_FILE" ]]; then
  echo "(no bus messages yet)"
  exit 0
fi

echo "=== GROK INBOX (last $N queries to Center) ==="
python3 - "$PCAC_BUS_FILE" "$N" <<'PY'
import json, sys
path, n = sys.argv[1], int(sys.argv[2])
lines = open(path, encoding="utf-8").read().splitlines()
queries = []
for line in lines:
    if not line.strip():
        continue
    try:
        o = json.loads(line)
    except json.JSONDecodeError:
        continue
    if o.get("kind") == "grok_query" and o.get("to") == "center":
        queries.append(o)
for o in queries[-n:]:
    print(f"{o.get('ts')} | {o.get('from')}")
    print(f"  {o.get('text')}")
    print()
PY
echo "Reply: pcac_center_reply left|right \"message\"  |  both: pcac_center_reply_both \"...\""
echo "Ask both brains: pcac-ask-both.sh \"question\" $(whoami)"