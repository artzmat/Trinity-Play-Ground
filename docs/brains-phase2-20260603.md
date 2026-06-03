# Phase 2 — Message bus + `ask:` local brains ✅

**Date:** 2026-06-03

## Added

| Component | Purpose |
|-----------|---------|
| `shared/bus/messages.jsonl` | Machine-readable bus (runtime, gitignored via `shared/`) |
| `scripts/pcac_bus.py` | Append / tail JSONL |
| `scripts/pcac_ask_brain.py` | LM Studio + `personas/*/SYSTEM.md` + `MEMORY.md` |
| `scripts/pcac-ask-brain.sh` | CLI wrapper |
| `config/lmstudio.env` | Base URL, model id, max tokens |
| `pcac_post_chat` | Dual-writes chat log + bus |
| `left-chat.sh` / `right-chat.sh` | `ask:` prefix → local brain |

## Bus record schema

```json
{"ts":"2026-06-03T18:00:00Z","from":"Left Grok (matt)","to":"center","kind":"grok_query","text":"grok: hello"}
```

| Field | Values |
|-------|--------|
| `kind` | `chat`, `grok_query`, `brain_reply`, `error` |
| `to` | `left`, `right`, `center` |

## Chat prefixes

| Prefix | Handler |
|--------|---------|
| `grok:` | Center orchestrator (you / cloud Grok) — bus `grok_query` → `center` |
| `ask:` | Local Left/Right brain via LM Studio |
| (plain) | Log only, visible to Center |

## Commands

```bash
# Tail bus from Center
source /data/PCaC-Playgrounds/scripts/lib/common.sh
pcac_tail_bus 20

# Ask from shell
/data/PCaC-Playgrounds/scripts/pcac-ask-brain.sh left "What should I check today?"

# Smoke LM Studio first
/data/PCaC-Playgrounds/scripts/smoke-test-lmstudio.sh
```

## Prerequisite

LM Studio **local server** must be running with the Qwen GGUF loaded. Until then, `ask:` posts an offline message to the side chat log.

## Next

- **go 2b** (optional): Center script to auto-reply to `grok_query` bus lines
- Eye tracking hooks in Right `MEMORY.md` when ready