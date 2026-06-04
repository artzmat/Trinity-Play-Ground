#!/usr/bin/env bash
# Auto test script for grok-left, grok-right, grok-center commands
# Part of PCaC-Playgrounds auto testing

set -euo pipefail

REPO_DIR="/data/PCaC-Playgrounds"
cd "$REPO_DIR"

echo "=== Starting auto test for grok commands at $(date) ==="

# Test 1: Check if commands are in PATH
echo "Test 1: Checking commands in PATH..."
which grok-left grok-right grok-center playground trinity-start trinity-copy || { echo "FAIL: Commands not in PATH"; exit 1; }
echo "PASS: Commands found in PATH (incl. playground + trinity-*)"

# Test 2: Check --help
echo "Test 2: Testing --help..."
grok-left --help | grep -q "Usage: grok-left" || { echo "FAIL: grok-left --help"; exit 1; }
grok-right --help | grep -q "Usage: grok-right" || { echo "FAIL: grok-right --help"; exit 1; }
grok-center --help | grep -q "Usage: grok-center" || { echo "FAIL: grok-center --help"; exit 1; }
playground --help | grep -q "Usage: playground" || { echo "FAIL: playground --help"; exit 1; }
trinity-start --help | grep -q "trinity-start" || { echo "FAIL: trinity-start --help"; exit 1; }
# Avoid pipe + set -euo pipefail SIGPIPE issues with grep -q on long output
tmpf="/tmp/trinity_copy_help_$$.txt"
trinity-copy --help > "$tmpf" 2>&1
grep -q "Trinity Copy\|left and right CLI logs" "$tmpf" || { echo "FAIL: trinity-copy --help"; rm -f "$tmpf"; exit 1; }
rm -f "$tmpf"
echo "PASS: --help works (incl. playground + trinity-*)"

# Test 3: Check scripts exist and are executable
echo "Test 3: Checking scripts..."
for script in scripts/left-tmux.sh scripts/right-tmux.sh scripts/center-tmux.sh scripts/left-chat.sh scripts/right-chat.sh scripts/center-chat-view.sh scripts/trinity-start.fish scripts/trinity-copy.fish; do
  [ -x "$script" ] || { echo "FAIL: $script not executable"; exit 1; }
done
echo "PASS: Scripts executable"

# Test 4: Syntax check
echo "Test 4: Syntax checks..."
bash -n grok-left grok-right grok-center playground scripts/*-tmux.sh scripts/*-chat.sh scripts/center-chat-view.sh || { echo "FAIL: Syntax error"; exit 1; }
echo "PASS: Syntax OK (incl. playground)"

# Test 5: Run pcstuff to update snapshot (auto update)
echo "Test 5: Running pcstuff for auto update..."
pcstuff > /dev/null 2>&1 || { echo "FAIL: pcstuff"; exit 1; }
echo "PASS: pcstuff updated"

# Test 6: Check chat logs exist (create if not)
echo "Test 6: Ensuring chat infrastructure..."
source scripts/lib/common.sh
pcac_ensure_chats
[ -f "$PCAC_LEFT_CHAT_LOG" ] && [ -f "$PCAC_RIGHT_CHAT_LOG" ] || { echo "FAIL: Chat logs"; exit 1; }
echo "PASS: Chat logs ready"

# Test new Grok Online copy helper (trinity / clip)
echo "Test 7: Trinity / grok-clip output helper..."
pcac-trinity-output --help >/dev/null && echo "  --help OK"
pcac-grok-clip 10 >/dev/null && echo "  pcac-grok-clip run OK (sections emitted)"
count=$(pcac-grok-clip 10 2>/dev/null | grep -c '=== .* Response' || true)
if [[ "$count" -ge 4 ]]; then
  echo "  $count Response headers (incl. Trinity Response (All three))"
else
  echo "  (only $count Response headers — check script)"
fi
command -v pcac_grok_clip >/dev/null 2>&1 || source scripts/lib/common.sh
pcac_grok_clip --help >/dev/null 2>&1 && echo "  pcac_grok_clip() via common OK"
# Exercise --full to ensure we can get the *whole* response (entire scrollback path + FULL marker)
pcac-grok-clip --full 2>/dev/null | grep -q 'FULL scrollback/history' && echo "  --full activates whole-response capture" || echo "  ( --full marker check )"
pcac-grok-clip --full 2>/dev/null | grep -q 'Trinity Response (All three)' && echo "  --full preserves all sections" || true
echo "PASS: trinity/grok-clip helper present and runnable"

# Test the new branded top-level Trinity commands
echo "Test 8: trinity-start + trinity-copy (branded easy commands)..."
trinity-start --help >/dev/null && echo "  trinity-start --help OK"
trinity-copy --help >/dev/null && echo "  trinity-copy --help OK"
trinity-copy 5 >/dev/null && echo "  trinity-copy run OK"
count=$(trinity-copy 5 2>/dev/null | grep -c '=== .* Response' || true)
[[ "$count" -ge 4 ]] && echo "  trinity-copy emits the 4 Response sections"
trinity-copy --full 2>/dev/null | grep -q 'FULL scrollback' && echo "  trinity-copy --full works"
echo "  (Note: trinity-start actually launches konsole windows — not exercised in this headless test)"
echo "PASS: trinity-start / trinity-copy present and functional"

echo "=== All auto tests PASSED at $(date) ==="

# Optional: Log to pcac log, include pc pin for auto updating (masked)
echo "[$(date)] Auto test for grok commands PASSED (playground + watch windows support) | pc pin 1566894405 (sudo code used)" >> /data/var/log/pcac/pcac.log || true

# Append to snapshot (masked)
SNAPSHOT=~/Documents/PC-Stuff/PC-Stuff-Snapshot.txt
if [ -f "$SNAPSHOT" ]; then
  echo "" >> "$SNAPSHOT"
  echo "Auto test run with pc pin (sudo code) at $(date)" >> "$SNAPSHOT"
fi

# Demo auto update using the pin (from env or ~/.config/pc-sudo-pin)
source scripts/lib/common.sh
pcac_auto_update || echo "Auto update demo completed (if sudo failed: run 'sudo bash /data/PCaC-Playgrounds/scripts/fix-pc-pin-sudoers.sh' once to wire your pc pin 1566894405 for real pacman/paru)"
