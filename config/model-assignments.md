# PCaC Model Assignments

Single source of truth for **which model runs which persona** and at what
sampling parameters. When you change a slot, temp, or context, update this
file **and** the underlying config (`config/lmstudio.env`,
`config/lmstudio.env`).

## The three voices

| Persona | Model | Slot (LM Studio) | Temp | Top-P | Context | Max tokens | Role | Use case |
|---|---|---|---|---|---|---|---|---|
| **Left-Brain** | `qwen2.5-coder-14b` (Q4_K_M) | `:1` | 0.2-0.35 (env: 0.3) | 0.85 | 16k-32k | 2048 (env) | Analytical, structured, chill | Plans, checklists, risks-first, schedules, low-stim Q&A |
| **Right-Brain** | `qwen2.5-coder-14b` (Q4_K_M) | `:2` | 0.75-0.9 + Mirostat 2 (Tau 5) | 0.93 | 8k-16k | 768 (env) | Creative, options, playful | Naming, tone, creative direction, vibe options |
| **Center** | **`c4ai-command-r-08-2024`** (GGUF) | `:3` | **0.35** | 0.9 | **4096** | 2048 | Orchestrator + tool caller | Dispatch to Left/Right, synthesize, AND multi-step tool work in Cline |

> **Center is local, not cloud.** As of 2026-06-07, Center is Command-R
> in LM Studio on slot :3. There is no cloud API fallback.
> **Tool Agent (formerly) (the previous fourth voice) is gone** — its role is
> absorbed into Center.

## Recommended LM Studio settings (per model)

### Qwen2.5-Coder-14B Q4_K_M — Left + Right (slots :1, :2)

- **Context length:** 16384-32768 (Left), 8192-16384 (Right)
- **GPU offload:** full offload (24 GB VRAM is comfortable)
- **Seed:** fixed (reproducibility)
- **Left specifics:** `temperature=0.3`, `top_p=0.85`, `top_k=30`,
  `repetition_penalty=1.1`
- **Right specifics:** `temperature=0.75-0.9` + `mirostat=2` (Tau 5),
  `top_p=0.93`, `top_k=50`, `min_p=0.08`, `repetition_penalty=1.15`
- **Mirostat is key for Right** — it is what keeps the creative voice from
  collapsing into Qwen's "Certainly! Here are 8 sections" default.

### Command-R (c4ai-command-r-08-2024) — Center (slot :3)

These are the values that resolve the prior 400 error. Increase ctx later
only if stable.

- **Context length:** **4096** (start here; raise to 8192 only if stable)
- **GPU offload:** full offload
- **Flash Attention:** on
- **Function calling / tool calling:** **enabled**. Command-R is
  purpose-built for tool use; disable this and you lose its main advantage.
- **Temperature:** **0.35** (reliability over creativity; Command-R is a
  reasoning model, not a creative writer)
- **Top-P:** 0.9
- **Max tokens:** 2048 (start conservative; raise if you anticipate long
  tool-call chains)
- **Repetition penalty:** 1.0-1.05 (Command-R is generally well-calibrated;
  avoid aggressive penalties)

**400-error recovery ladder** (if Center starts returning 400s again):

1. Drop **context** to 2048, retry.
2. Drop **temperature** to 0.2, retry.
3. Trim the system prompt / message; retry.
4. Simplify any malformed tool call; retry.
5. Reload the model in LM Studio after every setting change.

## VRAM budget (24 GB card, 7900 XTX-class)

| Slot | Model | Approx VRAM |
|---|---|---|
| `:1` Left | Qwen 2.5-Coder-14B Q4_K_M | ~9-10 GB |
| `:2` Right | Qwen 2.5-Coder-14B Q4_K_M | ~9-10 GB |
| `:3` Center | Command-R 08-2024 GGUF (Q4/Q5) | ~7-10 GB |

> Loading all three at once is tight. Practical pattern: load `:1` + `:2`
> for chat and quick dispatch; unload one of them and load `:3` (Center)
> when you intend to drive Cline/tool work. Reload the chat pair when done.

## How slots map to launchers

| Slot | Used by |
|---|---|
| `:1` | `pcac-ask-brain.sh left ...` and `pcac-ask-both.sh` (Left) |
| `:2` | `pcac-ask-brain.sh right ...` and `pcac-ask-both.sh` (Right) |
| `:3` | `center-c "..."` (Center via Cline) — slot must be loaded manually in LM Studio |
| ~~cloud~~ | (Deprecated) `grok-center`, `grok-left`, `grok-right` — fully local as of 2026-06-07 |

## When to use which

- **Quick Q&A, planning, structure, chill:** Left-Brain (`ask: ...` from
  Left, or local Qwen on `:1`).
- **Creative options, naming, vibe, play:** Right-Brain (`ask: ...` from
  Right, or local Qwen on `:2`).
- **Cross-cutting decisions, dispatch, post to logs, AND multi-step tool
  work:** Center (`center-c "..."`, or local Command-R on `:3`).
- **Trinity is now three voices** — Left, Right, Center. The previous
  Tool Agent (formerly) (a separate Command-R slot) is absorbed into Center.

## Editing this file

When you change a slot, temp, or context here, also update:

- `config/lmstudio.env` (base URL, model ids, side-specific temps)
- `config/lmstudio.env` (the `[model.*]` sections)
- The relevant `personas/*/SYSTEM.md` and `MEMORY.md` (durable facts)
