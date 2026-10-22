# Deploy Agent + SRE Agents — ۲۰ ایده (Research & Options)

> **Status:** ideas only. Nothing in the project was changed — `D:\Liara` is currently an empty folder, so everything below is a greenfield proposal.
> **تاریخ:** 2026-10-22

---

## 0. چی می‌خواهیم؟ / What you asked for

Two agent systems, described in your words:

1. **«AGENT برای راه‌اندازی، انتشار، دیپلوی، مدیریت، بررسی عملکرد و باگ‌های سایت — برای مبتدی‌ها که هیچ چیزی نمی‌دانند.»**
   → A **Deploy & Operate Agent**: one agent that sets up, publishes, deploys, manages, watches performance, and reports bugs — operated by someone with zero DevOps knowledge. Part A (ideas 1–10).

2. **"SRE Agents to run tests and find bugs on the app, and run the agent for fixes."**
   → An **SRE / QA agent fleet**: agents that test the running app, hunt bugs, and hand them to a **fix agent**. Part B (ideas 11–20).

### فرض‌های من / My assumptions

- Hosting is **Liara** (`liara.ir`) — that is what the folder name says. Everything Liara-specific below is verified against the real CLI and docs (see §Sources).
- The "site" doesn't exist yet in this folder, so you can pick the architecture freely.
- The operator (مبتدی) interacts in **Persian, in chat** — not with YAML, not with kubectl.
- Budget-conscious: prefer free / self-hosted / already-paid-for tools.

### حقایق پایه‌ای که تحقیق کردم / Ground facts worth knowing

Real, verified capabilities you can build on:

| Thing | Fact |
|---|---|
| `@liara/cli` | v9.6.0, MIT. Commands exist for `deploy`, `logs`, `app shell/start/stop/restart`, `env set/unset`, `db create/backup`, `disk create`, `zone record create/update` (DNS), `bucket`, `mail send`, `vm *`, `team *`. |
| `liara deploy` flags | `--api-token`, `-a/--app`, `-p/--port`, `--path`, `--platform`, `-m/--message`, `--detach`, `--no-cache`, `-i/--image`, `-f/--dockerfile`, `-b iran|germany`, `--liara-json`. |
| `liara logs` flags | `-a app`, `-f` (follow), `-s "1 hour ago"`, `-t` (timestamps), `-r v3` (per-release), `-c` (colorize). |
| `liara.json` | Supports `app`, `platform`, `port`, `build.location`, `disks[]`, `cron[]`, `healthCheck{command,interval,timeout,retries,startPeriod}`, `args`, `envs{}`. **`healthCheck` gates a release: if the check fails, the deployment fails.** `envs` in the file *replaces* all stored vars — so keep secrets out of it. |
| API token | Created in console.liara.ir → API, with expiry from 1 hour to 1 year, shown **once**. |
| Liara MCP server | An **unofficial** `liara-mcp` npm package exists (razavioo/liara-mcp) exposing app/db/DNS/metrics/logs tools to an AI assistant, with a "consolidated mode" of ~8 tools instead of 100+. Unofficial = read the code before trusting it with a token. |
| Playwright agents | Playwright 1.56 ships first-party **planner / generator / healer** agents (`npx playwright init-agents`) that explore a live app, write tests, and repair failing ones. |
| AI SRE market | Gartner made "AI SRE" its own category in Jan 2026. The consensus pattern that actually works: **detection → LLM triage → policy-gated remediation**. Autonomous production *fixes* remain approval-gated almost everywhere; one 2025 incident (Replit) had an agent drop a production DB during a freeze. Vendor MTTR numbers are vendor numbers. |

**The single most important design conclusion from the research:** constraints must be *structural* (tokens, scopes, environments, approval gates), never just "I told the agent in its prompt not to." Every idea below is scored for that.

---

# PART A — Deploy & Operate Agent for absolute beginners

**Goal:** the operator types «سایت رو منتشر کن» and the right thing happens, safely, with an explanation in Persian.

---

## ۱. "Big Red Button" — یک اسکیل، چهار دستور
### Idea 1: A single Claude Code skill with four verbs

**What:** One skill (`.claude/skills/deploy/SKILL.md`) that defines exactly four operations and nothing else:

- `/deploy` → انتشار نسخه جدید
- `/status` → سایت بالاست؟ چند خطا؟ چقدر کند؟
- `/rollback` → برگرد به نسخه قبلی
- `/logs` → ۵۰ خط آخر، ترجمه‌شده به فارسی ساده

**How:** The skill wraps the verified CLI calls:

```bash
liara deploy --app my-site --path . --message "release $(date +%F-%H%M)" --detach
```

```bash
liara logs --app my-site --since "30 minutes ago" --timestamps
```

The skill body tells the agent: never invent flags, never touch `db` or `env` commands, always print the Persian summary before and after.

**Why for beginners:** the surface area is four words. There is nothing to misconfigure because there is nothing to configure.

**Risk:** low. **Effort:** half a day. **Beginner fit:** ★★★★★
**به زبان ساده:** چهار دکمه، همین. هر چیز دیگری عمداً وجود ندارد.

---

## ۲. دیپلوی با Git، نه با لپ‌تاپ
### Idea 2: Git-push deploy (agent writes the pipeline once, then disappears)

**What:** Deployment is triggered by `git push`, not by a human running a CLI. A GitHub Actions workflow runs `liara deploy` with `--api-token=${{ secrets.LIARA_API_TOKEN }}`.

**How:** The agent generates `.github/workflows/deploy.yml` once:

```yaml
- run: npm i -g @liara/cli
- run: liara deploy --app my-site --path . --api-token "$LIARA_TOKEN" --detach --message "${{ github.sha }}"
```

The agent's ongoing job becomes *reading* the run result and explaining failures — not holding the token.

**Why for beginners:** the beginner's laptop never needs a token, a Node version, or a working CLI. Deployment becomes "save your work" instead of "perform a procedure."

**Risk:** low — and it *removes* a risk class (local token leakage). **Effort:** 1 day.
**Trade-off:** needs a GitHub repo and the operator must learn `git push` (or the agent pushes for them).
**Beginner fit:** ★★★★☆
**به زبان ساده:** دیپلوی خودکار بعد از هر push. توکن روی سرور گیت‌هاب می‌ماند، نه روی لپ‌تاپ شما.

---

## ۳. Health Check به‌عنوان دروازه انتشار
### Idea 3: Make `liara.json` healthCheck the release gate

**What:** Stop relying on the agent to "check if it worked." Let the platform refuse bad releases.

**How:** `liara.json` gets:

```json
{
  "app": "my-site",
  "port": 3000,
  "healthCheck": {
    "command": "CMD curl --fail http://localhost:3000/api/health || exit 1",
    "interval": 30, "timeout": 15, "retries": 2, "startPeriod": 5
  }
}
```

Plus an agent-written `/api/health` endpoint that actually checks DB connectivity, not just `return 200`.

**Why it matters:** this is the cheapest structural safety net you can buy. A broken build never reaches users, with zero agent intelligence involved. The docs confirm a failing healthCheck fails the deployment.

**Risk:** very low. **Effort:** 2 hours. **Beginner fit:** ★★★★★ (invisible to them, which is the point)
**به زبان ساده:** اگر نسخه جدید سالم نباشد، خود لیارا منتشرش نمی‌کند. لازم نیست کسی بفهمد.

---

## ۴. دو اپ، یک دامنه — Blue/Green با DNS
### Idea 4: Blue/green via two Liara apps + a DNS flip

**What:** Liara has no native canary, but it has DNS management. So: `my-site-blue` and `my-site-green` as two apps; the live domain's record points at one of them. Deploy to the dark one, test it on its own `*.liara.run` URL, then flip the record.

**How:** The agent uses `liara deploy -a my-site-green`, runs the Part B test agents against the green URL, and only then `liara zone record update`. Rollback = flip the record back, which takes seconds and needs no rebuild.

**Why for beginners:** "بازگشت به حالت قبل" becomes genuinely instant and genuinely safe, instead of "redeploy the old commit and pray."

**Risk:** medium — DNS TTL means the flip isn't atomic for all users; two apps cost two plans.
**Effort:** 2–3 days. **Beginner fit:** ★★★☆☆ (great safety, more moving parts)
**به زبان ساده:** دو نسخه از سایت؛ روی نسخه خاموش دیپلوی می‌کنیم، تست می‌کنیم، بعد دامنه را سوییچ می‌دهیم. برگشت = یک سوییچ دیگر.

---

## ۵. چک‌لیست قبل از پرواز
### Idea 5: A pre-flight gate the agent must pass before it is allowed to deploy

**What:** A deterministic script (`scripts/preflight.sh`) — not a prompt — that the deploy skill must run first and must see exit 0 from:

1. tests pass, 2. build succeeds, 3. no secret-looking strings in the diff, 4. required env vars exist on the target app (`liara env list`), 5. a fresh DB backup exists (`liara db backup create`), 6. the current production health endpoint is green.

**Why for beginners:** it encodes the five things an experienced engineer checks reflexively and a beginner has no way to know. Failure output is written as a Persian sentence: «دیپلوی انجام نشد چون ۳ تست شکست خورده — اینها هستند…».

**Risk:** low. **Effort:** 1 day. **Beginner fit:** ★★★★★
**به زبان ساده:** قبل از هر انتشار، ۶ مورد خودکار چک می‌شود. اگر یکی رد شود، دیپلوی متوقف و دلیلش به فارسی گفته می‌شود.

---

## ۶. دستیار راه‌اندازی اولیه (Zero-to-live Wizard)
### Idea 6: A one-time setup wizard agent

**What:** A separate, single-use agent whose only job is getting from nothing to a live site: choose platform, create the app (`liara app create`), create the DB (`liara db create`), wire `DATABASE_URL` via `liara env set`, create the disk for uploads, connect the domain and DNS, issue SSL, then do the first deploy.

**How:** It runs as an interview — one question at a time, in Persian, with a default answer for every question so «نمی‌دانم» is always a valid reply. It ends by writing `OPERATIONS.md`: what was created, what it costs, which commands matter.

**Why for beginners:** the hardest part for a true beginner is not deploying — it's the 20 one-time decisions nobody tells you about.

**Risk:** medium (it creates billable resources — put a confirmation on every `create`). **Effort:** 2–3 days. **Beginner fit:** ★★★★★
**به زبان ساده:** یک‌بار با شما مصاحبه می‌کند، همه‌چیز را می‌سازد، و یک فایل راهنما از کارهایی که کرده می‌نویسد.

---

## ۷. گزارش صبحگاهی سایت
### Idea 7: A scheduled daily "site report" in plain Persian

**What:** A scheduled agent run (Claude Code scheduled tasks / cron / a GitHub Actions `schedule:`) that every morning collects: uptime %, error count by type, slowest pages, traffic, disk usage, DB size, SSL/domain expiry, and yesterday's deploys — and writes **one paragraph** plus a traffic-light.

**How:** Data comes from `liara logs --since "24 hours ago"`, the Liara metrics API (the unofficial MCP exposes app metrics), and the uptime checker from idea 16.

**Why for beginners:** it replaces "learn to read a dashboard" with "read one message." It also builds intuition: after two weeks the operator knows what normal looks like.

**Risk:** very low. **Effort:** 1–2 days. **Beginner fit:** ★★★★★
**به زبان ساده:** هر روز صبح یک پیام: «سایت سالم است / دیروز ۴ خطا داشتیم / صفحه فروشگاه کند شده».

---

## ۸. حالت «توضیح بده، بعد انجام بده»
### Idea 8: Explain-then-act, with a hook that enforces it

**What:** Before any state-changing command, the agent must print: what it will do, what changes for users, how to undo it, and what it costs. Then wait for «بله».

**How:** Don't trust the prompt — enforce it with a **PreToolUse hook** on Bash that pattern-matches dangerous commands (`liara db *`, `liara app rm`, `liara env unset`, `liara deploy` to prod, anything with `delete|remove|drop`) and blocks them unless an approval marker is present in the session.

**Why it matters:** this is the structural version of judgment. Research is consistent here — prompt-level guardrails are the thing that failed in the published incidents.

**Risk:** low. **Effort:** 1 day. **Beginner fit:** ★★★★★
**به زبان ساده:** قبل از هر کار خطرناک، به فارسی توضیح می‌دهد و اجازه می‌گیرد — و این «اجازه گرفتن» با hook اجباری شده، نه با خواهش.

---

## ۹. دو توکن، دو دنیا
### Idea 9: Separate staging and production identities

**What:** The agent gets a **staging** API token by default. The production token lives somewhere the agent cannot read (GitHub secret, or a token with 1-day expiry the human pastes when needed).

**How:** `liara` supports multiple accounts (`liara account add/use`, `--account`, `--team-id`) and per-command `--api-token`, so this is natively supported. Staging app, staging DB, staging domain. The agent experiments freely there.

**Why it matters:** it turns the worst-case outcome from "production is gone" into "staging is gone, rebuild it." Token expiry (1 hour → 1 year options) is a real blast-radius control.

**Risk:** low. **Effort:** 1 day + the cost of a second small plan. **Beginner fit:** ★★★★☆
**به زبان ساده:** ایجنت فقط به محیط آزمایشی دسترسی دارد. دسترسی به سایت اصلی دست خودتان است.

---

## ۱۰. لایه MCP برای مدیریت (با احتیاط)
### Idea 10: An MCP layer so the agent manages infra by tools, not by shell

**What:** Instead of the agent composing shell strings, give it typed tools: list apps, get metrics, read logs, set env, create backup. Either the unofficial `liara-mcp` (consolidated mode, ~8 tools) or a thin MCP server you write that wraps *only* the ~10 calls you want to allow.

**Why it's better than shell:** a tool list is an allowlist. There is no `rm -rf` in a tool schema. Arguments are validated. Calls are loggable and reviewable.

**Why I'd write my own anyway:** `liara-mcp` is explicitly unofficial and unaffiliated, and it would hold a token with full account scope. A 200-line wrapper you control is a better trade for a beginner-operated system — and you can hard-code "read-only unless the env var says otherwise."

**Risk:** medium if you use the third-party one as-is (read the source first); low for a self-written wrapper. **Effort:** 1 day (third-party) / 3–4 days (own). **Beginner fit:** ★★★★☆
**به زبان ساده:** به‌جای اینکه ایجنت دستور شل بنویسد، فقط چند ابزار مشخص و محدود در اختیار دارد.

---

# PART B — SRE / QA agents: test, find bugs, fix

**Goal:** agents that behave like a tester and an on-call engineer, with the fix path gated.

---

## ۱۱. ایجنت کاوشگر (Explorer)
### Idea 11: An exploratory browser agent that just... uses the site

**What:** An agent driving a real browser (Playwright MCP / the in-app browser) with the instruction: behave like a confused first-time user. Click everything, submit empty forms, type Persian text in English-only fields, paste 500 characters into a name field, go back mid-checkout, double-submit.

**How:** It records console errors, failed network requests, 500s, layout breakage, and dead ends, then files each as a reproducible bug with steps + screenshot. Playwright's docs describe exactly this mode: autonomous exploration that detects bugs and proposes end-to-end tests.

**Why it's valuable:** this finds the class of bug your tests never cover, because you wrote the tests knowing how the app works.

**Risk:** low (run it against staging; against prod only read-only flows). **Effort:** 2–3 days. **Value:** ★★★★★
**به زبان ساده:** یک ایجنت مثل یک کاربر ناآشنا همه‌جای سایت را می‌زند و هر چیزی که خراب شود را گزارش می‌دهد.

---

## ۱۲. Planner → Generator → Healer
### Idea 12: Adopt Playwright's three first-party test agents

**What:** Use what already exists instead of building a test framework: `npx playwright init-agents` gives a **planner** (turns a feature into a test plan), a **generator** (writes the test against a live browser), and a **healer** (repairs tests that broke because the UI changed).

**Why this one is high-leverage:** the honest reading of the 2026 write-ups is that AI test *generation* is overhyped but AI test *maintenance* is the real win. Brittle selectors are why most beginner test suites get deleted after a month. The healer attacks precisely that.

**Caveat worth respecting:** a healed test can be a test that no longer tests anything. Require healer changes to arrive as reviewable diffs, never auto-committed.

**Risk:** low–medium (silent test erosion). **Effort:** 2 days. **Value:** ★★★★★
**به زبان ساده:** سه ایجنت آماده‌ی خود Playwright: یکی نقشه تست می‌کشد، یکی تست می‌نویسد، یکی تست‌های شکسته را تعمیر می‌کند.

---

## ۱۳. ایجنت ردیاب خطا (Error Triage)
### Idea 13: An error-triage agent on top of real error tracking

**What:** Install error tracking (self-hosted **GlitchTip** or Sentry's free tier) in the app. Then an agent that runs on new error groups: dedupe, rank by *users affected* (not count), find the commit that introduced it, decide «الان مهم است» vs «بعداً».

**How:** Sentry has an official MCP server; GlitchTip speaks the Sentry API, so the same tooling works. The agent's output is a ranked list of at most 5 items, each with one recommended action.

**Why for beginners:** raw error feeds are unreadable noise. Ranking by affected users is the single judgement call that makes the feed actionable.

**Risk:** low. **Effort:** 2 days (+ a few hours to self-host GlitchTip). **Value:** ★★★★★
**به زبان ساده:** خطاها جمع‌آوری و دسته‌بندی می‌شوند و ایجنت می‌گوید کدام‌ها واقعاً مهم‌اند و از کدام کامیت آمده‌اند.

---

## ۱۴. ایجنت تعمیرکار با PR، نه با دیپلوی
### Idea 14: A fix agent whose only output is a pull request

**What:** The fix agent reads a bug report (from ideas 11/13/16), reproduces it with a **failing test first**, writes the minimal fix, confirms the test passes, and opens a PR. It has **no deploy permission at all.**

**How:** `claude-code-action` on GitHub, triggered by an `agent-fix` label or an `@claude` comment. The PR body contains: the bug, the repro, the root cause in two sentences, the diff rationale, and what it did *not* fix.

**Why "PR only" is the whole design:** this is where the research is least ambiguous — autonomous production remediation is still approval-gated nearly everywhere in 2026, one benchmark cited has models resolving only ~14% of production-style failures, and the published failure mode is an agent with write access during a freeze. A PR keeps 100% of the speed benefit and 0% of that risk.

**Risk:** low, structurally. **Effort:** 2–3 days. **Value:** ★★★★★
**به زبان ساده:** ایجنت فقط Pull Request می‌سازد. هیچ‌وقت خودش روی سایت اصلی تغییر نمی‌دهد. تصمیم نهایی با آدم است.

---

## ۱۵. حلقه «CI شکست → تعمیر خودکار»
### Idea 15: Self-healing CI (the narrow, safe slice of auto-fix)

**What:** When CI fails on a PR, an agent investigates the failure and pushes a fix to **that PR's branch** if the cause is unambiguous — a lint error, a type error, a snapshot update, a missing import, a flaky retry. If it's not unambiguous, it comments its analysis and stops.

**How:** This exists as a product pattern already (`/autofix-pr`-style cloud sessions watching a PR; self-healing workflow skills that diagnose failed runs and either fix inline or open a PR).

**Why it's the right first auto-fix:** the branch is not production, the change is reviewed anyway, and "fix the lint" is a decidable problem. Start autonomy where being wrong is cheap.

**Risk:** low. **Effort:** 1–2 days. **Value:** ★★★★☆
**به زبان ساده:** اگر تست‌های یک PR به دلیل ساده‌ای شکست بخورند، ایجنت خودش همان‌جا درستش می‌کند. وگرنه فقط توضیح می‌دهد.

---

## ۱۶. نگهبان بیرونی (Synthetic Monitoring)
### Idea 16: An outside-in watchdog + an alert-triage agent

**What:** Checks that run from *outside* your infrastructure, every minute, on the 5 journeys that matter (homepage loads, login works, search returns results, checkout reaches payment, API responds). Self-hosted **Uptime Kuma** is the cheap option; Checkly-style browser checks are the richer one.

**Then the agent part:** when a check fails, an agent correlates it with recent deploys, error spikes, and logs, and produces one Persian sentence: «سایت از ۳ دقیقه پیش بالا نمی‌آید؛ به احتمال زیاد از دیپلوی ساعت ۱۴:۰۲ — پیشنهاد: rollback». Detection → triage → *suggested* remediation is the pattern the 2026 sources agree actually works.

**Why for beginners:** this is the difference between "a customer told me the site was down yesterday" and knowing in 60 seconds, with a cause.

**Risk:** very low. **Effort:** 1 day (Kuma) + 2 days (triage agent). **Value:** ★★★★★
**به زبان ساده:** از بیرون هر دقیقه سایت چک می‌شود؛ اگر خراب شد، ایجنت می‌گوید احتمالاً تقصیر کدام تغییر بوده.

---

## ۱۷. ایجنت کارایی (Performance)
### Idea 17: A performance watchdog with budgets

**What:** Lighthouse CI on every PR with hard budgets (LCP, CLS, bundle size), plus a weekly k6 load test against staging. The agent's job is to turn numbers into a cause: "the product page got 400ms slower; the diff added an un-indexed query in the loop at line X."

**Why budgets, not reports:** a report gets ignored; a budget fails the build. Beginners can't triage a waterfall chart, but they can read «صفحه محصول ۴۰۰ میلی‌ثانیه کندتر شد، دلیلش این خط است».

**Risk:** low. **Effort:** 2 days. **Value:** ★★★★☆
**به زبان ساده:** اگر سایت کندتر شود، همان لحظه در PR معلوم می‌شود و ایجنت دلیلش را نشان می‌دهد.

---

## ۱۸. ایجنت امنیت سبک
### Idea 18: A lightweight security sweep agent

**What:** A weekly scheduled agent that runs `npm audit` / dependency alerts, a **secret scan** across the repo and over the diff, an OWASP ZAP baseline scan against staging, a check that every `liara env` value marked secret is not also in git, and a TLS/domain-expiry check via `liara zone`.

**Output:** at most 3 items, each with severity, exploitability in your actual setup, and the fix. Not a 200-finding PDF.

**Why for beginners:** the beginner-specific failure modes are exactly these — a token committed to git, an admin route with no auth check, an expired cert, a `.env` deployed by accident.

**Risk:** low (scan staging, never prod, and never a host you don't own). **Effort:** 2 days. **Value:** ★★★★☆
**به زبان ساده:** هفته‌ای یک‌بار بررسی امنیتی سبک: توکن لو رفته، پکیج آسیب‌پذیر، گواهی منقضی.

---

## ۱۹. تمرین خرابی کنترل‌شده (Game Day)
### Idea 19: A rehearsal agent — break staging on purpose, on a schedule

**What:** Once a month, against **staging only**: kill the app (`liara app stop`), fill the disk, stop the DB (`liara db stop`), point an env var at a dead host. Then measure: did the watchdog notice? how fast? was the triage message right? did rollback actually work?

**Why this is the one most people skip:** an untested recovery procedure is a guess. This is also how you find out your "rollback" never worked — on a Tuesday afternoon with no customers watching, rather than during a real outage.

**Risk:** low *if and only if* it is structurally confined to the staging token from idea 9. This idea is dangerous without idea 9 — treat it as a dependency, not a suggestion.
**Effort:** 2–3 days. **Value:** ★★★★☆
**به زبان ساده:** ماهی یک‌بار عمداً محیط آزمایشی را خراب می‌کنیم تا ببینیم سیستم هشدار و بازگشت واقعاً کار می‌کند.

---

## ۲۰. دفترچه خاطرات حادثه‌ها
### Idea 20: An incident memory that compounds

**What:** Every incident and every agent fix appends one entry to `docs/incidents/` — symptom, cause, fix, how long, how we'd catch it 10× faster next time. The triage agent **reads this directory first** on every new alert.

**Why this is the quiet winner:** it is the one idea that gets *better* with age. By incident 20, the agent's first guess is informed by your system's actual history, not generic reasoning. It also doubles as the onboarding document for the beginner — a real, specific runbook written by experience instead of imagination.

Pair it with an SLO (e.g. "99.5% of homepage checks succeed, p95 < 800ms") so that "is this bad enough to act on?" has a numeric answer and not a vibe.

**Risk:** none. **Effort:** ongoing, ~10 min per incident. **Value:** ★★★★★
**به زبان ساده:** هر خرابی یک‌بار نوشته می‌شود؛ ایجنت قبل از هر تشخیص جدید، تاریخ خرابی‌های همین سایت را می‌خواند.

---

# چطور شروع کنیم / Recommended build order

Not all 20. Here is what I'd actually do, in order:

**هفته ۱ — پایه‌های ایمن (do these regardless of anything else)**
- Idea 3 (healthCheck gate) — 2 hours, highest safety-per-hour of anything here
- Idea 9 (staging vs prod tokens) — unlocks ideas 11, 17, 18, 19 safely
- Idea 1 (four-verb skill) — makes the system usable by the operator
- Idea 16, Uptime Kuma half only — you cannot operate what you cannot see

**هفته ۲ — چشم و دست**
- Idea 5 (pre-flight gate) + Idea 8 (enforcing hook)
- Idea 13 (error tracking + triage)
- Idea 7 (daily Persian report)

**هفته ۳ — تست و تعمیر**
- Idea 12 (Playwright planner/generator/healer)
- Idea 14 (fix agent → PR only)
- Idea 11 (explorer agent on staging)

**بعداً**
- Idea 15 (CI auto-fix), Idea 17 (perf budgets), Idea 18 (security sweep), Idea 2 (git-push deploy)
- Idea 20 from day one — it costs 10 minutes and pays forever
- Ideas 4, 6, 10, 19 when the basics are boring and reliable

### قواعد ثابت / Non-negotiables, whichever ideas you pick

1. **Agent never holds a production write token.** Separate identities, short expiry.
2. **Fix agents produce PRs, not deployments.** The approval gate is the product, not the friction.
3. **Guardrails are hooks and scopes, never prompt text.** This is the one lesson every published agent incident teaches.
4. **Every message to the operator is Persian, one paragraph, with one recommended action.**
5. **Backup before every migration, restore tested at least once.** An untested backup is a rumor.
6. **Deterministic things stay deterministic.** Use the LLM for triage, explanation, and code — not for deciding whether tests passed.

---

## Sources

Liara: [@liara/cli on npm](https://libraries.io/npm/@liara%2Fcli) · [liara-cloud GitHub org](https://github.com/liara-cloud) · [liara-cloud/docs](https://github.com/liara-cloud/docs) · [liara.json reference](https://docs.liara.ir/paas/liarajson/) · [PaaS overview](https://docs.liara.ir/paas/about/) · [unofficial liara-mcp](https://glama.ai/mcp/servers/@razavioo/liara-mcp/tree/6f2024169a6bd101de537495f1813247abc190f2)

Testing agents: [Playwright MCP — explore and test](https://playwright.dev/agents/playwright-mcp-explore-and-test) · [Playwright AI playbook 2026](https://dev.to/himanshuai/playwright-ai-the-complete-test-automation-playbook-2026-8d2) · [Checkly — generating E2E tests with AI](https://www.checklyhq.com/blog/generate-end-to-end-tests-with-ai-and-playwright/) · [Agentic QA with Playwright MCP](https://avijitportfolio.lovable.app/projects/agentic-ai-qa-automation-with-playwright-mcp)

AI SRE: [Augment Code — AI SRE 2026 guide](https://www.augmentcode.com/guides/ai-sre-ai-powered-site-reliability-engineering) · [awesome-ai-sre](https://github.com/agamm/awesome-ai-sre) · [SquareOps — AI incident response](https://squareops.com/blog/ai-powered-incident-response-reduce-mttr-sre/) · [Luminabyte — alert triage to supervised remediation](https://luminabyte.de/en/blog/ai-agents-sre-incident-response) · [Aurora SRE — incident lifecycle with agents](https://www.aurorasre.ai/blog/sre-incident-lifecycle-with-ai-agents) · [NeuBird — AI SRE tools](https://neubird.ai/blog/top-ai-sre-tools) · [Xurrent — 2026 AI SRE guide](https://www.xurrent.com/blog/ai-sre-guide)

Auto-fix: [claude-code-action notes](https://x-cmd.com/install/claude-code-action) · [autofix failing CI](https://wmedia.es/en/tips/claude-code-autofix-pr-fix-failing-ci) · [agentic workflow automation skill](https://claudemarketplaces.com/skills/ruvnet/ruflo/agent-workflow-automation)

**Reliability note:** Liara CLI flags, `liara.json` fields, and the Playwright agent set are from primary sources and are solid. The AI-SRE market claims and all MTTR / percentage figures come from vendor blogs and are unverified — I'd treat them as direction, not as numbers.
