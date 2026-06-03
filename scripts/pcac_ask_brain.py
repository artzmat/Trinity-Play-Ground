#!/usr/bin/env python3
"""Ask Left-Brain or Right-Brain via LM Studio OpenAI-compatible API."""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CONFIG_ENV = REPO / "config" / "lmstudio.env"
HF_VENV = Path("/data/AI/venv/bin/python3")


def load_env_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def persona_dir(side: str) -> Path:
    name = "left-brain" if side == "left" else "right-brain"
    return REPO / "personas" / name


def read_persona(side: str) -> tuple[str, str]:
    d = persona_dir(side)
    system = (d / "SYSTEM.md").read_text(encoding="utf-8") if (d / "SYSTEM.md").is_file() else ""
    memory = (d / "MEMORY.md").read_text(encoding="utf-8") if (d / "MEMORY.md").is_file() else ""
    return system, memory


def api_base(cfg: dict[str, str]) -> str:
    return os.environ.get(
        "LMSTUDIO_URL",
        cfg.get("LMSTUDIO_BASE_URL", "http://127.0.0.1:1234/v1"),
    ).rstrip("/")


def resolve_model_id(side: str, base: str, cfg: dict[str, str]) -> str:
    side_key = f"LMSTUDIO_MODEL_{side.upper()}"
    if os.environ.get(f"PCAC_LM_MODEL_{side.upper()}"):
        return os.environ[f"PCAC_LM_MODEL_{side.upper()}"]
    if cfg.get(side_key):
        return cfg[side_key]
    if os.environ.get("PCAC_LM_MODEL"):
        return os.environ["PCAC_LM_MODEL"]
    if cfg.get("LMSTUDIO_MODEL"):
        return cfg["LMSTUDIO_MODEL"]
    url = f"{base}/models"
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.load(resp)
    models = data.get("data") or []
    if not models:
        raise RuntimeError("No models loaded in LM Studio — load the GGUF and start server")
    return models[0]["id"]


def chat_completion(
    base: str,
    model: str,
    system: str,
    user_text: str,
    api_key: str,
    max_tokens: int,
) -> str:
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user_text},
    ]
    body = json.dumps(
        {
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": max_tokens,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        f"{base}/chat/completions",
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        data = json.load(resp)
    choice = data["choices"][0]["message"]["content"]
    return choice.strip()


def post_chat_log(side: str, from_name: str, text: str, kind: str = "chat") -> None:
    from datetime import datetime

    log_name = "left-chat.log" if side == "left" else "right-chat.log"
    log = REPO / "shared" / log_name
    log.parent.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%H:%M:%S")
    flat = re.sub(r"\s+", " ", text).strip()
    with log.open("a", encoding="utf-8") as f:
        f.write(f"[{ts}] {from_name}: {flat}\n")
    bus_append(from_name, side, kind, text)


def bus_append(from_: str, to: str, kind: str, text: str) -> None:
    import subprocess

    subprocess.run(
        [
            sys.executable,
            str(REPO / "scripts" / "pcac_bus.py"),
            "append",
            "--from",
            from_,
            "--to",
            to,
            "--kind",
            kind,
            "--text",
            text,
        ],
        check=False,
    )


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: pcac_ask_brain.py left|right 'message' [user_label]", file=sys.stderr)
        return 2

    side = sys.argv[1].lower()
    if side not in ("left", "right"):
        print("side must be left or right", file=sys.stderr)
        return 2

    user_msg = sys.argv[2]
    user_label = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("USER", "user")

    cfg = load_env_file(CONFIG_ENV)
    base = api_base(cfg)
    api_key = cfg.get("LMSTUDIO_API_KEY", "lm-studio")
    max_tokens = int(cfg.get("LMSTUDIO_MAX_TOKENS", "512"))

    brain_name = "Left-Brain" if side == "left" else "Right-Brain"
    from_chat = f"{brain_name} ({user_label})"

    system, memory = read_persona(side)
    system_block = system
    if memory.strip():
        system_block += "\n\n---\n\n# Persistent memory\n\n" + memory

    try:
        model = resolve_model_id(side, base, cfg)
        reply = chat_completion(base, model, system_block, user_msg, api_key, max_tokens)
    except Exception as e:
        err = f"[{brain_name} offline] {e}"
        post_chat_log(side, from_chat, err, "error")
        print(err, file=sys.stderr)
        return 1

    # Flatten reply for single-line log (keep short paragraphs)
    reply_log = re.sub(r"\s+", " ", reply)
    if len(reply_log) > 2000:
        reply_log = reply_log[:1997] + "..."

    post_chat_log(side, from_chat, reply_log, "brain_reply")
    print(reply)
    return 0


if __name__ == "__main__":
    sys.exit(main())