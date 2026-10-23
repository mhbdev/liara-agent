# Liara Agent Pack — پکیج ایجنت لیارا

Deploy, monitor and fix a website on [Liara](https://liara.ir) by talking to an
AI agent — designed for someone who knows nothing about servers.

انتشار، پایش و تعمیر یک وب‌سایت روی [لیارا](https://liara.ir) فقط با حرف زدن با
یک ایجنت هوش مصنوعی — ساخته‌شده برای کسی که هیچ چیزی از سرور نمی‌داند.

---

## Start here · از اینجا شروع کنید

| | |
|---|---|
| 🇬🇧 **English** | [Install in your project](docs/en/00-installation.md) → [Quickstart](docs/en/01-quickstart.md) → [Credentials](docs/en/02-credentials.md) → [Agents](docs/en/03-agents.md) |
| 🇮🇷 **فارسی** | [نصب در پروژه خودتان](docs/fa/00-installation.md) ← [شروع سریع](docs/fa/01-quickstart.md) ← [رمزها](docs/fa/02-credentials.md) ← [ایجنت‌ها](docs/fa/03-agents.md) |

## Install in your project · نصب در پروژه خودتان

**1. Open a terminal in your website's folder.** You need Node.js 20+, Git,
and a coding agent such as Claude Code or Codex.

**۱. ترمینال را در پوشه وب‌سایت خودتان باز کنید.** به Node.js نسخه ۲۰ یا
بالاتر، Git و یک ایجنت کدنویسی مثل Claude Code یا Codex نیاز دارید.

**2. Run one command · ۲. یک دستور اجرا کنید:**

```bash
npx --yes github:mhbdev/liara-agent
```

The installer prepares **Claude Code, Codex, Cursor, Windsurf, Aider and
Gemini** together, merging existing instructions and Claude settings for you.
Your website code, dependencies and credentials stay in place.

نصب‌کننده همه محیط‌های بالا را با هم آماده می‌کند و دستورالعمل‌ها و تنظیمات
Claude را با موارد فعلی ادغام می‌کند. کد، وابستگی‌ها و رمزهای وب‌سایت شما حفظ می‌شوند.

**3. Restart your coding agent in that folder and say:**

> Help me connect Liara and configure this project for staging.

**۳. ایجنت را در همان پوشه دوباره باز کنید و بگویید:**

> کمک کن حساب لیارا را وصل کنم و این پروژه را برای محیط آزمایشی تنظیم کنم.

The agent guides the rest. Enter your Liara token only in your own terminal,
never in chat. In Claude Code, `/liara-login` also starts the connection guide.

ایجنت بقیه مراحل را راهنمایی می‌کند. توکن لیارا را فقط در ترمینال خودتان وارد
کنید، نه در چت. در ویندوز، ابزارهای لیارا با Git Bash اجرا می‌شوند.

More options, preview and troubleshooting: [English](docs/en/00-installation.md) ·
[فارسی](docs/fa/00-installation.md). Installation adds project files; account
connection and deployment checks come afterward.

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

**2. The pack includes command guards and human approvals.**
With the supplied Claude Code hook active, `scripts/guard.sh` checks Bash tool
calls. Other environments require manual guard invocation and their own
sandbox settings. `scripts/approve.sh` issues
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
bin/install.mjs        one-command project installer (Node.js, no dependencies)
package.json           npx entry point + installer tests
.claude/
  agents/              6 subagent definitions
  commands/            7 slash commands
  skills/liara-ops/    verified Liara CLI + API reference
  settings.json        guard hook + path permissions
.codex/config.toml     optional Codex defaults (read-only, interactive approvals)
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
tests/guard-cases.txt  cases: what must be blocked and allowed
docs/en/ docs/fa/      installation + 7 operating guides each, bilingual
state/                 audit log, health log, incident records (gitignored)
```

---

## Provider support · پشتیبانی سرویس‌ها

| Pack integration | Claude Code | Codex | Cursor / Windsurf | Aider | Gemini |
|---|---|---|---|---|---|
| Supplied role files | **subagents** | read by path | read by path | `--read` | read by path |
| Supplied `/liara-*` commands | **yes** | use plain prompts | use plain prompts | use plain prompts | use plain prompts |
| **Pack's guard wired automatically** | **with settings active** | no | no | no | no |

**The supplied guard hook is wired only for Claude Code.** Other clients may
have their own hooks, but this pack does not install those integrations.
Use the provider's sandbox and keep production credentials off that machine.
Details: [English](docs/en/04-providers.md) ·
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
