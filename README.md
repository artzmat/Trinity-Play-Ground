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
├── personas/                    # Left-Brain / Right-Brain / Center prompts + memory (git)
│   ├── left-brain/              # SYSTEM.md + MEMORY.md
│   ├── right-brain/
│   └── center/
├── scripts/
│   ├── left-playground.sh       # Target: left monitor (chill + suggestions + kiosk)
│   ├── center-playground.sh     # Grok Center / main orchestrator + control
│   ├── right-playground.sh      # Target: right monitor (media / games / files)
│   ├── suggestion_service.py    # Local-only web form for the shared suggestion board
│   └── lib/
│       └── common.sh            # Shared: logging, paths, monitor mapping, suggestions helpers
├── docs/                        # Setup notes (brains audit, phase logs)
├── secrets/                     # VM guest creds — vm-guest.txt is gitignored
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
- `--watch [USER]` (Left/Right): Opens the full side "persona screen" as a tmux split:
  - Top pane: live watch (health/logs for Left; git for Right)
  - Bottom pane: interactive chat box ("Left Grok" / "Right Grok" persona)
  - Type `grok: your question` in the chat to post a query to Center Orchestrator Grok.
  - Responses from Center are posted back to the log (user pastes or uses pcac_post_chat helper).
  - Optional USER label for remote users ("User cursor: USER").
  - Left/Right personas can physically view the Center monitor but have no control over it.
- Center convenience:
  - `--watch-left [USER]` / `--watch-right [USER]`: open the full side screens from orchestrator.
  - `--view-chats`: tail both Left and Right chats in Center (orchestrator view).
  - `center-composer` (or `pcac_open_center_composer`): dedicated interactive chat box on center monitor for responses. Supports sending the same message or **/tailor** for different tailored messages to Left vs. Right in one session. Also **/ask-left /ask-right /ask-both** (and standalone `pcac-ask-both.sh`, `pcac-converse.sh`) to directly query/utilize the local LM Studio Left/Right brains from CENTER. **/power** shows CPU/GPU draw, profile, LM status to help optimize your 5950X + 7900XTX hardware. All centrally logged.
- `pcac_post_chat left/right "From" "message"` or `pcac_center_reply left|right "message"` (or `pcac_center_reply_both`) for Center.
- `pcac-grok-inbox` / `center-bus-watch.sh` — Center sees `grok:` queries on the bus.
- `pcac_view_all_chats` for Center overview.
- `pcac_list_monitors` + friendly side → output mapping using kscreen-doctor + xrandr.
- Everything logs + is reversible.

## Left-Brain / Right-Brain personas (prompt + memory, no fine-tuning)

Distinct personalities live under `personas/`:

- **Left-Brain** (`personas/left-brain/`) — analytical, structured, chill-layer support
- **Right-Brain** (`personas/right-brain/`) — creative, options-oriented, play/media
- **Center** (`personas/center/MEMORY.md`) — orchestrator notes in repo

Local LM Studio loads persona prompts on **`ask:`** in side chats (Phase 2). Use **`grok:`** for Center orchestrator. Machine-readable bus: `shared/bus/messages.jsonl` (dual-written with chat logs). See `docs/brains-phase2-20260603.md`.

See `docs/brains-audit-20260603.md` and `docs/brains-phase1a-20260603.md` for storage setup on `/data/AI`.

## Three-Persona "PC into Three" Setup (Left Grok / Right Grok / Center Orchestrator Grok)
The goal is to turn one physical PC + 3 monitors into three logical "computers"/personas:

- **Left screen (DP-3)**: Left Grok persona. Runs full tmux (via `--watch` or `--watch-left`):
  - Top: live health/logs watch.
  - Bottom: interactive chat box. Type messages or `grok: your question to Center`.
  - Can physically see Center monitor but has no control.
- **Right screen (DP-2)**: Right Grok persona. Same structure (git watch + chat).
- **Center screen (HDMI-A-1)**: Orchestrator Grok (you, running this Grok CLI).
  - Use `grok-center` or `./scripts/center-playground.sh --view-chats` to open a *minimized/small* Center terminal (small 960x600 konsole window centered on the center monitor + tmux split view) to see **both** Left and Right chats live in one window. (This keeps the physical center monitor mostly usable.)
  - Similarly, `grok-left` and `grok-right` now open small/minimized 960x600 windows on their monitors (Left/Right physical monitors remain mostly usable).
  - Respond by posting e.g. `pcac_post_chat left "Center Grok (to Left)" "My response..."` or manually to the .log files.
  - Controls everything: launchers, kiosk, services, etc.
  - Left/Right "use Grok" by posting `grok:` queries in their chat; you (Center) reply into their log.
  - `grok-center` gives you the "Center terminal to see both".

**How to "chat as Left/Right"**:
- On the side screen: run the chat (or use the bottom pane).
- Type normal messages (they appear in log for Center to see).
- On side: `grok: tell me a chill suggestion for Right` — query to the local Left/Right brain (LM Studio Qwen as the side "Grok").
- On side: `center: what should I prioritize today?` — query to Center Orchestrator Grok (main grok cli) — appears as grok_query on bus.
- `ask: ...` still works for local brain.
- From Center composer: use /ask-left /ask-right /ask-both to directly utilize Left-Right-LMStudio brains from CENTER.
- Center sees the center: queries (via bus watch or tail), thinks, posts response back as "Center Grok (to Left): ...".
- The side sees the response in their chat pane.

**Remote users / cursors**: Pass `[USER]` e.g. `--watch-left alice` — appears as "User cursor: alice" everywhere + in titles.

**Launching the full experience** (from Center):
```bash
./scripts/center-playground.sh --watch-left matt
./scripts/center-playground.sh --watch-right remoteuser
./scripts/center-playground.sh --view-chats   # keep this running or in another pane
# Also launch other things: --start-suggestions, kiosk flows (which now auto-open watch+chat on Left)
```

The chat logs live in `shared/left-chat.log` and `right-chat.log` (gitignored, under /data).

This keeps everything local, reversible, and under /data. The "three PCs" are monitor + persona + dedicated tools (kiosk on Left, games/media on Right, orchestrator on Center).

**Quick fire-up**: Just type `playground` (or `grok-center playground`) in your Center terminal / Center Grok. It fires up the Left, Right, and Center terminals with watch windows:
- Left monitor (DP-3): *small/minimized* konsole (960x600 centered, not full screen) + tmux (watch top + Left Grok chat box bottom) — "Left Grok" persona
- Right monitor (DP-2): *small/minimized* konsole (960x600 centered, not full screen) + tmux (watch top + Right Grok chat box bottom) — "Right Grok" persona
- Center monitor (HDMI-A-1): *small/minimized* konsole window (960x600 centered, not full screen) + tmux split to see both chats live + status (with "pc pin 1566894405" marker)

Supports optional label: `playground alice` or `grok-center playground bob` sets "User cursor: ..." in titles/headers/logs (for remote users / LAN-party future).

See the launchers' --help for full options. Use `pcac_post_chat` etc from common.sh when in Center.

## Usage Examples
```bash
# From Center (Grok CLI / orchestrator terminal) - the "three PC" hub
./scripts/center-playground.sh --start-suggestions
./scripts/center-playground.sh --view-suggestions
./scripts/center-playground.sh --watch-left          # full Left screen: watch + Left Grok chat box
./scripts/center-playground.sh --watch-right remote1 # full Right screen: watch + Right Grok chat box (remote label)
./scripts/center-playground.sh --view-chats          # open Center terminal (tmux split) to see both Left and Right

# Convenient global commands (added to ~/.local/bin/, available anywhere in fish)
grok-left          # start/attach Left Grok persona (*small/minimized* 960x600 window: watch top + chat bottom on Left monitor)
grok-right         # start/attach Right Grok persona (*small/minimized* 960x600 window: watch top + chat bottom on Right monitor) -- set up like left
grok-center        # open *minimized/small* Center terminal (tmux split view, small window on center monitor) to see **both** Left and Right
grok-left          # open *minimized/small* Left terminal (watch+chat)
grok-right         # open *minimized/small* Right terminal (watch+chat)
center-composer    # (in center) interactive reply box — now with /ask-left /ask-right /ask-both to utilize Left-Right-LMStudio from CENTER + /power for hardware optimization (5950X+7900XTX)
pcac-ask-both.sh   # ask both local brains (prints their answers for Center to use)
pcac-converse.sh   # start a conversation between Left-Brain and Right-Brain (Center logs it)
pcac-power-status  # live CPU/GPU power, profile, LM status, load (leverage your hardware efficiently)
grok-center playground [label]  # or just `playground [label]` — fire ALL THREE watch terminals at once from Center Grok
grok-left alice    # with "User cursor: alice" label for remote users

# One-command to fire up all three with watch windows (as requested)
playground         # entering "playground" in center grok fires Left + Right + Center terminals with watch windows (all three are small/minimized 960x600 windows)
playground alice   # with user cursor label

# In Left chat box (bottom pane of grok-left or --watch-left): type
#   grok: what do you think about cozy games for the Right side?
# Center Grok (you here) responds by posting to the log (or using pcac_post_chat)

# From Left side (once you switch to that monitor or via delegation)
./scripts/left-playground.sh --start-suggestions
./scripts/left-playground.sh --kiosk          # shows the browser command (now also opens watch+chat)
./scripts/left-playground.sh --watch          # opens/reopens full Left tmux (watch top + chat bottom)

# From Right
./scripts/right-playground.sh --view-suggestions
./scripts/right-playground.sh --open-shared
./scripts/right-playground.sh --watch matt    # with user cursor label

# In any chat: 'grok: ...' posts query; Center responds by appending "Center Grok (to Left): ..."
# Left/Right see Center monitor physically but can't control it.

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
