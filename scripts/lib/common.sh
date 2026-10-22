#!/usr/bin/env sh
# Shared helpers for the Liara agent pack. POSIX sh. No bashisms.
# Sourced by every script; never run directly.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STATE_DIR="$PROJECT_DIR/state"
CRED_DIR="$PROJECT_DIR/.liara"
AUDIT_LOG="$STATE_DIR/audit.log"
APPROVAL_DIR="$STATE_DIR/approvals"

mkdir -p "$STATE_DIR" "$CRED_DIR" "$APPROVAL_DIR" 2>/dev/null || true

# ---------- output ----------
c_red()  { printf '\033[31m%s\033[0m\n' "$*"; }
c_grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
info()   { printf '  %s\n' "$*"; }
die()    { c_red "ERROR: $*" >&2; exit 1; }

# ---------- redaction ----------
# Strips anything that looks like a credential from stdin.
# Applied to EVERY command output before it can reach a model context.
redact() {
  sed -E \
    -e 's/(ey[A-Za-z0-9_-]{10,})\.[A-Za-z0-9_.-]+/[REDACTED_JWT]/g' \
    -e 's/([Bb]earer )[A-Za-z0-9._-]{8,}/\1[REDACTED]/g' \
    -e 's/(--api-token[= ])[^ ]+/\1[REDACTED]/g' \
    -e 's/([Tt][Oo][Kk][Ee][Nn]["'"'"']?[=:][ ]*["'"'"']?)[A-Za-z0-9._-]{8,}/\1[REDACTED]/g' \
    -e 's/([Pp]assword["'"'"']?[=:][ ]*["'"'"']?)[^ "'"'"',}]+/\1[REDACTED]/g' \
    -e 's/([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})/[REDACTED_EMAIL]/g' \
    -e 's#(postgres|postgresql|mysql|mongodb|redis|amqp)(\+[a-z]+)?://[^ "'"'"']*#\1://[REDACTED_DSN]#g'
}

# mask abcdefghijklmn -> ****klmn  (last 4 only)
mask() {
  _v="${1:-}"
  _n=$(printf '%s' "$_v" | wc -c | tr -d ' ')
  if [ "$_n" -le 4 ]; then printf '****'; else printf '****%s' "$(printf '%s' "$_v" | tail -c 4)"; fi
}

# ---------- audit ----------
# Append-only record. Never contains secret values (input is redacted).
audit() {
  _action="${1:-unknown}"; shift 2>/dev/null || true
  _detail="$(printf '%s' "${*:-}" | redact | tr '\n' ' ' | cut -c1-500)"
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${LIARA_ENV:-unset}" "$_action" "$_detail" >> "$AUDIT_LOG"
}

# ---------- environment ----------
# Every mutating script must declare which environment it targets.
require_env() {
  case "${LIARA_ENV:-}" in
    staging|production) : ;;
    *) die "LIARA_ENV must be 'staging' or 'production' (got '${LIARA_ENV:-empty}'). See docs/en/02-credentials.md" ;;
  esac
}

is_prod() { [ "${LIARA_ENV:-}" = "production" ]; }

have() { command -v "$1" >/dev/null 2>&1; }
