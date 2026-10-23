[فارسی](../fa/04-providers.md) · **English**

# 4. Set up your coding environment

First [install the pack in your website repository](00-installation.md).
All paths and commands below are relative to that repository's root. Start or
restart your coding agent there after importing the files.

The [one-command installer](00-installation.md) already creates the client
files below and merges Claude settings. Start with the shared connection
prompt in that guide. The rest of this page is a reference for checking or
customizing an installation; manual configuration is not a prerequisite.

These instructions describe **the integrations supplied by this pack**, not
every feature a provider offers. The same six role files and scripts can be
used elsewhere, but their Claude metadata does not automatically create
native agents or commands in another client.

| Pack integration | Claude Code | Codex CLI / IDE / desktop | Cursor / Windsurf | Aider | Gemini CLI |
|---|---|---|---|---|---|
| Project instructions | `CLAUDE.md` → `AGENTS.md` | `AGENTS.md` | `AGENTS.md` / editor rules | `--read` | `GEMINI.md` import |
| Supplied roles | six native subagents | read role by path | read role by path | `--read` role | read role by path |
| Supplied `/liara-*` commands | yes | use plain prompts | use plain prompts | use plain prompts | use plain prompts |
| Pack's guard hook | when merged settings are active | not wired | not wired | not wired | not wired |

Only the Claude configuration supplied here wires `scripts/guard.sh` to
Bash tool calls. Other providers may offer hooks, but this pack does not
configure them. Read [known security gaps](07-security.md) before granting
production access, including when using Claude Code.

## Claude Code

1. Run the installer from your website folder. It adds `CLAUDE.md`, all of
   `.claude/`, and the common scripts, keeping existing project instructions.
2. If your project already has `.claude/settings.json`, preserve its entries
   while merging the pack's `hooks.PreToolUse` and permission arrays. Keep the
   guard command `sh "$CLAUDE_PROJECT_DIR/scripts/guard.sh"` intact. The
   installer performs this merge automatically.
3. Start a fresh Claude Code session in the website repository. Follow any
   project trust or hook review prompts, then ask it to list the six
   `liara-*` roles and explain the contract in `AGENTS.md`.
4. Run the installation checks in your terminal. Confirm the guard hook is
   active in the client as well; file checks alone do not prove this.

Then use these project commands:

```text
/liara-login          # connect first; you enter the token in a real terminal
/liara-setup          # configure your website
/liara-status
/liara-deploy staging
/liara-plan
/liara-diagnose
/liara-report
```

You can also say: "Use the liara-connect agent to help me connect staging."
The agent must leave `sh scripts/setup.sh connect staging` for you to run.

On Windows, use Git Bash and ensure the shell that launches Claude can find
`sh`. Do not rely on the hook until the checks and client activation succeed.
See Claude's official [subagent guide](https://code.claude.com/docs/en/sub-agents)
and [project settings](https://code.claude.com/docs/en/settings) for discovery
and settings behavior.

## Codex CLI, IDE and desktop

Open the website repository as the project. Codex discovers the root
`AGENTS.md`; start a new session and ask it to summarize the five rules and
identify the role file it will follow. Check for an `AGENTS.override.md` that
could replace the contract at the same directory level. See the official
[AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md/).

For **CLI**, start with local read-only access:

```bash
codex --sandbox read-only --ask-for-approval on-request \
  "Read AGENTS.md and .claude/agents/liara-connect.md. Explain how I connect staging; leave token entry to me."
```

For project configuration, patches or a staging deploy that requires local
writes and network access:

```bash
codex --sandbox workspace-write --ask-for-approval on-request \
  -c sandbox_workspace_write.network_access=true \
  "Follow AGENTS.md and .claude/agents/liara-onboarding.md to configure this website for staging."
```

`on-request` allows the agent to request approval when needed; it does not
ask before every command. Read-only limits local writes, not remote account
changes. Even status scripts write local audit/state files and may need a
reviewed permission request; do not silently broaden access to make them run.

For **IDE or desktop**, open the same website folder, select the available
sandbox and approval controls, and use the same plain-language role prompts.
CLI flags above apply to the CLI. This pack does not register its Claude
subagents or `/liara-*` commands in these clients.

### Optional Codex defaults and skill discovery

You may copy the pack's [`.codex/config.toml`](../../.codex/config.toml) into
your project's `.codex/` if no configuration exists, or merge its three
settings into an existing file. It defaults to read-only with `on-request`
approvals and keeps your chosen model. Project configuration loads only for
trusted projects. Current Codex ignores configuration profiles in project
files and no longer supports `approval_policy = "untrusted"`; the explicit
launch commands above replace the pack's former `liara-*` profile examples.
See the official [configuration reference](https://developers.openai.com/codex/config-reference/).

The installer sets up automatic **skill** discovery in
`.agents/skills/liara-ops/` for you. For a manual installation, copy the complete
`.claude/skills/liara-ops/` folder to `.agents/skills/liara-ops/` in your
website repository. Preserve any existing skill at that destination and
refresh this copy when updating the pack. You can then mention `$liara-ops`.
Without this optional copy, explicitly ask Codex to read
`.claude/skills/liara-ops/SKILL.md` before operations. See the official
[skills guide](https://developers.openai.com/codex/skills/).

Neither the optional configuration nor skill enables the pack's Claude hook
in Codex. Follow the manual guard procedure below before mutations.

## Cursor and Windsurf

Open the website repository. Both support project instructions in `AGENTS.md`.
For an explicit editor rule, add the matching file below while preserving
existing rules; Cursor and Windsurf use different formats.

**Cursor:** `.cursor/rules/liara.mdc`

```markdown
---
description: Liara operations
alwaysApply: true
---
Before any Liara task, read and follow AGENTS.md and
.claude/skills/liara-ops/SKILL.md. Read the chosen role in .claude/agents/.
Use LIARA_ENV=staging sh scripts/liara.sh for CLI operations.
Leave token entry and approval grants to the human.
```

**Windsurf:** `.windsurf/rules/liara.md`

```markdown
---
trigger: always_on
---
Before any Liara task, read and follow AGENTS.md and
.claude/skills/liara-ops/SKILL.md. Read the chosen role in .claude/agents/.
Use LIARA_ENV=staging sh scripts/liara.sh for CLI operations.
Leave token entry and approval grants to the human.
```

Start a fresh chat and ask it to identify the contract and follow
`.claude/agents/liara-connect.md` for staging. Verify the rule appears in
context. These rule files supply instructions; they do not wire the pack's
command guard. Official references: [Cursor rules](https://cursor.com/docs/context/rules)
and [Windsurf rules](https://docs.windsurf.com/windsurf/cascade/memories).

## Aider

From the website repository, load the contract, reference and chosen role as
read-only context:

```bash
aider --read AGENTS.md --read .claude/skills/liara-ops/SKILL.md \
  --read .claude/agents/liara-connect.md
```

Or merge these entries into the existing `read` list in `.aider.conf.yml`:

```yaml
read:
  - AGENTS.md
  - .claude/skills/liara-ops/SKILL.md
  - .claude/agents/liara-connect.md
```

Ask it to explain the staging connection process. For a different role,
change the final path. The `--read` flag protects those context files from
editing; it is not a sandbox for shell commands. The pack installs no Aider
hook. See the official [Aider options](https://aider.chat/docs/config/options.html).

## Gemini CLI

Add an explicit import to your website's `GEMINI.md`, preserving its existing
instructions:

The installer adds this import automatically; use the example below only
when configuring it manually.

```markdown
@./AGENTS.md

Before Liara operations, read .claude/skills/liara-ops/SKILL.md and the
chosen role in .claude/agents/. Default to staging; token entry and approval
grants belong to the human.
```

Restart Gemini in the website repository. Use `/memory show` to check the
contract is loaded, then ask it to follow `.claude/agents/liara-connect.md`.
The pack installs no Gemini hook. See the official
[GEMINI.md guide](https://geminicli.com/docs/cli/gemini-md/).

## Other coding agents

Use a local project session with file and POSIX shell access. Add this to
its project instructions, or send it as the first prompt:

```text
Read AGENTS.md and .claude/skills/liara-ops/SKILL.md first.
For this task, follow .claude/agents/liara-connect.md.
Work from this website repository root and default to staging.
Use only LIARA_ENV=staging sh scripts/liara.sh for Liara CLI operations.
Run the command guard before mutations. Leave token entry and approval
creation to the human. Explain the next step without asking for a token.
```

Change the role path for onboarding, deployment, status, plans, or debugging.
Ask the client to list what it loaded before operations. A chat without file
or shell access can explain these instructions but cannot operate the pack.

## Manual command guard outside Claude Code

The contract requires a guard check before a mutating command. For example,
after connecting staging and passing preflight, check this fixed command:

```bash
CMD='LIARA_ENV=staging sh scripts/liara.sh deploy --app my-site-staging --path .'
printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$CMD" \
  | sh scripts/guard.sh && eval "$CMD"
```

Replace the example app name with your configured staging app. This JSON
construction is for the literal command shown; commands containing quotes,
backslashes or newlines require proper JSON encoding. Only run the exact
command that passed the guard, and stop if it blocks. A manual check is not
automatic enforcement of later tool calls.

Use the client's restrictive sandbox and review consequential actions.
Keep production credentials off environments where the pack's guard is not
active. Production writes still require the human's single-use approval as
explained in [Credentials](02-credentials.md); a client permission prompt does
not replace that approval. After any deploy, run the health verification
before reporting success.
