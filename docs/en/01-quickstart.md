[فارسی](../fa/01-quickstart.md) · **English**

# 1. Quickstart — from nothing to a working agent

Fifteen minutes. You do not need to understand servers, Docker, or DNS. Each
step says what it does and what happens if it fails.

## Before you start

You need:

- A **Liara account** — <https://console.liara.ir>
- **Node.js 20+** — <https://nodejs.org> (the Liara CLI needs it)
- **Git Bash** if you are on Windows — it ships with Git for Windows. The
  scripts and the safety hook run under `sh`.
- **Claude Code** or **Codex CLI** installed

## Step 1 — install the Liara CLI

```bash
npm install -g @liara/cli
```

Check it:

```bash
liara --version
```

You should see something like `@liara/cli/9.6.0`. If the command is not found,
Node's global folder is not on your PATH — reinstall Node and reopen the
terminal.

## The short version

If you would rather not read the steps, run the one wizard and let it guide you:

```bash
sh scripts/setup.sh
```

It does steps 2 and 3 below in order — checks, login, verification, discovery —
and tells you what to say next. Or chat to the agent instead: **`/liara-login`**.

The rest of this page explains what it is doing and why.

## Step 2 — check the pack

```bash
sh scripts/setup.sh check
```

This verifies the CLI, `curl`, `git`, Node, that the safety hook is wired, that
secrets are gitignored — and it runs a **self-test of the guard**, proving the
protections actually fire. Fix anything marked `[FAIL]` before continuing.

> Why this matters: on Windows, if `sh` is missing the hook silently does not
> run, and the agent would be unguarded. The doctor is how you find that out.

## Step 3 — connect your Liara account

```bash
sh scripts/setup.sh connect staging
```

Or say "login" to the agent and it will open a terminal tab running exactly
this, so you can type without leaving the conversation.

The script tells you where to click. In short:

1. Open <https://console.liara.ir/API>
2. Choose an expiry — **1 month** is right for staging
3. Create the key and copy it. **It is shown only once.**
4. Paste it when the script asks

**Your typing is hidden, and the token never reaches the AI.** This is the
single most important design decision in this pack: the agent proves the
credential works by using it, and never sees its value.

Verify:

```bash
sh scripts/setup.sh status
```

You should see `staging stored ****a1b2`. That masked form is all the agent ever
reads.

> **Why the agent cannot do this step for you:** `setup.sh connect` requires a
> real terminal. If an agent runs it, it refuses with exit 3. The protection is
> structural — the agent is not *choosing* to stay away from your token, it
> cannot reach it.

### Do not set up production yet

Seriously. The agents work fully with staging. Not giving an AI agent access to
your live site is a feature. Come back to it in
[02-credentials.md](02-credentials.md) when you actually have something to ship.

## Step 4 — configure the project

```bash
cp env.example .env
cp liara.json.example liara.json
```

Then let the agent do the rest — in Claude Code:

```
/liara-setup
```

It will ask one question at a time, with a default for every one, so **"I don't
know" is always a valid answer.** It detects your project type, writes
`liara.json`, and creates `OPERATIONS.md` describing what it set up.

Make sure `liara.json` keeps its `healthCheck` block. That is what stops a
broken version of your site from going live — the platform refuses the release
instead of serving it.

## Step 5 — use it

Say these in plain language, Persian or English:

| You say | What happens |
|---|---|
| "is the site up?" / «وضعیت سایت چطوره؟» | liveness, latency, TLS, recent errors |
| "deploy" / «منتشر کن» | pre-flight → plan → deploy → verify |
| "which plan should I buy?" / «کدوم پلن؟» | live prices + your real usage |
| "it's broken, fix it" / «درست کن» | diagnosis with evidence, then a patch |

Or use the commands directly:

```
/liara-status      /liara-deploy      /liara-plan
/liara-diagnose    /liara-report      /liara-setup
```

## Step 6 — your first deploy

```
/liara-deploy staging
```

Watch what it does, in this order — and it will not skip a step:

1. **Pre-flight** — tests, build, secret scan, config check. Fails → stops.
2. **The plan** — what changes, who is affected, cost, how to undo it.
3. **Deploy** — through the wrapper, logged.
4. **Verify** — three consecutive health checks against the real URL.
5. **Report** — the URL, what was verified, and what was *not*.

If it says "deployed but not healthy", that is the system working. It will not
tell you something is live when it is not.

## When something goes wrong

- Site down → [05-runbook.md](05-runbook.md)
- "no credentials" → `sh scripts/creds.sh set staging`
- "BLOCKED by scripts/guard.sh" → that is intentional; read the message, it
  names what to do
- Token rejected → it expired. Make a new one at <https://console.liara.ir/API>

## Next

- [02-credentials.md](02-credentials.md) — how credentials are stored, and production
- [03-agents.md](03-agents.md) — what each agent does
- [04-providers.md](04-providers.md) — running on Claude Code, Codex, Cursor
- [05-runbook.md](05-runbook.md) — the site is down, now what
- [07-security.md](07-security.md) — what protects you, and what does not
