#!/usr/bin/env bash
# Download Qwen2.5-14B-Instruct Q4_K_M to /data/AI/models (Phase 1c)
set -euo pipefail

MODELS_DIR="${PCAC_MODELS_DIR:-/data/AI/models}"
REPO="bartowski/Qwen2.5-14B-Instruct-GGUF"
FILE="Qwen2.5-14B-Instruct-Q4_K_M.gguf"

mkdir -p "$MODELS_DIR"
HF="${PCAC_HF_CLI:-/data/AI/venv/bin/hf}"
if [[ ! -x "$HF" ]]; then
  echo "Missing $HF — run: python3 -m venv /data/AI/venv && /data/AI/venv/bin/pip install huggingface_hub" >&2
  exit 1
fi

if [[ -f "$MODELS_DIR/$FILE" ]]; then
  echo "Already present: $MODELS_DIR/$FILE"
  ls -lh "$MODELS_DIR/$FILE"
  exit 0
fi

echo "Downloading $REPO / $FILE (~8.4 GiB) to $MODELS_DIR ..."
"$HF" download "$REPO" "$FILE" --local-dir "$MODELS_DIR"

echo "Done:"
ls -lh "$MODELS_DIR/$FILE"