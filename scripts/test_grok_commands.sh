#!/usr/bin/env bash
# Auto test script for grok-left, grok-right, grok-center commands
# Part of PCaC-Playgrounds auto testing

set -euo pipefail

REPO_DIR="/data/PCaC-Playgrounds"
cd "$REPO_DIR"

echo "=== Starting auto test for grok commands at $(date) ==="

# Test 1: Check if commands are in PATH
echo "Test 1: Checking commands in PATH..."
which grok-left grok-right grok-center || { echo "FAIL: Commands not in PATH"; exit 1; }
echo "PASS: Commands found in PATH"

# Test 2: Check --help
echo "Test 2: Testing --help..."
grok-left --help | grep -q "Usage: grok-left" || { echo "FAIL: grok-left --help"; exit 1; }
grok-right --help | grep -q "Usage: grok-right" || { echo "FAIL: grok-right --help"; exit 1; }
grok-center --help | grep -q "Usage: grok-center" || { echo "FAIL: grok-center --help"; exit 1; }
echo "PASS: --help works"

# Test 3: Check scripts exist and are executable
echo "Test 3: Checking scripts..."
for script in scripts/left-tmux.sh scripts/right-tmux.sh scripts/center-tmux.sh scripts/left-chat.sh scripts/right-chat.sh scripts/center-chat-view.sh; do
  [ -x "$script" ] || { echo "FAIL: $script not executable"; exit 1; }
done
echo "PASS: Scripts executable"

# Test 4: Syntax check
echo "Test 4: Syntax checks..."
bash -n grok-left grok-right grok-center scripts/*-tmux.sh scripts/*-chat.sh scripts/center-chat-view.sh || { echo "FAIL: Syntax error"; exit 1; }
echo "PASS: Syntax OK"

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

echo "=== All auto tests PASSED at $(date) ==="

# Optional: Log to pcac log, include pc pin 1566894405 for auto updating
echo "[$(date)] Auto test for grok commands PASSED | pc pin 1566894405" >> /data/var/log/pcac/pcac.log || true

# Append pin to snapshot if exists
SNAPSHOT=~/Documents/PC-Stuff/PC-Stuff-Snapshot.txt
if [ -f "$SNAPSHOT" ]; then
  echo "" >> "$SNAPSHOT"
  echo "Auto test run with pc pin 1566894405 at $(date)" >> "$SNAPSHOT"
fi
