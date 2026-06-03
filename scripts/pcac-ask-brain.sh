#!/usr/bin/env bash
# Ask Left-Brain or Right-Brain (LM Studio + persona prompts)
# Usage: pcac-ask-brain.sh left|right "your question" [user_label]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

SIDE="${1:-}"
MSG="${2:-}"
USER_LABEL="${3:-$(whoami)}"

if [[ -z "$SIDE" || -z "$MSG" ]]; then
  echo "Usage: pcac-ask-brain.sh left|right \"message\" [user_label]" >&2
  exit 2
fi

exec python3 "$SCRIPT_DIR/pcac_ask_brain.py" "$SIDE" "$MSG" "$USER_LABEL"