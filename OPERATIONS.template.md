# OPERATIONS — <project name>

> The onboarding agent writes a filled-in `OPERATIONS.md` from this template.
> Keep it current: it is what you will read at 2am when something breaks, and
> what a new person reads on their first day.
> فایل OPERATIONS.md از روی این الگو ساخته می‌شود. به‌روز نگهش دارید.

**Last updated:** <date> · **Written by:** <agent run / person>

---

## What this is · این چیست

<One paragraph, no jargon. What the site does, who uses it.>
<یک پاراگراف، بدون اصطلاح فنی.>

---

## What exists · چه چیزی ساخته شده

| Resource | Name | Plan | Monthly cost | Environment |
|---|---|---|---|---|
| App | | | | staging |
| App | | | | production |
| Database | | | | |
| Disk | | | | |
| Object storage | | | | |
| Domain | | | | |

**Total:** <sum> — fetched from `liara plan list` on <date>, not from memory.

---

## Addresses · آدرس‌ها

| | URL |
|---|---|
| Live site | |
| Staging | |
| Health endpoint | |
| Liara console | https://console.liara.ir |

---

## The five commands you will actually use

```bash
sh scripts/doctor.sh                          # is everything set up correctly?
sh scripts/health.sh <url> /api/health 3      # is the site up right now?
sh scripts/creds.sh status                    # are my credentials still valid?
sh scripts/approve.sh grant prod-write        # allow ONE production change
cat state/audit.log                           # what has the agent actually done?
```

Or just talk to the agent: `/liara-status`, `/liara-deploy`, `/liara-diagnose`.

---

## When something breaks · وقتی چیزی خراب شد

1. Say «سایت بالا نمیاد» / "the site is down" — the SRE agent investigates.
2. If you need to act yourself: [docs/fa/05-runbook.md](docs/fa/05-runbook.md)
   or [docs/en/05-runbook.md](docs/en/05-runbook.md).
3. **Most outages are the last deploy.** Rolling back first is usually correct —
   restore service, then understand it.

---

## Who to contact · تماس

| Role | Name | Contact |
|---|---|---|
| Owner | | |
| Developer | | |
| Liara support | | https://liara.ir |

---

## Decisions made during setup · تصمیم‌های زمان راه‌اندازی

<Record anything non-obvious that a future reader would otherwise have to
rediscover — why this platform value, why this disk size, why this port.
Not what the code already says.>

---

## Known limitations of THIS setup

<What was deliberately not set up, and what would trigger revisiting it.
Example: "no production credentials on this machine — deliberate. Deploy to
production from CI instead.">

---

## Recurring tasks · کارهای دوره‌ای

| Task | How often | Command |
|---|---|---|
| Rotate staging token | monthly | `sh scripts/creds.sh set staging` |
| Rotate production token | weekly | `sh scripts/creds.sh set production` |
| Verify a database backup **restores** | quarterly | an untested backup is a rumour |
| Review `state/incidents/` for patterns | monthly | |
| Check TLS expiry | automatic | reported by `health.sh` |
