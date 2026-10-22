[فارسی](../fa/05-runbook.md) · **English**

# 5. Runbook — the site is broken, what now

Start here when something is wrong. Each section: what you see → what to do →
what to say to the agent.

**The rule for any outage: restore service first, understand it second.** A
rollback that works beats a diagnosis that is still in progress.

---

## The site is completely down

**You see:** nothing loads, timeout, or a Liara error page.

```bash
sh scripts/health.sh https://your-site.ir "" 3
```

Or just say: **«سایت بالا نمیاد»** / "the site is down".

Then, in order:

1. **Was there a recent deploy?** This is the answer most of the time.
   ```bash
   LIARA_ENV=staging sh scripts/liara.sh app logs --app YOUR-APP --since "1 hour ago" --timestamps
   ```
   If the first error is within a couple of minutes of a release — roll back
   now, diagnose after.

2. **Is the app even running?**
   ```bash
   LIARA_ENV=staging sh scripts/liara.sh app list
   ```
   Stopped → start it:
   ```bash
   LIARA_ENV=staging sh scripts/liara.sh app start --app YOUR-APP
   ```

3. **Out of memory or disk?** `GET /v1/projects/{name}/metrics/summary` returns
   `cpuUsage`, `memoryUsage`, `disksUsage`. OOM shows up as repeated restarts
   with no stack trace. A full disk shows up as write failures.

4. **Platform events** — `GET /v1/projects/{name}/events` shows restarts, OOM
   kills and failed releases that the app's own logs never mention.

5. **Still nothing?** Check Liara's own status, and that your domain and TLS have
   not expired (`health.sh` reports TLS days).

---

## The site loads but is broken

**You see:** homepage fine, but logging in / checkout / search fails.

This is `degraded`, and it is the state that makes "looks fine to me" wrong. A
200 on the homepage is **not** evidence the application works.

```bash
sh scripts/health.sh https://your-site.ir /api/health 3
```

Say: **«سایت باز میشه ولی فلان کار نمی‌کنه»** / "the site loads but X is broken".

Most common causes, in order:

| Cause | Signature | Fix |
|---|---|---|
| missing env var | `undefined` / `KeyError` on config | `liara env set` |
| DB unreachable | timeout or auth error on first query | check DB is running, check credentials |
| pending migration | boots fine, then 500 on every DB route | run the migration **deliberately**, with a backup |
| expired third-party key | 401/403 from an external API | rotate that key |
| full disk | upload or write failures | clear or resize the disk |

---

## The site is slow

```bash
SLOW_MS=1500 sh scripts/health.sh https://your-site.ir "" 5
```

Five checks, because one slow response is noise.

Then ask the agent to compare against the last deploy. Ordinary causes:
an un-indexed database query, a loop issuing one query per row (N+1), an
undersized plan (check `metrics/summary` before buying anything), or a slow
external API.

Say: **«سایت کند شده»** / "the site got slow".

---

## A deploy failed

**You see:** the deploy command errored, or `healthCheck` rejected the release.

**This is the system working.** `liara.json`'s `healthCheck` gates the release:
a failing check fails the deployment, so the broken build never served traffic.

```bash
LIARA_ENV=staging sh scripts/liara.sh logs --app YOUR-APP --since "20 minutes ago" --timestamps
```

| Signature | Usual cause |
|---|---|
| error before the app starts | build failure — fix the code or build command |
| starts, then health check times out | `port` in `liara.json` ≠ the port the app listens on |
| `module not found` | dependency or lockfile problem |
| `undefined` on a config value at boot | missing env var |

Say: **«دیپلوی خطا داد»** / "the deploy failed" — the fix agent will read the
logs and quote the evidence.

---

## Rolling back

Usually the right first move during an outage.

```bash
# inspect a known-good release
LIARA_ENV=staging sh scripts/liara.sh app logs --app YOUR-APP -r v11
```

Production rollback needs a human approval:

```bash
sh scripts/approve.sh grant rollback
```

Say: **«برگرد به نسخه قبلی»** / "roll back to the previous version".

---

## Database trouble

**Before anything else, take a backup:**

```bash
LIARA_ENV=staging sh scripts/liara.sh db backup create
LIARA_ENV=staging sh scripts/liara.sh db backup list
```

**The agents will refuse to run `DROP`, `TRUNCATE` or a destructive migration
to make an app boot.** That refusal is deliberate — data loss is not a
deployment strategy. A migration needs: a fresh backup, a tested rollback, and
a human running it.

---

## Reading the "BLOCKED" message

```
BLOCKED by scripts/guard.sh: production write without approval
```

Not a bug. The agent tried something that needs your explicit consent. The
message names exactly what to do. If you agree with the action:

```bash
sh scripts/approve.sh grant prod-write
```

Single use, 15 minutes. If you do **not** understand what it was about to do,
ask it to explain before you approve. That pause is the entire value of the gate.

---

## After every incident — do this one thing

Write it down. One file, five minutes:

`state/incidents/YYYY-MM-DD-short-slug.md`

- what you saw
- what it actually was
- what fixed it
- what would catch it 10× faster next time

The SRE agent **reads this directory before diagnosing anything new.** By the
twentieth incident its first guess is informed by your system's real history
rather than generic reasoning. This is the one part of the pack that gets
better with age — and the only part that depends on you.

---

## Emergency: stop everything

```bash
LIARA_ENV=production sh scripts/liara.sh app stop --app YOUR-APP   # needs approval
sh scripts/approve.sh revoke-all                                    # cancel all approvals
```

Enabling **read-only mode** on the app
(`POST /v1/projects/{id}/read-only/enable`) is a softer brake: the site keeps
serving, but nothing can write.
