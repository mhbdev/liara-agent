#!/usr/bin/env sh
# Controlled wrapper around the official Liara CLI.
#
# Why this exists instead of letting the agent call `liara` directly:
#   - resolves the token for the CURRENT environment only (staging by default)
#   - passes arguments as an argv array; never builds a shell string
#   - enforces a timeout and an output cap
#   - redacts every byte of output before it can reach a model context
#   - writes an audit record for each invocation
#
#   LIARA_ENV=staging sh scripts/liara.sh app list
#   LIARA_ENV=staging sh scripts/liara.sh logs --app my-site --since "30 minutes ago"
#
. "$(dirname "$0")/lib/common.sh"

TIMEOUT="${LIARA_TIMEOUT:-180}"
MAX_LINES="${LIARA_MAX_LINES:-400}"

[ "$#" -gt 0 ] || die "usage: liara.sh <liara-cli-args...>"
: "${LIARA_ENV:=staging}"
require_env
have liara || die "Liara CLI not found — run: npm install -g @liara/cli"

# Second line of defence. The hook in .claude/settings.json is the first.
case "$*" in
  *" rm "*|*" remove "*|*" delete "*|*"app rm"*|*"db rm"*|*"bucket delete"*|*"zone rm"*|*"vm rm"*)
    "$PROJECT_DIR/scripts/approve.sh" check "destructive" \
      || die "destructive command needs an approval — ask the human to run: sh scripts/approve.sh grant destructive" ;;
esac
if is_prod; then
  case "$1" in
    deploy|env|app|db|disk|zone|vm|bucket)
      case "$*" in
        *list*|*ls*|*logs*|*whoami*|*inspect*|*info*|*show*|*get*|*check*) : ;;
        *) "$PROJECT_DIR/scripts/approve.sh" check "prod-write" \
             || die "production write needs an approval — ask the human to run: sh scripts/approve.sh grant prod-write" ;;
      esac ;;
  esac
fi

TOKEN="$("$PROJECT_DIR/scripts/creds.sh" print-token "$LIARA_ENV" 2>/dev/null)" || TOKEN=""
[ -n "$TOKEN" ] || die "no credentials for '$LIARA_ENV' — run: sh scripts/setup.sh connect $LIARA_ENV"

audit "liara.$1" "env=$LIARA_ENV args=$*"

# NOTE: the CLI only accepts the token as a flag, so it is briefly visible in the
# local process list. Acceptable on a single-user dev machine; documented in
# docs/en/07-security.md. Nothing is written to disk or to the audit log.
run() {
  if have timeout; then
    timeout "$TIMEOUT" liara "$@" --api-token "$TOKEN" 2>&1
  else
    liara "$@" --api-token "$TOKEN" 2>&1
  fi
}

run "$@" | redact | head -n "$MAX_LINES"
_rc=$?
TOKEN=""
exit "$_rc"
