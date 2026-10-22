#!/usr/bin/env sh
# Pre-flight for the agent pack itself. Run this first, always.
. "$(dirname "$0")/lib/common.sh"

rc=0
chk() { # name, command, hint
  if eval "$2" >/dev/null 2>&1; then printf '  [ ok ] %s\n' "$1"
  else printf '  [FAIL] %-28s %s\n' "$1" "$3"; rc=1; fi
}

printf '\n  Liara agent pack — doctor\n  -------------------------\n'
chk "Liara CLI"        "command -v liara"   "npm install -g @liara/cli"
chk "curl"             "command -v curl"    "install curl"
chk "git"              "command -v git"     "install git"
chk "node"             "command -v node"    "install Node.js 20+"
chk "guard hook wired" "grep -q guard.sh .claude/settings.json" "restore .claude/settings.json"
chk "secrets ignored"  "grep -q '.liara/' .gitignore"           "add .liara/ to .gitignore"
chk "staging creds"    "[ -f .liara/token.staging ] || [ -f .liara/token.staging.dpapi ]" \
                       "sh scripts/creds.sh set staging"

printf '\n  Guard self-test\n'
for t in "rm -rf /" "liara app rm x" "cat .liara/token.production"; do
  if printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$t" | sh scripts/guard.sh >/dev/null 2>&1
  then printf '  [FAIL] guard allowed: %s\n' "$t"; rc=1
  else printf '  [ ok ] guard blocks: %s\n' "$t"; fi
done

printf '\n'
[ "$rc" -eq 0 ] && c_grn "  All checks passed." || c_ylw "  Fix the FAIL lines above before using the agents."
exit "$rc"
