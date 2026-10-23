[فارسی](../fa/00-installation.md) · **English**

# 0. Get started in your project

You need **Node.js 20+**, **Git**, and your preferred coding agent. On Windows,
install Git for Windows; use its Git Bash terminal when running Liara's shell
tools later. Connecting your Liara account comes after installation.

## 1. Run one command

Open a terminal in **your website's folder** and run:

```bash
npx --yes github:mhbdev/liara-agent
```

The installer downloads the pack and adds the project files for **Claude Code,
Codex, Cursor, Windsurf, Aider and Gemini** together. There is no provider choice,
manual copying, separate source folder, or global agent installation to manage.
Your website's dependencies and `package.json` stay unchanged.

## 2. Restart your coding agent and ask

Open the same website folder in your coding agent, start a fresh chat, and say:

```text
Help me connect Liara and configure this project for staging.
```

In Claude Code you can also use `/liara-login`, then `/liara-setup`.
Your agent will guide the remaining tool checks and account connection.
**Enter the token only in your own terminal**, never in chat. Installation
itself does not read credentials, connect an account, or deploy anything.

That's the starting path. The [quickstart](01-quickstart.md) explains the
remaining steps if you prefer to do them yourself; [provider details](04-providers.md)
cover client-specific controls and activation checks.

## If your project already has agent settings

The installer handles the usual case for you:

- Keeps existing project instructions and appends a clearly marked Liara section.
- Merges Claude permissions and hooks while keeping existing entries.
- Preserves existing Codex and Aider configuration. If Aider already has a
  configuration, the installer prints the exact startup command to load Liara.
- Adds credential ignore rules and copies the scripts, roles and reference files.
- Refuses conflicting pack files or linked destination paths before writing.
  If it stops, it names the paths to review; there is no overwrite option.

It leaves `.env`, `.liara/`, local state, application configuration and your
website's README alone. A repeat run with the same pack makes no changes.
Use your project's Git diff to review the installation.

## Optional: preview or choose a folder

See what would change without writing files:

```bash
npx --yes github:mhbdev/liara-agent --dry-run
```

Install into a particular website folder:

```bash
npx --yes github:mhbdev/liara-agent --project "/path/to/my website"
```

## Prefer a download or clone?

From your website folder:

```bash
git clone https://github.com/mhbdev/liara-agent.git ../liara-agent-pack
node ../liara-agent-pack/bin/install.mjs
```

A ZIP download also works: run `node /path/to/liara-agent/bin/install.mjs`
from your website folder. Keep the downloaded source outside the website.

## Before operating the site

Project files being installed does not prove a client activated its hooks or
that a deployment is healthy. Let the Connect agent guide the checks, or use
[Quickstart](01-quickstart.md). Liara operations need the Liara CLI, `curl` and
`sh`; the agent will explain any missing prerequisites.

The current pack has two documented guard test failures. See
[known security gaps](07-security.md); do not skip failing checks or report
command protection as verified. The installer does not alter these guards.

## Updating later

Run the same installer command. Identical files are left alone. If an installed
pack file differs from the downloaded version, installation stops before
writing so you can review the changes. It never silently replaces scripts or
local changes, and never copies credentials or approvals between projects.
