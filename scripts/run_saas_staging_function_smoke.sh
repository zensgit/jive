#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-}"
PROFILE="${JIVE_SAAS_STAGING_PROFILE:-full}"
FAILURES=0

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_function_smoke.sh [options]

Options:
  --env-file <path>      Staging env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --functions-url <url>  Optional functions base URL. Defaults to SUPABASE_URL/functions/v1.
  --profile <name>       full or core. Defaults to JIVE_SAAS_STAGING_PROFILE or full.
                         core checks only analytics, admin, and notification functions.
  --core-only            Alias for --profile core.
  --help                 Show this help.

Required env-file keys:
  SUPABASE_URL
  SUPABASE_ANON_KEY
  ADMIN_API_TOKEN
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
  PUBSUB_BEARER_TOKEN (full profile only)
  DOMESTIC_PAYMENT_WEBHOOK_TOKEN (optional; enables domestic payment smoke)

Notes:
  This script checks deployed Supabase Edge Functions without printing secrets.
  It assumes custom-auth functions were deployed with --no-verify-jwt.
EOF
}

log() {
  printf '[saas-function-smoke] %s\n' "$*"
}

warn() {
  printf '[saas-function-smoke] WARN: %s\n' "$*" >&2
}

die() {
  printf '[saas-function-smoke] ERROR: %s\n' "$*" >&2
  exit 1
}

value_from_env_file() {
  local key="$1"
  local file="$2"
  awk -F '=' -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub(/^[[:space:]]*/, "", $0)
      value = substr($0, length(key) + 2)
    }
    END { if (value != "") print value }
  ' "$file"
}

require_key() {
  local key="$1"
  local value

  value="$(value_from_env_file "$key" "$ENV_FILE")"
  if [[ -z "$value" ]]; then
    die "$key is missing in $ENV_FILE"
  fi

  printf '%s\n' "$value"
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --functions-url)
        FUNCTIONS_URL="${2:-}"
        shift 2
        ;;
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --core-only)
        PROFILE="core"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  case "$PROFILE" in
    full|core)
      ;;
    *)
      die "unknown profile: $PROFILE"
      ;;
  esac
}

json_google_test_notification() {
  local package_name="$1"

  python3 - "$package_name" <<'PY'
import base64
import json
import sys
import time

package_name = sys.argv[1] or "com.jivemoney.app.dev"
developer_notification = {
    "version": "1.0",
    "packageName": package_name,
    "eventTimeMillis": str(int(time.time() * 1000)),
    "testNotification": {},
}
payload = {
    "message": {
        "data": base64.b64encode(json.dumps(developer_notification).encode()).decode(),
        "messageId": f"jive-smoke-{int(time.time())}",
        "publishTime": None,
        "attributes": {},
    },
    "subscription": "jive-staging-smoke",
}
print(json.dumps(payload, separators=(",", ":")))
PY
}

redact_text() {
  python3 -c '
import re
import sys

text = sys.stdin.read()
text = re.sub(r"(?i)(Bearer\s+)[A-Za-z0-9._~+/=-]+", r"\1<redacted>", text)
text = re.sub(
    r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
    "<redacted-jwt>",
    text,
)
text = re.sub(r"sbp_[A-Za-z0-9]{16,}", "<redacted-supabase-token>", text)
text = re.sub(
    r"(?i)(access[_-]?token|refresh[_-]?token|purchase[_-]?token|password|"
    r"apikey|api[_-]?key|authorization|service[_-]?role(?:[_-]?key)?|"
    r"anon[_-]?key|admin[_-]?token|webhook[_-]?token)"
    r"([\"'\'']?\s*[:=]\s*[\"'\'']?)[^,\"'\''}\s]+",
    r"\1\2<redacted>",
    text,
)
sys.stdout.write(text)
'
}

response_summary() {
  local body_file="$1"

  python3 - "$body_file" <<'PY'
import json
import re
import sys
from pathlib import Path

body = Path(sys.argv[1]).read_bytes()
text = body.decode("utf-8", errors="replace")


def safe_key_name(key):
    key_text = str(key)
    if re.search(
        r"(?i)(access[_-]?token|refresh[_-]?token|purchase[_-]?token|password|"
        r"apikey|api[_-]?key|authorization|service[_-]?role|anon[_-]?key|"
        r"admin[_-]?token|webhook[_-]?token|jwt)",
        key_text,
    ):
        return "<sensitive>"
    return key_text


def key_summary(payload, limit=8):
    keys = sorted(safe_key_name(key) for key in payload.keys())
    visible = ", ".join(keys[:limit])
    suffix = ", ..." if len(keys) > limit else ""
    return f"[{visible}{suffix}]"


def shape(payload):
    if isinstance(payload, dict):
        return f"object(keys={key_summary(payload)})"
    if isinstance(payload, list):
        if not payload:
            return "array(len=0)"
        return f"array(len={len(payload)}, first={shape(payload[0])})"
    if payload is None:
        return "null"
    return type(payload).__name__


if not text.strip():
    print("empty_body")
    raise SystemExit

try:
    parsed = json.loads(text)
except json.JSONDecodeError:
    print(f"non_json_body(bytes={len(body)})")
else:
    print(shape(parsed))
PY
}

expect_status() {
  local label="$1"
  local expected="$2"
  shift 2

  local body_file
  local curl_error
  local http_status
  local summary
  body_file="$(mktemp)"

  if ! http_status="$(curl -sS -o "$body_file" -w "%{http_code}" "$@" 2>"$body_file.err")"; then
    curl_error="$(tr '\n' ' ' < "$body_file.err" | redact_text)"
    warn "$label curl failed: $curl_error"
    FAILURES=$((FAILURES + 1))
    rm -f "$body_file" "$body_file.err"
    return 0
  fi

  rm -f "$body_file.err"

  if [[ ",$expected," == *",$http_status,"* ]]; then
    log "PASS: $label -> HTTP $http_status"
  else
    summary="$(response_summary "$body_file")"
    warn "$label expected HTTP $expected but got $http_status"
    warn "$label response: $summary"
    FAILURES=$((FAILURES + 1))
  fi

  rm -f "$body_file"
}

main() {
  parse_args "$@"
  [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"

  local supabase_url
  local anon_key
  local pubsub_token
  local admin_token
  local analytics_token
  local notification_token
  local domestic_token
  local package_name
  local base_url
  local webhook_payload

  supabase_url="$(require_key "SUPABASE_URL")"
  anon_key="$(require_key "SUPABASE_ANON_KEY")"
  admin_token="$(require_key "ADMIN_API_TOKEN")"
  analytics_token="$(require_key "ANALYTICS_ADMIN_TOKEN")"
  notification_token="$(require_key "NOTIFICATION_ADMIN_TOKEN")"
  pubsub_token=""
  domestic_token=""
  package_name=""

  if [[ "$PROFILE" == "full" ]]; then
    pubsub_token="$(require_key "PUBSUB_BEARER_TOKEN")"
    domestic_token="$(value_from_env_file "DOMESTIC_PAYMENT_WEBHOOK_TOKEN" "$ENV_FILE")"
    package_name="$(value_from_env_file "GOOGLE_PLAY_PACKAGE_NAME" "$ENV_FILE")"
  fi

  if [[ -z "$FUNCTIONS_URL" ]]; then
    base_url="${supabase_url%/}/functions/v1"
  else
    base_url="${FUNCTIONS_URL%/}"
  fi

  log "functions url: $base_url"
  log "profile: $PROFILE"
  log "checking deployed function auth and core responses"

  if [[ "$PROFILE" == "full" ]]; then
    expect_status "verify-subscription requires a real user session" "401" \
      -X POST "$base_url/verify-subscription" \
      -H "apikey: $anon_key" \
      -H "Authorization: Bearer $anon_key" \
      -H "Content-Type: application/json" \
      --data '{"platform":"google_play","product_id":"jive_subscriber_monthly","purchase_token":"smoke"}'
  else
    log "billing and webhook smoke skipped for core profile"
  fi

  expect_status "analytics rejects missing admin token" "401" \
    -X GET "$base_url/analytics?days=7" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $anon_key"

  expect_status "analytics summary accepts admin token" "200" \
    -X GET "$base_url/analytics?days=7" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $analytics_token"

  expect_status "admin rejects anon token" "401" \
    -X GET "$base_url/admin?action=summary" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $anon_key"

  expect_status "admin summary accepts admin token" "200" \
    -X GET "$base_url/admin?action=summary" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $admin_token"

  expect_status "send-notification dry run accepts notification token" "200" \
    -X POST "$base_url/send-notification" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $anon_key" \
    -H "x-admin-token: $notification_token" \
    -H "Content-Type: application/json" \
    --data '{"action":"system_notice","dry_run":true,"user_ids":["00000000-0000-0000-0000-000000000001"],"notice_key":"staging-smoke","title":"Staging smoke","body":"Staging function smoke."}'

  if [[ "$PROFILE" == "full" ]]; then
    webhook_payload="$(json_google_test_notification "$package_name")"
    expect_status "subscription-webhook accepts Google test notification" "200" \
      -X POST "$base_url/subscription-webhook" \
      -H "apikey: $anon_key" \
      -H "Authorization: Bearer $pubsub_token" \
      -H "Content-Type: application/json" \
      --data "$webhook_payload"

    if [[ -n "$domestic_token" ]]; then
      expect_status "create-payment-order requires a real user session" "401" \
        -X POST "$base_url/create-payment-order" \
        -H "apikey: $anon_key" \
        -H "Authorization: Bearer $anon_key" \
        -H "Content-Type: application/json" \
        --data '{"provider":"wechat_pay","product_id":"jive_paid_unlock","plan_code":"pro_lifetime","client_channel":"self_hosted_web"}'

      expect_status "domestic-payment-webhook rejects missing token" "401" \
        -X POST "$base_url/domestic-payment-webhook" \
        -H "apikey: $anon_key" \
        -H "Content-Type: application/json" \
        --data '{"provider":"wechat_pay","event_id":"smoke-missing-token","event_type":"payment.paid","order_no":"missing","status":"paid"}'

      expect_status "domestic-payment-webhook accepts token and checks order existence" "404" \
        -X POST "$base_url/domestic-payment-webhook" \
        -H "apikey: $anon_key" \
        -H "x-domestic-payment-token: $domestic_token" \
        -H "Content-Type: application/json" \
        --data '{"provider":"wechat_pay","event_id":"smoke-missing-order","event_type":"payment.paid","order_no":"jive_missing_smoke_order","status":"paid","provider_trade_no":"smoke_trade"}'
    else
      log "domestic payment smoke skipped (DOMESTIC_PAYMENT_WEBHOOK_TOKEN not set)"
    fi
  fi

  if [[ "$FAILURES" -gt 0 ]]; then
    die "function smoke found $FAILURES issue(s)"
  fi

  log "function smoke passed"
}

main "$@"
