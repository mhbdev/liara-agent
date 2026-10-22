#!/usr/bin/env sh
# ONE front door for connecting a Liara account.
#
# Everything the onboarding conversation needs, in one script, so neither the
# user nor the agent has to remember doctor.sh / creds.sh / liara.sh.
#
#   sh scripts/setup.sh                    # the full guided wizard
#   sh scripts/setup.sh check              # environment only
#   sh scripts/setup.sh connect staging    # interactive, hidden token input
#   sh scripts/setup.sh verify staging     # does the stored token work?
#   sh scripts/setup.sh status             # masked summary (safe for the agent)
#   sh scripts/setup.sh discover           # what exists in the account
#
# WHICH OF THESE THE AGENT MAY RUN ITSELF:
#   check, status, verify, discover   -> yes, no secret is involved
#   connect                           -> NO. It needs a human at a keyboard,
#                                        because the token is typed with hidden
#                                        input and must never enter the chat.
#
. "$(dirname "$0")/lib/common.sh"

CREDS="$PROJECT_DIR/scripts/creds.sh"
LIARA="$PROJECT_DIR/scripts/liara.sh"

hr()  { printf '  ────────────────────────────────────────────────────────\n'; }
step() { printf '\n  %s\n'  "$*"; hr; }

# ── check ────────────────────────────────────────────────────────────────────
cmd_check() {
  step "1/4  Environment"
  rc=0
  chk() {
    if eval "$2" >/dev/null 2>&1; then printf '  [ ok ] %s\n' "$1"
    else printf '  [FAIL] %-22s %s\n' "$1" "$3"; rc=1; fi
  }
  chk "Liara CLI" "command -v liara" "npm install -g @liara/cli"
  chk "curl"      "command -v curl"  "install curl"
  chk "node"      "command -v node"  "install Node.js 20+"
  chk "git"       "command -v git"   "install git"
  chk "guard hook wired" "grep -q guard.sh '$PROJECT_DIR/.claude/settings.json'" \
      "restore .claude/settings.json"
  chk "secrets gitignored" "grep -q '.liara/' '$PROJECT_DIR/.gitignore'" \
      "add .liara/ to .gitignore"

  printf '\n  Guard self-test (these MUST be blocked)\n'
  for t in "rm -rf /" "liara app rm x"; do
    if printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$t" \
       | sh "$PROJECT_DIR/scripts/guard.sh" >/dev/null 2>&1
    then printf '  [FAIL] guard ALLOWED: %s\n' "$t"; rc=1
    else printf '  [ ok ] blocked: %s\n' "$t"; fi
  done
  return "$rc"
}

# ── connect ──────────────────────────────────────────────────────────────────
cmd_connect() {
  _env="${1:-staging}"
  case "$_env" in staging|production) ;; *) die "usage: setup.sh connect <staging|production>" ;; esac

  step "2/4  Connect your Liara account ($_env)"
  if [ ! -t 0 ]; then
    c_red "  This step needs a real terminal — you have to type the token."
    printf '\n  Open a terminal in this folder and run:\n\n'
    printf '      sh scripts/setup.sh connect %s\n\n' "$_env"
    return 3
  fi

  cat <<TXT
  Where to get the token:
    1) Open  https://console.liara.ir/API
    2) Pick an expiry:
          $_env  ->  $(if [ "$_env" = production ]; then echo "1 day or 7 days"; else echo "1 month"; fi)
    3) Click  "ساخت کلید جدید" / "Create new key"
    4) Copy it — it is shown ONCE

  What happens to it:
    - your typing is hidden
    - it is encrypted on this machine (DPAPI on Windows, 0600 elsewhere)
    - it is NEVER printed, logged, committed, or shown to the AI

TXT
  sh "$CREDS" set "$_env"
}

cmd_verify()  { step "3/4  Verify"; sh "$CREDS" verify "${1:-staging}"; }
cmd_status()  { sh "$CREDS" status; }

# ── discover ─────────────────────────────────────────────────────────────────
# Reads the account and saves a NON-SECRET context file the agents can use.
cmd_discover() {
  _env="${1:-staging}"
  step "4/4  What is in your account"

  sh "$CREDS" verify "$_env" >/dev/null 2>&1 \
    || { c_ylw "  No working credentials for $_env yet — run: sh scripts/setup.sh connect $_env"; return 1; }

  printf '  Apps\n'
  LIARA_ENV="$_env" sh "$LIARA" app list 2>/dev/null | sed 's/^/    /' || info "could not list apps"
  printf '\n  Databases\n'
  LIARA_ENV="$_env" sh "$LIARA" db list 2>/dev/null | sed 's/^/    /' || info "none, or not readable"

  # Non-secret context, safe to read and safe to show.
  cat > "$CRED_DIR/context.json" <<JSON
{"env":"$_env","connected_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","cli":"$(liara --version 2>/dev/null | head -1)"}
JSON
  audit "setup.discover" "env=$_env"
}

# ── the wizard ───────────────────────────────────────────────────────────────
cmd_all() {
  _env="${1:-staging}"
  printf '\n  Liara agent pack — guided setup\n'
  printf '  Target environment: %s\n' "$_env"

  cmd_check || { printf '\n'; c_red "  Fix the FAIL lines above first, then run this again."; return 1; }

  if sh "$CREDS" verify "$_env" >/dev/null 2>&1; then
    step "2/4  Connect your Liara account ($_env)"
    c_grn "  Already connected and working — skipping."
  else
    cmd_connect "$_env" || return $?
  fi

  cmd_verify "$_env"  || return 1
  cmd_discover "$_env" || true

  step "Done"
  cat <<TXT
  Next, in your AI agent, just talk to it:

      "وضعیت سایت چطوره؟"      /  "is the site up?"
      "منتشر کن"                /  "deploy it"
      "کدوم پلن رو بخرم؟"       /  "which plan should I buy?"

  Or run the setup agent to finish liara.json and OPERATIONS.md:

      /liara-login       (connect / re-connect an account)
      /liara-setup       (configure the project)

  Production: deliberately NOT set up. Add it later with
      sh scripts/setup.sh connect production
  and read docs/en/02-credentials.md first.

TXT
  audit "setup.complete" "env=$_env"
}

case "${1:-all}" in
  all|wizard|'')  shift 2>/dev/null || true; cmd_all "${1:-staging}" ;;
  check)          cmd_check ;;
  connect|login)  shift; cmd_connect "$@" ;;
  verify)         shift; cmd_verify "$@" ;;
  status)         cmd_status ;;
  discover)       shift; cmd_discover "$@" ;;
  *) die "usage: setup.sh {all|check|connect|verify|status|discover} [staging|production]" ;;
esac
