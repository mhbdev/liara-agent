---
description: Daily site report in plain language
allowed-tools: Task, Bash, Read, Write, Glob, Grep
---

Use the **liara-sre** subagent to produce today's report.

Collect: liveness and latency, errors in the last 24h grouped by type, yesterday's
deploys and their outcome, disk and memory headroom, TLS expiry days, and any
open incident in `state/incidents/`.

Output one paragraph in the user's language, with a traffic light
(green / yellow / red) and either "nothing to do" or one single recommended
action. No dashboards, no tables, no lists of five things to triage.
