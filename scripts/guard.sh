#!/usr/bin/env sh
# PreToolUse hook (Bash). Wired in .claude/settings.json.
#
# Exit 0 = allow.  Exit 2 = block, and stderr is shown to the agent.
#
# This is a DENY-LIST on the raw hook payload. It matches the whole JSON body,
# so it cannot be bypassed by quoting tricks, variable indirection or
# concatenation inside the command string.
#
# The agent cannot disable this. Only a human editing settings.json can.
#
. "$(dirname "$0")/lib/common.sh" 2>/dev/null || { PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"; }

PAYLOAD="$(cat)"
LOW="$(printf '%s' "$PAYLOAD" | tr '[:upper:]' '[:lower:]')"

block() {
  printf 'BLOCKED by scripts/guard.sh: %s\n\n%s\n' "$1" "$2" >&2
  [ -n "${AUDIT_LOG:-}" ] && printf '%s\tguard\tblocked\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$AUDIT_LOG" 2>/dev/null
  exit 2
}

match() { printf '%s' "$LOW" | grep -Eq "$1"; }

# ── 1. Never, under any circumstance ──────────────────────────────────────────
match 'rm +(-[a-z]+ +)*-[a-z]*r[a-z]*f|rm +-rf' \
  && block "recursive force delete" "If a file really must be removed, remove it by name."
match 'liara +(app +)?(rm|remove|delete)' \
  && block "deleting a Liara app" "Deleting an app is irreversible. A human must do this in console.liara.ir."
match 'liara +db +(rm|remove|delete)' \
  && block "deleting a Liara database" "Irreversible, and backups go with it. A human must do this in the console."
match 'drop +(database|table)|truncate +table' \
  && block "destructive SQL" "Propose a migration in a PR instead. Never run this from an agent session."
match 'liara +bucket +delete|liara +zone +(rm|delete)|liara +vm +(rm|delete)' \
  && block "deleting infrastructure" "A human must do this in the console."
match 'git +push +(-f|--force)|git +reset +--hard +origin' \
  && block "force-pushing or hard-resetting a remote branch" "Open a normal PR instead."

# ── 2. Secrets must never leave the machine ───────────────────────────────────
match 'cat +[^|&;]*\.liara/token|creds\.sh +print-token' \
  && block "reading a stored API token" \
     "Tokens are deliberately unreadable by you. Use: sh scripts/creds.sh status (masked)."
match '(curl|wget|nc|invoke-webrequest)[^|&;]*(\$liara_api_token|token\.(staging|production))' \
  && block "sending a credential over the network" "This is never allowed."
# Reading a real .env only. `cat > .env.example` is a write, not a leak,
# and .env.example / .sample / .template hold no secrets by definition.
if match '(cat|type|more|less|head|tail) +(-[a-z0-9]+ +)*[^|\&;>]*[.]env([^a-z.]|$)' \
   && ! match '[.]env[.](example|sample|template)'; then
  block "printing a .env file" "Use: sh scripts/liara.sh env list (names only, values masked)."
fi

# ── 3. Bypassing the wrapper ──────────────────────────────────────────────────
# The agent must go through scripts/liara.sh so that env scoping, redaction,
# audit and approvals apply. A bare `liara` call skips all four.
if match '(^|["[:space:];&|])liara +' && ! match 'scripts/liara\.sh|creds\.sh|liara --version|liara --help|liara help'; then
  block "calling the Liara CLI directly" \
    "Use the wrapper so scoping, redaction, audit and approvals apply:
  LIARA_ENV=staging sh scripts/liara.sh <args>"
fi
match '[-][-]api[-]token' \
  && block "passing a token on the command line" "scripts/liara.sh injects it for you."

# ── 4. Production writes need a consumable approval ───────────────────────────
if match 'liara_env=production|liara_env="production"'; then
  case "$LOW" in
    *list*|*" ls"*|*logs*|*whoami*|*inspect*|*metrics*|*status*|*check*) : ;;
    *)
      if ! sh "$PROJECT_DIR/scripts/approve.sh" check prod-write >/dev/null 2>&1; then
        block "production write without approval" \
          "Explain the change, then ask the human to run:
  sh scripts/approve.sh grant prod-write
It is single-use and expires in 15 minutes."
      fi ;;
  esac
fi

exit 0
