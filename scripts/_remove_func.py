#!/usr/bin/env python3
"""Remove the obsolete pcac_run_brain_persona function and xAI block from common.sh."""
p = "/data/New Monad (New Self)/Trinity-Play-Ground/scripts/lib/common.sh"
s = open(p).read()
lines = s.splitlines(keepends=True)

# Find function start: line beginning with "pcac_run_brain_persona() {"
# Find function end: next line that is exactly "}" (followed by newline)
start = None
for i, line in enumerate(lines):
    if line.startswith("pcac_run_brain_persona()"):
        start = i
        break
assert start is not None, "function start not found"

# Find the comment header above the function (consecutive '#' lines)
header = start
while header > 0 and lines[header - 1].lstrip().startswith("#"):
    header -= 1
# Also include the blank line before the comment block
if header > 0 and lines[header - 1].strip() == "":
    header -= 1

# Find function end (matching closing brace)
depth = 0
end = None
for i in range(start, len(lines)):
    for ch in lines[i]:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is not None:
        break
assert end is not None, "function end not found"
# Also drop the blank line after the closing brace if present
if end + 1 < len(lines) and lines[end + 1].strip() == "":
    end += 1

print(f"Removing lines {header+1}..{end+1} (1-indexed)")
print(f"  start: {lines[start].rstrip()}")
print(f"  end:   {lines[end].rstrip()}")
new_lines = lines[:header] + lines[end + 1:]
new_s = "".join(new_lines)
# Also remove xAI block: find the marker line and remove until EOF
xai_marker = "# Ensure xAI API key is available for any direct API calls"
if xai_marker in new_s:
    idx = new_s.index(xai_marker)
    # Walk back to the previous blank line
    while idx > 0 and new_s[idx - 1] in " \t":
        idx -= 1
    # Find the start of the line
    line_start = new_s.rfind("\n", 0, idx) + 1
    new_s = new_s[:line_start].rstrip() + "\n"
    print(f"xAI block removed (was at char {line_start})")

# Tidy blank-line clumps
import re
new_s = re.sub(r"\n{4,}", "\n\n\n", new_s)

open(p, "w").write(new_s)
print("Done.")
