# Center — orchestrator memory (optional)

**Grok Center** runs on the center monitor (HDMI-A-1). Cloud Grok CLI is the primary orchestrator; this file is for **cross-side notes** you want in git (not a replacement for `~/.grok/memory`).

## Three-way coordination

- Left chat: `shared/left-chat.log`
- Right chat: `shared/right-chat.log`
- Future bus: `shared/bus/messages.jsonl` (Phase 2)

## Decisions log

- 2026-06-03: Phase 1a — `/data/AI` layout + `~/.lmstudio` symlink
- 2026-06-03: Phase 1b — `personas/` scaffold in repo

## Pending

- LM Studio: restore AppImage or install `lm-studio-bin`
- Model: Qwen2.5-14B-Instruct Q4_K_M → `/data/AI/models`
- Phase 2: `ask:` local brain + JSONL bus