[فارسی](../fa/04-providers.md) · **English**

# 4. Running the agents on each AI provider

The pack is deliberately plain: Markdown instructions plus POSIX shell scripts.
Any coding agent can run it. What differs between providers is **how much is
enforced for you** versus how much depends on the agent's discipline.

Read this table before choosing. It is the honest summary.

| | Claude Code | Codex CLI | Cursor / Windsurf | Aider | Gemini CLI |
|---|---|---|---|---|---|
| Reads `AGENTS.md` | via `CLAUDE.md` | yes, automatically | yes | with `--read` | yes |
| Separate agent roles | **real subagents** | profiles + prompt | prompt only | prompt only | prompt only |
| Slash commands | **yes** | no | no | no | no |
| **Guard hook enforced** | **yes — automatic** | **no** | **no** | **no** | **no** |
| Path permission deny | **yes** | sandbox only | no | no | no |
| Sandbox | per-tool allowlist | **yes, strong** | no | no | limited |

**The one conclusion:** `scripts/guard.sh` runs automatically **only on Claude
Code**. Everywhere else, the destructive-command and credential protections are
not automatic. The scripts still work; the *enforcement* does not.

If a beginner is going to operate this, use Claude Code. That is not a
preference — it is the only configuration where the guardrails hold without
the agent choosing to honour them.

---

## Claude Code — fully enforced

Nothing to configure; it is already wired.

```
/liara-setup          # first time
/liara-status         # is the site up?
/liara-deploy staging
/liara-plan
/liara-diagnose
/liara-report
```

What is active:

- `scripts/guard.sh` as a **PreToolUse hook on Bash** — blocks destructive
  commands, credential reads, bare `liara` calls, unapproved production writes
- `permissions.deny` — blocks reads of `.liara/**` and `.env`, and edits to
  `guard.sh`, `approve.sh`, `preflight.sh`, `settings.json`
- Five subagents with per-role tool allowlists

Verify it is really on — do this before trusting it:

```bash
sh scripts/doctor.sh       # includes a guard self-test
sh scripts/test-guard.sh   # full regression suite
```

**Windows:** hooks run via `sh` (Git Bash). If `sh` is not on PATH, **the hook
does not run and commands are unguarded.** `doctor.sh` checks for this
explicitly. Do not skip it.

---

## Codex CLI — sandbox instead of hooks

Codex reads `AGENTS.md` automatically. It has **no PreToolUse hook**, so
substitute the sandbox:

```bash
codex --profile liara-sre     "وضعیت سایت چطور است؟"
codex --profile liara-deploy  "deploy to staging and verify"
codex --profile liara-prod    "deploy to production"
```

Profiles are in [`.codex/config.toml`](../../.codex/config.toml):

| profile | sandbox | approval | for |
|---|---|---|---|
| `liara-sre` | `read-only` | on-request | monitoring, logs, plans — **cannot change anything** |
| `liara-deploy` | `workspace-write` | on-request | deploying, patching |
| `liara-prod` | `workspace-write` | `untrusted` (every command) | production |

Use `liara-sre` as your default. A read-only sandbox is a real structural
control, and it covers most of what a beginner needs.

Invoke a role by reference:

```
follow .claude/agents/liara-sre.md and report the current status
```

Run the guard manually before a mutating command:

```bash
CMD='LIARA_ENV=staging sh scripts/liara.sh deploy --app my-site --path .'
printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$CMD" \
  | sh scripts/guard.sh && eval "$CMD"
```

Field names were current for Codex CLI ~v0.125; verify at
<https://developers.openai.com/codex> if a key is rejected.

---

## Cursor / Windsurf

Point the rules file at the contract rather than duplicating it:

`.cursor/rules/liara.mdc`
```markdown
---
description: Liara operations
alwaysApply: true
---
Follow @AGENTS.md exactly. Use `sh scripts/liara.sh` only — never a bare
`liara`. Default to LIARA_ENV=staging. Production writes need a human-granted
approval. Never ask for or read an API token.
```

**No hook enforcement.** Treat it as a capable assistant, not a guarded
operator, and keep production credentials off the machine.

---

## Aider

```bash
aider --read AGENTS.md --read .claude/skills/liara-ops/SKILL.md
```

Add to `.aider.conf.yml`:
```yaml
read: [AGENTS.md, .claude/skills/liara-ops/SKILL.md]
```

No hooks. Aider's commit-per-change behaviour pairs well with the "fix = patch"
rule, since every change is reviewable in git.

---

## Gemini CLI

Point `GEMINI.md` at the contract:

```markdown
# GEMINI.md
Follow AGENTS.md in this repository exactly, including the five rules.
```

No hook enforcement.

---

## Making it safe on a provider without hooks

If you must run unguarded, replace enforcement with scope:

1. **Never store production credentials on that machine.** `sh scripts/creds.sh
   set staging` only. This is the strongest single control available to you,
   and it needs no tooling.
2. Enable **read-only mode** on the production app while experimenting:
   `POST /v1/projects/{id}/read-only/enable`
3. Use the provider's own sandbox at its most restrictive setting.
4. Run `sh scripts/test-guard.sh` manually and read the audit log:
   `cat state/audit.log`
5. Deploy from CI instead of from the agent — then the token lives in CI and
   the agent only reads results.

## Provider-independent by design

Everything here is portable on purpose:

| Piece | Format | Depends on a provider? |
|---|---|---|
| `AGENTS.md` | Markdown | no |
| `.claude/agents/*.md` | Markdown + frontmatter | frontmatter ignored elsewhere |
| `scripts/*.sh` | POSIX sh | no |
| `.claude/skills/liara-ops/` | Markdown | no |
| `.claude/settings.json` | JSON | Claude Code only |
| `.codex/config.toml` | TOML | Codex only |

If you switch providers, you lose enforcement and keep everything else.
