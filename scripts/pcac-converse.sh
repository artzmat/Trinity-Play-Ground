#!/usr/bin/env bash
# Cross-brain conversation between Left and Right using their local LM Studio models.
# Center (you) orchestrates and everything is logged to the side chat logs + central bus.
# Perfect for testing dual-brain load and seeing GPU usage.
#
# Usage:
#   pcac-converse.sh left "topic here" [num_turns]
#   pcac-converse.sh right "another topic" 6
#
# After sourcing common.sh you can also just use the function: pcac_converse ...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

STARTER="${1:-left}"
TOPIC="${2:-}"
TURNS="${3:-4}"

if [[ -z "$TOPIC" ]]; then
  echo "Usage: pcac-converse.sh left|right \"topic for Left <-> Right dialogue\" [num_turns=4]"
  echo "Example: pcac-converse.sh left \"low-stimulation ways to explore new music while gaming\" 5"
  exit 2
fi

exec bash -c "source '$SCRIPT_DIR/lib/common.sh'; pcac_converse '$STARTER' '$TOPIC' '$TURNS'"
