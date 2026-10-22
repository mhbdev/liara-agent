[فارسی](../fa/03-agents.md) · **English**

# 3. The agents — who does what

Six roles. Each has a narrow job, and the boundaries between them are the
safety design, not bureaucracy.

```
                        ┌──────────────────┐
     "login" ──────────►│     CONNECT      │  account + credentials,
                        │                  │  conversationally
                        └────────┬─────────┘
                                 │
                        ┌────────▼─────────┐
     first time ───────►│   ONBOARDING     │  liara.json,
                        │                  │  OPERATIONS.md
                        └────────┬─────────┘
                                 │
      ┌──────────────────────────┼──────────────────────────┐
      │                          │                          │
┌─────▼──────┐          ┌────────▼────────┐        ┌────────▼────────┐
│    SRE     │          │     DEPLOY      │        │  PLAN ADVISOR   │
│ read-only  │          │ gated, verified │        │  live prices    │
│ is it up?  │          │ publish + prove │        │  right-sizing   │
└─────┬──────┘          └────────▲────────┘        └─────────────────┘
      │ problem found             │ staging only
      │                          │ (prod needs human approval)
┌─────▼──────────────────────────┴──┐
│          DEBUG & FIX              │
│  evidence → cause → failing test  │
│  → patch.  NEVER deploys to prod. │
└───────────────────────────────────┘
```

## Connect — «ایجنت ورود و اتصال حساب»

`.claude/agents/liara-connect.md` · `/liara-login`

**The one agent you chat with to get logged in.** You should never need to know
that `doctor.sh`, `creds.sh` and `setup.sh` exist — you say "login" and it
drives the whole thing: checks the machine, runs the guard self-test, opens a
terminal tab for the one step that needs your keyboard, verifies the result, and
tells you what is in your account.

It handles the ordinary annoyances too: an expired token (the most common
failure, and alarming if unexplained), removing access, and "is my setup safe?".

**It cannot capture your token even by mistake.** `setup.sh connect` requires a
real terminal, so an agent running it gets exit 3. The token goes from your
clipboard to an encrypted file on your machine, and the agent only ever sees
`****a1b2` and whether commands succeeded.

**Use for:** "login", "connect my account", «ورود», «اتصال حساب», a rejected
token, adding production later.

## Onboarding — «دستیار راه‌اندازی پروژه»

`.claude/agents/liara-onboarding.md`

Takes over once you are connected: detects the project type, writes
`liara.json` (always with a `healthCheck`), and creates `OPERATIONS.md`.

Asks **one question at a time**, each with a default, so «نمی‌دانم» is always a
complete answer. Ends by writing `OPERATIONS.md` — what it created, what it
costs, which commands matter.

**Use for:** first setup, expired credentials, adding an environment.

## SRE — «ایجنت پایش»

`.claude/agents/liara-sre.md`

Answers one question with evidence: *is this site actually working for its users
right now, and if not, what changed?*

**Read-only by design.** It diagnoses and recommends; it does not fix.

The five statuses, and the two that matter most:

| status | meaning |
|---|---|
| `healthy` | 2xx/3xx, latency within budget |
| `slow` | up, but over the latency budget |
| **`flapping`** | some checks pass, some fail — the worst state to ignore |
| **`degraded`** | homepage fine, `/health` failing — users hit broken features |
| `down` | every check failed |

`flapping` and `degraded` are the two you would never notice yourself, and the
two that make "the site looks fine to me" wrong.

Investigation order, cheapest first: what changed (the last deploy is usually
the answer) → platform events → resources → dependencies → TLS/DNS → **this
project's own incident history in `state/incidents/`**.

**Use for:** "is the site up?", "it's slow", "check the logs", daily reports.

## Deploy — «ایجنت انتشار»

`.claude/agents/liara-deploy.md`

Publishes, then **proves** it worked.

```
pre-flight → plan → approval → deploy → verify → report
```

Never skips, never reorders. Pre-flight is a deterministic script, not the
agent's judgement — six checks an experienced engineer does reflexively:
tests, build, secret scan over the staged diff, `liara.json` sanity, remote env
vars, and whether the current deployment is already unhealthy.

"Deployed" means health checks passed. A command exiting 0 is not evidence. If
it cannot verify, it says "deployed but not healthy" — which is the system
working correctly.

**Use for:** "deploy", "publish", «منتشر کن», shipping an approved fix.

## Plan Advisor — «مشاور منابع»

`.claude/agents/liara-plan-advisor.md`

Recommends what to buy, with the reasoning shown.

**The rule that defines it: never state a price from memory.** Liara changes
plans and prices; a remembered number delivered confidently is worse than no
answer, because you will spend money on it. Every figure comes from
`liara plan list` at run time, plus your app's real `metrics/summary`.

Every number is labelled:

- **[measured]** — from your app's own metrics, over a stated window
- **[estimated]** — from what you told it, with the assumption written out

It also accounts for the whole bill — app + database + disk + storage — because
the database is often the bigger line and the usual surprise.

**Use for:** "which plan?", "is my server too small?", "my hosting costs too much".

## Debug & Fix — «ایجنت عیب‌یابی»

`.claude/agents/liara-debug-fix.md`

Finds the cause from evidence, then prepares a fix a human can review in two
minutes.

**Its output is a patch, not a production change.** This is the single most
important boundary in the pack. You keep the whole speed benefit of automatic
diagnosis and patching, and none of the risk of an agent with production write
access during an incident.

Method: reproduce before theorising → bounded evidence window → classify →
**quote the evidence for every claim** → rank causes with confidence →
**failing test first** → smallest change that addresses the cause → verify →
handover note.

It refuses: destructive migrations to make an app boot; editing its own
guardrails to get past a block; claiming a fix works without running it; fixing
more than one thing per patch.

**Use for:** "why is this broken?", "fix it", a failed deploy, after the SRE
agent finds something.

## Why the separation

| Boundary | Prevents |
|---|---|
| SRE is read-only | an investigation that accidentally changes things |
| Fix agent cannot deploy to prod | the published failure mode — an agent writing to production mid-incident |
| Deploy cannot skip pre-flight | shipping a broken build because it seemed urgent |
| Plan Advisor cannot use remembered prices | confident wrong advice that costs real money |
| Only Connect touches credentials | five agents that could leak a token instead of one that cannot reach it |

## Running them

**Claude Code** — real subagents, each with its own tool allowlist:

```
/liara-login   /liara-setup    /liara-status
/liara-deploy  /liara-plan     /liara-diagnose   /liara-report
```

**Codex and others** — the files are plain Markdown. Reference one in the
prompt: *"follow .claude/agents/liara-sre.md"*. See
[04-providers.md](04-providers.md).
