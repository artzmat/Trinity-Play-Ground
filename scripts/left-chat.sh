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
  echo "Type 'grok: ...' to ask the local Left-Brain (LM Studio Qwen as Left Grok)."
  echo "Type 'center: ...' to ask the Center Orchestrator Grok (main grok cli)."
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
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      pcac_post_chat left "Left Grok ($USER_LABEL)" "$msg"
      echo "[$(date '+%H:%M:%S')] Left-Brain (LMStudio) thinking..."
      if pcac_ask_brain left "$msg" "$USER_LABEL"; then
        echo "[$(date '+%H:%M:%S')] Left-Brain (as Left Grok) replied (see chat log)"
      else
        echo "[$(date '+%H:%M:%S')] Left-Brain unavailable — start LM Studio server (:1234)"
      fi
      sleep 1
      show_chat
      ;;
    ask:*|Ask:*)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      echo "[$(date '+%H:%M:%S')] Left-Brain thinking..."
      if pcac_ask_brain left "$msg" "$USER_LABEL"; then
        echo "[$(date '+%H:%M:%S')] Left-Brain replied (see chat log)"
      else
        echo "[$(date '+%H:%M:%S')] Left-Brain unavailable — start LM Studio server (:1234)"
      fi
      sleep 1
      show_chat
      ;;
    center:*|Center:*)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      pcac_post_chat left "Left Grok ($USER_LABEL)" "grok: $msg"
      echo "[$(date '+%H:%M:%S')] [Query sent to Center — check Center monitor]"
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