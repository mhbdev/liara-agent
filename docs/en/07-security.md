[فارسی](../fa/07-security.md) · **English**

# 7. Security — what protects you, and what does not

Read the limitations section. A guardrail you believe in but that does not
actually fire is worse than no guardrail, because you will take risks you think
are covered.

## The design in one sentence

**Constraints are structural — files, scopes, tokens, exit codes — never
instructions to the model.** Every published incident involving an AI agent and
production infrastructure came from prompt-level guardrails: the agent was told
not to, and then did. A prompt cannot create an approval file, and no amount of
reasoning gets around a blocked exit code.

## The four layers

```
 1. permissions.deny     cannot read .liara/** or .env; cannot edit its own guards
 2. guard.sh hook        deny-list on every Bash call, before it runs
 3. approve.sh           one-time, 15-minute, human-granted approvals
 4. liara.sh wrapper     env scoping, redaction, timeout, output cap, audit
```

Each is independent. Layer 2 failing does not disable layers 1, 3 and 4.

### 1. Path permissions

From `.claude/settings.json`:

| Denied | Why |
|---|---|
| `Read(.liara/**)` | the agent cannot read a stored token |
| `Read(.env)` and friends | secrets stay out of context |
| `Edit(scripts/guard.sh)` | the agent cannot disarm itself |
| `Edit(scripts/approve.sh)` | the agent cannot grant itself approval |
| `Edit(.claude/settings.json)` | the agent cannot widen its own permissions |

### 2. The guard hook

`scripts/guard.sh` runs **before** every Bash command. It matches the whole hook
payload, so quoting tricks, variable indirection and string concatenation do not
help.

Blocked outright, no approval path:

`rm -rf` (any flag order) · `liara app rm/delete` · `liara db rm/delete` ·
`DROP`/`TRUNCATE` · `git push --force` · `git reset --hard origin` · reading
`.liara/token.*` · `cat .env` · a credential in a network call · `--api-token`
on a command line · a bare `liara` call

Test it yourself — do not take this document's word for it:

```bash
sh scripts/test-guard.sh
```

### 3. Approvals

```bash
sh scripts/approve.sh grant prod-write
```

Single use, 15-minute expiry, consumed on check whether or not it was valid.
Classes: `prod-write`, `prod-deploy`, `destructive`, `rollback`,
`db-migration`, `resize`.

**The agent cannot create one.** It must ask you, in words, and you decide.

### 4. The wrapper

Every CLI call goes through `scripts/liara.sh`, which:

- resolves the token for the current environment only — staging by default
- passes arguments as an array; never builds a shell string
- enforces a timeout (`LIARA_TIMEOUT`, default 180s)
- caps output (`LIARA_MAX_LINES`, default 400 lines)
- **redacts** JWTs, bearer tokens, passwords, DSNs and emails from all output
- appends an audit record

## Credentials

Covered in [02-credentials.md](02-credentials.md). The one-line version: the
token goes from your clipboard into a hidden-input script, is encrypted at rest
(DPAPI on Windows, `0600` elsewhere), and **is never in the model's context**.

## Audit trail

```bash
cat state/audit.log
```

Tab-separated: timestamp, environment, action, redacted detail. Every CLI call,
credential operation, approval grant/consume/denial, health check and guard
block. Append-only, and redacted before writing — no secret can land here.

---

## Known limitations — read this part

### Open right now, pending your patch

Two guard bypasses were found by the regression suite and are **not yet fixed**
in `scripts/guard.sh`:

| Gap | Effect |
|---|---|
| `rm -fr` (flags reversed) | not matched — the recursive-delete block is one character away from being bypassed |
| `cat .env.production` | not matched — only exactly `.env` is caught |

The corrected file and the expanded 48-case suite are prepared. Apply:

```bash
cp <scratchpad>/guard.sh scripts/guard.sh
cp <scratchpad>/guard-cases.txt tests/guard-cases.txt
sh scripts/test-guard.sh
```

Until then, treat the destructive-command protection as **partial**.

Also pending in `.claude/settings.json`: the deny list covers the `Edit` tool
but **not `Write`**, so an agent could overwrite `guard.sh` with `Write` rather
than editing it. Add the `Write(...)` twins of each `Edit(...)` deny rule.

### Structural, not fixable here

| Limitation | Detail | Mitigation |
|---|---|---|
| **Token visible in the process list** | the Liara CLI only accepts the token as a `--api-token` flag, so it appears briefly in `ps` output | acceptable on a single-user machine; on shared machines, deploy from CI instead |
| **Hooks are Claude Code only** | on Codex, Cursor, Aider and Gemini the guard does **not** run automatically | use the provider's sandbox; never store production credentials there — see [04-providers.md](04-providers.md) |
| **Hook fails open on Windows** | if `sh` is not on PATH the hook does not run and commands execute unguarded | `sh scripts/doctor.sh` checks this; run it before trusting anything |
| **Deny-list, not allow-list** | a novel destructive command nobody anticipated will pass | the approval gate still covers production; add a test case whenever you find a gap |
| **`state/` may contain log excerpts** | logs are redacted, but redaction is pattern-based | `state/` is gitignored; delete it when done |
| **The agent could propose a harmful patch** | nothing stops it *suggesting* something bad | fixes are patches, reviewed by you — that is the control |

### What this pack does not do

- No encryption of `state/` — it is local working data
- No multi-user access control — it assumes one operator on one machine
- No protection against a compromised npm dependency in your own project
- No protection if you paste a token into a chat (revoke it immediately)
- No defence against a malicious `AGENTS.md` if you clone someone else's repo —
  **read the agent instructions of any repo before running an agent in it**

## Checklist before giving an agent production access

Do not skip any of these. Each one is cheap and each one has a corresponding
real failure mode.

- [ ] `sh scripts/doctor.sh` passes, including the guard self-test
- [ ] `sh scripts/test-guard.sh` passes with **zero** failures
- [ ] The two guard gaps above are patched
- [ ] `Write(...)` deny rules added alongside the `Edit(...)` ones
- [ ] Production token expiry is 1–7 days, not 1 year
- [ ] `liara.json` has a `healthCheck` block
- [ ] Zero-downtime is enabled on the production app
- [ ] A database backup exists **and you have restored it once** — an untested backup is a rumour
- [ ] `state/audit.log` is being written
- [ ] You have read [05-runbook.md](05-runbook.md) *before* needing it

## If you think something was compromised

1. Revoke every token: <https://console.liara.ir/API>
2. `sh scripts/approve.sh revoke-all`
3. Read `state/audit.log` for what was actually executed
4. `LIARA_ENV=production sh scripts/liara.sh app logs --app X --since "24 hours ago"`
5. Consider enabling read-only mode: `POST /v1/projects/{id}/read-only/enable`
6. Rotate database credentials and any third-party keys the app holds
