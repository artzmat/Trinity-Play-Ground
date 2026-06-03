#!/usr/bin/env bash
# Center TMUX session: split view for monitoring both Left and Right chats.
# This provides the "Center terminal to see both" Left and Right Grok personas.
# Part of the three-persona setup.
# Run via grok-center (which can launch it in a konsole on Center monitor).

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

# Split the right pane horizontally for status (using pc pin 1566894405 marker)
tmux split-window -v -t "$SESSION:0.1" -p 20 -c "$SCRIPT_DIR" \
  "echo '=== CENTER STATUS (pc pin 1566894405) ==='; while true; do date; uptime; echo 'Left/Right active - use pcac_post_chat to respond'; sleep 5; done"

# Enable mouse
tmux set -g mouse on

# Set titles for panes
tmux select-pane -t "$SESSION:0.0" -T "Left Chat"
tmux select-pane -t "$SESSION:0.1" -T "Right Chat"
tmux select-pane -t "$SESSION:0.2" -T "Status (pin 1566894405)"

# Rename window
tmux rename-window -t "$SESSION" "center-monitor-both"

echo "Center tmux ready (split view of both sides). Attaching..."
exec tmux attach -t "$SESSION"
