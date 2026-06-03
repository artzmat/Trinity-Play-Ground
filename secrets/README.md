# Local secrets (not in git)

Passwords and pins for **VM guests only** — never the host `matt` account.

## Files

| File | In git? | Purpose |
|------|---------|---------|
| `vm-guest.txt.example` | Yes | Safe template — copy to `vm-guest.txt` |
| `vm-guest.txt` | **No** | Your real guest passwords (local only) |

## Setup (once)

```bash
cp secrets/vm-guest.txt.example secrets/vm-guest.txt
chmod 600 secrets/vm-guest.txt
# Edit vm-guest.txt with your editor — do not commit it
```

## Policy

See `docs/vm-guest-password-policy.md`.

## Rules

- Do **not** put host passwords or API keys here (use system keyring or `~/.config` outside git).
- Do **not** paste secrets into `personas/*/MEMORY.md`, chat logs, or Center chat.
- Prefer **unique** guest passwords per VM tier — not previously “public” pins.