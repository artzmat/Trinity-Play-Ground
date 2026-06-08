#!/usr/bin/env python3
"""Final cleanup: remove obsolete functions/blocks from common.sh and other
heavy-handed removals that the regex cleaner cannot safely do automatically.
"""
import os
import re

REPO = "/data/New Monad (New Self)/Trinity-Play-Ground"
COMMON = os.path.join(REPO, "scripts/lib/common.sh")

with open(COMMON) as f:
    s = f.read()

# Remove the pcac_run_grok_persona function entirely (it exec()s `grok` CLI,
# which is no longer in the workflow). Match from the comment header through
# the closing brace.
pat_func = re.compile(
    r"# Launch the full [^\n]*\n.*?pcac_run_grok_persona\(\) \{.*?^\}\n",
    re.DOTALL | re.MULTILINE,
)
s2 = pat_func.sub("", s)
print(f"pcac_run_grok_persona removed: {s2 != s}")
s = s2

# Remove the entire xAI API key block at the bottom of the file
pat_xai = re.compile(
    r"\n\n# Ensure xAI API key is available for any direct API calls.*?(?:\Z)",
    re.DOTALL,
)
s2 = pat_xai.sub("\n", s)
print(f"xAI block removed: {s2 != s}")
s = s2

# Remove pcac_grok_clip alias function (it just delegates to trinity-output
# which has been renamed in spirit; keep only the implementation function)
pat_clip = re.compile(
    r"# Convenience alias \(some Center sessions may prefer the 'clip' name\)\npcac_trinity_output\(\) \{.*?^\}\n",
    re.DOTALL | re.MULTILINE,
)
s2 = pat_clip.sub("", s)
print(f"pcac_trinity_output alias removed: {s2 != s}")
s = s2

# Tidy any leftover blank-line clumps
s = re.sub(r"\n{4,}", "\n\n\n", s)

with open(COMMON, "w") as f:
    f.write(s)
print("common.sh final cleanup done.")
