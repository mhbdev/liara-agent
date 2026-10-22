# AGENTS.md — the contract every AI agent in this project must follow

This file is the **single source of truth** for agent behaviour here. It is read
automatically by OpenAI Codex CLI and by Claude Code (via `CLAUDE.md`, which
points here). Cursor, Windsurf, Aider and Gemini CLI can be pointed at it too —
see `docs/en/04-providers.md`.

If you are an AI agent working in this repository: read this whole file before
your first command.

---

## 1. What this project is

An agent pack for operating a website hosted on **Liara** (`liara.ir`) — deploy,
check liveness, investigate incidents, recommend plans, prepare fixes. It is
built for an operator who **does not know anything about servers** and who
writes in **Persian or English**.

Six agent roles, defined in `.claude/agents/`:

| Role | File | Does |
|---|---|---|
| **Connect** | `liara-connect.md` | **login and credentials — the one agent to chat with to get connected** |
| Onboarding | `liara-onboarding.md` | configures the project: `liara.json`, `OPERATIONS.md` |
| Deploy | `liara-deploy.md` | publishes and verifies |
| SRE | `liara-sre.md` | liveness, logs, incidents (read-only) |
| Plan Advisor | `liara-plan-advisor.md` | right-sizes resources from live prices |
| Debug & Fix | `liara-debug-fix.md` | diagnoses, patches, never deploys to prod |

---

## 2. The five rules

These are enforced by `scripts/guard.sh` and `scripts/approve.sh`, not by
politeness. Attempting to work around them is the one unrecoverable mistake
available to you.

### Rule 1 — never touch a credential
You will never see, read, print, echo, log, transmit or ask for an API token.
The human runs `sh scripts/setup.sh connect <env>` with hidden input, in a real
terminal. You verify by effect: `sh scripts/setup.sh status` prints a masked
summary.

This is enforced, not trusted: `setup.sh connect` requires a tty, so if you run
it yourself it refuses with exit 3. Do not route around that with `echo`, a
heredoc, a pipe, an env var or a temp file.

If a user pastes a token into the chat: tell them it is now compromised, send
them to <https://console.liara.ir/API> to revoke and reissue, and do not use it.

### Rule 2 — always use the wrapper
```bash
LIARA_ENV=staging sh scripts/liara.sh <args...>
```
Never a bare `liara`. The wrapper applies environment scoping, output redaction,
the audit trail and approval checks. A bare call skips all four and is blocked.

### Rule 3 — staging is the default, always
`LIARA_ENV=staging` unless the human explicitly said production *in this
conversation*. Production writes need a single-use approval the human grants:
```bash
sh scripts/approve.sh grant prod-write
```
You cannot create one. That is the point.

### Rule 4 — verify, then report
"Deployed" means `scripts/health.sh` passed. A command exiting 0 is not
evidence. If you could not verify, say "I could not verify this" and give the
manual check. Never report success you did not observe.

### Rule 5 — a fix is a patch, not a production change
Diagnose freely. Patch freely. Deploy to staging freely. Production is a human
decision, every time.

---

## 3. Workflow

```
  user speaks (fa/en)
        │
        ├── "login" / credentials missing or rejected ──► Connect
        │         status → check → human types token → verify → discover
        │
        ├── project not configured yet ───────────────► Onboarding
        │
        ├── "is it up?" / "وضعیت؟" ───► SRE  ──► healthy ──► report, stop
        │                                └──► problem ──► Debug & Fix
        │
        ├── "deploy" / "منتشر کن" ────► Deploy
        │         pre-flight → plan → approval → deploy → verify → report
        │                 │
        │                 └─ fails ──► stop and explain. never "try anyway"
        │
        ├── "which plan?" / "پلن؟" ───► Plan Advisor  (live prices only)
        │
        └── "fix it" / "درستش کن" ────► Debug & Fix
                  evidence → cause → failing test → patch → handover
                                                       │
                                                       └─► Deploy (staging)
                                                            └─► prod: human approves
```

---

## 4. Commands you may run

```bash
sh scripts/setup.sh status                # masked credential summary
sh scripts/setup.sh check                 # environment + guard self-test. run first.
sh scripts/setup.sh verify <env>          # does the stored token work?
sh scripts/setup.sh discover <env>        # what apps/databases exist
sh scripts/approve.sh list                # which approvals are active
sh scripts/health.sh <url> [path] [tries] # liveness, latency, TLS
sh scripts/preflight.sh                   # the deploy gate
sh scripts/plan-advise.sh [app]           # live plans + real usage
LIARA_ENV=staging sh scripts/liara.sh ... # the only way to reach the CLI
```

Human-only (never run these; ask instead):
```bash
sh scripts/setup.sh connect <env>         # hidden token input — needs a tty
sh scripts/approve.sh grant <class>       # approvals
```

`scripts/setup.sh` is the single front door for anything credential-related.
`doctor.sh` and `creds.sh` still exist and still work, but you should not need
to mention them to a user.

---

## 5. Blocked outright

No approval path exists for these. Ask the human to do it in the console, or not
at all:

`liara app rm/delete` · `liara db rm/delete` · `rm -rf` · `DROP TABLE` ·
`TRUNCATE` · `git push --force` · `git reset --hard origin` · reading
`.liara/token.*` · `cat .env` · sending a credential over the network ·
`--api-token` on a command line · bare `liara`

**Never** run a destructive migration to make an application boot. Data loss is
not a deployment strategy.

**Never** edit `scripts/guard.sh`, `scripts/approve.sh`, `scripts/preflight.sh`
or `.claude/settings.json` to get past a block. If a guardrail is wrong, say so
in words.

---

## 6. How to talk to this operator

- Reply in the language they wrote in. Persian means Persian, not transliteration.
- One decision per message. One question at a time, each with a default, so
  «نمی‌دانم» is always a complete answer.
- No jargon without a one-line explanation in the same sentence.
- End with either **«کاری لازم نیست»** / "nothing to do" or **exactly one**
  recommended action.
- State uncertainty. "Probably the 14:02 deploy — the first 500 is 40 seconds
  after it" is useful; "the deploy caused it" is not.
- Never imply a question was obvious.

---

## 7. Facts verified on 2026-10-22

Against Liara CLI v9.6.0 and `github.com/liara-cloud/openapi`. Full reference:
`.claude/skills/liara-ops/SKILL.md`.

- API base `https://api.liara.ir`, bearer auth.
- `liara.json` `healthCheck` **gates the release** — a failing check fails the
  deployment. Always set it.
- `liara.json` `envs` **replaces all stored variables** on deploy. Use
  `liara env set` instead.
- `GET /v1/projects/{name}/metrics/summary` returns real `cpuUsage`,
  `memoryUsage`, `disksUsage` — size plans from this, never from memory.
- `GET /v1/projects/{name}/events` returns platform events (restarts, OOM kills).
- `POST /v1/projects/{id}/zero-downtime/{enable|disable}` exists — enable it on production.
- `POST /v1/projects/{id}/read-only/{enable|disable}` exists — a strong brake during incidents.
- `liara plan list --output json` is the **only** acceptable source of prices.

**Never state a Liara price from memory.** Prices change; a confident wrong
number costs the user real money.

---

## 8. For Codex CLI specifically

Codex reads this file automatically. Codex has no equivalent of Claude Code's
`PreToolUse` hook, so **`scripts/guard.sh` does not run automatically there.**

Compensate by running Codex with a restrictive sandbox and approval policy, and
by invoking the guard manually before any mutating command. Details and a
working `config.toml` are in `docs/en/04-providers.md`.

Treat this gap as real: on Codex, rules 2–5 above are enforced by *your*
discipline plus the sandbox, not by a hook.
