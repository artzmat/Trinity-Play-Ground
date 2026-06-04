#!/usr/bin/env bash
# Record a fact into Left-Brain or Right-Brain persistent memory (curated by Center).
# Usage: pcac-remember.sh left|right "short memorable fact or preference"
#
# Examples:
#   pcac-remember.sh left "User likes short numbered lists and explicit assumptions for plans."
#   pcac-remember.sh right "Ongoing creative thread: ambient game soundtracks for low-pressure exploration."

set -euo pipefail

# Resolve the real location even if this script is a symlink (e.g. in ~/.local/bin)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

SIDE="${1:-}"
FACT="${2:-}"

if [[ -z "$SIDE" || -z "$FACT" ]]; then
  echo "Usage: pcac-remember.sh left|right \"memorable fact\"" >&2
  echo "  Records under '## Curated facts (Center)' in the side's MEMORY.md" >&2
  exit 2
fi

exec python3 "$SCRIPT_DIR/pcac_remember.py" "$SIDE" "$FACT"
