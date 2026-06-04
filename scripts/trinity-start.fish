#!/usr/bin/env fish
# trinity-start — One-command start for the full Trinity of Grok CLIs on all three physical screens.
#
# Launches the small/minimized konsole + tmux + Grok persona TUI windows:
#   - Left screen (DP-3): Left-Brain persona (chill/analytical, watch + full grok CLI)
#   - Center screen (HDMI-A-1 / white HQ): Center orchestrator monitor (chat tails + bus)
#   - Right screen (DP-2): Right-Brain persona (creative/play, watch + full grok CLI)
#
# This is the easy "Trinity Start" entry point.
#
# Usage:
#   trinity-start [user-label]
#   trinity-start --help
#
# After starting: the Grok CLIs are running in the bottom panes of the small windows on each monitor.
# Use the physical screens:
#   Left: interact with Left-Brain Grok directly in its TUI (or via its chat log).
#   Right: interact with Right-Brain Grok.
#   Center: use the monitor window + your main desktop + composer + online grok.x.ai .
#
# To capture the current CLI outputs (left + right + center + trinity synthesis) for Grok Online:
#   trinity-copy [--full] [--copy]
#
# The small windows are designed to be minimized/floating so each monitor's primary use remains available.

set REPO_DIR /data/PCaC-Playgrounds

if test (count $argv) -gt 0; and contains -- $argv[1] --help -h
    echo "Usage: trinity-start [user-label]"
    echo ""
    echo "One-command 'Trinity Start' for running Grok CLIs on each of the three screens."
    echo "Opens small (960x600) minimized/floating konsole windows with tmux + the full cloud Grok TUI"
    echo "persona-injected for Left-Brain (Left monitor), Right-Brain (Right monitor), and Center monitor view."
    echo ""
    echo "Optional user-label for distinguishing 'cursors' in logs."
    echo ""
    echo "After launch, interact directly in the Grok TUIs on the side screens, or orchestrate from Center."
    echo "Later capture everything for online Grok with: trinity-copy"
    exit 0
end

set USER_LABEL (if test (count $argv) -gt 0; echo $argv[1]; else; whoami; end)

echo "=== Trinity Start ==="
echo "Starting Grok CLIs (full persona TUI + watch) on all three physical screens for user: $USER_LABEL"
echo "Left (DP-3 chill/analytical) | Center (HDMI-A-1 white HQ orchestrator) | Right (DP-2 creative/play)"
echo ""

# Launch using the existing grok-* launchers (they are bash but work fine from fish).
# They open the konsole windows with the correct geometry and run the tmux + grok persona.
grok-left $USER_LABEL &
grok-right $USER_LABEL &
grok-center &

echo ""
echo "=== Trinity Grok CLIs are now running ==="
echo "Check the three small floating/minimized windows on your physical monitors:"
echo "  • Left screen:  PCaC-Left-Screen-...  (top: watch, bottom: Left-Brain Grok CLI TUI)"
echo "  • Center screen: PCaC-Center-Monitor-Both-... (splits for Left+Right chat tails + bus)"
echo "  • Right screen: PCaC-Right-Screen-... (top: watch, bottom: Right-Brain Grok CLI TUI)"
echo ""
echo "Tips:"
echo "  - In the side Grok TUIs: type normally as that persona; use 'grok:' to ask Center."
echo "  - From Center: use center-composer, pcac_center_reply, or the bus."
echo "  - To capture the current Left/Right (and Center) CLI outputs + Trinity synthesis for Grok Online:"
echo "      trinity-copy"
echo "      trinity-copy --full --copy"
echo "    (Also saves to ~/Documents/PC-Stuff/Trinity.md for easy file upload.)"
echo ""
echo "To stop: close the small konsole windows or exit the tmux sessions inside (Ctrl-b d then exit)."
echo "Re-run trinity-start anytime to re-open (it will attach if sessions exist in some cases)."
echo ""
echo "Trinity is live. Go forth and orchestrate."