#!/usr/bin/env bash
# Right TMUX session: combined watch (top) + chat (bottom) for the Right screen.
# This turns the Right monitor into a self-contained "Right persona" terminal
# with monitoring + chat to Center Grok.
# Launched via small/minimized konsole window (960x600 centered) on Right monitor.
# User (Right) can switch panes with Ctrl-b then arrows (or mouse if enabled).
# The chat box allows using Grok via 'grok: ...' posts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
fi

pcac_ensure_dirs

SESSION="pcac-right"

# If session exists, just attach
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing $SESSION session..."
  exec tmux attach -t "$SESSION"
fi

echo "Creating new tmux session for Right: watch + chat"

# Create session with watch in first pane
tmux new-session -d -s "$SESSION" -n main -c "$SCRIPT_DIR" \
  "exec $SCRIPT_DIR/right-watch.sh ${1:-$(whoami)}"

# Split horizontal (bottom pane for chat)
tmux split-window -v -t "$SESSION" -p 30 -c "$SCRIPT_DIR" \
  "exec $SCRIPT_DIR/right-chat.sh ${1:-$(whoami)}"

# Optional: enable mouse for easier pane switching
tmux set -g mouse on

# Focus on chat pane initially? Or watch. Default top.
tmux select-pane -t "$SESSION:0.0"  # watch top

# Set titles
tmux rename-window -t "$SESSION" "right-watch+chat"

echo "Right tmux ready. Attaching..."
exec tmux attach -t "$SESSION"
