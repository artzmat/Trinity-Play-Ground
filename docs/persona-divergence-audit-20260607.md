# Persona Divergence Audit — 2026-06-07

## TL;DR

Three personas (Left-Brain, Right-Brain, Center) were each asked the same generic
question about Code-OSS. The three responses are **near-interchangeable** and do
**not** reflect the personas' defined identities. Left and Right collapse into the
same "Certainly! Here are 8 numbered categories" template. Center produces a
slightly more condensed variant but still no orchestrator framing. The Trinity is
currently a single generic LLM wearing three different name tags.

**Severity: high.** The whole point of the three-persona setup is differentiated
perspectives. Today, they are not differentiated.

---

## Per-Persona Comparison

| Persona | Defined identity (from SYSTEM.md / MEMORY.md) | Actual output | Format followed? |
|---|---|---|---|
| **Left-Brain** (DP-3, analytical) | **Bottom line** (1-2 sentences) → **Analysis** bullets (risks, tradeoffs, assumptions) → **Suggested next action** (exactly ONE). Concise, no hype, risks-first. | "Certainly! Code-OSS can be leveraged…" followed by **8 numbered sections** (Code Review, Version Control, Documentation, Security, Community, Performance, Cross-Platform, Continuous Learning). No Bottom line, no Analysis block, no single next action. | ❌ No |
| **Right-Brain** (DP-2, creative) | **Vibe line** → **numbered Options** (2-3) → **Soft pick with reason**. Playful, vibe-language, "what if" angles, not "the" answer. | "Certainly! Code-OSS can be harnessed…" followed by **8 numbered sections** with cosmetic word swaps ("harness" vs "leveraged", "elevate" vs "enhance", "strategic applications" vs "specific areas"). No Vibe line, no Options, no Soft pick. | ❌ No, and **indistinguishable from Left** |
| **Center** (HDMI-A-1, orchestrator) | Cloud Grok orchestrator; cross-side coordination; reads Left/Right outputs and synthesizes. *(Note: `personas/center/SYSTEM.md` did not exist at the time of this test — only `MEMORY.md`.)* | Condensed 8-item list + an extra "To leverage these capabilities" section with 4 action steps (Identify, Choose, Onboard, Monitor). Slightly more distinct from Left/Right. No orchestrator framing, no dispatch, no synthesis-of-perspectives. | ⚠️ Partially |

---

## Symptom Analysis

### 1. Left and Right collapse into the same template
Diffing the two responses at the bullet level yields **near-total semantic overlap**.
The only differences are surface-level synonyms. A user reading both side-by-side
would not be able to identify which came from the analytical brain and which from
the creative brain. This is the most damaging failure mode: the **two personas
designed to disagree are agreeing**.

### 2. Format collapse on both sides
- **Left** never produced the mandatory `Bottom line / Analysis / Suggested next action` structure.
- **Right** never produced the `Vibe / Options / Soft pick` structure.
- Both defaulted to the same "categorized numbered list" template, which is
  *neither* persona's preferred structure.

### 3. Center has no SYSTEM.md
`personas/center/SYSTEM.md` does not exist. `MEMORY.md` exists but contains only
historical decisions, not behavioral rules. Without a system prompt, the Center
persona has **no enforceable identity** — it falls back to whatever the underlying
LLM (cloud Grok or local Qwen) produces by default.

### 4. Generic-LLM fallback pattern
All three responses opened with **"Certainly!"** (or equivalent) and produced
**the same 8 sub-topics in the same order**. This is the unmistakable fingerprint
of a generic chat-tuned LLM being asked a "how can X help" question with no
behavioral conditioning. The persona files are currently treated as **labels**,
not as **active system prompts**.

---

## Root Cause

From `personas/README.md`:

> | Phase | Usage |
> |-------|--------|
> | **1b** (now) | Versioned prompts + memory templates in git |
> | **2** | `pcac_ask_left` / `pcac_ask_right` prepend SYSTEM + MEMORY to LM Studio calls |

We are functionally still in Phase 1b. The persona `SYSTEM.md` and `MEMORY.md`
files are **persisted as artifacts** but **not yet wired into the actual
inference path**. When the underlying LLM receives the user's prompt, it does so
without the persona conditioning attached.

Additional contributing factors:
- **Right-Brain SYSTEM.md is severely under-specified** (23 lines vs Left's 83).
  No anti-template-failure rules, no worked format example, no format self-check.
- **No anti-generic-list guard** exists in any persona. None of the three says
  "do NOT default to a 6-10 item categorized list." So when the underlying LLM
  is asked a list-y question, all three fall into the same trap.
- **No automated divergence test.** Nothing in the repo verifies that the three
  personas produce *different* outputs for the same prompt.

---

## Recommended Fixes (this commit)

### File changes
1. **Create `personas/center/SYSTEM.md`** — define Center as orchestrator with
   `Dispatch → Synthesis → Next Move` format. Add white-HQ protection and
   anti-generic-list guards.
2. **Strengthen `personas/right-brain/SYSTEM.md`** — add anti-template-failure
   rules, worked `Vibe → Options → Soft pick` example, format self-check, and
   a "hand off to Left/Center if no creative dimension" rule.
3. **Patch `personas/left-brain/SYSTEM.md`** — add an anti-generic-list guard
   and reinforce the existing format strictness ("Bottom line MUST be 1-2
   sentences", "Suggested next action MUST be exactly ONE step").

### Test harness
4. **Create `scripts/persona-divergence-test.sh`** — runs the same prompt
   through all three personas (via local LM Studio at `127.0.0.1:1234` or
   `pcac-ask-brain.sh`) and scores:
   - **Format presence** per persona (does Left contain "Bottom line"? does
     Right contain "Vibe" / "Options" / "soft pick"? does Center contain
     "Dispatch" / "Synthesis" / "Next Move"?)
   - **Pairwise Jaccard distance** on bullet points (Left↔Right, Left↔Center,
     Right↔Center). Higher is better; targets: >0.4 between any pair.
   - **Length sanity check** (no persona should be 5x longer than another).
   - Exits non-zero if any format check fails or if any pairwise distance is
     below threshold.

---

## Test Plan (post-fix)

1. Re-run the same Code-OSS prompt through all three personas.
2. Run `scripts/persona-divergence-test.sh "How can Code-OSS improve our
   software development processes?"`.
3. Expected results:
   - All three format checks pass.
   - Left ↔ Right Jaccard distance > 0.5 (they should genuinely disagree now).
   - Left ↔ Center distance > 0.3.
   - Right ↔ Center distance > 0.4.
4. If any check fails: the affected persona's SYSTEM.md needs another tightening
   pass. Likely culprit: missing anti-template-failure rule.

---

## Long-Term Notes (for Center's future curation)

- The Code-OSS test question is a **useful recurring probe**. Add it to a
  scheduled divergence test (e.g., weekly via `trinity-habit-observer.sh`).
- Consider adding a "persona drift" detector: track the Jaccard distance over
  time. If distances trend toward zero, the personas are converging (bad).
- Right-Brain's Qwen settings (Temp 0.75-0.9 + Mirostat) are correct for
  creative output. Left's (Temp 0.2-0.35) are correct for analytical. If Left
  and Right start producing identical outputs, **check the model slot** — they
  may be sharing a slot.
- Audit: `scripts/pcac-start-brains.sh` and `pcac-ask-brain.sh` should be
  re-read to confirm which model is loaded on `:1` (Left) vs `:2` (Right). A
  shared model would explain the collapse regardless of system prompt tuning.
