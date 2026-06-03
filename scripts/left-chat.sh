#!/usr/bin/env bash
# Left Chat Box - for the Left Grok persona
# Separate chat from Right.
# Supports "grok: your question here" to signal asking the Center Orchestrator Grok.
# Run in its own konsole on Left monitor (or in tmux pane with watch).
# Left/Right can see Center monitor (physically) but no control.
# Use optional first arg as user label for "cursor" (e.g. remote users).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
else
  PCAC_LEFT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/left-chat.log"
fi

pcac_ensure_chats

USER_LABEL="${1:-$(whoami)}"

# Function to display recent chat
show_chat() {
  clear
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  LEFT CHAT BOX  |  Left Grok persona  |  User: $USER_LABEL   ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo "This is the separate chat for Left. Center Orchestrator Grok sees this."
  echo "You (Left) can view the Center monitor but have no control over it."
  echo "Type 'grok: your message or question' to ask the Center Grok."
  echo "Type 'quit' or Ctrl-C to exit. 'clear' to refresh."
  echo "--------------------------------------------------------------"
  echo "Recent messages:"
  tail -30 "$PCAC_LEFT_CHAT_LOG" 2>/dev/null || echo "(no messages yet)"
  echo "--------------------------------------------------------------"
}

show_chat

while true; do
  read -r -p "Left> " input || break
  input=$(echo "$input" | xargs)  # trim
  if [[ -z "$input" ]]; then
    show_chat
    continue
  fi
  case "$input" in
    quit|q|exit)
      echo "[$(date '+%H:%M:%S')] Left ($USER_LABEL): [exited chat]" >> "$PCAC_LEFT_CHAT_LOG"
      break
      ;;
    clear|c)
      show_chat
      continue
      ;;
    grok:*|Grok:*)
      # Special: asking Grok (center will respond by posting back)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      pcac_post_chat left "Left Grok ($USER_LABEL)" "grok: $msg"
      echo "[$(date '+%H:%M:%S')] [Query sent to Center Grok - check Center monitor for response]"
      sleep 1
      show_chat
      ;;
    *)
      pcac_post_chat left "Left Grok ($USER_LABEL)" "$input"
      show_chat
      ;;
  esac
done

echo "Left chat exited."