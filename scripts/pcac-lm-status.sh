#!/usr/bin/env bash
# Quick LM Studio + PCaC brain status (VRAM when rocm-smi is available)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

BASE="${LMSTUDIO_URL:-http://127.0.0.1:1234/v1}"
ENV_FILE="${PCAC_ROOT}/config/lmstudio.env"

echo "=== PCaC LM / brain status ==="
echo "Time: $(date -Iseconds)"
echo ""

if [[ -f "$ENV_FILE" ]]; then
  echo "--- config/lmstudio.env (side mapping) ---"
  grep -E '^LMSTUDIO_MODEL' "$ENV_FILE" | grep -v '^#' || true
  echo ""
fi

echo "--- LM Studio API ($BASE) ---"
if curl -sfS --connect-timeout 2 "${BASE}/models" >/tmp/pcac-lm-models.json 2>/dev/null; then
  echo "Server: UP"
  jq -r '.data[] | "  \(.id)"' /tmp/pcac-lm-models.json 2>/dev/null || cat /tmp/pcac-lm-models.json
  rm -f /tmp/pcac-lm-models.json
else
  echo "Server: DOWN — start Local Server in LM Studio"
fi
echo ""

echo "--- GPU VRAM (if available) ---"
if command -v rocm-smi >/dev/null 2>&1; then
  rocm-smi --showmeminfo vram 2>/dev/null || rocm-smi 2>/dev/null | head -20
elif command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv
else
  echo "  (install rocm-smi or use LM Studio resource widget — not in PATH here)"
fi
echo ""

echo "--- lm-studio processes ---"
pgrep -c lm-studio 2>/dev/null && pgrep -a lm-studio 2>/dev/null | head -3 || echo "  (none)"
echo ""

echo "--- Recent bus (grok_query) ---"
pcac_tail_bus 5 2>/dev/null || true
echo ""
echo "Test brains: pcac-ask-brain.sh left|right \"ping\" $(whoami)"
echo "Test both:   pcac-ask-both.sh \"ping\" $(whoami)"