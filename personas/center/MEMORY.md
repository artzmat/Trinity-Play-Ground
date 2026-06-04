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
* [2026-06-04] Sides tweaking Qwen2.5-Coder-14B advanced settings in LM Studio. Left (analytical): Temp 0.2-0.35 (env 0.3 good), TopP 0.85, TopK 30, Repeat 1.1, Context 16-32k, full GPU offload, fixed seed. Right (creative): Temp 0.75-0.9 + Mirostat Mode 2 Tau 5 (key), TopP 0.93, TopK 50, MinP 0.08, Repeat 1.15, Context 8-16k. Both on 24GB AMD card - monitor VRAM. Env already has good side temp/max overrides. Update as sides test and report. Cloud Grok CLIs on sides notified via logs.

* [2026-06-04] Sides tweaking Qwen2.5-Coder-14B advanced settings in LM Studio. Left (analytical): Temp 0.2-0.35 (env 0.3 good), TopP 0.85, TopK 30, Repeat 1.1, Context 16-32k, full GPU offload, fixed seed. Right (creative): Temp 0.75-0.9 + Mirostat Mode 2 Tau 5 (key), TopP 0.93, TopK 50, MinP 0.08, Repeat 1.15, Context 8-16k. Both on 24GB AMD card - monitor VRAM. Env already has good side temp/max overrides. Update as sides test and report. Cloud Grok CLIs on sides notified via logs.

* [2026-06-04] Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions.

- [2026-06-04] Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions.
- [2026-06-04] Hardening log still has AppArmor as pending. Trinity Habit Observer and related tools should remain log-only (no enforcement) and respect hardening priorities. Note in Center-Operator-Cheat-Sheet.md.
- [2026-06-04] Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions.
- [2026-06-04] Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions.
- [2026-06-04] Right-Brain 'Check for updates from Center: Ask' processed: cross-convo 0929 reviewed (observer polish), mood roundtrip tested, observer self-reports + fix + restart wired per soft pick. Maps (PC-Stuff tree) updated. Self-training now has closed low-noise feedback loop. Observer at nice -n15 ionice -c3 persistent. Internal only, Center white protected.
