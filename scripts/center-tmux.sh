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

# Create session 
tmux new-session -d -s "$SESSION" -n main -c "$SCRIPT_DIR" \
  "echo '=== LEFT CHAT (from Left Grok persona) ==='; tail -f $PCAC_LEFT_CHAT_LOG"

# Split vertical for right chat
tmux split-window -h -t "$SESSION" -c "$SCRIPT_DIR" \
  "echo '=== RIGHT CHAT (from Right Grok persona) ==='; tail -f $PCAC_RIGHT_CHAT_LOG"

# Enable mouse
tmux set -g mouse on

# Set titles for panes
tmux select-pane -t "$SESSION:0.0" -T "Left Chat"
tmux select-pane -t "$SESSION:0.1" -T "Right Chat"

# Rename window
tmux rename-window -t "$SESSION" "center-monitor-both"

echo "Center tmux ready (split view of both sides). Attaching..."
exec tmux attach -t "$SESSION"
