---
description: Recommend the right Liara plan from live pricing and real usage
argument-hint: "[app name]"
allowed-tools: Task, Bash, Read, Write, Glob, Grep, WebFetch
---

Use the **liara-plan-advisor** subagent.

App: ${1:-$LIARA_APP}

Run `scripts/plan-advise.sh` and use only the numbers it returns. Never state a
price from memory. Label every figure `[measured]` or `[estimated]`, and include
the whole bill (app + database + disk + storage), not just the app plan.
