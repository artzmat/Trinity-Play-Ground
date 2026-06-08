# Phase 1a — LM Studio storage on `/data/AI` ✅

**Date:** 2026-06-03  
**Approved by:** user (`go 1a`)  
**Executed by:** Center

## What we did

| Action | Path | Reversible? |
|--------|------|-------------|
| Created models dir | `/data/AI/models/` | Delete dir if empty |
| Created app state dir | `/data/AI/lmstudio/` | Keep or archive |
| Created AppImage slot | `/data/AI/lm-studio/` | Keep |
| Symlink app home | `~/.lmstudio` → `/data/AI/lmstudio` | `rm ~/.lmstudio` (symlink only) |
| Symlink models inside home | `/data/AI/lmstudio/models` → `/data/AI/models` | `rm /data/AI/lmstudio/models` |

## Layout after 1a

```
/data/AI/
├── models/              # GGUF downloads (canonical)
├── lmstudio/            # LM Studio app state (~/.lmstudio)
│   └── models -> ../models
├── lm-studio/           # LM_Studio.AppImage + README
└── searxng/             # (existing)
```

## LM Studio install status

- **Not currently installed** — no AppImage at `/data/AI/lm-studio/LM_Studio.AppImage`, no `lm-studio-bin` package.
- Desktop entry exists but **Exec path is broken** until AppImage is placed or package installed.
- Local server was **off** at Phase 0; still off until LM Studio is run.

## Next steps (need separate go-ahead)

| Step | Action |
|------|--------|
| **1a-fix** | User: download AppImage to `/data/AI/lm-studio/` or `yay -S lm-studio-bin` |
| **1b** | Commit `personas/left-brain/` + `right-brain/` in PCaC-Playgrounds |
| **1c** | Download Qwen2.5-14B-Instruct **Q4_K_M** into `/data/AI/models`, start server, smoke-test |

## Verify commands

```bash
ls -la ~/.lmstudio
readlink -f ~/.lmstudio
readlink -f ~/.lmstudio/models
ls -la /data/AI/
```