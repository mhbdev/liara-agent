#!/usr/bin/env sh
# One-time, expiring approvals. This is the enforcement point the agent
# cannot talk its way past: a prompt cannot create a file.
#
#   sh scripts/approve.sh grant prod-write     # human runs this
#   sh scripts/approve.sh check prod-write     # scripts/hooks run this (consumes it)
#   sh scripts/approve.sh list
#   sh scripts/approve.sh revoke-all
#
. "$(dirname "$0")/lib/common.sh"

TTL="${APPROVAL_TTL:-900}"   # 15 minutes
CLASSES="prod-write prod-deploy destructive rollback db-migration resize"

valid_class() {
  for c in $CLASSES; do [ "$c" = "$1" ] && return 0; done
  return 1
}

cmd_grant() {
  _c="${1:-}"
  valid_class "$_c" || die "unknown approval class '$_c' (valid: $CLASSES)"
  _exp=$(( $(date +%s) + TTL ))
  printf '%s\n' "$_exp" > "$APPROVAL_DIR/$_c"
  audit "approval.grant" "class=$_c ttl=${TTL}s"
  c_grn "  Approved: $_c"
  info "Valid for $((TTL/60)) minutes, single use. Revoke early: sh scripts/approve.sh revoke-all"
}

cmd_check() {
  _c="${1:-}"; _f="$APPROVAL_DIR/$_c"
  [ -f "$_f" ] || { audit "approval.denied" "class=$_c reason=absent"; return 1; }
  _exp="$(cat "$_f" 2>/dev/null || echo 0)"
  rm -f "$_f"                                  # single use, consumed either way
  if [ "$(date +%s)" -gt "$_exp" ]; then
    audit "approval.denied" "class=$_c reason=expired"; return 1
  fi
  audit "approval.consumed" "class=$_c"; return 0
}

cmd_list() {
  _n=0
  for f in "$APPROVAL_DIR"/*; do
    [ -f "$f" ] || continue
    _exp="$(cat "$f")"; _left=$(( _exp - $(date +%s) ))
    if [ "$_left" -gt 0 ]; then
      printf '  %-14s valid for %ss\n' "$(basename "$f")" "$_left"; _n=$((_n+1))
    else
      printf '  %-14s EXPIRED\n' "$(basename "$f")"
    fi
  done
  [ "$_n" -eq 0 ] && info "no active approvals"
  return 0
}

case "${1:-list}" in
  grant)       shift; cmd_grant "$@" ;;
  check)       shift; cmd_check "$@" ;;
  list)        cmd_list ;;
  revoke-all)  rm -f "$APPROVAL_DIR"/*; audit "approval.revoke_all" ""; c_grn "  All approvals revoked." ;;
  *) die "usage: approve.sh {grant|check|list|revoke-all} [class]" ;;
esac
