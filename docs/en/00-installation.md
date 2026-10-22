[فارسی](../fa/00-installation.md) · **English**

# 0. Install the agents in your own project

Install this pack in the repository that contains your website's code. The
pack supplies instructions and tools; it does not contain your website.
Cloning the pack alone does not install it into another project.

## Before you start

- Install your coding agent and sign in using its own instructions. This is
  separate from connecting your Liara account.
- Install Git, Node.js 20+, and `curl`. On Windows, use **Git Bash** for every
  shell example below; `sh` must also be available to the coding agent's shell.
- Open a terminal at your **website repository root**, where its application
  files live. Review or commit existing work before importing files.

## 1. Get the pack

From your website repository, clone a separate source copy beside it:

```bash
git clone https://github.com/mhbdev/liara-agent.git ../liara-agent-pack
LIARA_PACK="$(cd ../liara-agent-pack && pwd)"
```

If you already downloaded or cloned it elsewhere, set `LIARA_PACK` to that
folder's absolute path instead. A ZIP download from the repository's **Code**
menu also works. Keep this source copy outside the website repository so a
deployment does not accidentally include it.

## 2. Import the project files

Choose **one** method below. Run commands from your website repository, in
the same terminal where you set `LIARA_PACK`.

### First installation with no conflicting paths

This block checks all destination paths before copying. If it reports an
existing path, it makes no changes: use the merge method below.

```bash
(
  set -eu
  for item in AGENTS.md CLAUDE.md .claude scripts tests/guard-cases.txt \
    docs/en docs/fa env.example liara.json.example OPERATIONS.template.md
  do
    if [ -e "$item" ] || [ -L "$item" ]; then
      printf 'Already exists: %s. Use the merge method.\n' "$item" >&2
      exit 1
    fi
  done

  mkdir -p tests docs
  for item in AGENTS.md CLAUDE.md env.example liara.json.example OPERATIONS.template.md
  do
    cp "$LIARA_PACK/$item" "$item"
  done
  cp -R "$LIARA_PACK/.claude" .claude
  cp -R "$LIARA_PACK/scripts" scripts
  cp "$LIARA_PACK/tests/guard-cases.txt" tests/guard-cases.txt
  cp -R "$LIARA_PACK/docs/en" docs/en
  cp -R "$LIARA_PACK/docs/fa" docs/fa

  printf '\n# Liara credentials and local state\n' >> .gitignore
  printf '%s\n' '.liara/' '.env' '.env.*' '!.env.example' 'state/' >> .gitignore
)
```

The pack's README, `.git` directory, credentials, and local state are not
imported. Your project's own README and application code stay in place.

### Existing agent configuration or shared directories

Use your editor or a file comparison tool to merge the following paths from
`LIARA_PACK` into the **same paths** in your website repository. Copy missing
files; compare existing files before changing them.

| Source → project destination | How to merge |
|---|---|
| `AGENTS.md` | Add the Liara contract to the project's instructions, keeping existing project rules. Resolve conflicting rules before running operations. |
| `CLAUDE.md` | Keep existing instructions; add the pack's Claude guidance and its requirement to read `AGENTS.md`. An `@AGENTS.md` line explicitly imports the contract in Claude Code. |
| `.claude/agents/liara-*.md` | Copy all six role definitions, preserving unrelated agents. |
| `.claude/commands/liara-*.md` | Copy all seven commands, preserving unrelated commands. |
| `.claude/skills/liara-ops/` | Copy the complete reference folder. Other providers can read it at this path too. |
| `.claude/settings.json` | Merge `hooks.PreToolUse` entries and `permissions.allow` / `permissions.deny` arrays with existing entries. Keep the guard command and deny rules intact; do not replace the whole settings file. |
| `scripts/` | Copy every pack script, including `lib/common.sh`. If a same-name script already differs, resolve the collision before continuing. |
| `tests/guard-cases.txt` | Copy the guard's test data; keep the project's other tests. |
| `docs/en/`, `docs/fa/` | Add these guides so references in the agent instructions resolve. Merge any same-name documents. |
| `env.example`, `liara.json.example`, `OPERATIONS.template.md` | Add templates; preserve existing application configuration. |
| `.gitignore` | Add `.liara/`, `.env`, `.env.*`, `!.env.example`, and `state/`, preserving existing rules. |

Keep `scripts/` and `.claude/` at the project root. The hooks, commands and
scripts refer to those paths. Installing the pack under `tools/liara/`, or
copying just the agent Markdown files, does not wire the complete pack.

Never copy `.liara/`, `.env`, `state/`, or approvals from another installation.
Ignore rules do not remove files already tracked by Git; resolve any tracked
credentials before connecting an account, without printing their contents.

## 3. Activate your coding environment

Use the [provider guide](04-providers.md) for the exact startup instructions:

| Environment | Project integration | First use |
|---|---|---|
| **Claude Code** | `CLAUDE.md`, `.claude/agents/`, commands, skill, and merged settings | Restart in the website repository; ask it to use `liara-connect`, or run `/liara-login`. |
| **Codex CLI / IDE / desktop** | Root `AGENTS.md`; role files are read by reference | Open the website repository and ask it to follow `.claude/agents/liara-connect.md`. Use the CLI sandbox options in the provider guide. |
| **Cursor** | Root `AGENTS.md`; optional `.cursor/rules/liara.mdc` | Open the website repository and request a role by its file path. |
| **Windsurf** | Root `AGENTS.md`; optional `.windsurf/rules/liara.md` | Open the website repository and request a role by its file path. |
| **Aider** | Load the contract, reference and chosen role with `--read` | Use the command in the provider guide. |
| **Gemini CLI** | Import `AGENTS.md` from `GEMINI.md` | Restart Gemini in the website repository and request a role by its file path. |
| **Other coding agents** | Explicitly load `AGENTS.md`, the Liara skill, and a role file | Use the portable prompt in the provider guide; shell access is required for operations. |

The import deliberately leaves your existing `.codex/config.toml` alone.
Optional Codex configuration and skill discovery are covered in the provider
guide. Installing the Liara skill alone does not install the scripts or roles.

This is a project installation, shared through your project's Git history.
Copying role files to `~/.claude/agents/` or a skill to `~/.agents/skills/`
does not install the project tools, settings, or contract for every project.

## 4. Check, connect, then configure

In your website repository:

```bash
npm install -g @liara/cli
sh scripts/setup.sh check
sh scripts/test-guard.sh
```

Fix failures before continuing. The check verifies files and runs guard cases;
it does **not** prove your coding agent loaded the instructions or that a live
hook is active. Follow the provider's activation checks too.

The current checkout has two documented guard regression failures. See
[known security gaps](07-security.md) if those cases fail; do not skip them or
report the installation's command protection as verified.

Then **you, the human**, run this in a real terminal:

```bash
sh scripts/setup.sh connect staging
```

Never put the token in chat. The agent may then run `setup.sh status`,
`setup.sh verify staging` and `setup.sh discover staging` to check the
connection without seeing the token.

Continue with [Quickstart, step 4](01-quickstart.md#step-4--configure-the-project)
to adapt `liara.json` and create `OPERATIONS.md` for your actual website.

## Updating an installed pack

Update the separate source copy, review its Git diff, and repeat the merge
method for the changed files. Review configuration changes as a human; do not
replace your project's instructions, hooks, or scripts wholesale. Repeat the
installation checks after each update. Local credentials and approvals stay
local and are never copied between projects.
