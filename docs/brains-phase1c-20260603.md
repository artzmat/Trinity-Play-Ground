# Phase 1c — Qwen2.5-14B Q4_K_M + LM Studio smoke test

**Date:** 2026-06-03  
**Command:** `go 1c`

## Completed

| Step | Status |
|------|--------|
| Model on `/data/AI/models` | ✅ `Qwen2.5-14B-Instruct-Q4_K_M.gguf` (~8.4 GiB) |
| Download script | ✅ `scripts/download-qwen14b-q4km.sh` |
| HF tooling venv | ✅ `/data/AI/venv` (huggingface_hub) |
| Smoke-test script | ✅ `scripts/smoke-test-lmstudio.sh` |

## Blocked (needs you)

| Step | Status |
|------|--------|
| `lm-studio-bin` installed | ❌ Run `scripts/install-lm-studio-bin.sh` (sudo) |
| Local server `:1234` | ❌ Not listening until LM Studio started |
| Load model in LM Studio | ❌ Manual: load GGUF from `/data/AI/models/` |
| Grok `~/.grok/config.toml` | ⏳ Template below after server shows model id |

## Finish 1c (your terminal)

```bash
# 1. Install LM Studio (if not done)
/data/PCaC-Playgrounds/scripts/install-lm-studio-bin.sh

# 2. GUI: load model + start server
lm-studio
# Load: /data/AI/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf
# Developer → Local Server → Start

# 3. Smoke test
/data/PCaC-Playgrounds/scripts/smoke-test-lmstudio.sh

# 4. Note model id from JSON, then add to ~/.grok/config.toml (see below)
curl -s http://127.0.0.1:1234/v1/models | jq .
```

## Grok config snippet (after you know model `id`)

```toml
[model.lmstudio-qwen]
model = "REPLACE_WITH_ID_FROM_/v1/models"
base_url = "http://127.0.0.1:1234/v1"
name = "Qwen2.5-14B Q4 (local)"
api_key = "lm-studio"
context_window = 32768

# optional default for local-only sessions:
# [models]
# default = "lmstudio-qwen"
```

Test: `grok -p "Say hi in one sentence" -m lmstudio-qwen`

## Reversible

- Delete GGUF: `rm /data/AI/models/Qwen2.5-14B-Instruct-Q4_K_M.gguf`
- Remove venv: `rm -rf /data/AI/venv`