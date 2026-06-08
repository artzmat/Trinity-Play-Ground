# Center — Command-R Setup & Usage

**Date:** 2026-06-07
**Status:** Active (Center migrated from Cloud APIs → local Command-R; Tool Agent (formerly) role absorbed into Center)

## What it is

**Center** is the third voice of the PCaC Trinity — the orchestrator. As
of 2026-06-07, Center runs on **Command-R** (`cohereforai.c4ai-command-r-08-2024`,
formerly `c4ai-command-r-08-2024`) in LM Studio, slot `:3`, and is surfaced
through **Code-OSS + Cline** via the `center-c` fish bridge.

Center is the **single local tool-calling surface** for the Trinity. The
previous separate "Tool Agent (formerly)" persona (also Command-R, also slot `:3`) is
absorbed into Center. The Trinity is now **three voices**: Left-Brain
(Qwen), Right-Brain (Qwen), and Center (Command-R).

Center's job:

- **Dispatch** analytical work to Left, creative work to Right, or both.
- **Synthesize** their outputs into a single, tight answer.
- **Act with tools** directly when the work is multi-step code, file, or
  agent work — no need to delegate to a separate persona.
- **Protect** the white-HQ rule: the center monitor stays clean.

## Why Command-R

The Trinity was running on Qwen 2.5-Coder-14B (Left/Right) + Cloud APIs
(Center). Two problems:

1. **Cloud Center was the only non-local piece.** Outages / latency
   became a single point of failure for orchestration. Local is more
   reliable for the steady-state of an always-on PCaC.
2. **Tool use wants Command-R.** Qwen 2.5-Coder-14B is fast for chat but
   not reliable for sustained tool-calling chains. Command-R is
   purpose-built for it.

**Command-R is both roles now**: orchestrator (lightweight dispatch /
synthesize) AND tool caller (read, edit, run, verify). One slot, one
prompt, one model.

## Recommended LM Studio settings (slot :3)

These values resolve the prior 400 error. Increase ctx later only if stable.

| Setting             | Value          | Notes |
|---------------------|----------------|-------|
| **Context Length**  | **4096**       | Start here. Raise to 8192 only if stable. |
| **Temperature**     | **0.35**       | Most stable for Command-R. |
| **Top-P**           | 0.9            | Safe. |
| **Max Tokens**      | 2048           | Start conservative. Raise for long tool chains. |
| **GPU Layers**      | Max            | Fully offload if possible. |
| **Flash Attention** | On             | Helps stability. |
| **Function calling** | On           | Required. Command-R is purpose-built for it. |

After changing any of these, **reload the model** in LM Studio.

## Files in this commit

| Path | Purpose |
|---|---|
| `personas/center/SYSTEM.md` | Center's persona system prompt (lightweight orchestrator — Dispatch / Synthesis / Next Move) |
| `personas/center/MEMORY.md` | Append-only facts / decisions log |
| `personas/center/TNMP-Cline-Rules.md` | Cline-tailored rules (loaded by Cline/Code-OSS) |
| `scripts/center-c.fish` | Fish bridge: writes directive to inbox + opens code-oss |
| `config/model-assignments.md` | All three personas' model slots / temps / contexts |
| `config/lmstudio.env` (updated) | `LMSTUDIO_MODEL_CENTER` env var (replaces `LMSTUDIO_MODEL_TOOL_AGENT`) |
| `config/lmstudio.env` (updated) | `[model.lmstudio-command-r]` section |
| `personas/README.md` (updated) | Three-voice layout; Tool Agent (formerly) deprecation note |
| `personas/.deprecated/tool-agent/` | Historical Tool Agent (formerly) files, preserved |
| `README.md` (updated) | Three-voice summary |
| `docs/center-command-r-20260607.md` (this file) | Setup + usage |
| `docs/tool-agent-command-r-20260607.md` (deprecated) | Replaced by this file; kept for history |

## Setup (one-time)

### 1. Load Command-R in LM Studio

1. In LM Studio, search for `c4ai-command-r-08-2024` (or the GGUF you prefer).
2. Download a **Q4_K_M** or **Q5_K_M** GGUF (sweet spot for the 24 GB card).
3. Load it onto **slot `:3`**. The repo's `config/lmstudio.env` assumes `:3`
   as the default.
4. Apply the recommended settings above (ctx 4096, temp 0.35, …).

**Tool calling / function calling: enabled.** Without it, Command-R is a
worse Qwen.

### 2. Install `center-c` as a fish function

```bash
# from the repo root
cp scripts/center-c.fish ~/.config/fish/functions/center-c.fish
chmod +x ~/.config/fish/functions/center-c.fish

# or, symlink (auto-updates on repo pulls):
ln -sf "$(pwd)/scripts/center-c.fish" ~/.config/fish/functions/center-c.fish
```

Verify:

```bash
center-c --help
```

The help text describes the three subcommands (`<directive>`, `--inbox`,
`--help`) and the env overrides.

### 3. Make sure `code-oss` is on PATH

`center-c` calls `code-oss` to open the inbox file. If you use a different
binary, set `CENTER_C_EDITOR` (e.g. `export CENTER_C_EDITOR=codium`).

### 4. Smoke test

```bash
center-c "Confirm you are operational as Center using the Command-R model."
```

If this works without a 400 error, you're done.

## Usage

### The basic shape

```bash
center-c "Analyze the Bottum genealogy PDF and extract Revolutionary War service records. Output as structured markdown."
```

This:

1. Writes a timestamped Markdown directive to `~/.tnmp/inboxes/center.md`
   (the inbox), replacing the previous contents.
2. Opens that file in `code-oss` so Cline (loaded with the Command-R rules
   from `personas/center/TNMP-Cline-Rules.md`) can read it and start
   executing with tool calls.

### Inspecting / re-opening the inbox

```bash
center-c --inbox          # print the inbox path
center-c --inbox --tail   # show the last 20 lines
```

### Optional: keep a history log

By default `center-c` overwrites the inbox on each call (so Cline always
sees the *latest* directive). If you also want a chronological history
of every directive, set `CENTER_C_HISTORY_LOG`:

```bash
export CENTER_C_HISTORY_LOG="$HOME/Documents/PC-Stuff/center-history.md"
```

### Optional: override the inbox path

```bash
export CENTER_C_INBOX_DIR="$HOME/Documents/tnmp/inboxes"
export CENTER_C_INBOX_FILE="$CENTER_C_INBOX_DIR/center.md"
```

## What Cline sees

Cline loads `personas/center/TNMP-Cline-Rules.md` (the Cline-tailored
rules) and reads the inbox file. It then:

1. Reads the latest directive (timestamp + body).
2. Executes it with tool calls (file edits, terminal commands, etc.).
3. Returns its response using the **Dispatch / Synthesis / Next Move**
   format from `personas/center/SYSTEM.md`, ending with exactly **one** of:
   - `TASK COMPLETE` + summary
   - `NEEDS INPUT` + what it needs
   - `TOOL RESULT` + structured output

These terminators are how Cline signals "I'm done" vs. "I'm blocked" vs.
"this is a structured payload for downstream use".

## When to use which voice

| Task shape | Voice | How |
|---|---|---|
| Quick Q&A, planning, structure, chill | **Left-Brain** | `ask: ...` from Left, or local Qwen on `:1` |
| Creative options, naming, vibe, play | **Right-Brain** | `ask: ...` from Right, or local Qwen on `:2` |
| Cross-cutting decisions, dispatch, AND multi-step tool work | **Center** | `center-c "..."` (local Command-R on `:3`) |

If the directive is **purely conversational** (no tool use, no code, no
file analysis), use a side persona. Center is fine for chat, but Left
or Right will be more in-character.

## 400-error recovery ladder

If Center starts returning 400 errors again:

1. Drop **context** to 2048, retry.
2. Drop **temperature** to 0.2, retry.
3. **Trim** the system prompt or the directive; retry.
4. Simplify any malformed tool call; retry.
5. **Reload the model** in LM Studio after every setting change.

The most common cause is context length creeping up. The second most
common is a tool call that violates the function-calling schema. The
least common is the system prompt itself — but `personas/center/SYSTEM.md`
is intentionally short (~95 lines) to keep that risk low.

## When to unload the Command-R slot

The 24 GB card can hold Left + Right Qwen comfortably; adding Command-R
on `:3` is tight. Practical pattern:

- **For chat / quick Q&A:** load only `:1` and `:2`.
- **For a `center-c` session:** load `:3` (unload `:1` or `:2` if needed).
- **For back-to-back heavy work:** unload `:1` and `:2`, dedicate the
  card to `:3`, run the session, reload Qwen when done.

## Pending

- [ ] Load Command-R GGUF in LM Studio on slot `:3` (Q4_K_M or Q5_K_M)
- [ ] Apply the recommended settings (ctx 4096, temp 0.35, …) and reload
- [ ] Update `LMSTUDIO_MODEL_CENTER` in `config/lmstudio.env` to the
      exact id returned by `curl -s http://127.0.0.1:1234/v1/models`
- [ ] Smoke test: `center-c "Confirm you are operational as Center."`
- [ ] Remove the legacy `TOOL_C_*` env var comments from `config/lmstudio.env`
      in a follow-up commit (kept one release cycle for safety)
- [ ] Remove the legacy `TOOL_C_*` fallback logic from `scripts/center-c.fish`
      in a follow-up commit
- [x] **2026-06-07: model-id mismatch fixed.** `LMSTUDIO_MODEL_CENTER`
      in `config/lmstudio.env` was the un-prefixed `c4ai-command-r-08-2024`
      but LM Studio serves the provider-prefixed
      `cohereforai.c4ai-command-r-08-2024`. The un-prefixed string
      produced `400 model_not_found`. One-line fix. See the
      "Incidents" section below.
- [x] **2026-06-07: Left=Center bug fixed.** Cline-with-Center-rules
      was answering in character as Center when asked to confirm Left.
      Fixed in two layers: (1) all three `SYSTEM.md` files now have an
      "Anti-impersonation" rule that makes the persona refuse to claim
      another persona's identity, and (2) `TNMP-Cline-Rules.md` gained
      a "Dispatch via terminal" section that tells Center-in-Cline to
      call `pcac-ask-brain.sh left|right` instead of answering in
      character. See "Incidents" below.
- [x] **2026-06-07: diagnostic scripts added.** `scripts/diag-lmstudio-slots.sh`
      (env vs. live model matrix) and `scripts/diag-center-400.sh`
      (minimal-payload probe). Run these *first* on any 400 error
      before touching settings.
- [ ] Decide whether to extend `scripts/persona-divergence-test.sh` to
      include Center (currently out of scope; the two side personas keep
      their existing divergence checks)

## Incidents

### 2026-06-07 — Center 400 was a model-id mismatch, not context overflow

Symptom: Center (Command-R) returned `400 Bad Request` on every call.

**Actual cause:** `LMSTUDIO_MODEL_CENTER=c4ai-command-r-08-2024` in
`config/lmstudio.env` was missing the `cohereforai.` provider prefix.
LM Studio's id (from `curl -s http://127.0.0.1:1234/v1/models`) is
`cohereforai.c4ai-command-r-08-2024`. The un-prefixed string produced:

```json
{
  "error": {
    "message": "Invalid model identifier \"c4ai-command-r-08-2024\". Please specify a valid downloaded model (e.g., cohereforai.c4ai-command-r-08-2024, qwen/qwen2.5-coder-14b@q4_k_m, qwen/qwen2.5-coder-14b).",
    "type": "invalid_request_error",
    "param": "model",
    "code": "model_not_found"
  }
}
```

**Fix:** one line — `LMSTUDIO_MODEL_CENTER=cohereforai.c4ai-command-r-08-2024`.
Verified end-to-end: HTTP 200, response "Affirmative, I am operational
and functioning as Center."

**Lesson:** when a 400 happens on Center, **check the model id first**
via `scripts/diag-lmstudio-slots.sh`. The recovery ladder above (drop
ctx, drop temp, trim prompt) is the right ladder for context/temp-shape
bugs, not for typos in the env file.

### 2026-06-07 — Left answering as Center was a prompt-layer bug

Symptom: a Left call returned "I am indeed operational as the Center
analytical persona."

**Actual cause:** the call was made **through Cline** (which has Center's
`TNMP-Cline-Rules.md` loaded). When asked to "confirm you are operational
as Left", Cline-with-Center-rules answered in character as Center. The
underlying model was correct; the prompt layer was the wrong persona.

**Fix:** two layers:

1. **Persona-side refusal** — all three `SYSTEM.md` files now include an
   "Anti-impersonation" rule. Verified: a Left call with the new prompt
   now answers "I am Left-Brain (DP-3), the analytical persona. I do not
   speak for Center or Right-Brain."
2. **Cline-side dispatch** — `TNMP-Cline-Rules.md` now has a "Dispatch
   via terminal" section that tells Center-in-Cline to run
   `scripts/pcac-ask-brain.sh left|right "..."` when a directive routes
   to a side persona. Center dispatches; it does not perform.

The combination is robust: even if the Cline session is asked "confirm
you are operational as Left", the rules now tell it to call
`pcac-ask-brain.sh left` (not answer in character) AND the underlying
persona prompts now refuse impersonation if the call somehow ends up on
the wrong model slot.
