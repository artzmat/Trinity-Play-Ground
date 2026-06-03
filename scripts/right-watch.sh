#!/usr/bin/env bash
# PCaC Right Watch Terminal
# Live git status and recent commits from the PCaC-Playgrounds repo
# Intended to run full-time on Right monitor (DP-2)
# Safe, local, no network. Reversible: just Ctrl-C or kill the terminal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== PCaC Right Watch starting ==="
echo "Repo: $REPO_DIR"
echo "Press Ctrl-C to stop this watch."
echo

# Use watch for live updating display of git
exec watch -n 5 -t "
echo '=== PCaC RIGHT MONITOR - Git Status & Commits ==='
date '+%Y-%m-%d %H:%M:%S'
echo
cd \"$REPO_DIR\"
echo '=== Git Status ==='
git status --short
echo
echo '=== Recent Commits (last 10) ==='
git log --oneline -10
echo
echo '=== Last commit details ==='
git log -1 --pretty=format:'%h - %s (%cr) <%an>%n'
echo
echo '--- (auto-refresh every 5s - Ctrl-C to exit) ---'
"