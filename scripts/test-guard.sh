#!/usr/bin/env sh
# Guard regression suite.
#
#   sh scripts/test-guard.sh                      # uses tests/guard-cases.txt
#   sh scripts/test-guard.sh path/to/cases.txt
#
# Case file format, one per line:  <expected-exit>\t<command>
#   0 = guard must ALLOW     2 = guard must BLOCK
#
# Note: the cases live in a data file on purpose. If they were inline in a
# shell command, the guard would (correctly) block the test runner itself for
# containing the very strings it is meant to reject.
#
CASES="${1:-tests/guard-cases.txt}"
GUARD="$(dirname "$0")/guard.sh"

[ -f "$CASES" ] || { printf 'no case file: %s\n' "$CASES" >&2; exit 1; }

pass=0; fail=0
while IFS="$(printf '\t')" read -r want cmd; do
  case "${want:-}" in ''|\#*) continue ;; esac
  [ -n "${cmd:-}" ] || continue

  # Feed the case through the guard exactly as a PreToolUse hook would.
  esc="$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$esc" \
    | sh "$GUARD" >/dev/null 2>&1
  got=$?

  if [ "$got" = "$want" ]; then
    pass=$((pass+1))
    printf '  [ ok ] %-4s %s\n' "$([ "$want" = 2 ] && echo block || echo allow)" "$cmd"
  else
    fail=$((fail+1))
    printf '  [FAIL] expected %s got %s: %s\n' "$want" "$got" "$cmd"
  fi
done < "$CASES"

printf '\n  %s passed, %s failed\n\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
