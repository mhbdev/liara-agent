[فارسی](../fa/06-capability-matrix.md) · **English**

# 6. Capability matrix — what is verified, and what is not

This answers §6 of the implementation plan: *do not assume an operation exists
because it would be convenient.*

**Verified on 2026-10-22** against:
- Liara CLI **v9.6.0** (`@liara/cli`, MIT) — `github.com/liara-cloud/cli`
- Official OpenAPI specs — `github.com/liara-cloud/openapi`
- Docs — `docs.liara.ir`

Status meanings:

| | |
|---|---|
| ✅ **verified** | read from the official CLI help output or the OpenAPI spec |
| ⚠️ **untested** | documented, but not yet run against a live account from this pack |
| ❓ **unknown** | not found in any official source — do not rely on it |

---

## Authentication

| Capability | Mechanism | Status |
|---|---|---|
| API token | created at console.liara.ir/API; expiry 1h–1y; shown once | ✅ |
| Token auth (API) | `Authorization: Bearer <token>` to `https://api.liara.ir` | ✅ |
| Token auth (CLI) | `--api-token <value>` on every command | ✅ |
| Multiple accounts | `liara account add/list/use/remove`, `--account` | ✅ |
| Teams | `liara team *`, `--team-id` | ✅ |
| Regions | `iran`, `germany` | ✅ |
| OAuth / short-lived creds | — | ❓ not found; use short token expiry instead |

## Applications

| Capability | CLI | API | Status |
|---|---|---|---|
| List apps | `app list` | `GET /v1/projects` | ✅ |
| Inspect app | — | `GET /v1/projects/{name}` | ✅ |
| Create app | `app create` | `POST /v1/projects` | ✅ |
| Start / stop | `app start` / `app stop` | — | ✅ |
| Restart | `app restart` | `POST /v1/projects/{name}/actions/restart` | ✅ |
| Scale | — | `POST /v1/projects/{name}/actions/scale` | ✅ |
| Resize | — | `POST /v1/projects/{name}/resize` | ✅ |
| Shell | `app shell` | — | ✅ interactive; poor fit for an agent |
| Change port | `app update-port` | — | ✅ |
| Delete | `app rm` | `DELETE /v1/projects/{name}` | ✅ **blocked by the guard** |

## Deployment

| Capability | CLI | API | Status |
|---|---|---|---|
| Deploy from a path | `deploy --path .` | — | ✅ |
| Upload source | — | `POST /v2/projects/{name}/sources` | ✅ |
| Create release | — | `POST /v2/projects/{name}/releases` | ✅ |
| Release history | — | `GET /v1/projects/{name}/releases` | ✅ |
| Release message | `-m/--message` | — | ✅ |
| Background build | `--detach` | — | ✅ |
| Skip cache | `--no-cache` | — | ✅ |
| Docker image | `-i/--image`, `-f/--dockerfile`, `--build-arg` | — | ✅ |
| Build location | `-b iran\|germany` | — | ✅ |
| **Zero-downtime toggle** | — | `POST /v1/projects/{id}/zero-downtime/{enable\|disable}` | ✅ **enable this on production** |
| **Health check gate** | `liara.json` → `healthCheck` | — | ✅ **a failing check fails the deploy** |
| Rollback | redeploy a known-good release | — | ⚠️ no single rollback command |
| Git-push deploy | — | — | ⚠️ documented under CI/CD; not tested here |

## Environment variables

| Capability | CLI | API | Status |
|---|---|---|---|
| List | `env list` | — | ✅ |
| Set | `env set KEY=value` | `POST /v1/projects/update-envs` | ✅ |
| Unset | `env unset KEY` | — | ✅ needs approval |
| Via `liara.json` | `envs: {}` | — | ✅ **replaces ALL stored vars — avoid** |
| Restart semantics | — | — | ⚠️ assume a restart; verify for your platform |

## Observability

| Capability | CLI | API | Status |
|---|---|---|---|
| Runtime logs | `logs --app X` | `GET /v1/projects/{name}/logs` | ✅ |
| Since a time | `--since "1 hour ago"` | — | ✅ |
| Per release | `-r v12` | — | ✅ |
| Follow | `-f` | — | ✅ |
| **Platform events** | — | `GET /v1/projects/{name}/events` | ✅ restarts, OOM kills, failed releases |
| **Metrics summary** | — | `GET /v1/projects/{name}/metrics/summary` | ✅ `cpuUsage`, `memoryUsage`, `disksUsage` |
| CPU / memory series | — | `GET /v1/projects/{name}/metrics/cpu` · `/memory` | ✅ |
| Network series | — | `.../metrics/network-receive` · `network-transmit` | ✅ |
| Log retention | — | — ️| ❓ not documented — assume bounded, say so when the window is gone |
| Error tracking | — | — | ❓ not a Liara feature; use Sentry or self-hosted GlitchTip |

## Databases

| Capability | CLI | Status |
|---|---|---|
| List / inspect | `db list` | ✅ |
| Create | `db create` | ✅ paid → approval |
| Start / stop | `db start` / `db stop` | ✅ |
| Resize | `db resize` | ✅ paid → approval |
| Backup create | `db backup create` | ✅ **do this before any migration** |
| Backup list / download | `db backup list` / `download` | ✅ |
| Restore | — | ⚠️ verify before relying on it |
| Delete | `db rm` | ✅ **blocked by the guard** |
| Engines | MariaDB, MySQL, PostgreSQL, MSSQL, MongoDB, Redis, ElasticSearch, RabbitMQ | ✅ |

## Plans and pricing

| Capability | Source | Status |
|---|---|---|
| **List plans** | `liara plan list --output json` | ✅ **the only acceptable price source** |
| Plan specs | same | ✅ |
| Hard-coded prices | — | ❌ **forbidden.** Prices change; a confident wrong number costs real money |

## Domains, DNS, TLS

| Capability | CLI | API | Status |
|---|---|---|---|
| List / add domain | — | `GET\|POST /v1/domains` | ✅ |
| Attach to app | — | `POST /v1/domains/set-project` | ✅ |
| Check domain | — | `GET /v1/domains/{id}/check` | ✅ |
| Provision SSL | — | `POST /v1/domains/provision-ssl-certs` | ✅ |
| Disable SSL | — | `POST /v1/domains/{id}/ssl/disable` | ✅ |
| DNS zones / records | `zone *`, `zone record *` | `dns.yaml` | ✅ |
| TLS expiry monitoring | `scripts/health.sh` (openssl) | — | ✅ |

## Disks, storage, other

| Capability | CLI | API | Status |
|---|---|---|---|
| Create / list disks | `disk create` | `GET\|POST /v1/projects/{id}/disks` | ✅ |
| Disk backups | — | `.../disks/{name}/backups` | ✅ |
| Resize disk | — | `.../disks/{dname}/resize` | ✅ |
| FTP access | — | `.../disks/{dname}/ftp`, `/v1/ftp/{fname}` | ✅ |
| Object storage | `bucket *` | `object-storage.yaml` | ✅ |
| Mail | `mail create/send/list` | `mail.yaml` | ✅ |
| VMs (IaaS) | `vm *` | `Iaas.yaml` | ✅ |
| Fixed IP | — | `POST /v1/projects/{id}/fixed-ip/{status}` | ✅ |
| **Read-only mode** | — | `POST /v1/projects/{id}/read-only/{enable\|disable}` | ✅ **a strong brake during incidents** |
| Cron jobs | `liara.json` → `cron[]` | — | ✅ standard cron + command |

## Two findings worth acting on

1. **`zero-downtime`** — exists as an API toggle and is off unless enabled.
   Enable it on production apps; it is the difference between a deploy users
   notice and one they do not.
2. **`read-only`** — enabling it on a production app is a strong structural
   brake. A good default while an agent is new, and a good first move during an
   incident where you suspect bad writes.

## What is NOT available — plan around these

| Gap | Consequence | Work around it with |
|---|---|---|
| No native canary/blue-green | no gradual rollout | two apps + a DNS record flip |
| No single rollback command | rollback = redeploy a good release | keep release ids; test the path before you need it |
| No error tracking | you cannot see client-side errors | Sentry, or self-hosted GlitchTip |
| No uptime monitoring | nothing watches from outside | `scripts/health.sh` on a schedule, or Uptime Kuma |
| Log retention undocumented | an old window may be gone | investigate early; say so when evidence is missing |

## Before adding any new operation

1. Find it in the official CLI help or the OpenAPI spec.
2. Record the method, path, auth, request and response shape.
3. Test it against a **disposable** app.
4. Note its failure modes and whether a retry is safe.
5. Only then add it to the skill file — and mark it ⚠️ until step 3 is done.
