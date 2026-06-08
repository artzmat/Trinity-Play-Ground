#!/usr/bin/env bash
# Center Composer - Interactive chat box for the Center Orchestrator.
# Run this on the center monitor for quick responses to Left and/or Right.
# Supports sending the same message to both, or tailored/different messages to each.
# All posts go through the logs + bus so sides see them and Center has full history.
#
# Usage: center-composer.sh [user_label]
# Or after `source lib/common.sh`: pcac_open_center_composer

set -euo pipefail

# Resolve real location (works when symlinked, e.g. in ~/.local/bin)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$SCRIPT_DIR/lib/common.sh"
else
  PCAC_LEFT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/left-chat.log"
  PCAC_RIGHT_CHAT_LOG="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/right-chat.log"
  PCAC_BUS_FILE="${PCAC_SHARED_DIR:-/data/PCaC-Playgrounds/shared}/bus/messages.jsonl"
fi

pcac_ensure_chats

USER_LABEL="${1:-$(whoami)}"

show_header() {
  clear
  echo "╔════════════════════════════════════════════════════════════════════════════╗"
  echo "║  CENTER COMPOSER  |  Orchestrator  |  User: $USER_LABEL               ║"
  echo "╚════════════════════════════════════════════════════════════════════════════╝"
  echo "Type a message to send to both sides (same text)."
  echo "Special commands:"
  echo "  /left <msg>     Send only to Left (tailored for analytical/chill)"
  echo "  /right <msg>    Send only to Right (tailored for creative/play)"
  echo "  /both <msg>     Send same to both (default if no prefix)"
  echo "  /tailor         Enter two different messages (one for each side) in one go"
  echo "  /ask-left <q>   Ask Left-Brain (local LM Studio) the question, show reply"
  echo "  /ask-right <q>  Ask Right-Brain (local LM Studio) the question, show reply"
  echo "  /ask-both <q>   Ask both Left+Right brains in parallel, show both replies"
  echo "  /inbox          Show recent center: queries from sides"
  echo "  /recent         Show recent activity from both sides"
  echo "  /power          Show CPU/GPU power, profile, LM status (leverage your 5950X + 7900XTX)"
  echo "  /help           This help"
  echo "  quit / q / exit Leave the composer"
  echo "--------------------------------------------------------------------------------"
}

show_recent() {
  echo "RECENT LEFT:"
  tail -5 "$PCAC_LEFT_CHAT_LOG" 2>/dev/null | cat
  echo
  echo "RECENT RIGHT:"
  tail -5 "$PCAC_RIGHT_CHAT_LOG" 2>/dev/null | cat
  echo
}

show_inbox() {
  echo "PENDING / RECENT center: QUERIES (from sides to Center):"
  "$SCRIPT_DIR/pcac-grok-inbox.sh" 2>/dev/null | head -20 | cat
  echo
}

show_help() {
  echo "Tips for tailored responses:"
  echo "  - Use /tailor to craft a structured version for Left and a vibe/options version for Right."
  echo "  - Use /ask-left /ask-right /ask-both to query the local LM Studio brains for ideas before replying."
  echo "  - Use /power to see how your 5950X + 7900XTX is doing (power, profile, LM status)."
  echo "  - The sides will see your message in their chat box as coming from 'Center (to Left)' etc."
  echo "  - Everything is also on the bus for full audit."
  echo "  - Run this composer alongside the center-tmux monitor (tails + bus watch)."
  echo
}

post_to_left() {
  local msg="$1"
  pcac_center_reply left "$msg"
  echo "[posted to LEFT] $msg"
}

post_to_right() {
  local msg="$1"
  pcac_center_reply right "$msg"
  echo "[posted to RIGHT] $msg"
}

post_to_both() {
  local msg="$1"
  pcac_center_reply_both "$msg"
  echo "[posted to BOTH] $msg"
}

do_tailor_mode() {
  echo "TAILORED MODE - enter different text for each side (or empty to skip one)."
  read -e -p "For LEFT (analytical/structured/chill): " left_msg
  read -e -p "For RIGHT (creative/playful/options): " right_msg

  if [[ -n "$left_msg" ]]; then
    post_to_left "$left_msg"
  fi
  if [[ -n "$right_msg" ]]; then
    post_to_right "$right_msg"
  fi
  echo "Tailored posts complete."
}

main_loop() {
  show_header
  show_recent
  show_inbox

  while true; do
    read -e -p "Center> " input || break
    input=$(echo "$input" | xargs)  # trim

    if [[ -z "$input" ]]; then
      show_header
      show_recent
      continue
    fi

    case "$input" in
      quit|q|exit)
        echo "Exiting Center composer. (The monitor tails keep running.)"
        break
        ;;
      /help|h|help)
        show_help
        ;;
      /inbox)
        show_inbox
        ;;
      /recent)
        show_recent
        ;;
      /tailor|tailor|t)
        do_tailor_mode
        echo "Press enter to refresh view..."
        read -r
        show_header
        show_recent
        show_inbox
        ;;
      /left\ *|/l\ *)
        msg="${input#*/left }"
        msg="${msg#*/l }"
        post_to_left "$msg"
        ;;
      /right\ *|/r\ *)
        msg="${input#*/right }"
        msg="${msg#*/r }"
        post_to_right "$msg"
        ;;
      /both\ *|/b\ *)
        msg="${input#*/both }"
        msg="${msg#*/b }"
        post_to_both "$msg"
        ;;
      /ask-left\ *|/al\ *)
        q="${input#*/ask-left }"
        q="${q#*/al }"
        echo "[Asking Left-Brain...]"
        pcac_ask_brain left "$q" "$USER_LABEL"
        ;;
      /ask-right\ *|/ar\ *)
        q="${input#*/ask-right }"
        q="${q#*/ar }"
        echo "[Asking Right-Brain...]"
        pcac_ask_brain right "$q" "$USER_LABEL"
        ;;
      /ask-both\ *|/ab\ *)
        q="${input#*/ask-both }"
        q="${q#*/ab }"
        echo "[Asking both brains...]"
        pcac_ask_both "$q" "$USER_LABEL"
        ;;
      /power|/status|p)
        pcac-power-status 2>/dev/null || ~/.local/bin/pcac-power-status 2>/dev/null || /data/PCaC-Playgrounds/scripts/pcac-power-status.sh
        ;;
      *)
        # Default: send same to both
        post_to_both "$input"
        ;;
    esac

    # Small pause so logs update, then optional auto-refresh
    sleep 0.3
  done
}

main_loop
