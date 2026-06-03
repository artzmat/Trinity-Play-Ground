#!/usr/bin/env bash
# Ask Left-Brain and Right-Brain the same question (parallel LM Studio calls).
# Usage: pcac-ask-both.sh "your question" [user_label]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MSG="${1:-}"
USER_LABEL="${2:-$(whoami)}"

if [[ -z "$MSG" ]]; then
  echo "Usage: pcac-ask-both.sh \"message\" [user_label]" >&2
  exit 2
fi

pcac_ask_both "$MSG" "$USER_LABEL"