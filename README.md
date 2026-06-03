# PCaC v0.001 — Left / Center / Right Playgrounds + controlled chill layer

**PCaC** = Personal Computing and Chill (or "Playgrounds and Controlled Chill").

## Core Rules
- **Everything lives on /data** (the 4 TB drive).
  - VMs, containers, media, games, logs, state, downloads, projects.
- **1 TB root drive stays clean** — only the minimal OS + personal dotfiles + this control repo.
- Separation of concerns across physical (or virtual) monitors:
  - **Left**: locked-down internet, suggestions, chill / low-stimulation layer.
  - **Center**: the Grok Center — main control surface, orchestrator, primary Grok/suggestion interface, "brain".
  - **Right**: media, games, files, high-engagement / play layer.

## Directory Layout (in this repo)
```
PCaC-Playgrounds/
├── README.md
├── .gitignore
├── scripts/
│   ├── left-playground.sh     # Target: left monitor (chill + suggestions)
│   ├── center-playground.sh   # Grok Center / main orchestrator + control
│   ├── right-playground.sh    # Target: right monitor (media + games + files)
│   └── lib/
│       └── common.sh          # Shared: logging, PCAC_* paths, output detection, traps
└── (future: config/, profiles/, state/, etc.)
```

Runtime logs and heavy state go to `/data/var/log/pcac` (and siblings) — gitignored.

## Usage (current placeholders)
```bash
# From anywhere (they resolve their own root)
./scripts/left-playground.sh --help
./scripts/left-playground.sh --detect     # see monitors + env
./scripts/center-playground.sh --launch-left --launch-right

# Or run directly for the banner + plan
./scripts/center-playground.sh
```

All three scripts currently:
- Are safe no-op placeholders.
- Support `--help`, `--detect`, `--dry-run`.
- Log to both stderr and `$PCAC_LOG_DIR/pcac.log`.
- Detect available display tools (wlr-randr / xrandr).
- Print expansion hints for future real implementations.

## Philosophy & Future Direction
- **Left** becomes a calm, curated internet + LLM-powered suggestion surface. Think "kiosk that only shows good stuff" + Grok context.
- **Right** is the fun/play zone: games (with controllers), Spotify + visualizers, local media, file browsing for active creative work.
- **Center (Grok Center)** is the conductor:
  - You talk to Grok here.
  - It decides or helps route things to Left vs Right.
  - It can launch / focus / tear down sessions on the side monitors.
  - Maintains allow-lists, profiles, "today's chill mode", etc.
- Long term: these scripts will know how to target specific outputs, move windows, start isolated sessions (bwrap, distrobox, libvirt, etc.), and integrate deeply with the window manager / compositor.

## Contributing / Expanding (with Grok)
When you want to evolve one side, tell Grok:
- "Expand the left playground to launch a restricted Firefox kiosk on output DP-1"
- "Make center able to launch left+right together and show their status"
- "Add a simple TUI to center-playground.sh using gum or dialog"

Grok will edit the scripts, add to common.sh, update docs, and keep the `/data`-only discipline.

## Current Status
v0.001 — just the three hardened placeholder launchers + shared lib + this README.

Next milestones (tracked by actually editing the scripts):
- Real monitor targeting + window management helpers
- First useful left-side thing (e.g. a local suggestions dashboard)
- First right-side thing (e.g. a game or media launcher)
- Center becoming actually useful as a control plane
