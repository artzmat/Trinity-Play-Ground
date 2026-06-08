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


def get_recent_context(side: str, n: int = 8) -> str:
    """Return a short 'Recent activity on this side' block from the side's chat log.
    Gives the brain continuity across chat restarts / reboots without full history.
    """
    log_name = "left-chat.log" if side == "left" else "right-chat.log"
    log_path = REPO / "shared" / log_name
    if not log_path.exists():
        return ""
    try:
        lines = [ln.rstrip() for ln in log_path.read_text(encoding="utf-8").splitlines() if ln.strip()]
        recent = lines[-n:]
        if not recent:
            return ""
        formatted = "\n".join(recent)
        return f"Recent messages on this side (most recent last):\n{formatted}"
    except Exception:
        return ""


def api_base(cfg: dict[str, str]) -> str:
    return os.environ.get(
        "LMSTUDIO_URL",
        cfg.get("LMSTUDIO_BASE_URL", "http://127.0.0.1:1234/v1"),
    ).rstrip("/")


def fetch_live_model_ids(base: str) -> list[str]:
    """Return the list of model ids currently loaded in LM Studio.

    Raises RuntimeError with a useful message if the server is unreachable.
    Centralized so resolve_model_id can validate the chosen id against the
    live list instead of silently falling through to the first model.
    """
    url = f"{base}/models"
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.load(resp)
    except (urllib.error.URLError, ConnectionError, TimeoutError) as e:
        raise RuntimeError(
            f"LM Studio not reachable at {url} — is the local server running?\n"
            f"  Underlying error: {e}"
        ) from e
    models = data.get("data") or []
    if not models:
        raise RuntimeError("No models loaded in LM Studio — load the GGUF and start the server")
    return [m.get("id", "") for m in models if m.get("id")]


def resolve_model_id(side: str, base: str, cfg: dict[str, str]) -> str:
    """Pick a model id for the given side, validating against live /v1/models.

    Resolution order (first match wins):
      1. PCAC_LM_MODEL_{SIDE}  env var (per-side override)
      2. LMSTUDIO_MODEL_{SIDE} from config/lmstudio.env
      3. PCAC_LM_MODEL         env var (global override)
      4. LMSTUDIO_MODEL        from config (global default)

    If the chosen id does NOT exist in /v1/models, raise RuntimeError
    with the list of available ids. This prevents the previous bug where a
    typo in the env value (e.g. `c4ai-command-r-08-2024` instead of the
    provider-prefixed `cohereforai.c4ai-command-r-08-2024`) caused a 400
    from the server, *and* the silent fallback to models[0]["id"] could
    send a Left call to the wrong slot (persona collapse). See 2026-06-07
    incident in docs/center-command-r-20260607.md.
    """
    side_key = f"LMSTUDIO_MODEL_{side.upper()}"
    chosen = None
    chosen_source = None
    if os.environ.get(f"PCAC_LM_MODEL_{side.upper()}"):
        chosen = os.environ[f"PCAC_LM_MODEL_{side.upper()}"]
        chosen_source = f"env PCAC_LM_MODEL_{side.upper()}"
    elif cfg.get(side_key):
        chosen = cfg[side_key]
        chosen_source = f"config {side_key}"
    elif os.environ.get("PCAC_LM_MODEL"):
        chosen = os.environ["PCAC_LM_MODEL"]
        chosen_source = "env PCAC_LM_MODEL"
    elif cfg.get("LMSTUDIO_MODEL"):
        chosen = cfg["LMSTUDIO_MODEL"]
        chosen_source = "config LMSTUDIO_MODEL"

    if chosen:
        # Validate against the live model list. We do this even when the
        # chosen id came from the env file, because the env file is the
        # single most common source of typos (2026-06-07 incident).
        try:
            live_ids = fetch_live_model_ids(base)
        except RuntimeError:
            # If the server is unreachable, we can't validate. Surface a
            # useful error instead of falling through to a silent fallback.
            raise
        if chosen in live_ids:
            return chosen
        # Close-match hint: did the user drop the provider prefix?
        # e.g. "c4ai-command-r-08-2024" vs "cohereforai.c4ai-command-r-08-2024"
        suffix = chosen.split("/")[-1]
        close = [m for m in live_ids if m.endswith(suffix) or suffix in m]
        hint = ""
        if close:
            hint = f"\n  Did you mean one of these loaded ids?\n    " + "\n    ".join(close)
        raise RuntimeError(
            f"Model id from {chosen_source} ('{chosen}') is not loaded in LM Studio.{hint}\n"
            f"  Run `scripts/diag-lmstudio-slots.sh` to see the env vs. live matrix."
        )

    # No configured target at all: explicitly fail loud. The old code would
    # silently pick models[0]["id"], which has caused persona collapse when
    # a slot was unloaded.
    try:
        live_ids = fetch_live_model_ids(base)
    except RuntimeError as e:
        raise RuntimeError(
            f"No LMSTUDIO_MODEL_{side.upper()} configured and server unreachable.\n  {e}"
        ) from e
    raise RuntimeError(
        f"No model id configured for side '{side}'.\n"
        f"  Set LMSTUDIO_MODEL_{side.upper()} in config/lmstudio.env to one of:\n    "
        + "\n    ".join(live_ids)
        + "\n  Then re-run. Run `scripts/diag-lmstudio-slots.sh` to diagnose."
    )


def chat_completion(
    base: str,
    model: str,
    system: str,
    user_text: str,
    api_key: str,
    max_tokens: int,
    temperature: float = 0.7,
) -> str:
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": user_text},
    ]
    body = json.dumps(
        {
            "model": model,
            "messages": messages,
            "temperature": temperature,
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

    if side == "left":
        max_tokens = int(cfg.get("LMSTUDIO_MAX_TOKENS_LEFT", cfg.get("LMSTUDIO_MAX_TOKENS", "512")))
        temperature = float(cfg.get("LMSTUDIO_TEMPERATURE_LEFT", "0.35"))
    else:
        max_tokens = int(cfg.get("LMSTUDIO_MAX_TOKENS_RIGHT", cfg.get("LMSTUDIO_MAX_TOKENS", "512")))
        temperature = float(cfg.get("LMSTUDIO_TEMPERATURE_RIGHT", "0.75"))

    brain_name = "Left-Brain" if side == "left" else "Right-Brain"
    from_chat = f"{brain_name} ({user_label})"

    system, memory = read_persona(side)
    recent = get_recent_context(side, n=8)

    system_block = system
    if memory.strip():
        system_block += "\n\n---\n\n# Persistent Memory (curated facts + context about you and ongoing work)\n\n" + memory.strip()
    if recent:
        system_block += "\n\n---\n\n# Recent activity on this side\n" + recent

    # Extra reinforcement for Left-Brain (analytical structure, low-stimulation, Center coordination)
    if side == "left":
        system_block += "\n\n---\n\n# Critical Response Rules for This Query\nAlways begin with exactly '1. **Bottom line**' (1-2 sentences). Then '2. **Analysis**' as bullets (include risks, assumptions, data). End with '3. **Suggested next action**' (exactly one concrete step, propose only). Stay concise, chill, use tools via terminal if needed for facts before replying. No hype. Prefer /data. Coordinate via pcac_post_chat or bus when appropriate."

    try:
        model = resolve_model_id(side, base, cfg)
        reply = chat_completion(base, model, system_block, user_msg, api_key, max_tokens, temperature)
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