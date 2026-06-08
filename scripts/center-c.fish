#!/usr/bin/env fish
# center-c — Bridge for Center (Command-R) → code-oss + Cline
#
# Writes the user's directive to ~/.tnmp/inboxes/center.md and opens the
# file in code-oss so Cline (running on the loaded Command-R GGUF in LM
# Studio, slot :3) can pick it up and execute it with tool calls.
#
# As of 2026-06-07, Center IS the local Command-R model. The previous
# separate "Tool Agent (formerly)" role is absorbed into Center, so this is the
# single tool-calling bridge for the Trinity.
#
# Usage:
#   center-c "Analyze the Bottum genealogy PDF and extract Revolutionary War service records."
#   center-c --help
#   center-c --inbox                  # just print the inbox path
#   center-c --inbox --tail           # show last 20 lines of the inbox
#
# Install:
#   cp scripts/center-c.fish ~/.config/fish/functions/center-c.fish
#   chmod +x ~/.config/fish/functions/center-c.fish
#   # (already executable in the repo; `cp` preserves the +x bit when the
#   #  source filesystem supports it; otherwise `chmod +x` after the copy.)
#
# Environment overrides:
#   CENTER_C_INBOX_DIR   default: $HOME/.tnmp/inboxes
#   CENTER_C_INBOX_FILE  default: $CENTER_C_INBOX_DIR/center.md
#   CENTER_C_EDITOR      default: code-oss   (the IDE/agent surface to open)
#   CENTER_C_HISTORY_LOG default: (unset)    (set to a file path to enable)
#
# Legacy env vars (deprecated 2026-06-07) are still honored as fallbacks
# for one release cycle so existing callers keep working:
#   TOOL_C_INBOX_DIR, TOOL_C_INBOX_FILE, TOOL_C_EDITOR, TOOL_C_HISTORY_LOG

# Help
if contains -- --help $argv; or contains -- -h $argv
    echo "center-c — Bridge for Center (Command-R) → code-oss + Cline"
    echo ""
    echo "Usage:"
    echo "  center-c \"<directive>\"            Write directive to inbox and open in code-oss"
    echo "  center-c --inbox                  Print the inbox file path"
    echo "  center-c --inbox --tail           Show last 20 lines of the inbox"
    echo "  center-c --help                   This help"
    echo ""
    echo "The directive is wrapped in a timestamped Markdown file and opened in"
    echo "code-oss. Cline (running on the Command-R GGUF in LM Studio slot :3)"
    echo "reads it and executes the task with tool calls. Response uses the"
    echo "Dispatch / Synthesis / Next Move format and ends with one of:"
    echo "  TASK COMPLETE  /  NEEDS INPUT  /  TOOL RESULT"
    echo ""
    echo "Env overrides:"
    echo "  CENTER_C_INBOX_DIR   (default: \$HOME/.tnmp/inboxes)"
    echo "  CENTER_C_INBOX_FILE  (default: \$CENTER_C_INBOX_DIR/center.md)"
    echo "  CENTER_C_EDITOR      (default: code-oss)"
    echo "  CENTER_C_HISTORY_LOG (default: unset; set to a file path to log every directive)"
    echo ""
    echo "Legacy fallbacks (deprecated 2026-06-07): TOOL_C_INBOX_DIR,"
    echo "  TOOL_C_INBOX_FILE, TOOL_C_EDITOR, TOOL_C_HISTORY_LOG."
    echo ""
    echo "See personas/center/SYSTEM.md and personas/center/TNMP-Cline-Rules.md"
    echo "for the full persona definition and Cline rules."
    exit 0
end

# Pick the first non-empty value among the candidate env-var names.
# Usage: _center_c_first_nonempty VAR1 VAR2 ...  --  returns via stdout.
function _center_c_first_nonempty
    for var in $argv
        if set -q $var; and test -n "$$var"
            echo "$$var"
            return 0
        end
    end
    return 1
end

# Resolve all config once at the top, honoring legacy fallbacks.
set _raw_inbox_dir  (_center_c_first_nonempty CENTER_C_INBOX_DIR  TOOL_C_INBOX_DIR)
set _raw_inbox_file (_center_c_first_nonempty CENTER_C_INBOX_FILE TOOL_C_INBOX_FILE)
set _raw_editor     (_center_c_first_nonempty CENTER_C_EDITOR     TOOL_C_EDITOR)
set _raw_history    (_center_c_first_nonempty CENTER_C_HISTORY_LOG TOOL_C_HISTORY_LOG)

# Strip trailing slashes for canonical paths.
if test -n "$_raw_inbox_dir"
    set inbox_dir (string replace -r '/$' '' -- "$_raw_inbox_dir")
else
    set inbox_dir "$HOME/.tnmp/inboxes"
end
if test -n "$_raw_inbox_file"
    set inbox_file (string replace -r '/$' '' -- "$_raw_inbox_file")
else
    set inbox_file "$inbox_dir/center.md"
end
if test -n "$_raw_editor"
    set editor "$_raw_editor"
else
    set editor "code-oss"
end
set history_log "$_raw_history"

if contains -- --inbox $argv
    echo "Inbox dir:  $inbox_dir"
    echo "Inbox file: $inbox_file"
    if test -f "$inbox_file"
        echo ""
        echo "Last modified: $(date -r "$inbox_file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -c '%y' "$inbox_file" 2>/dev/null || echo unknown)"
        echo "Size:         $(wc -c < "$inbox_file") bytes"
    else
        echo ""
        echo "(inbox file does not exist yet — run 'center-c \"<directive>\"' to create it)"
    end
    if contains -- --tail $argv
        echo ""
        echo "--- last 20 lines ---"
        if test -f "$inbox_file"
            tail -n 20 "$inbox_file"
        else
            echo "(empty)"
        end
    end
    exit 0
end

# Sanity: need a directive
if test (count $argv) -eq 0
    echo "center-c: missing directive" >&2
    echo "  Usage: center-c \"<directive>\"" >&2
    echo "  Try:   center-c --help" >&2
    exit 2
end

# Ensure inbox dir exists
mkdir -p "$inbox_dir"

# Build the directive body (join $argv with spaces, like a single sentence)
set directive (string join ' ' -- $argv)
set ts (date '+%Y-%m-%d %H:%M:%S')

# Write the file. We use a single block (no append) so the inbox always
# reflects the *latest* directive (Cline reads the top of the file).
set tmpfile (mktemp "$inbox_dir/.center.XXXXXX.md")
printf '# Center Directive (Command-R on slot :3)\n' > "$tmpfile"
printf 'Timestamp: %s\n' "$ts" >> "$tmpfile"
printf '\n' >> "$tmpfile"
printf '%s\n' "$directive" >> "$tmpfile"
printf '\n---\n' >> "$tmpfile"
printf 'You are Center. Use Dispatch / Synthesis / Next Move. Act with tools where appropriate.\n' >> "$tmpfile"
printf '\n' >> "$tmpfile"
printf 'End your response with exactly ONE of:\n' >> "$tmpfile"
printf '  TASK COMPLETE  — work is done; summary follows\n' >> "$tmpfile"
printf '  NEEDS INPUT    — state what you need to unblock\n' >> "$tmpfile"
printf '  TOOL RESULT    — structured output (e.g. JSON) for downstream\n' >> "$tmpfile"

# Atomic move into place. Use mv so the file the IDE opens is never
# observed half-written.
mv "$tmpfile" "$inbox_file"

# Optional: also drop a chronological log alongside the inbox so a history
# of every directive is preserved (handy for "what did I ask Center to
# do last week?"). Disabled by default; flip the env to enable.
if test -n "$history_log"
    set histdir (dirname "$history_log")
    mkdir -p "$histdir"
    printf '## %s\n\n%s\n\n' "$ts" "$directive" >> "$history_log"
end

# Surface a one-liner so the terminal shows what just happened.
echo "[center-c] $ts  →  $inbox_file"
echo "[center-c] directive: $directive"

# Open in the editor (default: code-oss). If code-oss is not on PATH, fall
# back to a friendly error but don't fail the write — the inbox file is
# already saved and can be opened manually.
if command -q "$editor"
    "$editor" "$inbox_file" &
    set editor_pid $last_pid
    echo "[center-c] opened in $editor (pid $editor_pid)"
else
    echo "[center-c] NOTE: '$editor' not found on PATH. The directive is saved at:" >&2
    echo "           $inbox_file" >&2
    echo "           Open it manually in your IDE (or set CENTER_C_EDITOR)." >&2
end
