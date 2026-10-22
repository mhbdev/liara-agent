#!/usr/bin/env sh
# Outside-in liveness check. Deterministic: no model involved in deciding
# pass/fail, which is the point.
#
#   sh scripts/health.sh https://my-site.ir
#   sh scripts/health.sh https://my-site.ir /api/health 3
#
# Exit 0 = healthy. Exit 1 = unhealthy (after N consecutive failures).
# A single transient failure never reports unhealthy.
#
. "$(dirname "$0")/lib/common.sh"

URL="${1:-}"
HEALTH_PATH="${2:-}"
TRIES="${3:-3}"
SLOW_MS="${SLOW_MS:-2000}"

[ -n "$URL" ] || die "usage: health.sh <url> [health-path] [consecutive-tries]"
have curl || die "curl not found"

HEALTH_LOG="$STATE_DIR/health.log"
fail=0; ok=0; last=""; total_ms=0

i=1
while [ "$i" -le "$TRIES" ]; do
  out="$(curl -sS -o /dev/null -w '%{http_code} %{time_total} %{ssl_verify_result}' \
         --max-time 15 --retry 0 "$URL" 2>&1)" || out="000 0 999"
  code="$(printf '%s' "$out" | awk '{print $1}')"
  secs="$(printf '%s' "$out" | awk '{print $2}')"
  tls="$(printf  '%s' "$out" | awk '{print $3}')"
  ms="$(awk -v s="$secs" 'BEGIN{printf "%d", s*1000}' 2>/dev/null || echo 0)"
  total_ms=$(( total_ms + ms ))
  last="$code"
  case "$code" in
    2*|3*) ok=$((ok+1)) ;;
    *)     fail=$((fail+1)) ;;
  esac
  printf '  attempt %s/%s  http=%s  %sms  tls_verify=%s\n' "$i" "$TRIES" "$code" "$ms" "$tls"
  i=$((i+1))
  [ "$i" -le "$TRIES" ] && sleep 2
done

avg_ms=$(( total_ms / TRIES ))

# TLS expiry (informational, never fails the check on its own)
tls_days="unknown"
case "$URL" in
  https://*)
    host="$(printf '%s' "$URL" | sed -E 's#https://([^/:]+).*#\1#')"
    if have openssl; then
      end="$(printf '' | openssl s_client -connect "$host:443" -servername "$host" 2>/dev/null \
             | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)"
      if [ -n "${end:-}" ]; then
        e=$(date -d "$end" +%s 2>/dev/null || echo "")
        [ -n "$e" ] && tls_days=$(( (e - $(date +%s)) / 86400 ))
      fi
    fi ;;
esac

# Optional application health endpoint — a 200 on the homepage is not evidence
# that the application's own dependencies are healthy.
app_health="not-configured"
if [ -n "$HEALTH_PATH" ]; then
  hc="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "${URL%/}$HEALTH_PATH" 2>&1 || echo 000)"
  case "$hc" in 2*) app_health="ok ($hc)" ;; *) app_health="FAIL ($hc)"; fail=$((fail+1)) ;; esac
fi

status="healthy"
[ "$fail" -ge "$TRIES" ] && status="down"
[ "$fail" -gt 0 ] && [ "$fail" -lt "$TRIES" ] && status="flapping"
[ "$status" = "healthy" ] && [ "$avg_ms" -gt "$SLOW_MS" ] && status="slow"
case "$app_health" in FAIL*) status="degraded" ;; esac

printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$URL" "$status" "$last" "${avg_ms}ms" "tls_days=$tls_days" >> "$HEALTH_LOG"

printf '\n  url         %s\n  status      %s\n  http        %s\n  avg latency %sms (slow above %sms)\n  tls expires %s days\n  app health  %s\n  checks      %s ok / %s failed of %s\n\n' \
  "$URL" "$status" "$last" "$avg_ms" "$SLOW_MS" "$tls_days" "$app_health" "$ok" "$fail" "$TRIES"

audit "health.check" "url=$URL status=$status http=$last avg=${avg_ms}ms"
[ "$status" = "healthy" ] || [ "$status" = "slow" ]
