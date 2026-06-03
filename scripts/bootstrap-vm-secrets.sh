#!/usr/bin/env bash
# Create local-only secrets/vm-guest.txt from example (never overwrites existing).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE="$REPO/secrets/vm-guest.txt.example"
TARGET="$REPO/secrets/vm-guest.txt"

if [[ -f "$TARGET" ]]; then
  echo "Already exists: $TARGET (unchanged)"
  ls -la "$TARGET"
  exit 0
fi

cp "$EXAMPLE" "$TARGET"
chmod 600 "$TARGET"
echo "Created $TARGET — edit with your dedicated VM guest passwords."
echo "Policy: docs/vm-guest-password-policy.md"