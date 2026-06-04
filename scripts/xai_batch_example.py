#!/usr/bin/env python3
"""
xAI Batch API Example using the official xai-sdk (pip install xai-sdk).

This demonstrates creating a batch, adding multiple chat requests (cheap async processing),
and retrieving results. Perfect for bulk work like generating persona content, analyses,
or creative material for the Trinity/PCaC setup at lower cost.

The script automatically loads your XAI_API_KEY from the standard location
used by your PCaC setup (~/.config/xai/api-key) or the environment variable.

Usage (after `pip install xai-sdk` or in a venv that has it):
  xai-batch-example "my_trinity_personal_batch"

  # Or directly
  python /data/PCaC-Playgrounds/scripts/xai_batch_example.py "demo_batch"

See full docs: https://docs.x.ai/developers/advanced-api-usage/batch-api
"""

import os
import sys
import time
from xai_sdk import Client
from xai_sdk.chat import system, user

def load_xai_key():
    """Load key preferring the PCaC / xAI standard location."""
    key = os.getenv("XAI_API_KEY")
    if key:
        return key
    key_file = os.path.expanduser("~/.config/xai/api-key")
    if os.path.exists(key_file):
        with open(key_file) as f:
            key = f.read().strip()
        os.environ["XAI_API_KEY"] = key
        return key
    raise RuntimeError(
        "No XAI_API_KEY found.\n"
        "Set the environment variable or place your key in ~/.config/xai/api-key\n"
        "(your PCaC setup already manages this file)."
    )

def main(batch_name: str = "your_first_batch"):
    api_key = load_xai_key()
    print(f"Using XAI API key: {api_key[:12]}... (from env or ~/.config/xai/api-key)")

    client = Client()  # Automatically uses XAI_API_KEY from environment

    # 1. Create a new batch
    batch = client.batch.create(batch_name=batch_name)
    batch_id = batch.batch_id
    print(f"\nCreated batch: {batch_id}")
    print(f"  Name: {batch.name}")

    # 2. Prepare example batch requests.
    # Customize these for your Trinity use cases (personal files, mood-sync, hardening, creative, etc.)
    batch_requests = []

    # Left-brain style analytical request about personal files
    chat = client.chat.create(
        model="grok-4.3",
        batch_request_id="left_personal_analytical",
    )
    chat.append(system(
        "You are Left-Brain: analytical, structured, chill, privacy-conscious. "
        "Use exactly this format:\n"
        "1. **Bottom line** (1-2 sentences)\n"
        "2. **Analysis** (bullets with risks, data, assumptions)\n"
        "3. **Suggested next action** (one concrete, reversible step)"
    ))
    chat.append(user(
        "We want to safely expose parts of Google Drive and ~/Documents/Matt "
        "(Health, House, Marriage legal docs, Military records) to the Left and Right "
        "personas on separate monitors while keeping the Center white desktop (HDMI-A-1) "
        "completely clean and untouched. Propose a plan using /data mounts, symlinks, "
        "and the existing PCaC usual launchers."
    ))
    batch_requests.append(chat)

    # Right-brain creative request
    chat = client.chat.create(
        model="grok-4.3",
        batch_request_id="right_creative_personal",
    )
    chat.append(system(
        "You are Right-Brain: creative, playful, vibe/options focused, compact. "
        "Give numbered fun ideas and keep responses engaging but not overwhelming."
    ))
    chat.append(user(
        "Suggest 5 creative, low-stimulation ways to turn family photos, memes, "
        "and ambient media from Google Drive / Pictures/Personal into background "
        "stories or visual flows that run while gaming on the Right monitor (DP-2), "
        "optionally triggered by mood-sync from the creative layer."
    ))
    batch_requests.append(chat)

    # Center orchestration request
    chat = client.chat.create(
        model="grok-4.3",
        batch_request_id="center_orchestration",
    )
    chat.append(system(
        "You are Center Grok: the orchestrator. Protect the white personal desktop, "
        "coordinate via shared bus/logs, prefer local-first tools, keep everything "
        "reversible and auditable. Propose thin, low-load solutions."
    ))
    chat.append(user(
        "Design the thinnest possible integration so Left and Right can access "
        "role-appropriate personal files and Google Drive (mounted at /data/gdrive) "
        "via their 'usual' launchers and browsers, without ever touching the Center "
        "monitor's desktop or mental load. Include how the new trinity-habit-observer "
        "could propose future tweaks."
    ))
    batch_requests.append(chat)

    print(f"Prepared {len(batch_requests)} requests for batch.")

    # 3. Add requests to the batch
    client.batch.add(batch_id=batch_id, batch_requests=batch_requests)
    print(f"Added {len(batch_requests)} requests to batch {batch_id}")

    # 4. Poll until complete (batches are cheaper async jobs)
    print("\nWaiting for batch to process (usually fast for small batches)...")
    for attempt in range(60):
        b = client.batch.get(batch_id)
        st = b.state
        pending = getattr(st, "num_pending", 0)
        success = getattr(st, "num_success", 0)
        failed = getattr(st, "num_failed", 0)
        print(f"  [{attempt:02d}] total={st.num_requests} pending={pending} success={success} failed={failed}")
        if pending == 0:
            break
        time.sleep(5)

    # 5. Retrieve and print results
    print("\n=== Batch Results ===")
    results_resp = client.batch.list_batch_results(batch_id)
    for res in results_resp.results:
        rid = getattr(res, "batch_request_id", "unknown")
        if hasattr(res, "response") and res.response:
            content = getattr(res.response, "content", "(no content)")
            print(f"\n[{rid}]\n{content}\n")
        else:
            print(f"\n[{rid}] (error or no response): {res}")

    print(f"\nBatch {batch_id} finished.")
    print("You can inspect more with:")
    print(f"  client.batch.get('{batch_id}')")
    print("  client.batch.list()   # all your batches")

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "your_first_batch"
    main(name)
