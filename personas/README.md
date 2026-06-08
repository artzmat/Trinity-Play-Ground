# PCaC personas — Left-Brain / Right-Brain / Center

Persistent **personalities** for the three-monitor setup. No fine-tuning: behavior comes from `SYSTEM.md` + append-only `MEMORY.md`.

## Layout

```
personas/
├── left-brain/     # DP-3 — analytical, structured, task-oriented
│   ├── SYSTEM.md
│   └── MEMORY.md
├── right-brain/    # DP-2 — creative, exploratory, play-oriented
│   ├── SYSTEM.md
│   └── MEMORY.md
├── center/         # HDMI-A-1 — orchestrator (Command-R on LM Studio slot :3)
│   ├── SYSTEM.md            # persona system prompt (loaded by LM Studio)
│   ├── MEMORY.md            # append-only facts / decisions log
│   └── TNMP-Cline-Rules.md  # Cline-tailored rules (loaded by Cline/Code-OSS)
└── .deprecated/    # historical personas kept for reference
    ├── README.md
    └── tool-agent/         # 2026-06-07: absorbed into Center
```

## How these files are used

| Phase | Usage |
|-------|--------|
| **1b** (now) | Versioned prompts + memory templates in git |
| **2** | `pcac_ask_left` / `pcac_ask_right` prepend SYSTEM + MEMORY to LM Studio calls |
| **Chat (cloud)** | (Deprecated) `grok:` → Center; fully replaced by local Command-R on 2026-06-07 |
| **Chat (local)** | `ask:` → local brain (when wired); Center = local Command-R, slot :3 |
| **Cline** | `center-c "<directive>"` writes to `~/.tnmp/inboxes/center.md`; Cline reads and routes to Command-R (slot :3) with `TNMP-Cline-Rules.md` loaded |

## Center = Command-R (2026-06-07)

Center moved from **Cloud APIs** to **local Command-R**
(`cohereforai.c4ai-command-r-08-2024`) on LM Studio slot :3. This is the
**fully local** orchestrator — no cloud fallback. The previous Tool Agent (formerly)
role (also Command-R, also slot :3) is absorbed into Center, so the
fourth voice is gone. See `personas/center/SYSTEM.md`,
`personas/center/TNMP-Cline-Rules.md`, and the 2026-06-07 entry in
`personas/center/MEMORY.md` for the migration details.

## Editing memory

- **Append-only:** add bullets; do not rewrite history in `MEMORY.md`.
- Add short, factual lines (preferences, system state, creative threads).
- Center may copy summaries into side memory after orchestration sessions.
- Both sides: **propose only** — Center approves system-level changes.
- Do not store secrets (passwords, API keys) here.

## Monitors

See `scripts/lib/common.sh`: Left = DP-3, Center = HDMI-A-1, Right = DP-2.
