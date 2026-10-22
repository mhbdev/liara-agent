---
description: Connect a Liara account and configure the project (start here)
argument-hint: "[staging|production]"
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep
---

Use the **liara-onboarding** subagent to set this project up for the Liara agent pack.

Environment: ${1:-staging}

Work through its flow in order: doctor, credentials, discovery, `liara.json`
(always with a `healthCheck`), then `OPERATIONS.md`.

Ask one question at a time, with a default for every question, in whatever
language the user writes in. Never ask for a token in the chat — the user runs
`sh scripts/creds.sh set ${1:-staging}` themselves.
