#!/usr/bin/env sh
# Credential onboarding for the Liara agent pack.
#
# DESIGN RULE: the API token must never pass through a model context.
# The agent explains and verifies; the human pastes the token into THIS script.
# Nothing here ever prints a token, and every path is gitignored.
#
#   sh scripts/creds.sh set staging       # interactive, hidden input
#   sh scripts/creds.sh status            # masked summary (safe for the agent to read)
#   sh scripts/creds.sh verify staging    # calls `liara whoami`
#   sh scripts/creds.sh remove production
#
. "$(dirname "$0")/lib/common.sh"

token_file() { printf '%s/token.%s' "$CRED_DIR" "$1"; }
meta_file()  { printf '%s/context.json' "$CRED_DIR"; }

# Windows DPAPI (per-user, machine-bound) when PowerShell is available,
# plain 0600 file elsewhere. Both are gitignored.
dpapi_available() { have powershell.exe || have powershell; }
ps_bin() { if have powershell.exe; then echo powershell.exe; else echo powershell; fi; }

store_token() { # $1=env  (token on stdin)
  _f="$(token_file "$1")"
  if dpapi_available; then
    "$(ps_bin)" -NoProfile -NonInteractive -Command \
      '$t=[Console]::In.ReadToEnd().Trim(); if(-not $t){exit 3}; ConvertTo-SecureString $t -AsPlainText -Force | ConvertFrom-SecureString' \
      > "$_f.dpapi" 2>/dev/null && { rm -f "$_f"; chmod 600 "$_f.dpapi" 2>/dev/null; return 0; }
  fi
  cat > "$_f"; chmod 600 "$_f" 2>/dev/null; rm -f "$_f.dpapi"
}

read_token() { # $1=env -> token on stdout (callers must never echo it)
  _f="$(token_file "$1")"
  if [ -f "$_f.dpapi" ] && dpapi_available; then
    "$(ps_bin)" -NoProfile -NonInteractive -Command \
      '$e=[Console]::In.ReadToEnd().Trim();
       $s=ConvertTo-SecureString $e;
       $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s);
       try{[Runtime.InteropServices.Marshal]::PtrToStringAuto($b)}
       finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}' \
      < "$_f.dpapi" 2>/dev/null | tr -d '\r\n'
  elif [ -f "$_f" ]; then
    tr -d '\r\n' < "$_f"
  else
    return 1
  fi
}

has_token() { [ -f "$(token_file "$1")" ] || [ -f "$(token_file "$1").dpapi" ]; }

cmd_set() {
  _env="${1:-}"
  case "$_env" in staging|production) ;; *) die "usage: creds.sh set <staging|production>" ;; esac

  cat <<TXT

  ── Connect a Liara account: $_env ───────────────────────────────
  1) Open  https://console.liara.ir/API
  2) Choose an expiry. For $_env we recommend:
        staging     -> 1 month
        production  -> 1 day or 7 days (create it when you need it)
  3) Click "ساخت کلید جدید" / "Create new key"
  4) Copy the token. It is shown ONCE.

  Paste it below. Input is hidden and is never printed, never logged,
  and never sent to the AI model.

TXT
  printf '  Token for %s: ' "$_env"
  if [ -t 0 ]; then stty -echo 2>/dev/null; fi
  IFS= read -r _tok
  if [ -t 0 ]; then stty echo 2>/dev/null; printf '\n'; fi
  [ -n "${_tok:-}" ] || die "empty token, nothing stored"

  printf '%s' "$_tok" | store_token "$_env"
  _tok=""
  audit "creds.set" "env=$_env"
  c_grn "  Stored for $_env."
  info "Verifying..."
  cmd_verify "$_env"
}

cmd_verify() {
  _env="${1:-staging}"
  has_token "$_env" || die "no token stored for $_env — run: sh scripts/setup.sh connect $_env"
  have liara || die "Liara CLI not found — run: npm install -g @liara/cli"
  _t="$(read_token "$_env")" || die "could not read stored token for $_env"
  if liara whoami --api-token "$_t" 2>&1 | redact; then
    _t=""
    audit "creds.verify" "env=$_env result=ok"
    c_grn "  $_env credentials work."
  else
    _t=""
    audit "creds.verify" "env=$_env result=fail"
    die "token rejected for $_env (expired or revoked?) — create a new one"
  fi
}

cmd_status() {
  printf '\n  Liara agent pack — credential status\n'
  printf '  -----------------------------------\n'
  for e in staging production; do
    if has_token "$e"; then
      _t="$(read_token "$e" 2>/dev/null)" || _t=""
      _f="$(token_file "$e")"
      _how="file(0600)"; [ -f "$_f.dpapi" ] && _how="DPAPI(user-bound)"
      printf '  %-11s stored    %s   storage=%s\n' "$e" "$(mask "$_t")" "$_how"
      _t=""
    else
      printf '  %-11s MISSING   run: sh scripts/setup.sh connect %s\n' "$e" "$e"
    fi
  done
  printf '  CLI:        %s\n' "$(if have liara; then liara --version 2>/dev/null | head -1; else echo 'NOT INSTALLED (npm i -g @liara/cli)'; fi)"
  printf '  LIARA_ENV:  %s\n' "${LIARA_ENV:-<unset>}"
  [ -f "$(meta_file)" ] && { printf '  context:    '; cat "$(meta_file)" | redact; printf '\n'; }
  printf '\n'
}

cmd_remove() {
  _env="${1:-}"; case "$_env" in staging|production) ;; *) die "usage: creds.sh remove <staging|production>" ;; esac
  rm -f "$(token_file "$_env")" "$(token_file "$_env").dpapi"
  audit "creds.remove" "env=$_env"
  c_grn "  Removed local credentials for $_env."
  info "Also revoke the key at https://console.liara.ir/API"
}

case "${1:-status}" in
  set)     shift; cmd_set "$@" ;;
  verify)  shift; cmd_verify "$@" ;;
  status)  cmd_status ;;
  remove)  shift; cmd_remove "$@" ;;
  print-token) # internal: used only by scripts/liara.sh, never by the agent
           shift; read_token "${1:-staging}" ;;
  *) die "usage: creds.sh {set|verify|status|remove} [staging|production]" ;;
esac
