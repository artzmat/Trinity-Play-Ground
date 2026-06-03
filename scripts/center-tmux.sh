#!/usr/bin/env bash
# Center TMUX session: split view for monitoring both Left and Right chats.
# This provides the "Center terminal to see both" Left and Right Grok personas.
# Part of the three-persona setup.
# Launched via grok-center / playground in a *minimized/small* konsole window
# (960x600 centered) on the center monitor so the physical center display stays usable.

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
  "echo '=== LEFT CHAT (from Left Grok persona) ==='; while true; do tail -f $PCAC_LEFT_CHAT_LOG; done"

# Split vertical for right chat
tmux split-window -h -t "$SESSION" -c "$SCRIPT_DIR" \
  "echo '=== RIGHT CHAT (from Right Grok persona) ==='; while true; do tail -f $PCAC_RIGHT_CHAT_LOG; done"

# Split the right pane horizontally for bus watch (grok_query inbox)
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

echo "Center tmux ready (split view of both sides). Attaching..."
exec tmux attach -t "$SESSION"
