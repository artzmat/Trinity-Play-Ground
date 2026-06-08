# Phase 1b — Persona scaffold in repo ✅

**Date:** 2026-06-03  
**Approved by:** user (`go 1b`)

## Added to git

```
personas/
├── README.md
├── left-brain/
│   ├── SYSTEM.md
│   └── MEMORY.md
├── right-brain/
│   ├── SYSTEM.md
│   └── MEMORY.md
└── center/
    └── MEMORY.md
```

## Not in this phase

- LM Studio install or model download
- `pcac_ask_left` / `pcac_ask_right` scripts
- `shared/bus/messages.jsonl` (Phase 2)

## Next

| Step | User command |
|------|----------------|
| Install LM Studio | `go install lm-studio` or place AppImage |
| Download model | `go 1c` |
| Wire local asks + bus | `go 2` |