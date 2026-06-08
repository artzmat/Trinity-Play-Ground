# Center — orchestrator memory (optional)

**Center** runs on the center monitor (HDMI-A-1) and is powered by **Command-R** (`cohereforai.c4ai-command-r-08-2024`) in LM Studio, slot :3. This file is for **cross-side notes** you want in git (not a replacement for the LM Studio context).

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

## Local-first migration (2026-06-07)

- 2026-06-07: Center migrated from Cloud Grok → local **Command-R** (`cohereforai.c4ai-command-r-08-2024`) in LM Studio, slot :3. Cloud Grok removed from the active surface; no fallback configured.
- 2026-06-07: Tool Agent role **absorbed** into Center. The fourth voice (Command-R on slot :3 for Cline/tool work) is now just Center. `personas/tool-agent/` moved to `personas/.deprecated/tool-agent/` for history. `scripts/tool-c.fish` renamed/repurposed to `scripts/center-c.fish` and now points to Center's inbox.
- 2026-06-07: Center LM Studio settings (slot :3) — Context **4096**, Temperature **0.35**, Top-P 0.9, Max Tokens 2048, full GPU offload, Flash Attention on, function calling enabled. These are the values that resolve the prior 400 error. Increase ctx later only if stable.
- 2026-06-07: New `personas/center/TNMP-Cline-Rules.md` is the Cline-tailored rules file for Center-on-Command-R. It inherits the Dispatch / Synthesis / Next Move format from `SYSTEM.md`, adds Cline terminators (`TASK COMPLETE` / `NEEDS INPUT` / `TOOL RESULT`), and documents the 400-error recovery procedure.
- 2026-06-07: Trinity is now **three voices**: Left (Qwen :1), Right (Qwen :2), Center (Command-R :3). VRAM budget on a 24 GB card: Qwen :1 + :2 OR Command-R :3 comfortably; not all three at once.
