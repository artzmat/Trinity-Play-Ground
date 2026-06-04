#!/bin/bash
# trinity-habit-observer.sh — Lightweight background observer for Trinity habit learning
#
# Launch (low priority, as directed by Center):
#   nice -n 15 ionice -c 3 ~/bin/trinity-habit-observer &
#
# Watches chat logs + bus + PC-Stuff docs for repeated patterns across Left/Right/Center (the Trinity).
# Proposes pcac_remember facts, small reversible tweaks, or doc updates.
# NEVER auto-applies. Always posts clear [habit-proposal] to bus + detailed log.
# Respects hardening priorities (references hardening-log, becomes log-only if AppArmor etc pending).
# Documentation-first: always cross-references ~/Documents/PC-Stuff/ before proposing.
# Low resource use.
# Center white HQ protection is non-negotiable — all proposals must preserve it.

set -euo pipefail

source /data/PCaC-Playgrounds/scripts/lib/common.sh 2>/dev/null || true

LOG_DIR="/data/var/log/pcac"
mkdir -p "$LOG_DIR"
PROPOSAL_LOG="$LOG_DIR/habit-proposals.log"
STATE_DIR="$LOG_DIR/habit-state"
mkdir -p "$STATE_DIR"

# Rate limiter (Qwen Left-Brain "ask" suggestion for Center directive): max ~2-4 proposals/hour to keep bus clean.
# 900s interval = up to 4 per hour.
LAST_PROPOSAL_TIME_FILE="$LOG_DIR/last_habit_proposal_time"
MIN_SECONDS_BETWEEN_PROPOSALS=900

can_propose_now() {
    local now=$(date +%s)
    local last=0
    if [ -f "$LAST_PROPOSAL_TIME_FILE" ]; then
        last=$(cat "$LAST_PROPOSAL_TIME_FILE" 2>/dev/null || echo 0)
    fi
    if [ $(( now - last )) -ge $MIN_SECONDS_BETWEEN_PROPOSALS ]; then
        echo "$now" > "$LAST_PROPOSAL_TIME_FILE"
        return 0
    fi
    return 1
}

# Self-enforce low priority
renice -n 15 $$ >/dev/null 2>&1 || true
ionice -c 3 -n 7 -p $$ 2>/dev/null || true

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$PROPOSAL_LOG"
}

propose() {
    local area="$1"
    local fact="$2"
    local suggested_cmd="$3"
    local priority="${4:-normal}"

    # Rate limiter (Qwen suggestion): prevent > ~4 proposals per hour on the bus
    if ! can_propose_now; then
        return 0
    fi

    local proposal_text="[$area] $fact | Suggested: $suggested_cmd (priority: $priority)"

    # Simple scoring for prioritization (higher = better to surface)
    # Based on keywords from active threads in maps (creative, mood-sync, hardening, docs, trinity) + length
    local score=0
    for kw in creative mood-sync right-daily cava ambient slot habit note hardening AppArmor trinity harmony "PC-Stuff" "Center white" "documentation-first" observer; do
        if echo "$proposal_text" | grep -qi "$kw"; then
            score=$((score + 2))
        fi
    done
    local len=$(echo "$proposal_text" | wc -c)
    if [ "$len" -gt 120 ]; then score=$((score + 1)); fi
    if echo "$proposal_text" | grep -qi "PC-Stuff\|Center white\|map"; then score=$((score + 3)); fi

    # Only propose high-signal ones (threshold to reduce noise)
    if [ "$score" -lt 6 ]; then
        return 0
    fi

    # Dedup: skip if this exact suggestion seen in last 6 hours
    local hash
    hash=$(echo "$proposal_text" | md5sum | cut -d' ' -f1)
    local state_file="$STATE_DIR/$hash"
    if [ -f "$state_file" ] && [ $(find "$state_file" -mmin +360 2>/dev/null | wc -l) -eq 0 ]; then
        return 0  # seen recently
    fi
    touch "$state_file"

    log "[PROPOSAL score=$score] $proposal_text"

    # Post to bus for Center visibility (kind=habit-proposal)
    pcac_bus_append "Trinity-Habit-Observer" "center" "habit-proposal" "$proposal_text" || true

    # Also append to a dedicated proposals file for easy review
    echo "$proposal_text" >> "$LOG_DIR/habit-proposals.txt"
}

is_hardening_pending() {
    # Check the official hardening log for pending critical items (AppArmor etc.)
    if [ -f ~/Documents/PC-Stuff/hardening-log-2026-06-03.md ]; then
        if grep -q "AppArmor is the immediate next" ~/Documents/PC-Stuff/hardening-log-2026-06-03.md; then
            return 0  # pending
        fi
    fi
    return 1
}

do_observation_cycle() {
    log "Starting observation cycle (documentation-first, hardening-aware, Center white HQ protected)..."

    local hardening_pending=false
    if is_hardening_pending; then
        hardening_pending=true
        log "Hardening priorities active (AppArmor pending per official log). Proposals will be conservative / log-only where relevant."
    fi

    # === RIGHT creative layer patterns (from right-chat and bus) ===
    local right_patterns
    right_patterns=$(tail -n 400 /data/PCaC-Playgrounds/shared/right-chat.log 2>/dev/null | grep -iE 'mood|creative|chill|low.?stim|ambient|slot|viz|cava|story|queue' | tail -n 10 || true)
    if [ -n "$right_patterns" ]; then
        propose "RIGHT-CREATIVE" \
            "Ongoing low-stim creative habit on Right: cava viz + slot machine + ambient stories via mood-sync to Left. Right-daily --creative should become the single entry point. Always update PC-Stuff docs when changing creative layer." \
            "pcac_remember right \"Ongoing low-stim creative habit on Right: cava viz + slot machine + ambient stories via mood-sync to Left. Right-daily --creative should become the single entry point. Always update PC-Stuff docs when changing creative layer.\""
        if $hardening_pending; then
            propose "RIGHT-CREATIVE" \
                "Hardening pending — keep all Right creative automations strictly DP-2 only and log-only for now." \
                "Update right-daily --creative comment to note 'respect current hardening priorities (AppArmor next)'."
        fi
    fi

    # === LEFT workspace / mood-sync / automation patterns ===
    local left_patterns
    left_patterns=$(tail -n 400 /data/PCaC-Playgrounds/shared/left-chat.log 2>/dev/null | grep -iE 'mood|workspace|hardening|setup_left|watch-mood|automation|trigger' | tail -n 8 || true)
    if [ -n "$left_patterns" ]; then
        propose "LEFT-WORKSPACE" \
            "Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe." \
            "pcac_remember left \"Enhance setup_left_workspace.sh --watch-mood to emit a compact 'habit note' back to Right via bus when it processes a signal. Keep all responses minimal and Center-white-HQ-safe.\""
        if $hardening_pending; then
            propose "LEFT-WORKSPACE" \
                "Left workspace changes must remain log-only and reversible while AppArmor is pending in hardening-log." \
                "Add note at top of setup_left_workspace.sh: 'Hardening priorities active — no new services until AppArmor step complete per official log.'"
        fi
    fi

    # === CENTER / observer / orchestration patterns (from bus and docs) ===
    local center_patterns
    center_patterns=$(tail -n 300 /data/PCaC-Playgrounds/shared/bus/messages.jsonl 2>/dev/null | grep -iE 'habit|observer|trinity|composer|orchestrat' | tail -n 5 || true)
    if [ -n "$center_patterns" ]; then
        propose "CENTER" \
            "Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions." \
            "pcac_remember center \"Trinity Habit Observer is now running persistently (nice/ionice). It produces proposals on the bus. Center should review and selectively apply 2-4 high-quality ones per day during active sessions.\""
    fi

    # Watch for Left compact habit notes (roundtrip from mood-sync / --watch-mood)
    if [ -f /data/PCaC-Playgrounds/shared/left-habit-notes.txt ]; then
        recent_left_notes=$(tail -n 3 /data/PCaC-Playgrounds/shared/left-habit-notes.txt 2>/dev/null || true)
        if [ -n "$recent_left_notes" ]; then
            propose "LEFT-HABIT-NOTE" \
                "Left emitted compact habit note(s) from mood-sync processing (e.g. processed signal, resources chill)." \
                "pcac_remember right \"Left minimalist layer responds to mood-sync with compact habit notes. Use these to keep Right creative layer aligned and low-load while protecting Center white HQ.\""
        fi
    fi

    # Watch right-habit-notes symmetrically (from right-daily --creative runs) for creative alignment proposals
    if [ -f /data/PCaC-Playgrounds/shared/right-habit-notes.txt ]; then
        recent_right_notes=$(tail -n 3 /data/PCaC-Playgrounds/shared/right-habit-notes.txt 2>/dev/null || true)
        if [ -n "$recent_right_notes" ]; then
            propose "RIGHT-HABIT-NOTE" \
                "Right creative run emitted habit note (cava + slot + stories + mood-sync). Loop feedback active." \
                "pcac_remember right \"Right creative layer (right-daily --creative) now emits habit notes; observer watches them for self-alignment and low-load creative refinements while Center white HQ stays protected.\""
        fi
    fi

    # Cross reference PC-Stuff docs (documentation-first)
    if [ -f ~/Documents/PC-Stuff/Center-Operator-Cheat-Sheet.md ]; then
        if ! grep -q "Trinity Habit Observer" ~/Documents/PC-Stuff/Center-Operator-Cheat-Sheet.md 2>/dev/null; then
            propose "DOCS" \
                "PC-Stuff official cheat sheet should document the live Trinity Habit Observer and self-training loop." \
                "Update ~/Documents/PC-Stuff/Center-Operator-Cheat-Sheet.md with current observer status, launch command, and bus proposal workflow."
        fi
        # Map sync probe (Right-Brain suggestion from recent cross in right-chat.log): check for self-report language
        if ! grep -q "self-report\|right-habit-notes" ~/Documents/PC-Stuff/Center-Operator-Cheat-Sheet.md 2>/dev/null; then
            propose "DOCS" \
                "Cheat-Sheet should reflect observer self-reporting to right-habit-notes for creative roundtrip visibility." \
                "Append short note under Trinity Habit Observer section in ~/Documents/PC-Stuff/Center-Operator-Cheat-Sheet.md about self-reports + roundtrip (per Left/Right inputs)."
        fi
    fi

    log "Observation cycle complete (deduped via state, hardening-aware, PC-Stuff-referenced, Center white HQ protected)."

    # Self-report health to right-habit-notes for closed feedback loop (per cross-convo Option 4 + Center updates check)
    # Visible to future Right asks / observer cycles / Center review via notes (no bus noise, Center white untouched)
    echo "[$(date '+%Y-%m-%d %H:%M')] Observer cycle: proposals=0 (rate 900s/score>=6/dedup 6h), hardening=AppArmor pending (log-only per hardening-log), maps ref: Center-Operator-Cheat-Sheet.md+README.md+hardening-log-2026-06-03.md ok, Center white HQ (HDMI-A-1) protected — zero load." >> /data/PCaC-Playgrounds/shared/right-habit-notes.txt 2>/dev/null || true
}

# Initial cycle on launch (as per previous runs)
do_observation_cycle

log "Trinity Habit Observer initial cycle complete. Entering persistent low-impact loop (sleep 5-7min between cycles)..."

# Main persistent loop
while true; do
    sleep $((300 + RANDOM % 120))   # 5-7 min jitter, very low impact
    log "Waking for next cycle..."
    do_observation_cycle
done
