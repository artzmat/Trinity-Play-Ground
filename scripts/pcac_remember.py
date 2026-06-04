#!/usr/bin/env python3
"""Record a persistent fact into a side's MEMORY.md (Center-curated).

Usage:
  python3 pcac_remember.py left "User prefers checklists and numbered steps for plans."
  python3 pcac_remember.py right "Current vibe thread: lo-fi beats while exploring creative writing."

Appends under a '## Curated facts (Center)' section with a date stamp.
Safe for hand-editing the .md files too.
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def persona_memory_path(side: str) -> Path:
    name = "left-brain" if side == "left" else "right-brain"
    return REPO / "personas" / name / "MEMORY.md"


def ensure_curated_section(content: str) -> str:
    """Ensure a '## Curated facts (Center)' section exists. Return (possibly modified) content."""
    header = "## Curated facts (Center)"
    if header in content:
        return content
    # Append at end, with a blank line before if needed
    if content.rstrip():
        return content.rstrip() + "\n\n" + header + "\n"
    return header + "\n"


def append_fact(content: str, fact: str) -> str:
    """Append a dated bullet to the Curated facts section. Keeps clean markdown spacing."""
    date = datetime.now().strftime("%Y-%m-%d")
    bullet = f"- [{date}] {fact.strip()}\n"
    header = "## Curated facts (Center)"

    lines = content.splitlines(keepends=True)

    # Locate the curated section and a good insertion point after its placeholder content
    insert_idx = None
    header_line_idx = None
    for i, line in enumerate(lines):
        if line.strip() == header:
            header_line_idx = i
            insert_idx = i + 1
            continue
        if insert_idx is not None and line.strip().startswith("## ") and line.strip() != header:
            insert_idx = i
            break

    if header_line_idx is None:
        # No section yet — ensure_section should have added it, but fall back
        if content.rstrip():
            content = content.rstrip() + "\n\n" + header + "\n"
        else:
            content = header + "\n"
        lines = content.splitlines(keepends=True)
        insert_idx = len(lines)

    # Ensure a blank line before the new bullet if the previous content line isn't blank
    if insert_idx > 0 and lines[insert_idx-1].strip() and not lines[insert_idx-1].strip().startswith("-"):
        lines.insert(insert_idx, "\n")
        insert_idx += 1

    lines.insert(insert_idx, bullet)

    # Make sure the following header (if any) has a blank line before it
    # (we'll clean trailing newlines at the end of insert)
    result = "".join(lines)
    # Light cleanup: ensure exactly one blank line before any following ## header
    result = re.sub(r"\n(## [^\n]+)", r"\n\n\1", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Record fact into side MEMORY.md")
    parser.add_argument("side", choices=["left", "right"], help="left or right brain")
    parser.add_argument("fact", help="The memorable fact or preference (one line recommended)")
    args = parser.parse_args()

    mem_path = persona_memory_path(args.side)
    mem_path.parent.mkdir(parents=True, exist_ok=True)

    if not mem_path.exists():
        mem_path.write_text("# " + ("Left-Brain" if args.side == "left" else "Right-Brain") + " — persistent memory\n\n", encoding="utf-8")

    original = mem_path.read_text(encoding="utf-8")
    with_section = ensure_curated_section(original)
    updated = append_fact(with_section, args.fact)

    if updated != original:
        mem_path.write_text(updated, encoding="utf-8")
        print(f"Recorded for {args.side}: {args.fact}")
        print(f"Updated: {mem_path}")
    else:
        print("No change (fact may already be present in identical form).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
