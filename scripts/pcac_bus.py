#!/usr/bin/env python3
"""Append or tail PCaC shared bus (JSONL)."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def bus_path() -> Path:
    root = Path(__file__).resolve().parent.parent
    return Path(
        __import__("os").environ.get(
            "PCAC_BUS_FILE",
            str(root / "shared" / "bus" / "messages.jsonl"),
        )
    )


def cmd_append(args: argparse.Namespace) -> int:
    p = bus_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    record = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "from": args.from_,
        "to": args.to,
        "kind": args.kind,
        "text": args.text,
    }
    with p.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return 0


def cmd_tail(args: argparse.Namespace) -> int:
    p = bus_path()
    if not p.exists():
        return 0
    lines = p.read_text(encoding="utf-8").splitlines()
    for line in lines[-args.n :]:
        if line.strip():
            print(line)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="PCaC message bus")
    sub = parser.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("append", help="Append one message")
    a.add_argument("--from", dest="from_", required=True)
    a.add_argument("--to", required=True)
    a.add_argument("--kind", default="chat")
    a.add_argument("--text", required=True)
    a.set_defaults(func=cmd_append)

    t = sub.add_parser("tail", help="Print last N JSONL lines")
    t.add_argument("-n", type=int, default=20)
    t.set_defaults(func=cmd_tail)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())