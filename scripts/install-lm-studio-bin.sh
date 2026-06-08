#!/usr/bin/env bash
# Install pre-built lm-studio-bin from paru cache (after paru -S built the package).
# Run from a terminal where sudo works: ./scripts/install-lm-studio-bin.sh

set -euo pipefail

PKG="/home/matt/.cache/paru/clone/lm-studio-bin/lm-studio-bin-0.4.15-2-x86_64.pkg.tar.zst"

if [[ ! -f "$PKG" ]]; then
  echo "Package not found. Build first:" >&2
  echo "  paru -S lm-studio-bin" >&2
  exit 1
fi

sudo pacman -U --needed "$PKG"
echo ""
echo "Installed. Verify:"
command -v lm-studio
lm-studio --version 2>/dev/null || true
echo ""
echo "Desktop: use /usr/bin/lm-studio (see scripts/lm-studio.desktop)"
echo "Models:  /data/AI/models  (~/.lmstudio/models)"