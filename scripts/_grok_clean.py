#!/usr/bin/env python3
"""One-shot Grok reference cleaner. Run from repo root.

Usage: python3 scripts/_grok_clean.py
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (regex_pattern, replacement) pairs applied to all text files
REPLACEMENTS = [
    # Bus kind: center_query -> center_query
    (r"\bgrok_query\b", "center_query"),
    # Persona labels
    (r"Center \(ask both", "Center (ask both"),
    (r"Center \(to", "Center (to"),
    (r"Center \(orchestrator\) Grok", "Center"),
    (r"Center \(orchestrator\) can view both", "Center can view both"),
    # Comment / banner updates
    (r"Orchestrator / Center brain lives here",
     "Orchestrator / Center brain lives here"),
    (r"CENTER VIEW: BOTH CHATS", "CENTER VIEW: BOTH CHATS"),
    (r"asking Center", "asking Center"),
    (r"visible in center-monitor", "visible in center-monitor"),
    # Three-persona comment header
    (r"Three-Persona setup \(Left Grok, Right Grok, Center\)",
     "Three-Persona setup (Left-Brain, Right-Brain, Center)"),
    (r"Three-Persona setup \(Left, Right, Center\)",
     "Three-Persona setup (Left-Brain, Right-Brain, Center)"),
    # Window/launcher references
    (r"\bleft-watch/right-watch/center-monitor\b",
     "left-watch / right-watch / center-monitor"),
    # 'grok:' prefix chat triggers -> 'center:'
    (r'"grok: \.\.\."', '"center: ..."'),
    (r"'grok: \.\.\.'", "'center: ..."),
    (r"\bgrok: queries are addressed to Center orchestrator\b",
     "center: queries are addressed to Center orchestrator"),
    (r"\bgrok: \*/\)?", "center: */)"),
    # User-facing references in chats
    (r"center: → Center", "center: → Center"),
    (r"center: your question", "center: your question"),
    (r"grok: \.\.\.", "center: ..."),
    (r"'grok: \.\.\.'", "'center: ...'"),
    (r"Left-Brain persona", "Left-Brain persona"),
    (r"Right-Brain persona", "Right-Brain persona"),
    (r"Left-Brain", "Left-Brain"),
    (r"Right-Brain", "Right-Brain"),
    (r"Center", "Center"),
    (r"Center", "Center"),
    (r"\bGrok CLI\b", "LM Studio CLI"),
    (r"\bGrok Center\b", "Center"),
    (r"\bGrok Online\b", "online chat"),
    (r"\bgrok\.x\.ai\b", "online chat"),
    (r"\bcloud Grok\b", "cloud API"),
    (r"\bGrok API\b", "cloud API"),
    (r"\bcloud LM Studio CLI\b", "cloud API CLI"),
    # Run/launch functions
    (r"pcac_run_brain_persona\b", "pcac_run_brain_persona"),
    (r"pcac_trinity_clip\b", "pcac_trinity_clip"),
    # Removed entirely
    (r"     ""),
    (r"Grok lives here and helps evolve the scripts\.\n", ""),
    # Misc
    (r"\bOrchestrator Grok\b", "Orchestrator"),
    (r"\bGrok persona\b", "brain persona"),
    (r"\bGrok chat box\b", "chat box"),
    (r"\bGrok TUI\b", "brain TUI"),
    (r"\bGrok context\b", "brain context"),
    (r"\bGrok account\b", "online"),
    (r"\bGrok UI\b", "Center UI"),
    (r"\bGrok web\b", "web"),
    (r"\bGrok integration\b", "brain integration"),
    (r"\bGrok interface\b", "interface"),
    (r"\bGrok monitors the bus\b", "Center monitors the bus"),
    (r"\bCenter \(orchestrator\) monitors the bus\b",
     "Center monitors the bus"),
    (r"\basked Center for help, share important updates, or 'grok:'",
     "ask Center for help, share important updates, or 'center:'"),
    (r"or 'grok:' something \(as in the old simple chat mode\)",
     "or 'center:' something (as in the old simple chat mode)"),
    # xAI/x.AI references
    (r"\bxAI API key\b", "API key"),
    (r"\bXAI_API_KEY\b", "API_KEY"),
    (r"\bxai/api-key\b", "api-key"),
    (r"\bEnsure API key is available for any direct API calls.*\n",
     ""),
    (r"\(e\.g\., if using cloud API in custom scripts\)",
     "(no longer used)"),
    # Chat labels / log prefixes
    (r"\bgrok: \b", "center: "),
    (r"\bCenter \(\.\.\.\)", "Center (...)"),
    # File: config/lmstudio.env
    (r"config/grok-lmstudio\.toml\.example", "config/lmstudio.env"),
    # Mistaken chat-mode messaging
    (r"respond from Center with pcac_center_reply\.",
     "respond from Center with pcac_center_reply."),
    (r"left\|right 'Center \(\.\.\.\)'",
     "left|right 'Center (...)'"),
    # Other
    (r"\bPLAYGROUND REQUESTED IN CENTER GROK\b",
     "PLAYGROUND REQUESTED"),
    (r"in Center:", "in Center:"),
    (r"in Center:", "in Center:"),
    (r"Center \(the orchestrator\)", "Center (the orchestrator)"),
    (r"Center \(the main orchestrator Grok, usually on the center monitor\)",
     "Center (the orchestrator, on the center monitor)"),
    (r"Center \(the main orchestrator Grok,", "Center (the orchestrator,"),
    (r"Center \(main orchestrator\)", "Center (orchestrator)"),
    (r"\bGrok Center\b", "Center"),
    (r"as Left-Brain", "as Left-Brain"),
    (r"as Right-Brain", "as Right-Brain"),
    (r"as Left\.\.\.Grok", "as Left-Brain"),
    (r"as the Left-Brain persona", "as the Left-Brain persona"),
    (r"as the Right-Brain persona", "as the Right-Brain persona"),
    (r"\bGrok in PATH\b", "command in PATH"),
    (r"left-watch / right-watch / center-monitor", "left-watch/right-watch/center-monitor"),
    (r"\(grok-left, grok-right, grok-center\)",
     "(left-watch, right-watch, center-monitor)"),
    (r"\bGrok chat box\b", "chat box"),
    (r"\bgrok_left\b", "left_brain"),
    (r"\bgrok_right\b", "right_brain"),
    (r"\b\(or the previous fourth voice\)", "(previous separate voice)"),
    (r"\bdeprecated third voice\b", "deprecated voice"),
    (r"\bcloud Grok CLIs\b", "cloud APIs"),
    (r"\bCloud Grok\b", "Cloud APIs"),
    (r"\btool agent\b", "tool agent (formerly) (formerly)"),
    (r"\bTool Agent\b", "Tool Agent (formerly) (formerly)"),
]

# File extensions to skip (binary, archives, etc.)
SKIP_EXTS = {".pyc", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".pdf",
             ".zip", ".tar", ".gz", ".bz2", ".xz", ".lock", ".sum",
             ".mod", ".ttf", ".woff", ".woff2", ".mp3", ".mp4", ".webm"}

# Directories to skip
SKIP_DIRS = {".git", "node_modules", "__pycache__", "playground",
             "shared", "secrets", "var", ".deprecated"}


def is_text(path):
    if os.path.splitext(path)[1].lower() in SKIP_EXTS:
        return False
    try:
        with open(path, "rb") as f:
            chunk = f.read(8192)
        if b"\x00" in chunk:
            return False
        return True
    except Exception:
        return False


def main():
    total_files = 0
    total_subs = 0
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            path = os.path.join(root, name)
            rel = os.path.relpath(path, REPO)
            if not is_text(path):
                continue
            try:
                with open(path, "r", encoding="utf-8") as f:
                    s = f.read()
            except Exception:
                continue
            orig = s
            for pat, repl in REPLACEMENTS:
                s = re.sub(pat, repl, s)
            if s != orig:
                n = sum(1 for a, b in zip(orig.splitlines(), s.splitlines())
                        if a != b)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(s)
                total_files += 1
                total_subs += 1
                print(f"  {rel}: cleaned")
    print(f"\nDone. {total_files} files updated, {total_subs} total pass hits.")


if __name__ == "__main__":
    main()
