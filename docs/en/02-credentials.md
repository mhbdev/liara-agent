[فارسی](../fa/02-credentials.md) · **English**

# 2. Credentials — how the agent gets access without ever seeing it

## The principle

**The AI agent never sees your API token.** Not once, not briefly, not in a
"safe" form.

This is not caution for its own sake. Anything in a model's context can end up
in a log, a cached prompt, an error report or a summary. The only token that
cannot leak that way is one that was never there.

So the flow is:

```
  your clipboard  ──►  scripts/creds.sh  ──►  encrypted file on your disk
                              │
                              └──►  injected into the CLI at run time
                                     by scripts/liara.sh

  the agent sees:  ****a1b2   and whether commands succeeded
```

The agent confirms the credential works by its **effect**, never its value.

## Getting a token

1. Open <https://console.liara.ir/API>
2. Pick an expiry. Available: 1 hour, 1 day, 7 days, 1 month, 6 months, 1 year.

   | Environment | Recommended | Why |
   |---|---|---|
   | staging | 1 month | convenient; worst case is a rebuildable test app |
   | production | 1 day or 7 days | short life is your blast-radius control |

3. Click **ساخت کلید جدید** / *Create new key*
4. Copy it immediately — **it is shown only once**

## Storing it

```bash
sh scripts/setup.sh connect staging
sh scripts/setup.sh connect production    # only when you actually need it
```

Or say "login" to the **liara-connect** agent — it runs the checks, opens a
terminal tab with this command so you can type into it, then verifies and
reports back. The conversation is in chat; the secret stays in the terminal.

Input is hidden. Nothing is echoed, logged or printed.

**This step cannot be done by an agent.** `setup.sh connect` requires a real
terminal, so an agent running it gets exit 3 and a message telling it to ask
you. That is the protection: not a rule the agent follows, a thing it cannot do.

Where it goes:

| Platform | Storage | Protection |
|---|---|---|
| Windows | `.liara/token.<env>.dpapi` | DPAPI — encrypted to your Windows user; another user on the same machine cannot read it |
| macOS / Linux | `.liara/token.<env>` | file mode `0600` — owner only |

Both are gitignored. `.liara/` is also in the agent's `permissions.deny`, so the
agent cannot read the directory even if it tries.

## Checking without exposing

```bash
sh scripts/setup.sh status
```

```
  staging     stored    ****a1b2   storage=DPAPI(user-bound)
  production  MISSING   run: sh scripts/setup.sh connect production
  CLI:        @liara/cli/9.6.0
  LIARA_ENV:  staging
```

Masked, and safe for the agent to read. Verify a token actually works:

```bash
sh scripts/setup.sh verify staging
```

## Two environments, deliberately

The agent gets **staging** by default. Production is separate and opt-in.

This turns the worst case from "your live site is gone" into "the test app is
gone, rebuild it." If you only ever set up staging, the agents remain fully
useful for monitoring, diagnosis and patch preparation.

```bash
# the agent's default
LIARA_ENV=staging sh scripts/liara.sh app list

# production, read-only — allowed
LIARA_ENV=production sh scripts/liara.sh app list

# production, write — blocked until a human approves
LIARA_ENV=production sh scripts/liara.sh deploy --app my-site
# → BLOCKED: production write without approval
```

To allow one production write:

```bash
sh scripts/approve.sh grant prod-write
```

Single use. Expires in 15 minutes. **The agent cannot create this** — a prompt
cannot write a file. That is the whole point.

## If a token leaks

Assume it is compromised the moment it appears anywhere it should not —
including in a chat message.

1. <https://console.liara.ir/API> → delete that key
2. Create a new one
3. `sh scripts/creds.sh set <env>`
4. Check `state/audit.log` for what was done with it

Short expiry limits the damage. This is why production gets 1–7 days.

## Rotation

| Token | Rotate |
|---|---|
| staging | when it expires, monthly |
| production | every 1–7 days, or immediately after anyone leaves the project |

Remove locally and revoke in the console:

```bash
sh scripts/creds.sh remove production
```

## What the agent is blocked from doing

Enforced by `scripts/guard.sh` and `permissions.deny`, not by instructions:

- reading `.liara/token.*` → blocked
- `sh scripts/creds.sh print-token` → blocked
- `cat .env` / `.env.production` → blocked
- `curl` with a token in a header → blocked
- `--api-token` on any command line → blocked
- a bare `liara` call (which would skip the wrapper) → blocked

Verify these are really active:

```bash
sh scripts/test-guard.sh
```
