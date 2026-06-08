#!/usr/bin/env bash
# diag-lmstudio-slots.sh — Compare env-var model targets to live LM Studio ids.
#
# Prints a 3-column matrix:
#   side | env target | live /v1/models ids | status
# Status values:
#   OK            — env target matches a loaded model id exactly
#   UNIQUE-MISS   — env target does not match any loaded model id (likely 400)
#   COLLAPSE      — two env targets resolve to the same model id
#                   (Left and Right would hit the same slot — persona collapse)
#
# Usage:
#   scripts/diag-lmstudio-slots.sh
#   LMSTUDIO_URL=http://127.0.0.1:1234/v1 scripts/diag-lmstudio-slots.sh
#
# Exits non-zero if any status is UNIQUE-MISS or COLLAPSE. That way you can
# `set -e` and `&&` it into a smoke pipeline.
#
# History: written 2026-06-07 after the 400 / Left=Center bug surfaced.
# The single most common cause of "my persona answered as the wrong persona"
# is a misrouted model id in this matrix. Run this *before* troubleshooting
# the system prompt or the model itself.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_DIR/config/lmstudio.env"

# Load env file (only KEY=VALUE lines, ignore comments and blank lines)
declare -A ENV_TARGET
if [[ -f "$ENV_FILE" ]]; then
    while IFS='=' read -r k v; do
        # skip blanks and comments
        [[ -z "$k" || "$k" =~ ^[[:space:]]*# ]] && continue
        k="$(echo "$k" | xargs)"
        v="$(echo "$v" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
        ENV_TARGET["$k"]="$v"
    done < <(grep -E '^[A-Z_]+=' "$ENV_FILE" || true)
fi

# Env var can override
BASE_URL="${LMSTUDIO_URL:-${ENV_TARGET[LMSTUDIO_BASE_URL]:-http://127.0.0.1:1234/v1}}"
BASE_URL="${BASE_URL%/}"

# Fetch live model list
LIVE_JSON="$(curl -sS --connect-timeout 3 "$BASE_URL/models" || true)"
if [[ -z "$LIVE_JSON" ]]; then
    echo "FAIL: could not reach $BASE_URL/models" >&2
    echo "  1) Is LM Studio running?" >&2
    echo "  2) Is the local server started (Developer → Local Server → Start)?" >&2
    exit 2
fi

# Parse ids with python (jq is allowed but python is universally present)
mapfile -t LIVE_IDS < <(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
for m in data.get("data") or []:
    print(m.get("id", ""))
' <<< "$LIVE_JSON")

# Pretty print
printf '%-9s | %-50s | %s\n' "SIDE" "ENV TARGET" "STATUS"
printf '%-9s-+-%-50s-+-%s\n' "---------" "$(printf '%.0s-' {1..50})" "----------------------------------------"

EXIT_CODE=0
declare -A RESOLVED_ID
TARGETS=(
    "LEFT|LMSTUDIO_MODEL_LEFT"
    "RIGHT|LMSTUDIO_MODEL_RIGHT"
    "CENTER|LMSTUDIO_MODEL_CENTER"
)

for entry in "${TARGETS[@]}"; do
    side="${entry%%|*}"
    env_key="${entry##*|}"
    target="${ENV_TARGET[$env_key]:-}"
    target="${target:-<unset>}"

    status="UNIQUE-MISS"
    match_id=""
    for id in "${LIVE_IDS[@]}"; do
        if [[ "$id" == "$target" ]]; then
            status="OK"
            match_id="$id"
            break
        fi
    done

    if [[ "$status" == "OK" ]]; then
        printf '%-9s | %-50s | OK  (matches %s)\n' "$side" "$target" "$match_id"
        RESOLVED_ID["$side"]="$match_id"
    else
        printf '%-9s | %-50s | UNIQUE-MISS  (closest live id: see list below)\n' "$side" "$target"
        # Helpful hint: prefix-stripped close match
        for id in "${LIVE_IDS[@]}"; do
            if [[ "$id" == *"$(echo "$target" | sed -e 's|.*/||')"* ]]; then
                printf '           %-50s   did you mean: %s ?\n' "" "$id"
            fi
        done
        EXIT_CODE=1
    fi
done

# Detect collapse: Left and Right resolve to the same id
if [[ "${RESOLVED_ID[LEFT]:-}" != "" && "${RESOLVED_ID[RIGHT]:-}" != "" \
      && "${RESOLVED_ID[LEFT]}" == "${RESOLVED_ID[RIGHT]}" ]]; then
    echo
    echo "COLLAPSE: LEFT and RIGHT both resolve to '${RESOLVED_ID[LEFT]}'."
    echo "  Load two separate Qwen instances in LM Studio (slot :1 and slot :2)"
    echo "  and update LMSTUDIO_MODEL_LEFT / LMSTUDIO_MODEL_RIGHT in"
    echo "  $ENV_FILE to point at distinct ids."
    EXIT_CODE=1
fi

echo
echo "Live model ids from $BASE_URL/models:"
for id in "${LIVE_IDS[@]}"; do
    echo "  - $id"
done

if [[ $EXIT_CODE -ne 0 ]]; then
    echo
    echo "RESULT: at least one issue. Fix the env file or load missing models."
fi

exit $EXIT_CODE
