#!/usr/bin/env bash
# pcac-start-brains — Helper to get Left/Right local LM brains online.
# Center runs this (or sides via ask:). Opens LM Studio app if needed and gives exact steps.
# Per cross-convo recommendations: reduces friction for local persona convos.
set -euo pipefail

echo "=== PCaC Start Local Brains (LM Studio) ==="
echo "Config: Left = qwen/qwen2.5-coder-14b , Right = qwen/qwen2.5-coder-14b:2 (see config/lmstudio.env)"
echo ""

# Strict local-first check for lms (as broadcast by Center)
echo "=== Strict local-first lms check (no network) ==="
which lms 2>/dev/null || echo "which: no lms in PATH"
type lms 2>/dev/null || echo "type: lms not a shell builtin or alias"
find ~ -name 'lms' -type f 2>/dev/null | head -3
ls -l ~/.local/bin/lms 2>/dev/null || echo "~/.local/bin/lms not present (will try to expose bundled one)"
LMS_BUNDLED="/opt/LM-Studio/resources/app/.webpack/lms"
if [[ -x "$LMS_BUNDLED" ]]; then
  echo "Found bundled binary inside LM Studio app: $LMS_BUNDLED"
  "$LMS_BUNDLED" --version 2>&1 | head -1
  mkdir -p ~/.local/bin
  ln -sf "$LMS_BUNDLED" ~/.local/bin/lms
  echo "Symlinked to ~/.local/bin/lms for local use (note: this is Bun 1.3.3 runtime bundled by LM Studio, not the dedicated CLI manager)."
else
  echo "No bundled lms found at $LMS_BUNDLED"
fi
lms --version 2>&1 || echo "lms --version (after possible symlink) failed or still missing dedicated CLI"
lms status 2>&1 || echo "lms status failed (expected if no dedicated lms CLI or server not up)"
echo "=== end lms check ==="
echo ""

if pgrep -f 'lm-studio' >/dev/null 2>&1 || pgrep -f 'LM-Studio' >/dev/null 2>&1; then
  echo "LM Studio app appears to be running."
else
  echo "Launching LM Studio app..."
  /usr/bin/lm-studio &
  sleep 3
fi

echo ""
echo "=== NEXT STEPS IN THE LM STUDIO GUI (white center or wherever) ==="
echo "1. Switch to the 'Developer' or 'Local Server' tab/section."
echo "2. Click 'Start Server' (should listen on http://127.0.0.1:1234/v1 )."
echo "3. In the Models or Chat section, load the models:"
echo "   - For Left: qwen/qwen2.5-coder-14b or the GGUF at /data/AI/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf"
echo "   - For Right: the :2 variant or duplicate load."
echo "4. Verify with: curl -s http://127.0.0.1:1234/v1/models | jq ."
echo ""
echo "Note on 'lms' CLI: Current LM Studio packaging bundles 'lms' as Bun runtime (not the full CLI for 'lms server start')."
echo "If a dedicated lms CLI binary becomes available strictly locally, it will be picked up by the check above."
echo ""
echo "Once server is up, test from center:"
echo "  pcac-ask-brain.sh left 'quick test' matt"
echo "  pcac-ask-both.sh 'system status vibe check' matt"
echo "  Or start cross-convo: pcac-converse.sh right 'topic' 4"
echo ""
echo "Tip: Add to fish: alias start-brains='/data/PCaC-Playgrounds/scripts/pcac-start-brains.sh'"
echo "If you want one-click full: Center can script xdotool or accessibility to auto-click Start Server (advanced, brittle)."
