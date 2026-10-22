# CLAUDE.md

**Read [AGENTS.md](AGENTS.md) first — it is the binding contract for every agent
in this project.** This file only adds Claude Code specifics.

## Enforcement that is active here

- `.claude/settings.json` wires `scripts/guard.sh` as a **PreToolUse hook on
  Bash**. It blocks destructive commands, credential reads and unapproved
  production writes.
- `permissions.deny` blocks reads of `.liara/**` and `.env*`, and edits to
  `guard.sh`, `approve.sh` and `settings.json` — so an agent cannot quietly
  disarm its own guardrails.
- Verify both are live before trusting them: `sh scripts/doctor.sh` runs a guard
  self-test. Regression suite: `sh scripts/test-guard.sh`.

## Subagents

Delegate operations rather than running them inline:

| Say this | Agent |
|---|---|
| login / connect account / credentials / «ورود» «اتصال حساب» | `liara-connect` |
| configure the project / «راه‌اندازی پروژه» | `liara-onboarding` |
| deploy / publish / «منتشر کن» | `liara-deploy` |
| is it up / status / «وضعیت سایت» | `liara-sre` |
| which plan / «کدوم پلن» | `liara-plan-advisor` |
| fix it / why broken / «درستش کن» | `liara-debug-fix` |

## Slash commands

`/liara-login` · `/liara-setup` · `/liara-deploy` · `/liara-status` ·
`/liara-plan` · `/liara-diagnose` · `/liara-report`

Start with `/liara-login`. The token step needs a real terminal — open a
terminal tab for the user and run `sh scripts/setup.sh connect staging` there,
so they can type without leaving the conversation. Never ask for a token in
chat.

## Skill

`.claude/skills/liara-ops/SKILL.md` — the verified Liara CLI and API reference.
Load it before any Liara operation.

## Windows note

Hooks and scripts run under Git Bash (`sh`). If `sh` is not on PATH the hook
fails and commands may run **unguarded**. `sh scripts/doctor.sh` checks this
explicitly — run it before relying on any protection described above.
