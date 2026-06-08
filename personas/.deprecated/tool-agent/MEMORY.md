# Tool Agent — memory (append-only)

**Tool Agent** runs on Command-R (c4ai-command-r-08-2024) in LM Studio, and
is typically surfaced through Code-OSS + Cline via the `tool-c` fish bridge
(writes to `~/.tnmp/inboxes/tool-agent.md`).

This file is for **durable facts** you want in git (not a replacement for
LM Studio conversation history). Short, dated, factual.

## Repo conventions worth remembering

- Heavy data lives under `/data` (4 TB drive). Never fill the root drive.
- Persona prompts are at `personas/{left-brain,right-brain,center,tool-agent}/`.
- The Trinity (Left/Right/Center) uses Qwen2.5-Coder-14B on LM Studio slots
  `:1` (Left) and `:2` (Right); Center is cloud Grok. You are on a separate
  Command-R slot (typically `:3`, opt-in — see `config/lmstudio.env`).
- The shared bus (`shared/bus/messages.jsonl`) is for Trinity coordination.
  You do not normally post there.
- The `~/.tnmp/inboxes/tool-agent.md` inbox is your primary input surface
  when launched via `tool-c`.

## Decisions log

- 2026-06-07: Tool Agent persona created (Command-R, GGUF, slot :3 opt-in).
  Temp 0.35-0.45, Top-P 0.9, Context 8192-16384, Max 4096+. Bridge:
  `tool-c "..."` writes directive + opens Code-OSS for Cline.
- 2026-06-07: Three terminators defined for the Cline surface: `TASK COMPLETE`
  / `NEEDS INPUT` / `TOOL RESULT`.

## Pending

- LM Studio: load `c4ai-command-r-08-2024` GGUF onto a third slot (`:3`).
  Unload if VRAM pressure rises; Left/Right Qwen slots take priority.
- Confirm the exact jinja chat template for Command-R tool calling in LM
  Studio (see `config/lmstudio.env` and `grok-lmstudio.toml.example`).
- Decide whether to extend `scripts/persona-divergence-test.sh` to include
  the Tool Agent (currently out of scope; the three Trinity personas keep
  their existing divergence checks).
