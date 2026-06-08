# Left/Right Brain Setup — Phase 0 Audit

**Date:** 2026-06-03  
**Auditor:** Center (read-only, no config changes)  
**Repo:** `/data/PCaC-Playgrounds`

---

## Executive summary

| Area | Status |
|------|--------|
| `/data` mount | OK — 3.6T, 35% used, 2.3T free |
| PCaC tmux personas | OK — `pcac-left`, `pcac-right` attached |
| Chat bus (logs) | OK — `shared/left-chat.log`, `right-chat.log` present |
| LM Studio API | **OFF** — nothing listening on `127.0.0.1:1234` |
| LM Studio data dir | **Not set up** — `~/.lmstudio` missing; `/data/AI` has no `models/` yet |
| LM Studio CLI | OK — `grok 0.2.20` at `~/.grok/bin/grok` |
| GPU | RX 7900 XTX class (Navi 31); `rocm-smi` not in PATH |

**Next safe work:** consolidate LM Studio under `/data/AI`, then scaffold `personas/` + `shared/bus/messages.jsonl` (no model download until user confirms).

---

## Storage (`/data`)

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme1n1p1  3.6T  1.2T  2.3T  35% /data
```

### `/data/AI`

```
/data/AI/
└── searxng/    # only child today; no models/ or lmstudio/ yet
```

**Note:** PC-Stuff snapshot references models on `/data/AI`; directory layout not yet created for LM Studio/GGUF.

---

## LM Studio

| Check | Result |
|-------|--------|
| `curl http://127.0.0.1:1234/v1/models` | Connection refused (server not running) |
| `~/.lmstudio` | Does not exist |
| `~/.local/share/LM*` / `~/.config/LM*` | Not found |
| `lmstudio` / `lms` in PATH | Not found |
| Running process | No LM Studio process detected at audit time |

**Implication:** LM Studio may be installed elsewhere (AppImage, manual path) or only used intermittently. Phase 1 should confirm install location, then symlink data → `/data/AI/lmstudio` and downloads → `/data/AI/models` **before** large downloads.

---

## GPU

```
09:00.0 VGA compatible controller: AMD/ATI Navi 31 [Radeon RX 7900 XT/XTX/GRE/7900M]
```

- Documented stack: Vulkan (per PC-Stuff snapshot).
- `rocm-smi` not available in default PATH during audit.

---

## PCaC three-monitor / tmux

### Active tmux sessions

```
pcac-left:  1 windows (created Wed Jun  3 09:24:27 2026) (attached)
pcac-right: 1 windows (created Wed Jun  3 09:43:02 2026) (attached)
```

### Chat logs (last lines)

**left-chat.log:**
```
[09:22:31] Left Grok (demo): center: hello center, any chill suggestions for the right side today?
[09:30:39] Left Grok (testuser): Hello, what is right up to?
```

**right-chat.log:**
```
[09:22:31] Right Grok (demo): center: what game should I suggest from the library?
[10:43:05] Right Grok (matt): Hello
```

### Launchers present

- `grok-left`, `grok-right`, `grok-center` → `scripts/*-playground.sh`, `*-tmux.sh`, `*-chat.sh`
- Monitor map: DP-3 (left), HDMI-A-1 (center), DP-2 (right) — `scripts/lib/common.sh`

### Gitignore note

`shared/` is gitignored (includes chat logs). Plan: commit `personas/` and `shared/bus/.gitkeep` + schema; keep `messages.jsonl` runtime-only inside gitignored `shared/` or document pattern.

---

## LM Studio CLI (Center)

- Version: `grok 0.2.20 (77224a6aa) [stable]`
- Config: `~/.grok/config.toml` minimal (`[cli] installer = "internal"` only)
- No LM Studio model entries configured yet

---

## Refined plan (incorporates user feedback)

### Models

- **Start:** Qwen2.5-14B-Instruct **Q4_K_M** (not Q5 — safer headroom for context on 24GB).
- **One model, two personas** via `personas/left-brain/SYSTEM.md` and `right-brain/SYSTEM.md`.
- **After 1–2 weeks:** if Right feels too samey, add Gemma-2-9B or Llama-3.1-8B Q4 for Right only (second port or swap-load).

### Communication

- Keep human-readable `left-chat.log` / `right-chat.log`.
- **Phase 2:** add `shared/bus/messages.jsonl` (simple JSONL: `ts`, `from`, `to`, `text`, `kind`) for Center parsing; chat scripts dual-write.

### LM Studio on `/data`

- Early Phase 1 step (after go-ahead):
  - `/data/AI/models/` — GGUF downloads
  - `/data/AI/lmstudio/` — app state
  - Symlink `~/.lmstudio` → `/data/AI/lmstudio` (reversible)

### Phases (unchanged)

| Phase | Action |
|-------|--------|
| 0 | This audit ✅ |
| 1 | LM Studio paths + `personas/` scaffold + download Qwen2.5-14B Q4 |
| 2 | `pcac_ask_left/right` + `messages.jsonl` bus |
| 3 | Optional second model; eye tracking later |

---

## Recommended user confirmation before Phase 1

1. Confirm LM Studio install path (or reinstall if needed).
2. Approve symlink: `~/.lmstudio` → `/data/AI/lmstudio`.
3. Approve download: **Qwen2.5-14B-Instruct Q4_K_M** (~8–9 GB).
4. Approve git commit: `personas/`, `docs/`, bus schema in repo.

---

*End of Phase 0 audit.*