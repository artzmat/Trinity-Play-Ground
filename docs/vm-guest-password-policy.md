# VM guest password policy (PCaC)

Host (`matt`) credentials are **out of scope** for this repo. Use `passwd` on the host only.

## Tiers

| Tier | VMs | Password strength | Rotation |
|------|-----|-------------------|----------|
| **Playground** | `playground`, legacy `right-guest` | Simple is OK — guest is disposable | Anytime; restore from snapshot |
| **Work / dev** (future) | TBD | Unique, not reused from playground | When VM role changes |
| **Sensitive** (future) | Anything with keys or `/data` mounts | Strong, random, password manager | Regular |

## Rules

1. **Never** reuse host password or host PIN for any VM.
2. **Avoid** reusing values that were posted in chat or docs — generate a dedicated guest password.
3. Store live values in `secrets/vm-guest.txt` only (`chmod 600`, gitignored).
4. VMs must stay **isolated**: no bridged trust to host SSH keys, no write access to `/data/HOME` unless intentional and reviewed.
5. Take a **snapshot** before handing a playground VM to “play” mode.

## Isolation checklist (playground)

- [ ] Guest user is not in host `wheel` / sudo on host
- [ ] No virtio-fs mount of full `/data` home tree
- [ ] Snapshot `clean` exists before experiments
- [ ] Host password not typed inside guest

## Center

Scripts and docs may say “see `secrets/vm-guest.txt`” — never embed the secret in git.