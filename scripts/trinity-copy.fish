#!/usr/bin/env fish
# trinity-copy — Capture Left + Right (and Center) CLI outputs / logs
# for easy paste or file upload into Grok Online (grok.x.ai).
#
# This is the friendly "Trinity Copy" fish terminal command.
# It produces the structured:
#   === Left Response ===
#   === Right Response ===
#   === Center Response ===
#   === Trinity Response (All three) ===
#
# (with synthesis guidance tuned for the three-persona PCaC setup).
#
# The output is also *always* written as:
#   ~/Documents/PC-Stuff/Trinity.md          (the smart "Trinity File" — replaces previous, keeps useful prior Trinity Response(s) + new fresh capture)
#   ~/Documents/PC-Stuff/Trinity-Output-*.md (pure dated raw snapshots)
# A reference is appended to PC-Stuff-Snapshot.txt .
#
# Usage:
#   trinity-copy [lines]
#   trinity-copy --full          # entire scrollback (recommended to get the *whole* responses)
#   trinity-copy --full --copy   # also pipe to clipboard (if wl-copy or xclip present)
#   trinity-copy | wl-copy
#   trinity-copy --help
#
# Run this from Center after Left/Right have been thinking, cross-conversing, or after
# mood-sync / composer activity so you capture fresh full CLI log state from the sides.
#
# "To get left and right CLI logs for Grok Online" — exactly. The pane captures pull
# directly from the running Grok TUI sessions on Left and Right screens.

set IMPL /data/PCaC-Playgrounds/scripts/pcac-trinity-output.sh

if not test -x $IMPL
    echo "Error: Trinity implementation not found at $IMPL" >&2
    exit 1
end

if test (count $argv) -gt 0; and contains -- $argv[1] --help -h
    echo "trinity-copy — Capture Left + Right (and Center) CLI logs for Grok Online."
    echo "See full details and advanced usage with the underlying implementation if needed,"
    echo "or try these common forms:"
    echo "  trinity-copy --full"
    echo "  trinity-copy --full --copy"
    echo "  trinity-copy 100 | wl-copy"
    echo ""
    echo "Always also writes the Trinity File:"
    echo "  ~/Documents/PC-Stuff/Trinity.md (replaces the previous one; keeps needed prior Trinity Response block(s) + fresh capture for continuity)"
    echo "  ~/Documents/PC-Stuff/Trinity-Output-*.md (pure dated raw snapshots of each run)"
    echo "  (Reference also appended to PC-Stuff-Snapshot.txt)"
    echo "Primary fish command for \"Trinity Copy To get left and right CLI logs for Grok Online.\""
    exit 0
end

# Pass through all args to the real (bash) implementation.
# It handles --full, line counts, --copy, the Trinity file saving to PC-Stuff, etc.
exec $IMPL $argv