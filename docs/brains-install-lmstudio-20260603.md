# LM Studio install (AUR) — 2026-06-03

## Status

| Step | State |
|------|--------|
| `paru -S lm-studio-bin` (build) | ✅ Done — package in cache |
| `sudo pacman -U` (install) | ⏳ **Needs your password** (non-interactive Grok session cannot sudo) |

Built package:

```
/home/matt/.cache/paru/clone/lm-studio-bin/lm-studio-bin-0.4.15-2-x86_64.pkg.tar.zst
```

## One command (run in your terminal)

```bash
/data/PCaC-Playgrounds/scripts/install-lm-studio-bin.sh
```

Or:

```bash
sudo pacman -U --needed /home/matt/.cache/paru/clone/lm-studio-bin/lm-studio-bin-0.4.15-2-x86_64.pkg.tar.zst
```

## After install

```bash
command -v lm-studio    # /usr/bin/lm-studio
lm-studio               # GUI — set download folder to /data/AI/models
# Developer → Local Server → Start → http://127.0.0.1:1234
curl -s http://127.0.0.1:1234/v1/models | head
```

## Desktop shortcut

Old shortcut pointed at missing AppImage. Template in repo:

```bash
cp /data/PCaC-Playgrounds/scripts/lm-studio.desktop ~/.local/share/applications/lm-studio.desktop
```

## Data paths (unchanged from Phase 1a)

- `~/.lmstudio` → `/data/AI/lmstudio`
- Models → `/data/AI/models`

## Next

Say **go 1c** after LM Studio runs and local server responds on :1234.