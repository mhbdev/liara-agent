---
description: Find the cause of a failure and prepare a reviewable fix
argument-hint: "[what is broken]"
allowed-tools: Task, Bash, Read, Write, Edit, Glob, Grep
---

Use the **liara-debug-fix** subagent.

Problem: ${1:-investigate the most recent failure}

Read `state/incidents/` first — this system's own history is the best prior.
Reproduce before theorising. Quote the evidence for every claim. Write the
failing test before the fix.

Your output is a patch plus a handover note, never a production deployment.
