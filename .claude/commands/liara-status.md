---
description: Is the site up, fast and healthy?
argument-hint: "[url]"
allowed-tools: Task, Bash, Read, Write, Glob, Grep, WebFetch
---

Use the **liara-sre** subagent to report the current state of the site.

URL: ${1:-$LIARA_URL}

Run the liveness check, then read recent logs and platform events only if
something looks wrong. Report in one short paragraph in the user's language,
ending with either "nothing to do" or exactly one recommended action.

Do not fix anything. Diagnose and recommend only.
