---
description: Connect a Liara account by chatting — login and credentials in one place
argument-hint: "[staging|production]"
allowed-tools: Task, Bash, Read, Write, Glob, Grep
---

Use the **liara-connect** subagent to get this machine connected to Liara.

Environment: ${1:-staging}

Start by running `sh scripts/setup.sh status` to see where things stand, and
route from there — do not make the user redo setup that already works.

The token step (`setup.sh connect`) needs a real terminal. Open a terminal tab
for them and run it there so they can type without leaving the conversation.
**Never ask for the token in chat, and never accept one that is pasted** — if
they paste it, tell them it is compromised and have them reissue it at
<https://console.liara.ir/API>.

Default to staging, and recommend against setting up production until they
actually have something to deploy.
