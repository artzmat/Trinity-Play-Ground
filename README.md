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

## 3-Monitor Mapping (your actual hardware)
- **Left monitor (DP-3)**   → Left Playground: Internet / Suggestions / Chill layer (PCaC)
- **Center monitor (HDMI-A-1)** → Center / Grok CLI: Orchestrator / brain (this is where you run Grok + these scripts)
- **Right monitor (DP-2)**  → Right Playground: Media, Games, Files / high-engagement

(Defined in `scripts/lib/common.sh` — override with `PCAC_LEFT_MONITOR=...` etc. if your outputs change.)

## Directory Layout (in this repo)
```
PCaC-Playgrounds/
├── README.md
├── .gitignore
├── scripts/
│   ├── left-playground.sh       # Target: left monitor (chill + suggestions + kiosk)
│   ├── center-playground.sh     # Grok Center / main orchestrator + control
│   ├── right-playground.sh      # Target: right monitor (media / games / files)
│   ├── suggestion_service.py    # Local-only web form for the shared suggestion board
│   └── lib/
│       └── common.sh            # Shared: logging, paths, monitor mapping, suggestions helpers
├── shared/                      # Runtime shared data (gitignored)
│   └── suggestions/
│       └── suggestions.txt      # Written by Left, readable by Center + Right
└── (future: profiles/, vms/, etc.)
```

Runtime logs → `/data/var/log/pcac`

Shared playground data (suggestions etc.) → `shared/` (inside repo for convenience, gitignored).

## Current Features (beyond placeholders)
- `--start-suggestions` (Left/Center): Starts the pure-Python local web suggestion board (localhost only).
- `--view-suggestions` (all sides): Shows the shared board.
- `--kiosk` (Left): Prints ready-to-use locked-down Firefox/Chromium kiosk commands targeting the left monitor.
- `--open-shared` (Right): Opens the suggestions folder in a file manager.
- `pcac_list_monitors` + friendly side → output mapping using kscreen-doctor + xrandr.
- Everything logs + is reversible.

## Usage Examples
```bash
# From Center (Grok CLI / orchestrator terminal)
./scripts/center-playground.sh --start-suggestions
./scripts/center-playground.sh --view-suggestions

# From Left side (once you switch to that monitor or via delegation)
./scripts/left-playground.sh --start-suggestions
./scripts/left-playground.sh --kiosk          # shows the browser command for left monitor

# From Right
./scripts/right-playground.sh --view-suggestions
./scripts/right-playground.sh --open-shared

# Inspect monitors + mapping
./scripts/left-playground.sh --detect
./scripts/center-playground.sh --detect
```

Visit the suggestion board (after starting the service):
http://127.0.0.1:8765   (default port)

## Philosophy & Incremental Development
We start **simple and local**:

**Left Playground (Internet / Suggestions / Chill)**
- Local-only suggestion board (web form → shared file)
- Locked-down browser kiosk (Firefox/Chromium --kiosk, restricted profile, no downloads)
- Read-only access to the shared “Suggestions” folder from Right
- Basic logging of suggestions (reviewable from Center)

**Right Playground (Spotify / Games / Files / Media)**
- Full-screen gaming (Steam / individual titles)
- Spotify / music player full-screen
- File browser with easy access to shared suggestions from Left
- Media player (mpv)
- Easy way to “accept” a suggestion (future one-click launch game/playlist)

**Center (Grok Center)**
- The conductor. You run these launcher scripts here.
- Can start/stop/view things on Left and Right.
- Grok lives here and helps evolve the scripts.

Future shared:
- Controlled networking per side
- Snapshot/restore
- Deeper KWin / kscreen-doctor integration for true full-screen on specific outputs
- VMs from the data-vms pool positioned on specific monitors

## Contributing / Expanding (with Grok)
Paste prompts like these directly to the Grok CLI TUI on the Center monitor:

“Write the content for scripts/left-playground.sh that eventually launches a locked-down browser kiosk on the left monitor. Start with a safe placeholder and comments.”

“Create a simple local web suggestion form (Python + HTML) that writes to /data/PCaC-Playgrounds/shared/suggestions.txt and can be viewed from the Right side.”

“Improve scripts/right-playground.sh so it can launch a full-screen Steam session or specific game on the right monitor using the data-vms pool.”

“Show me how to use kscreen-doctor to get monitor names and geometry so I can launch things full-screen on specific monitors.”

Grok will edit the scripts in place, keep the `/data` discipline, update docs, and test.

## Current Status
v0.002 — First real shared feature: the local suggestion board + monitor-aware launchers + kiosk stubs + improved common library.

Next steps we can do right now (tell me which):
- Make the kiosk actually launch (with better targeting)
- Add a "launch Steam" stub on Right
- Add virsh / data-vms VM launching helpers
- Better window positioning via kscreen-doctor + KWin scripting
- Persistent service management (systemd user units or simple pid files)

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
