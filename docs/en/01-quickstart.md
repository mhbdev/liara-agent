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
- A coding agent installed — Claude Code, Codex, Cursor, Windsurf, Aider or
  Gemini CLI. See [provider setup](04-providers.md).

## Step 0 — install the pack in your website repository

Follow [Install the agents in your own project](00-installation.md) first.
It explains downloading the pack, copying or merging its files without
replacing your existing instructions, and activating your coding environment.
Run every command below from your **website repository root**, not the
separate source copy of this pack. On Windows, use Git Bash.

## Step 1 — install the Liara CLI

```bash
npm install -g @liara/cli
```

Check it:

```bash
npm list -g @liara/cli --depth=0
```

You should see something like `@liara/cli@9.6.0`. If the command is not found,
Node's global folder is not on your PATH — reinstall Node and reopen the
terminal.

## The short version

After installing the pack and CLI, **you, the human**, can run the guided
wizard in a real terminal:

```bash
sh scripts/setup.sh
```

It does steps 2 and 3 below in order — checks, login, verification, discovery —
and tells you what to say next. In Claude Code you can also use
**`/liara-login`**. In other coding agents, ask it to follow
`.claude/agents/liara-connect.md`; token entry stays in your human terminal.

The rest of this page explains what it is doing and why.

## Step 2 — check the pack

```bash
sh scripts/setup.sh check
```

This verifies the CLI, `curl`, `git`, Node, that the hook configuration is
present, and that secrets are gitignored. It runs guard self-tests too.
Fix anything marked `[FAIL]` before continuing, then run the full suite:

```bash
sh scripts/test-guard.sh
```

These are file and script checks. Confirm your agent actually loaded the
instructions and hook using the [provider activation steps](04-providers.md).

> Why this matters: on Windows, if `sh` is missing the hook silently does not
> run, and the agent would be unguarded. Run the checks from the shell your
> coding agent uses too.

## Step 3 — connect your Liara account

```bash
sh scripts/setup.sh connect staging
```

Run this yourself in a real terminal. Saying "login" to the agent starts the
connection guidance; it must leave token entry to you.

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
[ -e .env ] || cp env.example .env
[ -e liara.json ] || cp liara.json.example liara.json
```

These commands preserve existing configuration. Review the examples for your
actual app, port and health endpoint; remove example disks or scheduled jobs
your website does not use. Do not put API tokens in `.env`.

Then let the agent do the rest — in Claude Code:

```
/liara-setup
```

In Codex or another coding agent, say: "Follow AGENTS.md and
.claude/agents/liara-onboarding.md to configure this website for staging."

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

In Claude Code, you can also use the project commands directly:

```
/liara-status      /liara-deploy      /liara-plan
/liara-diagnose    /liara-report      /liara-setup
```

## Step 6 — your first deploy

In Claude Code:

```
/liara-deploy staging
```

In other coding agents, say: "Follow AGENTS.md and
.claude/agents/liara-deploy.md to deploy to staging and verify it."
Use the sandbox and manual guard procedure in [provider setup](04-providers.md).

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
- "no credentials" → run `sh scripts/setup.sh connect staging` yourself in a
  real terminal
- "BLOCKED by scripts/guard.sh" → that is intentional; read the message, it
  names what to do
- Token rejected → it expired. Make a new one at <https://console.liara.ir/API>

## Next

- [00-installation.md](00-installation.md) — installing or updating in your own project
- [02-credentials.md](02-credentials.md) — how credentials are stored, and production
- [03-agents.md](03-agents.md) — what each agent does
- [04-providers.md](04-providers.md) — running on Claude Code, Codex, Cursor
- [05-runbook.md](05-runbook.md) — the site is down, now what
- [07-security.md](07-security.md) — what protects you, and what does not
