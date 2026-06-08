#!/usr/bin/env bash
# diag-center-400.sh — Minimal-payload probe for the Center (Command-R) slot.
#
# History: 2026-06-07 the Center 400 error was caused by a wrong model id
# in the env file. This script:
#   1) Reads LMSTUDIO_MODEL_CENTER from config/lmstudio.env
#   2) Sends a minimal 1-sentence system + 1-sentence user prompt
#   3) Tries BOTH the env-var model id AND each live id whose name contains
#      "command-r" — so we can tell whether the problem is the env id, the
#      model itself, or LM Studio settings.
#
# Usage:
#   scripts/diag-center-400.sh
#   LMSTUDIO_URL=http://127.0.0.1:1234/v1 scripts/diag-center-400.sh
#
# Exits non-zero if every probe returned 4xx. Exits 0 if at least one
# returned 200.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_DIR/config/lmstudio.env"

# Read the env target the same way other scripts do
ENV_TARGET="$(grep -E '^LMSTUDIO_MODEL_CENTER=' "$ENV_FILE" 2>/dev/null \
    | head -n1 | cut -d= -f2- | xargs | sed -e 's/^"//' -e 's/"$//')"
ENV_TARGET="${ENV_TARGET:-}"

# Base URL
BASE_URL="${LMSTUDIO_URL:-http://127.0.0.1:1234/v1}"
BASE_URL="${BASE_URL%/}"

API_KEY="${LMSTUDIO_API_KEY:-lm-studio}"

probe_model() {
    local model_id="$1"
    local label="$2"
    echo
    echo "--- probe: $label  (model=$model_id) ---"
    local body
    body=$(cat <<EOF
{
  "model": "$model_id",
  "messages": [
    {"role": "system", "content": "You are Center. You are operational."},
    {"role": "user",   "content": "Confirm you are operational as Center."}
  ],
  "temperature": 0.3,
  "max_tokens": 128
}
EOF
)
    local out
    out="$(curl -sS -X POST "$BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "$body" \
        -w "\n__HTTP_STATUS__=%{http_code}")"
    local code content
    code="$(printf '%s' "$out" | sed -n 's/^__HTTP_STATUS__=//p')"
    content="$(printf '%s' "$out" | sed '$d')"
    echo "HTTP $code"
    # Print first ~400 chars of body, single-line
    echo "$content" | tr -d '\n' | cut -c1-400
    echo
    if [[ "$code" =~ ^2 ]]; then
        return 0
    else
        return 1
    fi
}

if [[ -z "$ENV_TARGET" ]]; then
    echo "FAIL: LMSTUDIO_MODEL_CENTER is not set in $ENV_FILE" >&2
    exit 2
fi

# 1) Probe with the env value
probe_model "$ENV_TARGET" "env value" && exit 0

# 2) Probe every live id whose name contains 'command-r' as a fallback hint
echo
echo "Env target did not respond 200. Trying all loaded 'command-r' ids..."
mapfile -t CANDIDATES < <(curl -sS "$BASE_URL/models" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
for m in data.get("data") or []:
    mid = m.get("id","")
    if "command-r" in mid.lower():
        print(mid)
')
ANY_OK=1
for cand in "${CANDIDATES[@]}"; do
    if probe_model "$cand" "live candidate"; then
        ANY_OK=0
        SUGGESTED="$cand"
    fi
done

if [[ $ANY_OK -eq 0 ]]; then
    echo
    echo "RESULT: at least one Command-R id responds 200. Suggested fix:"
    echo "  Set LMSTUDIO_MODEL_CENTER=$SUGGESTED in $ENV_FILE"
    exit 0
fi

echo
echo "RESULT: no Command-R id responds 200. Either the model is not loaded"
echo "        in LM Studio, or LM Studio's local server is not running."
exit 1
