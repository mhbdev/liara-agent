# Liara Agent Pack — پکیج ایجنت لیارا

Deploy, monitor and fix a website on [Liara](https://liara.ir) by talking to an
AI agent — designed for someone who knows nothing about servers.

انتشار، پایش و تعمیر یک وب‌سایت روی [لیارا](https://liara.ir) فقط با حرف زدن با
یک ایجنت هوش مصنوعی — ساخته‌شده برای کسی که هیچ چیزی از سرور نمی‌داند.

---

## Start here · از اینجا شروع کنید

| | |
|---|---|
| 🇬🇧 **English** | [Quickstart](docs/en/01-quickstart.md) → [Credentials](docs/en/02-credentials.md) → [Agents](docs/en/03-agents.md) |
| 🇮🇷 **فارسی** | [شروع سریع](docs/fa/01-quickstart.md) ← [رمزها](docs/fa/02-credentials.md) ← [ایجنت‌ها](docs/fa/03-agents.md) |

```bash
npm install -g @liara/cli     # 1. install the Liara CLI
sh scripts/setup.sh           # 2. one guided wizard: checks, login, discovery
```

Or just chat to it — in Claude Code: **`/liara-login`**, then `/liara-setup`.

The wizard is the only place you type anything secret, and your typing is
hidden. Everything else you can do by talking.

---

## What you can say · چه چیزی می‌توانید بگویید

| English | فارسی | What happens |
|---|---|---|
| "is the site up?" | «وضعیت سایت چطوره؟» | liveness, latency, TLS, recent errors |
| "deploy it" | «منتشر کن» | pre-flight → plan → deploy → **verify** |
| "which plan should I buy?" | «کدوم پلن رو بخرم؟» | live prices + your real measured usage |
| "it's broken, fix it" | «خرابه، درستش کن» | evidence-based diagnosis, then a patch |
| "roll back" | «برگرد به نسخه قبلی» | restore the previous release |

---

## The six agents · شش ایجنت

| Agent | Does | Can it change production? |
|---|---|---|
| **Connect** | login and credentials, conversationally | no |
| **Onboarding** | `liara.json`, handover notes | no |
| **SRE** | liveness, logs, metrics, incidents | **no — read-only by design** |
| **Deploy** | publish and verify | only with a human approval |
| **Plan Advisor** | right-sizing from live prices | no (resize needs approval) |
| **Debug & Fix** | diagnose, patch, test | **no — its output is a patch** |

Full descriptions: [English](docs/en/03-agents.md) · [فارسی](docs/fa/03-agents.md)

---

## Three design decisions worth knowing

**1. The agent never sees your API token.**
It goes from your clipboard into a local script with hidden input, encrypted at
rest. The agent proves the credential works by *using* it, never by reading it.
Anything in a model's context can end up in a log — the only token that cannot
leak that way is one that was never there.

**2. Guardrails are structural, not instructions.**
`scripts/guard.sh` runs before every shell command. `scripts/approve.sh` issues
single-use, 15-minute approvals that **the agent cannot create for itself**.
Every published incident involving an agent and production infrastructure came
from prompt-level guardrails — the agent was told not to, and then did.

**3. A fix is a patch, not a production change.**
The debug agent diagnoses, writes a failing test, and patches. Deploying to
production is a human decision, every time. You keep all the speed and none of
the risk.

---

## Layout · ساختار

```
AGENTS.md              the binding contract — read by Codex and Claude Code
CLAUDE.md              Claude Code specifics
.claude/
  agents/              5 subagent definitions
  commands/            6 slash commands
  skills/liara-ops/    verified Liara CLI + API reference
  settings.json        guard hook + path permissions
.codex/config.toml     Codex profiles (read-only / deploy / prod)
scripts/
  setup.sh             THE front door: check / connect / verify / discover
  doctor.sh            environment check + guard self-test
  creds.sh             credential storage (hidden input, encrypted at rest)
  liara.sh             the ONLY way to reach the Liara CLI
  guard.sh             PreToolUse deny-list
  approve.sh           one-time human approvals
  preflight.sh         the deploy gate
  health.sh            liveness, latency, TLS
  plan-advise.sh       live plan + usage data
  test-guard.sh        guard regression suite
tests/guard-cases.txt  48 cases: what must be blocked and allowed
docs/en/ docs/fa/      7 documents each, bilingual
state/                 audit log, health log, incident records (gitignored)
```

---

## Provider support · پشتیبانی سرویس‌ها

| | Claude Code | Codex | Cursor | Aider | Gemini |
|---|---|---|---|---|---|
| Agent roles | **subagents** | profiles | prompt | prompt | prompt |
| Slash commands | **yes** | no | no | no | no |
| **Guard enforced automatically** | **yes** | no | no | no | no |

**The guard hook runs automatically only on Claude Code.** Elsewhere the scripts
work but enforcement does not — use the provider's sandbox and keep production
credentials off that machine. Details: [English](docs/en/04-providers.md) ·
[فارسی](docs/fa/04-providers.md)

---

## Verified, not assumed

Everything Liara-specific was checked on 2026-10-22 against CLI v9.6.0 and the
official OpenAPI specs. The [capability matrix](docs/en/06-capability-matrix.md)
marks each operation ✅ verified, ⚠️ untested or ❓ unknown — and lists what Liara
does **not** provide (no native canary, no single rollback command, no error
tracking, no built-in uptime monitoring) so you can plan around the gaps.

**Prices are never hard-coded.** They come from `liara plan list` at run time.

---

## Known gaps · شکاف‌های شناخته‌شده

Read [docs/en/07-security.md](docs/en/07-security.md) before giving any agent
production access. It lists two guard bypasses currently pending a patch, the
`--api-token` process-list exposure, and the Windows fail-open behaviour —
honestly, with mitigations.
