#!/usr/bin/env sh
# Deterministic gate the Deploy Agent must pass before it may deploy.
# Six checks an experienced engineer does reflexively and a beginner cannot know.
#
#   LIARA_ENV=staging sh scripts/preflight.sh
#
# Exit 0 = cleared to deploy. Exit 1 = blocked, with the reason.
#
. "$(dirname "$0")/lib/common.sh"
: "${LIARA_ENV:=staging}"
require_env

rc=0
pass() { c_grn "  [ ok ] $1"; }
fail() { c_red "  [FAIL] $1"; printf '         %s\n' "${2:-}"; rc=1; }
skip() { c_ylw "  [skip] $1"; printf '         %s\n' "${2:-}"; }

printf '\n  Pre-flight for %s\n  --------------------------\n' "$LIARA_ENV"

# 1 ── tests
if [ -f package.json ] && grep -q '"test"' package.json 2>/dev/null; then
  if npm test --silent >"$STATE_DIR/preflight-test.log" 2>&1
  then pass "tests pass"
  else fail "tests failing" "see state/preflight-test.log"; fi
else skip "tests" "no test script in package.json"; fi

# 2 ── build
if [ -f package.json ] && grep -q '"build"' package.json 2>/dev/null; then
  if npm run build --silent >"$STATE_DIR/preflight-build.log" 2>&1
  then pass "build succeeds"
  else fail "build failing" "see state/preflight-build.log"; fi
else skip "build" "no build script"; fi

# 3 ── secret scan over what is about to ship
if have git && [ -d .git ]; then
  if git diff --cached -U0 2>/dev/null | grep -nEi \
     '(api[_-]?key|secret|passwd|password|private[_-]key|BEGIN [A-Z ]*PRIVATE KEY)[^a-z]{0,3}[=:][[:space:]]*["'"'"']?[A-Za-z0-9/_+-]{12,}' \
     >"$STATE_DIR/preflight-secrets.log" 2>&1
  then fail "possible secret in staged diff" "see state/preflight-secrets.log — move it to env vars"
  else pass "no secret-shaped strings in staged diff"; fi
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    fail ".env is tracked by git" "run: git rm --cached .env && echo .env >> .gitignore"
  else pass ".env not tracked"; fi
else skip "secret scan" "not a git repository"; fi

# 4 ── liara.json sanity
if [ -f liara.json ]; then
  if grep -q '"healthCheck"' liara.json
  then pass "liara.json has a healthCheck release gate"
  else fail "liara.json has no healthCheck" "a broken release will go live — see docs/en/05-runbook.md"; fi
  if grep -qE '"envs"[[:space:]]*:' liara.json; then
    c_ylw "  [warn] liara.json defines envs — it REPLACES all stored vars on deploy"
  fi
else fail "no liara.json" "run /liara-setup, or copy liara.json.example"; fi

# 5 ── remote env vars exist
if [ -n "${LIARA_APP:-}" ]; then
  if sh "$PROJECT_DIR/scripts/liara.sh" env list --app "$LIARA_APP" >"$STATE_DIR/preflight-env.log" 2>&1
  then pass "env vars readable for $LIARA_APP ($(grep -c . "$STATE_DIR/preflight-env.log") lines)"
  else fail "cannot read env vars for $LIARA_APP" "check credentials and app name"; fi
else skip "remote env check" "set LIARA_APP to enable"; fi

# 6 ── current production is healthy before we touch it
if [ -n "${LIARA_URL:-}" ]; then
  if sh "$PROJECT_DIR/scripts/health.sh" "$LIARA_URL" "${LIARA_HEALTH_PATH:-}" 2 >/dev/null 2>&1
  then pass "current deployment is healthy"
  else c_ylw "  [warn] current deployment is already unhealthy — deploying may mask the cause"; fi
else skip "live health check" "set LIARA_URL to enable"; fi

printf '\n'
if [ "$rc" -eq 0 ]; then
  c_grn "  CLEARED TO DEPLOY ($LIARA_ENV)"
  audit "preflight" "env=$LIARA_ENV result=pass"
else
  c_red "  DEPLOY BLOCKED — fix the FAIL lines above."
  audit "preflight" "env=$LIARA_ENV result=blocked"
fi
exit "$rc"
