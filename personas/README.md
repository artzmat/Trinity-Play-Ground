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
└── center/         # HDMI-A-1 — orchestrator notes (optional)
    └── MEMORY.md
```

## How these files are used (planned)

| Phase | Usage |
|-------|--------|
| **1b** (now) | Versioned prompts + memory templates in git |
| **2** | `pcac_ask_left` / `pcac_ask_right` prepend SYSTEM + MEMORY to LM Studio calls |
| **Chat** | `grok:` → Center (cloud Grok); `ask:` → local brain (when wired) |

## Editing memory

- Add short, factual bullets to `MEMORY.md` (preferences, constraints, running jokes).
- Center may copy summaries into side memory after orchestration sessions.
- Do not store secrets (passwords, API keys) here.

## Monitors

See `scripts/lib/common.sh`: Left = DP-3, Center = HDMI-A-1, Right = DP-2.