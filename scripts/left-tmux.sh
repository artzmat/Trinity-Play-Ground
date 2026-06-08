#!/usr/bin/env bash
# Left TMUX session: combined watch (top) + full brain TUI as Left-Brain persona (bottom).
# This turns the Left monitor (DP-3) into a self-contained "Left persona" terminal
# with monitoring + a full powerful LM Studio CLI running as the Left-Brain (cloud, persona-injected).
# No LM Studio needed for this mode.
# Launched via small/minimized konsole on Left monitor.
# User can switch panes with Ctrl-b.
# The persona Grok is instructed to coordinate with Center via the shared bus/logs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
fi

pcac_ensure_dirs

SESSION="pcac-left"

# If session exists, just attach
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Attaching to existing $SESSION session..."
  exec tmux attach -t "$SESSION"
fi

echo "Creating new tmux session for Left: watch + chat"

# Create session with watch in first pane
tmux new-session -d -s "$SESSION" -n main -c "$SCRIPT_DIR" \
  "exec $SCRIPT_DIR/left-watch.sh ${1:-$(whoami)}"

# Split horizontal (bottom pane for full brain TUI as Left-Brain persona)
# This replaces the old simple chat box + local LM. Now a full powerful grok cli
# configured with Left persona (SYSTEM + MEMORY injected at launch).
tmux split-window -v -t "$SESSION" -p 30 -c "$SCRIPT_DIR" \
  "bash -c 'source \"$SCRIPT_DIR/lib/common.sh\"; pcac_run_brain_persona left \"${1:-$(whoami)}\"'"

# Optional: enable mouse for easier pane switching
tmux set -g mouse on

# Focus on chat pane initially? Or watch. Let's start with chat at bottom focused? Default top.
tmux select-pane -t "$SESSION:0.0"  # watch top

# Set titles
tmux rename-window -t "$SESSION" "left-watch+chat"

# Launch SearX (local private search UI) in browser for easy research on Left monitor (low visual impact)
# Use --new-window to keep it separate; configure the browser profile for minimal load if desired.
firefox --new-window "http://127.0.0.1:8080" &

echo "Left tmux ready (with SearX browser). Attaching..."
exec tmux attach -t "$SESSION"
