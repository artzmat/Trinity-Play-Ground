#!/usr/bin/env bash
# Center TMUX session: split view for monitoring both Left and Right chats.
# This provides the "Center terminal to see both" Left and Right-Brain personas.
# Part of the three-persona setup.
# Launched (like Left/Right) via *minimized/small* konsole window (960x600 centered)
# so the physical center display stays usable. All three persona windows are now small.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
fi

pcac_ensure_chats

SESSION="pcac-center"

# If session exists, just attach
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing $SESSION session..."
  exec tmux attach -t "$SESSION"
fi

echo "Creating new tmux session for Center: monitoring both Left and Right"

# Create session with left chat
tmux new-session -d -s "$SESSION" -n main -c "$SCRIPT_DIR" \
  "echo '=== LEFT CHAT (from Left-Brain persona) ==='; while true; do tail -f $PCAC_LEFT_CHAT_LOG; done"

# Split vertical for right chat
tmux split-window -h -t "$SESSION" -c "$SCRIPT_DIR" \
  "echo '=== RIGHT CHAT (from Right-Brain persona) ==='; while true; do tail -f $PCAC_RIGHT_CHAT_LOG; done"

# Split the right pane horizontally for bus watch (center_query inbox)
tmux split-window -v -t "$SESSION:0.1" -p 25 -c "$SCRIPT_DIR" \
  "$SCRIPT_DIR/center-bus-watch.sh"

# Enable mouse
tmux set -g mouse on

# Set titles for panes
tmux select-pane -t "$SESSION:0.0" -T "Left Chat"
tmux select-pane -t "$SESSION:0.1" -T "Right Chat"
tmux select-pane -t "$SESSION:0.2" -T "Bus / Grok inbox"

# Rename window
tmux rename-window -t "$SESSION" "center-monitor-both"

# Launch web UI (your online online chat interface) as a supplementary visual/parallel access on Center monitor.
# The primary Center is this CLI/TUI + composer for orchestration. The web UI can be useful for quick non-agentic interactions or reference.
firefox --new-window "https://online chat" &

# Launch SearX (local private search at 127.0.0.1:8080) on Center screen to create the 'Searx Grok' hub:
# Easy local research (private, low-impact) right alongside your web/CLI on the orchestrator's monitor (HDMI-A-1).
# This streamlines access so research and Grok interactions are consolidated on Center without switching monitors or heavy copy-paste.
firefox --new-window "http://127.0.0.1:8080" &

echo "Center tmux ready (split view of both sides). Attaching..."
echo "For interactive replies (incl /tailor, /ask-left/right/both for LMStudio brains, /power for hardware):"
echo "  source /data/PCaC-Playgrounds/scripts/lib/common.sh ; pcac_open_center_composer"
echo "  (or just run 'center-composer' in another terminal on this monitor)"
echo "Also: pcac-ask-both.sh \"question\"   |   pcac-converse.sh left \"topic\" 5   |   pcac-power-status"
exec tmux attach -t "$SESSION"
