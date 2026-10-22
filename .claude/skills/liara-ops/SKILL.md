---
name: liara-ops
description: Operating a site on Liara — the verified CLI and API surface, the safe-command wrapper, credential rules, approval gates and the pre-flight gate. Load before any deploy, log read, metric read, plan lookup, health check or incident investigation on Liara, and whenever a Liara token, app, database, disk, domain or plan is involved.
---

# Liara operations — verified reference

Everything here was checked against Liara CLI **v9.6.0** and the official
OpenAPI specs in `liara-cloud/openapi` on 2026-10-22. If a command or endpoint
is not in this file, verify it before using it — do not infer that an operation
exists because it would be convenient.

## The one rule

Call the CLI **only** through the wrapper:

```bash
LIARA_ENV=staging sh scripts/liara.sh <args...>
```

A bare `liara` call is blocked by `scripts/guard.sh`, because it bypasses
environment scoping, output redaction, the audit trail and the approval gate.
That is four protections, not a style preference.

## Credentials

- Tokens come from <https://console.liara.ir/API>, with expiry from 1 hour to 1 year.
- A token is shown **once**.
- Stored per environment, gitignored, 0600, and DPAPI-encrypted on Windows:
  `.liara/token.staging`, `.liara/token.production`
- **The agent never sees a token.** The human runs `sh scripts/creds.sh set <env>`
  with hidden input. The agent reads only the masked output of
  `sh scripts/creds.sh status`.
- Never ask for a token in chat. Never `cat` one. Both are blocked.

## Verified CLI commands

```bash
# apps
sh scripts/liara.sh app list
sh scripts/liara.sh app logs --app NAME
sh scripts/liara.sh app restart --app NAME
sh scripts/liara.sh app shell --app NAME          # interactive; rarely right for an agent
sh scripts/liara.sh app start|stop --app NAME
sh scripts/liara.sh app update-port --app NAME

# deploy
sh scripts/liara.sh deploy --app NAME --path . --message "msg" --detach
#   also: -p/--port  -i/--image  -f/--dockerfile  --no-cache  --build-arg
#         -b iran|germany  -d/--disks  --liara-json  --platform  --args

# logs
sh scripts/liara.sh logs --app NAME --since "1 hour ago" --timestamps
sh scripts/liara.sh logs --app NAME -r v12        # one specific release
#   also: -f/--follow  -c/--colorize  -l/--last-lines

# env vars  (values are never printed by the wrapper)
sh scripts/liara.sh env list --app NAME
sh scripts/liara.sh env set KEY=value --app NAME
sh scripts/liara.sh env unset KEY --app NAME      # needs approval

# databases
sh scripts/liara.sh db list
sh scripts/liara.sh db backup create              # do this before any migration
sh scripts/liara.sh db backup list|download
sh scripts/liara.sh db resize                     # paid change -> approval

# plans  (the only acceptable source of prices)
sh scripts/liara.sh plan list --output json

# other
sh scripts/liara.sh disk create
sh scripts/liara.sh zone list | zone record create|update|list
sh scripts/liara.sh bucket list
sh scripts/liara.sh whoami
```

## Verified API surface

Base URL `https://api.liara.ir`, bearer token auth.

| Purpose | Endpoint |
|---|---|
| List apps | `GET /v1/projects` |
| Inspect app | `GET /v1/projects/{name}` |
| Restart | `POST /v1/projects/{name}/actions/restart` |
| Scale | `POST /v1/projects/{name}/actions/scale` |
| Resize | `POST /v1/projects/{name}/resize` |
| Upload source | `POST /v2/projects/{name}/sources` |
| Create release | `POST /v2/projects/{name}/releases` |
| Release history | `GET /v1/projects/{name}/releases` |
| Logs | `GET /v1/projects/{name}/logs` |
| **Platform events** | `GET /v1/projects/{name}/events` |
| **Metrics summary** | `GET /v1/projects/{name}/metrics/summary` → `cpuUsage`, `memoryUsage`, `disksUsage` |
| Metrics detail | `GET /v1/projects/{name}/metrics/{cpu,memory,network-receive,network-transmit}` |
| Update env vars | `POST /v1/projects/update-envs` |
| **Zero-downtime toggle** | `POST /v1/projects/{id}/zero-downtime/{enable|disable}` |
| **Read-only toggle** | `POST /v1/projects/{id}/read-only/{enable|disable}` |
| Fixed IP | `POST /v1/projects/{id}/fixed-ip/{status}` |
| Disks | `GET|POST /v1/projects/{id}/disks`, `.../backups`, `.../resize` |
| Domains | `GET|POST /v1/domains`, `/v1/domains/set-project`, `/v1/domains/{id}/check` |
| SSL | `POST /v1/domains/provision-ssl-certs`, `POST /v1/domains/{id}/ssl/disable` |

Two of these are worth knowing about explicitly:

- **zero-downtime** — enable it on production apps. It is the difference between
  a deploy users notice and one they do not.
- **read-only** — enabling it on a production app is a strong structural brake
  during an incident, and a good default while an agent is learning.

Other specs in the same repo: `dbaas.yaml`, `object-storage.yaml`, `dns.yaml`,
`mail.yaml`, `file-browser.yaml`, `Iaas.yaml`.

## liara.json

```json
{
  "app": "my-site",
  "platform": "node",
  "port": 3000,
  "build": { "location": "iran" },
  "disks": [{ "name": "uploads", "mountTo": "/app/uploads" }],
  "cron": ["0 1 * * * cd $ROOT && node scripts/nightly.js >> /dev/null 2>&1"],
  "healthCheck": {
    "command": "CMD curl --fail http://localhost:3000/api/health || exit 1",
    "interval": 30, "timeout": 15, "retries": 2, "startPeriod": 5
  }
}
```

Three facts that matter:

1. **`healthCheck` gates the release.** If the check fails, the deployment
   fails and the broken build never serves traffic. This is the cheapest safety
   you can buy — always set it.
2. **`envs` in this file REPLACES every stored variable** on deploy. This pack
   therefore uses `liara env set` instead, and `preflight.sh` warns if `envs`
   appears here.
3. `platform` is only needed when detection is ambiguous — Fastify and Gatsby
   are the documented cases.

## Approval gates

Granted by a human, single-use, expiring in 15 minutes:

```bash
sh scripts/approve.sh grant prod-write      # any production mutation
sh scripts/approve.sh grant prod-deploy     # production release
sh scripts/approve.sh grant destructive     # delete/remove anything
sh scripts/approve.sh grant rollback        # production rollback
sh scripts/approve.sh grant db-migration    # schema change
sh scripts/approve.sh grant resize          # paid resource change
```

The agent cannot create these. A prompt cannot write a file.

## Blocked outright — no approval path

`liara app rm/delete` · `liara db rm/delete` · `rm -rf` · `DROP`/`TRUNCATE` ·
`git push --force` · reading a stored token · sending a credential over the
network · `cat .env` · bare `liara` · `--api-token` on the command line.

A human does these in the console, deliberately, or not at all.

## Honest limits

- The CLI takes the token as a **command-line flag**, so it is briefly visible
  in the local process list. Acceptable on a single-user machine; see
  `docs/en/07-security.md`.
- Log retention is bounded. If the window has passed, say so rather than
  reasoning from nothing.
- `liara app shell` is interactive and generally wrong for an agent — prefer
  logs and metrics.
- HTTP 200 on a homepage is **not** evidence the application works.
