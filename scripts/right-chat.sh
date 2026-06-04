#!/usr/bin/env bash
# Right Chat Box - for the Right Grok persona
# Separate chat from Left.
# Supports "grok: your question here" to signal asking the Center Orchestrator Grok.
# Run in its own konsole on Right monitor (or in tmux pane with watch).
# Left/Right can see Center monitor (physically) but have no control.
# Use optional first arg as user label for "cursor" (e.g. remote users).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
else
  PCAC_RIGHT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/right-chat.log"
fi

pcac_ensure_chats

USER_LABEL="${1:-$(whoami)}"

# Function to display recent chat
show_chat() {
  clear
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  RIGHT CHAT BOX  |  Right Grok persona  |  User: $USER_LABEL  ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo "This is the separate chat for Right. Center Orchestrator Grok sees this."
  echo "You (Right) can view the Center monitor but have no control over it."
  echo "Type 'grok: ...' to ask the local Right-Brain (LM Studio Qwen as Right Grok)."
  echo "Type 'center: ...' to ask the Center Orchestrator Grok (main grok cli)."
  echo "Type 'quit' or Ctrl-C to exit. 'clear' to refresh."
  echo "--------------------------------------------------------------"
  echo "Recent messages:"
  tail -30 "$PCAC_RIGHT_CHAT_LOG" 2>/dev/null || echo "(no messages yet)"
  echo "--------------------------------------------------------------"
}

show_chat

while true; do
  read -r -p "Right> " input || break
  input=$(echo "$input" | xargs)  # trim
  if [[ -z "$input" ]]; then
    show_chat
    continue
  fi
  case "$input" in
    quit|q|exit)
      echo "[$(date '+%H:%M:%S')] Right ($USER_LABEL): [exited chat]" >> "$PCAC_RIGHT_CHAT_LOG"
      break
      ;;
    clear|c)
      show_chat
      continue
      ;;
    grok:*|Grok:*)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      pcac_post_chat right "Right Grok ($USER_LABEL)" "$msg"
      echo "[$(date '+%H:%M:%S')] Right-Brain (LMStudio) thinking..."
      if pcac_ask_brain right "$msg" "$USER_LABEL"; then
        echo "[$(date '+%H:%M:%S')] Right-Brain (as Right Grok) replied (see chat log)"
      else
        echo "[$(date '+%H:%M:%S')] Right-Brain unavailable — start LM Studio server (:1234)"
      fi
      sleep 1
      show_chat
      ;;
    ask:*|Ask:*)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      echo "[$(date '+%H:%M:%S')] Right-Brain thinking..."
      if pcac_ask_brain right "$msg" "$USER_LABEL"; then
        echo "[$(date '+%H:%M:%S')] Right-Brain replied (see chat log)"
      else
        echo "[$(date '+%H:%M:%S')] Right-Brain unavailable — start LM Studio server (:1234)"
      fi
      sleep 1
      show_chat
      ;;
    center:*|Center:*)
      msg="${input#*:}"
      msg=$(echo "$msg" | xargs)
      pcac_post_chat right "Right Grok ($USER_LABEL)" "grok: $msg"
      echo "[$(date '+%H:%M:%S')] [Query sent to Center — check Center monitor]"
      sleep 1
      show_chat
      ;;
    *)
      pcac_post_chat right "Right Grok ($USER_LABEL)" "$input"
      show_chat
      ;;
  esac
done

echo "Right chat exited."