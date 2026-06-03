#!/usr/bin/env bash
# Smoke-test LM Studio OpenAI-compatible API (Phase 1c)
set -euo pipefail

BASE="${LMSTUDIO_URL:-http://127.0.0.1:1234/v1}"

echo "GET $BASE/models"
if ! curl -sfS --connect-timeout 3 "$BASE/models" | head -c 2000; then
  echo "" >&2
  echo "FAIL: LM Studio server not reachable." >&2
  echo "  1) Install: /data/PCaC-Playgrounds/scripts/install-lm-studio-bin.sh" >&2
  echo "  2) Open lm-studio → Developer → Local Server → Start" >&2
  echo "  3) Load model: /data/AI/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf" >&2
  exit 1
fi

echo ""
echo "OK — server responding."