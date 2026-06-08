#!/usr/bin/env bash
# persona-divergence-test.sh
# ---------------------------------------------------------------
# Send the same prompt to all three personas (Left, Right, Center)
# and score how much they actually diverge.
#
# Usage:
#   ./persona-divergence-test.sh "How can Code-OSS improve dev?"
#   echo "prompt" | ./persona-divergence-test.sh
#
# Requirements:
#   - LM Studio running locally on 127.0.0.1:1234
#   - Models loaded: qwen2.5-coder-14b on slots :1 (Left) and :2 (Right)
#   - Persona SYSTEM.md files in ../personas/{left-brain,right-brain,center}/
#   - Optional: pcac-ask-brain.sh on PATH (preferred). Falls back to curl.
#
# Exit codes:
#   0 = all checks passed
#   1 = at least one format check failed
#   2 = at least one pairwise distance below threshold
#   3 = tool/runtime error (LM Studio down, network issue, etc.)
# ---------------------------------------------------------------

set -u
# Note: not using `set -e` because we want to keep going through checks
# and report all failures, not bail on the first one.

# ---------- config ----------
LMSTUDIO_URL="${LMSTUDIO_URL:-http://127.0.0.1:1234}"
PERSONA_DIR="${PERSONA_DIR:-$(cd "$(dirname "$0")/../personas" && pwd)}"
LEFT_MODEL_SLOT="${LEFT_MODEL_SLOT:-1}"   # /v1/models slot or model id
RIGHT_MODEL_SLOT="${RIGHT_MODEL_SLOT:-2}"
CENTER_MODEL_SLOT="${CENTER_MODEL_SLOT:-1}" # cloud API if available; else local
PROMPT_THRESHOLD="${PROMPT_THRESHOLD:-120}" # word count, sanity upper bound
JACCARD_FLOOR_LR="${JACCARD_FLOOR_LR:-0.4}"  # min Left<->Right distance
JACCARD_FLOOR_LC="${JACCARD_FLOOR_LC:-0.3}"  # min Left<->Center
JACCARD_FLOOR_RC="${JACCARD_FLOOR_RC:-0.4}"  # min Right<->Center

# ---------- args ----------
if [[ $# -ge 1 ]]; then
  PROMPT="$1"
else
  PROMPT="$(cat)"
fi
if [[ -z "${PROMPT:-}" ]]; then
  echo "ERROR: no prompt provided (arg or stdin)" >&2
  exit 3
fi

# ---------- helpers ----------
note() { printf '\033[1;34m[test]\033[0m %s\n' "$*"; }
pass() { printf '\033[1;32m[PASS]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; FAILED=1; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

FAILED=0

# Read a persona's system prompt
read_system() {
  local persona="$1"
  local f="$PERSONA_DIR/$persona/SYSTEM.md"
  if [[ -f "$f" ]]; then
    cat "$f"
  else
    warn "no SYSTEM.md for $persona at $f (using empty prompt)"
    echo ""
  fi
}

# Call a model slot via LM Studio /v1/chat/completions
call_lm() {
  local slot="$1"
  local system="$2"
  local user="$3"
  local payload
  payload=$(jq -n \
    --arg model "$slot" \
    --arg sys "$system" \
    --arg usr "$user" \
    '{model: $model, messages: [{role: "system", content: $sys}, {role: "user", content: $usr}], temperature: 0.5, max_tokens: 1024, stream: false}')

  curl -sS --max-time 60 \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$LMSTUDIO_URL/v1/chat/completions" \
  | jq -r '.choices[0].message.content // empty'
}

# Pull bullets (lines starting with -, *, •, or a digit+.) and lowercase
extract_bullets() {
  grep -E '^[[:space:]]*([-*•]|[0-9]+\.)' \
    | sed -E 's/^[[:space:]]*([-*•]|[0-9]+\.)[[:space:]]*//' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9 ]//g' \
    | awk 'NF>2'
}

# Word count of a string
word_count() { echo "$1" | wc -w | awk '{print $1}'; }

# Jaccard distance: 1 - |A∩B|/|A∪B| on word-shingles (k=3) for soft semantic overlap
jaccard_distance() {
  local a="$1" b="$2" k="${3:-3}"
  python3 - "$a" "$b" "$k" <<'PY'
import sys, re
a, b, k = sys.argv[1], sys.argv[2], int(sys.argv[3])
def shingles(s, k):
    toks = re.findall(r"[a-z0-9]+", s.lower())
    if len(toks) < k: return set(toks)
    return {tuple(toks[i:i+k]) for i in range(len(toks)-k+1)}
sa, sb = shingles(a, k), shingles(b, k)
if not sa or not sb:
    print("0.0"); sys.exit(0)
inter = len(sa & sb)
uni = len(sa | sb)
print(f"{(1 - inter/uni):.3f}")
PY
}

# Format checks
check_left_format() {
  local out="$1"
  local ok=1
  echo "$out" | grep -qiE 'bottom\s*line' || { fail "Left: missing 'Bottom line' header"; ok=0; }
  echo "$out" | grep -qiE 'analysis' || { fail "Left: missing 'Analysis' header"; ok=0; }
  echo "$out" | grep -qiE 'suggested\s*next\s*action|next\s*action' || { fail "Left: missing 'Suggested next action' header"; ok=0; }
  if [[ $ok -eq 1 ]]; then pass "Left format: Bottom line / Analysis / Suggested next action present"; fi
}

check_right_format() {
  local out="$1"
  local ok=1
  echo "$out" | grep -qiE 'vibe' || { fail "Right: missing 'Vibe' line"; ok=0; }
  # Options block: count of `**N.**` or numbered options
  local opt_count
  opt_count=$(echo "$out" | grep -cE '^[[:space:]]*([0-9]+\.|\*\*[0-9]+)' || true)
  if [[ "${opt_count:-0}" -lt 2 ]]; then
    fail "Right: fewer than 2 numbered options (found $opt_count)"
    ok=0
  fi
  echo "$out" | grep -qiE 'soft\s*pick|lean\s*toward|drift\s*toward' || { fail "Right: missing 'Soft pick' (or 'lean toward' / 'drift toward')"; ok=0; }
  if [[ $ok -eq 1 ]]; then pass "Right format: Vibe / 2-3 Options / Soft pick present"; fi
}

check_center_format() {
  local out="$1"
  local ok=1
  echo "$out" | grep -qiE 'dispatch' || { fail "Center: missing 'Dispatch' line"; ok=0; }
  echo "$out" | grep -qiE 'synthesis' || { fail "Center: missing 'Synthesis' block"; ok=0; }
  echo "$out" | grep -qiE 'next\s*move' || { fail "Center: missing 'Next Move' line"; ok=0; }
  if [[ $ok -eq 1 ]]; then pass "Center format: Dispatch / Synthesis / Next Move present"; fi
}

# ---------- runtime check ----------
note "checking LM Studio at $LMSTUDIO_URL ..."
if ! curl -sS --max-time 5 "$LMSTUDIO_URL/v1/models" >/dev/null 2>&1; then
  echo "ERROR: LM Studio not reachable at $LMSTUDIO_URL" >&2
  echo "       start it and load a model on :1 and :2, then re-run." >&2
  exit 3
fi

# ---------- load system prompts ----------
note "loading persona system prompts from $PERSONA_DIR"
LEFT_SYS="$(read_system left-brain)"
RIGHT_SYS="$(read_system right-brain)"
CENTER_SYS="$(read_system center)"

# ---------- dispatch ----------
note "prompt: \"$PROMPT\""
echo

note "calling Left-Brain (slot $LEFT_MODEL_SLOT) ..."
LEFT_OUT="$(call_lm "$LEFT_MODEL_SLOT" "$LEFT_SYS" "$PROMPT" || true)"
[[ -n "$LEFT_OUT" ]] || { echo "ERROR: empty response from Left" >&2; exit 3; }

note "calling Right-Brain (slot $RIGHT_MODEL_SLOT) ..."
RIGHT_OUT="$(call_lm "$RIGHT_MODEL_SLOT" "$RIGHT_SYS" "$PROMPT" || true)"
[[ -n "$RIGHT_OUT" ]] || { echo "ERROR: empty response from Right" >&2; exit 3; }

note "calling Center (slot $CENTER_MODEL_SLOT) ..."
CENTER_OUT="$(call_lm "$CENTER_MODEL_SLOT" "$CENTER_SYS" "$PROMPT" || true)"
[[ -n "$CENTER_OUT" ]] || { echo "ERROR: empty response from Center" >&2; exit 3; }

# ---------- save artifacts ----------
ART_DIR="${ART_DIR:-/tmp/persona-divergence-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$ART_DIR"
printf '%s' "$LEFT_OUT"   > "$ART_DIR/left.md"
printf '%s' "$RIGHT_OUT"  > "$ART_DIR/right.md"
printf '%s' "$CENTER_OUT" > "$ART_DIR/center.md"
note "saved responses to $ART_DIR/{left,right,center}.md"
echo

# ---------- format checks ----------
echo "================ FORMAT CHECKS ================"
check_left_format   "$LEFT_OUT"
check_right_format  "$RIGHT_OUT"
check_center_format "$CENTER_OUT"
echo

# ---------- length sanity ----------
echo "================ LENGTH SANITY ================"
LW=$(word_count "$LEFT_OUT")
RW=$(word_count "$RIGHT_OUT")
CW=$(word_count "$CENTER_OUT")
echo "  Left   = $LW words"
echo "  Right  = $RW words"
echo "  Center = $CW words"
MIN=$(( LW < RW ? LW : RW )); MIN=$(( MIN < CW ? MIN : CW ))
MAX=$(( LW > RW ? LW : RW )); MAX=$(( MAX > CW ? MAX : CW ))
if [[ "$MIN" -gt 0 ]] && [[ $(( MAX / MIN )) -gt 5 ]]; then
  fail "length ratio > 5x (max=$MAX, min=$MIN) — one persona is dominating"
else
  pass "lengths within 5x ratio"
fi
echo

# ---------- divergence ----------
echo "================ PAIRWISE DIVERGENCE ================"
echo "(Jaccard distance on 3-word shingles; higher = more divergent)"
LR=$(jaccard_distance "$LEFT_OUT"  "$RIGHT_OUT")
LC=$(jaccard_distance "$LEFT_OUT"  "$CENTER_OUT")
RC=$(jaccard_distance "$RIGHT_OUT" "$CENTER_OUT")
echo "  Left  <-> Right  = $LR   (floor: $JACCARD_FLOOR_LR)"
echo "  Left  <-> Center = $LC   (floor: $JACCARD_FLOOR_LC)"
echo "  Right <-> Center = $RC   (floor: $JACCARD_FLOOR_RC)"

# Compare as floats (bash doesn't do floats; use python)
check_floor() {
  local label="$1" val="$2" floor="$3"
  python3 -c "import sys; sys.exit(0 if float('$val') >= float('$floor') else 1)" \
    && pass "$label  >=  $floor" \
    || fail "$label  =  $val  is below floor $floor"
}
check_floor "Left  <-> Right  " "$LR" "$JACCARD_FLOOR_LR"
check_floor "Left  <-> Center " "$LC" "$JACCARD_FLOOR_LC"
check_floor "Right <-> Center " "$RC" "$JACCARD_FLOOR_RC"
echo

# ---------- verdict ----------
echo "================ VERDICT ================"
if [[ "$FAILED" -eq 0 ]]; then
  pass "all checks passed — personas are diverging as designed"
  exit 0
fi
fail "at least one check failed — see above"
# Decide exit code: prefer "format" failures (1), then "divergence" (2)
if [[ "$FAILED" -eq 1 ]]; then exit 1; else exit 2; fi
 