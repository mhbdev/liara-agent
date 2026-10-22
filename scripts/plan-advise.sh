#!/usr/bin/env sh
# Gathers LIVE plan + usage data for the Plan Advisor agent.
#
# Prices and plan specs are never hard-coded here. Liara changes them, and a
# stale number in a script becomes a confident wrong answer. Everything below
# comes from `liara plan list` and the app's own metrics at run time.
#
#   LIARA_ENV=staging sh scripts/plan-advise.sh            # plans only
#   LIARA_ENV=staging sh scripts/plan-advise.sh my-site    # plans + real usage
#
. "$(dirname "$0")/lib/common.sh"
: "${LIARA_ENV:=staging}"
APP="${1:-}"

printf '\n  === LIVE PLAN DATA (source: liara plan list, fetched %s) ===\n\n' "$(date -u +%Y-%m-%dT%H:%MZ)"
sh "$PROJECT_DIR/scripts/liara.sh" plan list --output json 2>/dev/null \
  || sh "$PROJECT_DIR/scripts/liara.sh" plan list 2>/dev/null \
  || c_ylw "  Could not read plans. Check credentials: sh scripts/creds.sh status"

if [ -n "$APP" ]; then
  printf '\n  === CURRENT APP ===\n\n'
  sh "$PROJECT_DIR/scripts/liara.sh" app list 2>/dev/null | grep -i "$APP" || info "app '$APP' not in the list"

  printf '\n  === OBSERVED USAGE ===\n'
  info "GET https://api.liara.ir/v1/projects/$APP/metrics/summary"
  info "(cpuUsage, memoryUsage, disksUsage - see docs/en/06-capability-matrix.md)"
  TOKEN="$("$PROJECT_DIR/scripts/creds.sh" print-token "$LIARA_ENV" 2>/dev/null)" || TOKEN=""
  if [ -n "$TOKEN" ] && have curl; then
    curl -sS --max-time 20 -H "Authorization: Bearer $TOKEN" \
      "https://api.liara.ir/v1/projects/$APP/metrics/summary" 2>&1 | redact | head -c 4000
    printf '\n'
  fi
  TOKEN=""
fi

cat <<'TXT'

  === HOW THE PLAN ADVISOR MUST REASON ===

  1. Use the numbers above. Never a price you remember.
  2. Size from EVIDENCE where it exists (metrics/summary), from the user's
     stated traffic where it does not - and say which one you used.
  3. Quote the plan name and its price exactly as printed above.
  4. Label every recommendation with its basis:
        [measured]  - from this app's own metrics
        [estimated] - from user-stated traffic, with the assumption written out
  5. Recommend the smallest plan that fits, plus the next size up as headroom,
     and say what signal should trigger the upgrade.
  6. Creating or resizing a paid resource needs:
        sh scripts/approve.sh grant resize
  7. If the data above failed to load, say so. Do not guess a price.

TXT
audit "plan.advise" "app=${APP:-none}"
