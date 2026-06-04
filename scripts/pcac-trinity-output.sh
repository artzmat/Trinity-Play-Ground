#!/bin/bash
# pcac-trinity-output.sh — Capture latest CLI outputs from Left, Right, Center
# for easy one-command copy-paste into Grok Online (https://grok.x.ai on Center).
#
# Exactly the sections you asked for:
#   Left Response
#   Right Response
#   Center Response
#   Trinity Response (All three)
#
# Run from Center (after side activity or cross-convos).
# Left/Right captured from their tmux grok-persona pane (the full TUI output you see on side monitors).
# Center pulled from chat logs + bus + center-monitor panes.
#
# Usage:
#   pcac-trinity-output [lines]         # lines of recent scrollback per side (default 300 for whole responses)
#   pcac-trinity-output --full          # capture entire available tmux scrollback for sides + generous logs for Center (to ensure *whole* responses)
#   pcac-trinity-output --copy          # try auto to clipboard (wl-copy / xclip)
#   pcac-trinity-output --full | wl-copy
#   pcac-trinity-output --help
#
# Primary friendly names (recommended):
#   trinity-copy   (also: trinity-copy --full)
# Legacy / scripting names (still fully supported):
#   pcac-trinity-output , pcac-grok-clip
#
# Re-run after new Left/Right thinking, mood-sync, cross-converse, or composer replies
# so the captures are fresh for feeding back into online Grok for deeper Trinity synthesis.
# Use --full (or a high number) when a persona just produced a long structured response, full script, or detailed analysis
# so nothing gets cut off mid-thought in the paste to grok.x.ai .
#
# Output is *always* also written to:
#   ~/Documents/PC-Stuff/Trinity.md (the smart Trinity File — replaces the previous one, keeping needed prior Trinity Response block(s) + fresh capture)
#   ~/Documents/PC-Stuff/Trinity-Output-*.md (pure dated raw snapshots) + Trinity-Raw-Latest.md symlink.

set -euo pipefail

# Resolve real script dir even when invoked via symlink (~/bin/pcac-*) 
_real_me="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  _real_me="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
fi
SCRIPT_DIR="$(cd "$(dirname "$_real_me")" && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null || true

pcac_ensure_chats 2>/dev/null || true

# Handle --help very early (no deps)
for arg in "$@"; do
  case "$arg" in
    --help|-h)
      sed -n '2,40p' "$0" | sed 's/^# //;s/^#//'
      echo ""
      echo "Current symlinks: ~/bin/pcac-trinity-output  and  ~/bin/pcac-grok-clip (identical)"
      exit 0
      ;;
  esac
done

# Defaults chosen to get "the whole response" for typical persona outputs (long analyses, code, lists, plans).
# Use --full or a large number (e.g. 1000) or "full" when you need the complete untruncated history.
LINES=300
FULL_MODE=0
DO_COPY=0
for arg in "$@"; do
  case "$arg" in
    --copy) DO_COPY=1 ;;
    --full) FULL_MODE=1 ;;
    full) FULL_MODE=1 ;;
    [0-9]*) LINES="$arg" ;;
  esac
done

if [[ "$FULL_MODE" == "1" ]]; then
  # For full mode we still pass a high LINES for any non-full code paths, but capture logic below will ignore tail limit.
  LINES=9999
fi

# --- Persist Trinity captures to PC-Stuff folder for easy file upload to Grok Online ---
# - Pure raw snapshot always written to dated Trinity-Output-*.md
# - Main Trinity.md (the "Trinity File") is replaced with fresh capture + kept parts (e.g. prior Trinity Response block) from the old Trinity.md
# "replace the previous trinity file. Keep what you need from it and write a new one to replace the one that is there."
# Trinity-Raw-Latest.md symlink to the latest raw for reference.
TRINITY_DIR="$HOME/Documents/PC-Stuff"
mkdir -p "$TRINITY_DIR" 2>/dev/null || true
TRINITY_TS="$(date '+%Y-%m-%d-%H%M%S')"
TRINITY_DATED="$TRINITY_DIR/Trinity-Output-${TRINITY_TS}.md"
TRINITY_LATEST="$TRINITY_DIR/Trinity.md"

strip_ansi() {
  # Remove common ANSI escape sequences (colors, cursor, etc.) for clean paste
  sed -E 's/\x1B\[[0-9;]*[mGKHJ]//g' | sed -E 's/\x1B\][^\x07]*\x07//g'
}

capture_pane() {
  local target="$1"
  local n="${2:-$LINES}"
  if tmux has-session -t "${target%%:*}" 2>/dev/null; then
    local capture_start="-1000"
    local do_tail=1
    if [[ "$FULL_MODE" == "1" || "$n" == "full" || "$n" == "all" || "$n" -gt 2000 ]]; then
      capture_start="-"   # entire scrollback buffer (the "whole" history available for this pane)
      do_tail=0
    fi
    # Capture from far back in history (or all). Strip ANSI for clean paste into web Grok.
    local out
    if [[ $do_tail -eq 1 ]]; then
      out=$(tmux capture-pane -t "$target" -S "$capture_start" -p 2>/dev/null | strip_ansi | tail -n "$n") || true
    else
      out=$(tmux capture-pane -t "$target" -S "$capture_start" -p 2>/dev/null | strip_ansi) || true
    fi
    if [[ -n "$out" ]]; then
      echo "$out"
    else
      # Only a short note if we got literally nothing (rare)
      echo "(no recent output captured from $target; pane may be idle or layout changed)"
    fi
  else
    echo "(tmux session for $target not running)"
  fi
}

# Redirect stdout from here on through tee so everything (the four sections, template, end notes)
# goes to terminal *and* is saved to the dated Trinity file (pure historical snapshot).
# The main "Trinity File" (Trinity.md) will be smart-replaced at the end: fresh content + kept useful parts (e.g. previous Trinity Response) from the old one.
exec > >(tee "$TRINITY_DATED" 2>/dev/null || cat)

echo "=== Left Response ==="
# Left persona Grok TUI is in bottom pane (index 1) of pcac-left
left_cap="$(capture_pane "pcac-left:0.1" "$LINES")"
echo "$left_cap"
echo ""

echo "=== Right Response ==="
right_cap="$(capture_pane "pcac-right:0.1" "$LINES")"
echo "$right_cap"
echo ""

echo "=== Center Response ==="
echo "(Center orchestration / recent coordination visible on Center monitor + your latest synthesis. Re-run after composer or bus activity.)"
echo ""

# Scale Center capture based on full vs normal (to ensure we get complete Center responses/posts too)
CENTER_LOG_LINES=25
BUS_PREVIEW_LINES=40
CENTER_PANE_LINES=25
if [[ "$FULL_MODE" == "1" ]]; then
  CENTER_LOG_LINES=150
  BUS_PREVIEW_LINES=100
  CENTER_PANE_LINES=80
fi

echo "Recent Center posts (from side chat logs):"
pcac_ensure_chats
# tail a window then grep recent Center messages so we get the *whole* recent Center replies (they can be long)
tail -n "$CENTER_LOG_LINES" "$PCAC_LEFT_CHAT_LOG" 2>/dev/null | grep -E 'Center Grok' | tail -20 || echo "  (no Center posts to left yet)"
tail -n "$CENTER_LOG_LINES" "$PCAC_RIGHT_CHAT_LOG" 2>/dev/null | grep -E 'Center Grok' | tail -20 || echo "  (no Center posts to right yet)"
echo ""

echo "Recent bus activity (grok_query / cross / center replies):"
if [[ -s "$PCAC_BUS_FILE" ]]; then
  tail -n "$BUS_PREVIEW_LINES" "$PCAC_BUS_FILE" 2>/dev/null | python3 - "$PCAC_BUS_FILE" 20 <<'PY' 2>/dev/null || tail -n 20 "$PCAC_BUS_FILE"
import json, sys
path = sys.argv[1]
n = int(sys.argv[2]) if len(sys.argv)>2 else 20
for line in open(path, encoding="utf-8").read().splitlines()[-80:]:
    if not line.strip(): continue
    try:
        o = json.loads(line)
    except Exception:
        continue
    k = o.get("kind","")
    if k in ("grok_query","center_reply","cross_start","cross_turn","cross_end","ask_both"):
        print(f"  [{o.get('ts','')[:19]}] {k} | {o.get('from','')}→{o.get('to','')} : {str(o.get('text',''))[:200]}")
PY
else
  echo "  (bus empty)"
fi
echo ""

if tmux has-session -t pcac-center 2>/dev/null; then
  echo "Recent from Center monitor panes (bus + chats view):"
  # 0.2 is usually the bus watch; 0.0/0.1 are the chat tails
  capture_pane "pcac-center:0.2" "$CENTER_PANE_LINES"
  echo ""
fi

# Local LM + self-training snapshot (optimizes Trinity captures now that LM Studio is up and loaded with Qwen models per user).
# Pulls compact status from pcac-lm-status.sh (Left 0.3 structured / Right creative tuning) + recent habit notes (roundtrip from mood-sync / observer self-reports).
# Makes the "whole responses" fed to grok.x.ai more aware of live local brains + habit observer loop without adding load.
echo "Local brains / self-training snapshot (LM up, captured for richer Trinity context):"
if command -v /data/PCaC-Playgrounds/scripts/pcac-lm-status.sh >/dev/null 2>&1; then
  /data/PCaC-Playgrounds/scripts/pcac-lm-status.sh 2>/dev/null | head -20 | cat || echo "  (lm status script present but no output)"
else
  echo "  (pcac-lm-status.sh not in expected path)"
fi
echo "Recent habit notes (Left mood roundtrip + Right creative self-reports for observer visibility):"
for note_file in /data/PCaC-Playgrounds/shared/left-habit-notes.txt /data/PCaC-Playgrounds/shared/right-habit-notes.txt; do
  if [ -f "$note_file" ]; then
    echo "  $(basename $note_file):"
    tail -n 2 "$note_file" 2>/dev/null | sed 's/^/    /'
  fi
done
echo ""

echo "=== Trinity Response (All three) ==="
cat <<'TRINITY'
Take the *complete* Left Response, Right Response, and Center Response above (the full recent outputs from our local PCaC three-persona setup; captured with --full or high line count where needed) and produce one unified "Trinity Response (All three)".

Coordination rules:
- Left-Brain (DP-3): analytical, structured, chill, minimal load on Center white HQ (HDMI-A-1). Prefers local tools (sear), low-impact. Use for deep analysis, plans, hardening, code review.
- Right-Brain (DP-2): creative/play layer, vibe/options, high-engagement stack (Spotify/Steam/Thunderbird/VM/monitor). Compact, fun, suggestions. Drives mood-sync etc to Left via thin Background Task Queue.
- Center (orchestrator, white desktop): protects personal workspace, coordinates via shared bus/logs, local-first (sear + anything on 127.0.0.1), auditable (pcac_remember, timestamped backups), launches the sides, wires mood-sync, runs composer for simultaneous tailored replies. Never loads the Center monitor visually/mentally.

Output a single coherent Trinity reply that:
- Respects the physical + role separation.
- Pulls the strongest ideas from each (use the *whole* provided text for each, do not truncate).
- Proposes concrete next local actions (scripts, flags, bus posts, composer use).
- Keeps Center white HQ clean and low-load.

If more context or a specific topic is needed, note it and suggest a follow-up cross-converse or pcac-ask-both.
TRINITY
echo ""
echo "[End of Trinity template — paste the four === sections (or just the three Responses + this Trinity header) into grok.x.ai for the synthesized reply. Use --full when re-running the local command if any response feels cut off.]"
echo ""

echo "=== End Trinity Output ==="
if [[ "$FULL_MODE" == "1" ]]; then
  echo "Captured: $(date '+%Y-%m-%d %H:%M:%S') | FULL scrollback/history per side + generous Center logs (whole responses)"
else
  echo "Captured: $(date '+%Y-%m-%d %H:%M:%S') | lines≈$LINES per side"
fi
echo "Re-capture after side activity, cross-convo (pcac-converse), mood-sync, or center-composer replies."
echo "If a response was truncated, re-run with --full (or higher number) before copying to grok.x.ai ."

if [[ "$DO_COPY" != "1" ]]; then
  echo ""
  echo "Clipboard tips:"
  echo "  pcac-trinity-output --copy"
  echo "  pcac-trinity-output --full --copy"
  echo "  pcac-trinity-output | wl-copy     # (sudo pacman -S wl-clipboard or apt install wl-clipboard)"
  echo "  pcac-trinity-output | xclip -selection clipboard"
  echo ""
  echo "Also runnable as: pcac-grok-clip (identical)"
fi

# Optional auto-copy (re-invoke without --copy flag so inner run is clean; its stdout goes to clipboard)
if [[ "$DO_COPY" == "1" ]]; then
  clip_cmd=""
  if command -v wl-copy >/dev/null 2>&1; then
    clip_cmd="wl-copy"
  elif command -v xclip >/dev/null 2>&1; then
    clip_cmd="xclip -selection clipboard"
  fi
  copy_args=()
  if [[ -n "$clip_cmd" ]]; then
    # Build args for clean inner run (forward --full if active; avoid duplicating --copy)
    if [[ "$FULL_MODE" == "1" ]]; then
      copy_args+=( "--full" )
    fi
    if [[ "$LINES" =~ ^[0-9]+$ && "$LINES" -lt 9000 ]]; then
      copy_args+=( "$LINES" )
    fi
    # Use full resolved path to avoid any symlink/argv weirdness on re-invoke
    "$SCRIPT_DIR/pcac-trinity-output.sh" "${copy_args[@]}" 2>/dev/null | $clip_cmd && echo "Copied full Trinity output to clipboard via $clip_cmd." || echo "(clipboard command failed; output was on stdout above)"
  else
    echo "No wl-copy or xclip found. Install wl-clipboard (Wayland) or xclip (X11) then use --copy."
    echo "For now the formatted sections are above — select/copy them manually."
  fi
fi

# --- Post-run: smart replace for the main Trinity File (Trinity.md) ---
# The DATED file already has the pure fresh capture for this run (raw historical snapshot via tee).
# We now replace the main "Trinity File" (Trinity.md, for easy Grok Online upload) with a *new* version that:
#   - Contains the fresh current output from this run (the four === Response === sections + template + end).
#   - Keeps useful parts from the *previous* Trinity.md (the most recent prior "Trinity Response (All three)" block) for continuity and richer cumulative context.
# This fulfills "replace the previous trinity file. Keep what you need from it and write a new one to replace the one that is there."
# Dated raw snapshots remain separate for full history.

if [ -f "$TRINITY_DATED" ]; then
  PREV_TRINITY_BLOCK=""
  if [ -f "$TRINITY_LATEST" ]; then
    # Extract the most recent previous Trinity Response block from the old file (what we "keep").
    PREV_TRINITY_BLOCK=$(awk '
      /=== Trinity Response \(All three\) ===/ {
        capturing=1
        block = $0 "\n"
        next
      }
      capturing {
        block = block $0 "\n"
      }
      /=== End Trinity Output ===/ && capturing {
        last = block
        capturing=0
      }
      END {
        if (last) print last
      }
    ' "$TRINITY_LATEST")
  fi

  # Write the fresh current capture as the base of the new Trinity.md
  cat "$TRINITY_DATED" > "$TRINITY_LATEST" 2>/dev/null || cp "$TRINITY_DATED" "$TRINITY_LATEST"

  # Append the kept previous if we extracted any
  if [ -n "$PREV_TRINITY_BLOCK" ]; then
    cat >> "$TRINITY_LATEST" << 'HISTEOF'
────────────────────────────────────────────────────────────
## Previous Trinity Response (kept from the replaced previous Trinity File)

Preserved here so this single Trinity.md file carries forward useful historical synthesis/context for ongoing easy uploads to Grok Online (grok.x.ai). Only the most recent prior block is kept to avoid unbounded growth; full raw history lives in the dated Trinity-Output-*.md files.

HISTEOF
    echo "$PREV_TRINITY_BLOCK" >> "$TRINITY_LATEST"
    echo "" >> "$TRINITY_LATEST"
    echo "[This Trinity.md replaces the previous file while retaining the kept historical Trinity Response for continuity.]" >> "$TRINITY_LATEST"
  fi

  chmod 644 "$TRINITY_LATEST" 2>/dev/null || true
fi

# Optional: maintain a symlink to the latest *pure raw* capture
ln -sf "$TRINITY_DATED" "$TRINITY_DIR/Trinity-Raw-Latest.md" 2>/dev/null || true

# Append reference to the PC-Stuff snapshot ("update the Things")
SNAPSHOT="$HOME/Documents/PC-Stuff/PC-Stuff-Snapshot.txt"
if [[ -f "$SNAPSHOT" ]]; then
  echo "" >> "$SNAPSHOT" 2>/dev/null || true
  echo "Trinity capture (raw dated): $TRINITY_DATED | Smart Trinity File replaced (fresh + kept prev): $TRINITY_LATEST at $(date '+%Y-%m-%d %H:%M:%S')" >> "$SNAPSHOT" 2>/dev/null || true
fi

# Notify (bypass tee if active)
NOTE_MSG="[Trinity File replaced with new version: $TRINITY_LATEST (current capture + kept previous Trinity Response)]
[Raw snapshot this run: $TRINITY_DATED (and Trinity-Raw-Latest.md)]
[PC-Stuff snapshot reference appended]"
( echo "$NOTE_MSG" > /dev/tty ) 2>/dev/null || echo "$NOTE_MSG"
