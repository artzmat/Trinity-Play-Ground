#!/usr/bin/env bash
# fix-pc-pin-sudoers.sh
# One-time setup to make your "pc pin 1566894405" work for real PC updates.
#
# Run exactly like this (from any terminal, you will type your real sudo password once):
#   sudo bash /data/PCaC-Playgrounds/scripts/fix-pc-pin-sudoers.sh
#
# What it does (plain English for mechanic):
# - Makes sure your private pin file ~/.config/pc-sudo-pin has exactly the code "1566894405"
#   and is locked so only you can read it (600).
# - Creates a tiny "backstage pass" file in /etc/sudoers.d/ that says:
#   "matt is allowed to run pacman and paru (the update programs) without typing password every time"
#   This is ONLY for the update commands the scripts use. Reversible (just delete the file).
# - After this, the pcac_auto_update / scheduled 5min/15min / test script can run
#   "sudo pacman -Syu" etc using the pin file as marker (logs/snapshots always say "pc pin 1566894405").
# - Your real login sudo password stays secret and unchanged. The pin code is just your label for the PCaC system.
#
# Safe + reversible: rm the sudoers file anytime to go back to normal password prompts for updates.
# Everything stays in /data/PCaC-Playgrounds + your home. Git will track the script + logs (markers only).

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run this with sudo."
  echo "Correct command (copy-paste):"
  echo "  sudo bash /data/PCaC-Playgrounds/scripts/fix-pc-pin-sudoers.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-matt}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [[ -z "$TARGET_HOME" ]]; then
  TARGET_HOME="/home/$TARGET_USER"
fi

echo "=== PCaC Pin + Sudoers Fix (for updates) ==="
echo "Target user: $TARGET_USER"
echo "Home: $TARGET_HOME"
echo "Date: $(date)"
echo ""

# 1. Ensure the private pin file for the user (the "sudo code pin thing")
PIN_FILE="$TARGET_HOME/.config/pc-sudo-pin"
PIN_CODE="1566894405"
mkdir -p "$(dirname "$PIN_FILE")"
echo -n "$PIN_CODE" > "$PIN_FILE"
chown "$TARGET_USER:$TARGET_USER" "$PIN_FILE"
chmod 600 "$PIN_FILE"
echo "✓ Pin file ensured: $PIN_FILE (600, owned by $TARGET_USER, content length=$(wc -c < "$PIN_FILE"))"
echo "  (This is your personal marker only - never your login password.)"
echo ""

# 2. Create the sudoers drop-in so pacman/paru work passwordless for the scripts
SUDOERS_FILE="/etc/sudoers.d/99-pc-update-pin"
cat > "$SUDOERS_FILE" <<'SUDOEOF'
# PCaC-Playgrounds "pc pin 1566894405" auto-update support
# Lets the scripts (pcac_sudo / pcac_auto_update / test_grok_commands.sh / 5min scheduler)
# run system package updates (pacman -Syu, paru -Syu) without interactive password.
# The number in ~/.config/pc-sudo-pin is ONLY a marker for logs and snapshots.
# Auth here is by policy (NOPASSWD for these cmds only).
# Reversible: sudo rm /etc/sudoers.d/99-pc-update-pin
# User: matt (or whoever ran the fix with their SUDO_USER)

matt ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/paru
matt ALL=(ALL) NOPASSWD: /usr/bin/pacman-db-upgrade
SUDOEOF

# Make sure only root can read it (standard for sudoers.d)
chown root:root "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

echo "✓ Sudoers drop-in written: $SUDOERS_FILE (440)"
echo ""

# 3. Validate the sudoers syntax (important - prevents breaking sudo)
if visudo -c -f "$SUDOERS_FILE"; then
  echo "✓ visudo check: parsed OK"
else
  echo "ERROR: visudo check failed - removing bad file to protect your sudo"
  rm -f "$SUDOERS_FILE"
  exit 1
fi
echo ""

# 4. Test that the target user can now use sudo -n for pacman (no prompt)
echo "=== Testing passwordless update commands for $TARGET_USER ==="
if sudo -u "$TARGET_USER" sudo -n pacman -Qu >/dev/null 2>&1; then
  echo "✓ sudo -n pacman works for $TARGET_USER (no password needed)"
else
  echo "Note: sudo -n pacman test returned non-zero (may be normal if no updates, or policy not fully active yet)"
  # Still continue - the rule is there
fi

# Quick version check (user readable)
sudo -u "$TARGET_USER" pacman -Qu | head -5 || true
echo ""

# 5. Run pcstuff as the user so snapshot gets updated with the fix + pin marker
echo "=== Running pcstuff as $TARGET_USER (updates snapshot with pin) ==="
sudo -u "$TARGET_USER" bash -c '
  export PATH="$HOME/.local/bin:$PATH"
  pcstuff || true
' || true
echo "pcstuff done as user."
echo ""

# 6. Append a clear marker entry to the pcac log (as root, then fix perms)
LOG_FILE="/data/var/log/pcac/pcac.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] PC UPDATE PIN FIX + SUDOERS SETUP COMPLETE for user $TARGET_USER | pc pin 1566894405 (now real pacman/paru will work via the drop-in for auto updates, tests, pcac_auto_update)" >> "$LOG_FILE" || true
chown "$TARGET_USER:$TARGET_USER" "$LOG_FILE" 2>/dev/null || true
chmod 644 "$LOG_FILE" 2>/dev/null || true
echo "✓ Logged the pin fix + setup to $LOG_FILE with marker"
echo ""

# 7. Also run the auto test as the user (so it exercises the now-working path + appends its own pin lines)
echo "=== Running the 15min-style test as $TARGET_USER (exercises pcac_auto_update with working pin path) ==="
sudo -u "$TARGET_USER" bash -c '
  cd /data/PCaC-Playgrounds
  ./scripts/test_grok_commands.sh || true
' || true
echo ""

echo "=== DONE ==="
echo "Your pin (1566894405) is now wired so the PCaC scripts can update the PC."
echo "Reversible anytime with: sudo rm /etc/sudoers.d/99-pc-update-pin"
echo "Next time scheduled tasks or you run 'playground' or test, they will do real pacman -Syu when updates exist."
echo "All logs/snapshots still only ever reference the marker text 'pc pin 1566894405'."
echo ""
echo "You can now tell the Center Grok (or run in terminal):"
echo "  cd /data/PCaC-Playgrounds && ./scripts/test_grok_commands.sh"
echo "or just let the 5min/15min scheduled things handle it."
