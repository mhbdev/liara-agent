---
description: Deploy with pre-flight, approval and verification
argument-hint: "[staging|production] [message]"
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep
---

Use the **liara-deploy** subagent to publish this project.

Target environment: ${1:-staging}
Release message: ${2:-}

Follow the sequence without skipping: pre-flight → plan → approval → deploy →
verify → report.

If the target is `production`, present the plan and stop for the human to run
`sh scripts/approve.sh grant prod-write`. Report success only if
`scripts/health.sh` passed.
