# PCaC v0.001 — Left / Center / Right Playgrounds + controlled chill layer

**PCaC** = Personal Computing and Chill (or "Playgrounds and Controlled Chill").

## Core Rules
- **Everything lives on /data** (the 4 TB drive).
  - VMs, containers, media, games, logs, state, downloads, projects.
- **1 TB root drive stays clean** — only the minimal OS + personal dotfiles + this control repo.
- Separation of concerns across physical (or virtual) monitors (user clarification: "Center is mine. It is white."):
  - **Left (DP-3)**: locked-down internet, suggestions, chill / analytical / low-stimulation layer.
  - **Center (HDMI-A-1)**: user's primary personal workspace — clean/white themed HQ. The Center (orchestrator / main control surface / brain) runs here, but the physical monitor stays mostly the user's clean personal desktop (small minimized windows help).
  - **Right (DP-2)**: media, games, files, high-engagement / colorful immersive play layer.

## 3-Monitor Mapping (your actual hardware)
- **Left monitor (DP-3)**   → Left Playground: chill / analytical / low-stimulation / suggestions / locked-down internet (PCaC)
- **Center monitor (HDMI-A-1)** → Center: user's primary personal workspace (clean/white themed HQ). Orchestrator / LM Studio CLI / brain runs here in small/minimized windows so the physical monitor remains usable for personal desktop use.
- **Right monitor (DP-2)**  → Right Playground: Media, Games, Files / high-engagement / colorful immersive play zone

User note: "Center is mine. It is white."

(Defined in `scripts/lib/common.sh` — override with `PCAC_LEFT_MONITOR=...` etc. if your outputs change.)

## Directory Layout (in this repo)
```
PCaC-Playgrounds/
├── README.md
├── .gitignore
├── personas/                    # Left-Brain / Right-Brain / Center prompts + memory (git)
│   ├── left-brain/              # SYSTEM.md + MEMORY.md
│   ├── right-brain/
│   ├── center/                  # SYSTEM.md + MEMORY.md + TNMP-Cline-Rules.md
│   │                            # (Center = local Command-R on LM Studio slot :3;
│   │                            #  tool-calling + coding agent role absorbed 2026-06-07)
│   └── .deprecated/             # Historical personas preserved for reference
│       └── tool-agent/          # Absorbed into Center on 2026-06-07
├── scripts/
│   ├── left-playground.sh       # Target: left monitor (chill + suggestions + kiosk)
│   ├── center-playground.sh     # Center / main orchestrator + control
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
- `--usual` (Left): One-command setup for the typical left screen apps — OpenRGB (lighting) + Firefox kiosk to the local suggestion board (the "I usually open OpenRGB and Firefox on this screen" flow). Starts suggestion service too. Safe/idempotent.
- `--open-shared` (Right): Opens the suggestions folder in a file manager.
- `--watch [USER]` (Left/Right): Opens the full side "persona screen" as a tmux split:
  - Top pane: live watch (health/logs for Left; git for Right)
  - Bottom pane: interactive chat box ("Left Grok" / "Right Grok" persona)
  - Type `center: your question` in the chat to post a query to Center.
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

## Personas (prompt + memory, no fine-tuning) — Left / Right / Center

Distinct personalities live under `personas/`:

- **Left-Brain** (`personas/left-brain/`) — analytical, structured, chill-layer support
- **Right-Brain** (`personas/right-brain/`) — creative, options-oriented, play/media
- **Center** (`personas/center/`) — orchestrator **and** tool caller, running on
  **Command-R** in LM Studio slot `:3`, surfaced through **code-oss + Cline**
  via the `center-c` fish bridge. Use for cross-cutting dispatch, synthesis,
  and any multi-step work that needs tools: code edits, refactors, file
  analysis, agent loops. See `docs/center-command-r-20260607.md`.

> **Trinity is now three voices.** The previous separate "Tool Agent (formerly)"
> persona (also Command-R, also slot `:3`) is **absorbed into Center** as
> of 2026-06-07 — see `personas/center/MEMORY.md` and
> `personas/.deprecated/tool-agent/`. The Trinity is fully local: Left/Right
> run on Qwen 2.5-Coder-14B (slots `:1`/`:2`), Center runs on Command-R
> (slot `:3`). Cloud APIs is no longer the Center orchestrator.

Local LM Studio loads persona prompts on **`ask:`** or **`grok:`** in side chats (the side "Grok" is now the local Qwen via LMStudio). Use **`center:`** (or `grok:` from Center) for the main Center orchestrator. Machine-readable bus: `shared/bus/messages.jsonl` (dual-written with chat logs). See `docs/brains-phase2-20260603.md`.

See `docs/brains-audit-20260603.md` and `docs/brains-phase1a-20260603.md` for storage setup on `/data/AI`.

### Routing work to the right voice

| Task shape | Voice | How |
|---|---|---|
| Quick Q&A, planning, structure, chill | **Left-Brain** | `ask: ...` from Left, or local Qwen on slot `:1` |
| Creative options, naming, vibe, play | **Right-Brain** | `ask: ...` from Right, or local Qwen on slot `:2` |
| Cross-cutting decisions, dispatch, AND multi-step tool work | **Center** | `center-c "..."` (local Command-R on slot `:3`) |

**Install `center-c`:**
```bash
cp scripts/center-c.fish ~/.config/fish/functions/center-c.fish
chmod +x ~/.config/fish/functions/center-c.fish
```

**Use it:**
```bash
center-c "Analyze the Bottum genealogy PDF and extract Revolutionary War service records. Output as structured markdown."
center-c --help
center-c --inbox --tail
```

The directive is written to `~/.tnmp/inboxes/center.md` and opened in
`code-oss` so Cline (Command-R on slot :3) can execute it with tool calls.
Full setup + usage: `docs/center-command-r-20260607.md`.

## Three-Persona "PC into Three" Setup (Left / Right / Center)
The goal is to turn one physical PC + 3 monitors into three logical "computers"/personas. The Trinity is **fully local** as of 2026-06-07:

- **Left + Right** (slots `:1` / `:2` in LM Studio): Qwen 2.5-Coder-14B Q4_K_M, surfaced through fish-launcher tmux panes (`grok-left`, `grok-right`).
- **Center** (slot `:3` in LM Studio): **Command-R** (orchestrator + tool caller), surfaced through the `center-c` fish bridge into code-oss + Cline. **No cloud API for Center anymore.**

Cloud APIs is no longer in the active loop for any voice. If a previous session left a cloud `grok-center` / `grok-left` / `grok-right` shell alias behind, it will still work but will route to a deprecated path — prefer the local flow.

- **Left screen (DP-3)**: Left-Brain persona (local Qwen with Left-Brain SYSTEM.md + MEMORY.md baked in). Runs in tmux (via `grok-left`):
  - Top: live health/logs watch.
  - Bottom: interactive chat box. Type messages or `center: your question` (to local Qwen via LM Studio) or `center: your question for Center`.
  - Can physically see Center monitor but has no control.
- **Right screen (DP-2)**: Right-Brain persona. Same structure (git watch + chat). Colorful immersive play zone.
- **Center screen (HDMI-A-1)**: User's primary personal workspace (clean/white themed HQ). Center (Command-R) lives here in code-oss + Cline, opened by `center-c "..."`.
  - Use `./scripts/center-playground.sh --view-chats` to open a *minimized/small* Center terminal (small 960x600 konsole window centered on the center monitor + tmux split view) to see **both** Left and Right chats live in one window. (This keeps the physical center monitor mostly usable for the user's clean white personal desktop.)
  - Similarly, `grok-left` and `grok-right` open small/minimized 960x600 windows on their monitors.
  - Respond by posting e.g. `pcac_post_chat left "Center" "My response..."` or manually to the .log files.
  - Controls everything: launchers, kiosk, services, etc.
  - Left/Right can call Center with `center: ...` in their chat; Center replies into the side's log.
  - For multi-step tool work, Center uses `center-c "..."` (it writes to its own inbox and Cline executes).

**How the personas work now (fully local, three voices)**:
- On the side screen: the bottom pane is the **local Qwen** TUI running as that persona (Left-Brain or Right-Brain with SYSTEM + MEMORY injected at launch).
- The side persona can reason, remember (its own + the injected shared MD), and post to the shared bus for coordination.
- For coordination with Center or the other persona: the side persona is instructed to post to the shared bus. Center monitors the bus and can respond by posting to the side's log or using the composer.
- You (human at Center) can also directly use the Center Composer (`center-composer`) with /tailor to send different tailored messages to the two side personas' logs.
- The `ask:` / local LM Studio distinction is gone; the side personas run Qwen via LM Studio on slot `:1` / `:2` directly. Center runs Command-R on slot `:3` via the `center-c` bridge.

**Remote users / cursors**: Pass `[USER]` e.g. `grok-left alice` — appears in titles and can be used in prompts.

**Launching the full experience** (from Center):
```bash
./scripts/center-playground.sh --watch-left matt
./scripts/center-playground.sh --watch-right remoteuser
./scripts/center-playground.sh --view-chats   # keep this running or in another pane
# Also launch other things: --start-suggestions, kiosk flows (which now auto-open watch+chat on Left)
```

The chat logs live in `shared/left-chat.log` and `right-chat.log` (gitignored, under /data).

This keeps everything local, reversible, and under /data. The "three PCs" are monitor + persona + dedicated tools (kiosk on Left, games/media on Right, orchestrator on Center).

**Quick fire-up**: Just type `playground` (or `grok-center playground`) in your Center terminal / Center. It fires up the Left, Right, and Center terminals with watch windows:
- Left monitor (DP-3): *small/minimized* konsole (960x600 centered, not full screen) + tmux (watch top + Left chat box bottom) — "Left Grok" persona
- Right monitor (DP-2): *small/minimized* konsole (960x600 centered, not full screen) + tmux (watch top + Right chat box bottom) — "Right Grok" persona
- Center monitor (HDMI-A-1): *small/minimized* konsole window (960x600 centered, not full screen) + tmux split to see both chats live + status (with "pc pin 1566894405" marker)

Supports optional label: `playground alice` or `grok-center playground bob` sets "User cursor: ..." in titles/headers/logs (for remote users / LAN-party future).

See the launchers' --help for full options. Use `pcac_post_chat` etc from common.sh when in Center.

## Usage Examples
```bash
# From Center (LM Studio CLI / orchestrator terminal) - the "three PC" hub
./scripts/center-playground.sh --start-suggestions
./scripts/center-playground.sh --view-suggestions
./scripts/center-playground.sh --watch-left          # full Left screen: watch + Left chat box
./scripts/center-playground.sh --watch-right remote1 # full Right screen: watch + Right chat box (remote label)
./scripts/center-playground.sh --view-chats          # open Center terminal (tmux split) to see both Left and Right

# Convenient global commands (added to ~/.local/bin/, available anywhere in fish)
grok-left          # start/attach Left-Brain persona (*small/minimized* 960x600 window: watch top + chat bottom on Left monitor)
grok-right         # start/attach Right-Brain persona (*small/minimized* 960x600 window: watch top + chat bottom on Right monitor) -- set up like left
grok-center        # open *minimized/small* Center terminal (tmux split view, small window on center monitor) to see **both** Left and Right
grok-left          # open *minimized/small* Left terminal (watch+chat)
grok-right         # open *minimized/small* Right terminal (watch+chat)
center-composer    # (in center) interactive reply box — now with /ask-left /ask-right /ask-both to utilize Left-Right-LMStudio from CENTER + /power for hardware optimization (5950X+7900XTX)
pcac-ask-both.sh   # ask both local brains (prints their answers for Center to use)
pcac-converse.sh   # start a conversation between Left-Brain and Right-Brain (Center logs it)
pcac-power-status  # live CPU/GPU power, profile, LM status, load (leverage your hardware efficiently)
grok-center playground [label]  # or just `playground [label]` — fire ALL THREE watch terminals at once from Center
grok-left alice    # with "User cursor: alice" label for remote users

# One-command to fire up all three with watch windows (as requested)
playground         # entering "playground" in center grok fires Left + Right + Center terminals with watch windows (all three are small/minimized 960x600 windows)
playground alice   # with user cursor label

# In Left chat box (bottom pane of grok-left or --watch-left): type
#   center: what do you think about cozy games for the Right side?   (local side brain)
#   center: coordinate with the other side   (to main grok cli)
# Center (you here) responds by posting to the log (or using pcac_post_chat)

# From Left side (once you switch to that monitor or via delegation)
./scripts/left-playground.sh --start-suggestions
./scripts/left-playground.sh --kiosk          # shows the browser command (now also opens watch+chat)
./scripts/left-playground.sh --usual          # OpenRGB + Firefox (kiosk to suggestions) + service — usual apps on left/DP-3 chill screen
./scripts/left-playground.sh --watch          # opens/reopens full Left tmux (watch top + chat bottom)

# From Right
./scripts/right-playground.sh --view-suggestions
./scripts/right-playground.sh --open-shared
./scripts/right-playground.sh --watch matt    # with user cursor label

# In side chat: 'center: ... queries local side brain (LMStudio); 'center: ...' posts query to main Center cli; Center responds by appending "Center (to Left): ..."
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

**Center (Center)**
- The conductor. You run these launcher scripts here.
- Can start/stop/view things on Left and Right.
- 
Future shared:
- Controlled networking per side
- Snapshot/restore
- Deeper KWin / kscreen-doctor integration for true full-screen on specific outputs
- VMs from the data-vms pool positioned on specific monitors

## Contributing / Expanding (with Grok)
Paste prompts like these directly to the LM Studio CLI TUI on the Center monitor:

“Write the content for scripts/left-playground.sh that eventually launches a locked-down browser kiosk on the left monitor. Start with a safe placeholder and comments.”

“Create a simple local web suggestion form (Python + HTML) that writes to /data/PCaC-Playgrounds/shared/suggestions.txt and can be viewed from the Right side.”

“Improve scripts/right-playground.sh so it can launch a full-screen Steam session or specific game on the right monitor using the data-vms pool.”

“Show me how to use kscreen-doctor to get monitor names and geometry so I can launch things full-screen on specific monitors.”


## Current Status
v0.002 — First real shared feature: the local suggestion board + monitor-aware launchers + kiosk stubs + improved common library.

Next steps we can do right now (tell me which):
- Make the kiosk actually launch (with better targeting)
- Add a "launch Steam" stub on Right
- Add virsh / data-vms VM launching helpers
- Better window positioning via kscreen-doctor + KWin scripting
- Persistent service management (systemd user units or simple pid files)

## Philosophy & Future Direction
- **Left** becomes a calm, curated internet + LLM-powered suggestion surface. Think "kiosk that only shows good stuff" + brain context.
- **Right** is the fun/play zone: games (with controllers), Spotify + visualizers, local media, file browsing for active creative work.
- **Center (Center)** is the conductor:
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
