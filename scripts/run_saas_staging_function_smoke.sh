#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-}"
PROFILE="${JIVE_SAAS_STAGING_PROFILE:-full}"
FAILURES=0
RUN_DOMESTIC_PAYMENT_E2E=0
DOMESTIC_E2E_PROVIDER="${JIVE_DOMESTIC_PAYMENT_E2E_PROVIDER:-wechat_pay}"
DOMESTIC_E2E_PRODUCT_ID="${JIVE_DOMESTIC_PAYMENT_E2E_PRODUCT_ID:-jive_paid_unlock}"
DOMESTIC_E2E_PLAN_CODE="${JIVE_DOMESTIC_PAYMENT_E2E_PLAN_CODE:-pro_lifetime}"
DOMESTIC_E2E_CLIENT_CHANNEL="${JIVE_DOMESTIC_PAYMENT_E2E_CLIENT_CHANNEL:-self_hosted_web}"
DOMESTIC_E2E_SUPABASE_URL=""
DOMESTIC_E2E_SERVICE_ROLE_KEY=""
DOMESTIC_E2E_USER_ID=""
DOMESTIC_E2E_ORDER_NO=""
DOMESTIC_E2E_EVENT_ID=""
DOMESTIC_E2E_PROVIDER_TRADE_NO=""

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
  --run-domestic-payment-e2e
                         Opt in to a staging write-path smoke for domestic payment:
                         create a temporary user, create an order, post a paid webhook,
                         verify the subscription projection, then clean up.
  --help                 Show this help.

Required env-file keys:
  SUPABASE_URL
  SUPABASE_ANON_KEY
  ADMIN_API_TOKEN
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
  PUBSUB_BEARER_TOKEN (full profile only)
  DOMESTIC_PAYMENT_WEBHOOK_TOKEN (full profile only)
  SUPABASE_SERVICE_ROLE_KEY (--run-domestic-payment-e2e only)

Notes:
  This script checks deployed Supabase Edge Functions without printing secrets.
  It assumes custom-auth functions were deployed with --no-verify-jwt.
  The domestic payment E2E smoke is off by default because it writes temporary
  auth, payment, and subscription rows before cleaning them up.
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
      --run-domestic-payment-e2e)
        RUN_DOMESTIC_PAYMENT_E2E=1
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

  if [[ "$RUN_DOMESTIC_PAYMENT_E2E" == "1" && "$PROFILE" != "full" ]]; then
    die "--run-domestic-payment-e2e requires --profile full"
  fi
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

json_error_matches() {
  local body_file="$1"
  local expected_error="$2"

  python3 - "$body_file" "$expected_error" <<'PY'
import json
import sys
from pathlib import Path

body_file = Path(sys.argv[1])
expected_error = sys.argv[2]

try:
    payload = json.loads(body_file.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)

if not isinstance(payload, dict):
    raise SystemExit(1)

raise SystemExit(0 if payload.get("error") == expected_error else 1)
PY
}

expect_json_error() {
  local label="$1"
  local expected_status="$2"
  local expected_error="$3"
  shift 3

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

  if [[ "$http_status" == "$expected_status" ]] &&
    json_error_matches "$body_file" "$expected_error"; then
    log "PASS: $label -> HTTP $http_status error=$expected_error"
  else
    summary="$(response_summary "$body_file")"
    warn "$label expected HTTP $expected_status with error=$expected_error but got $http_status"
    warn "$label response: $summary"
    FAILURES=$((FAILURES + 1))
  fi

  rm -f "$body_file"
}

json_get() {
  local body_file="$1"
  local path="$2"

  python3 - "$body_file" "$path" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
value = payload
for part in sys.argv[2].split("."):
    if isinstance(value, dict) and part in value:
        value = value[part]
    else:
        raise SystemExit(1)

if value is None or isinstance(value, (dict, list)):
    raise SystemExit(1)

print(value)
PY
}

json_expect_subscription_projection() {
  local body_file="$1"
  local expected_user_id="$2"
  local expected_provider="$3"
  local expected_order_no="$4"
  local expected_trade_no="$5"
  local expected_tier="$6"

  python3 - "$body_file" "$expected_user_id" "$expected_provider" \
    "$expected_order_no" "$expected_trade_no" "$expected_tier" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = {
    "user_id": sys.argv[2],
    "platform": sys.argv[3],
    "source_order_no": sys.argv[4],
    "purchase_token": sys.argv[5],
    "entitlement_tier": sys.argv[6],
    "status": "active",
}

if not isinstance(payload, list):
    raise SystemExit(1)

for row in payload:
    if not isinstance(row, dict):
        continue
    if all(row.get(key) == value for key, value in expected.items()):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

domestic_e2e_expected_tier() {
  case "$DOMESTIC_E2E_PLAN_CODE" in
    pro_lifetime)
      printf 'paid\n'
      ;;
    *)
      printf 'subscriber\n'
      ;;
  esac
}

domestic_e2e_request() {
  local label="$1"
  local expected="$2"
  local body_file="$3"
  shift 3

  local curl_error
  local http_status
  local summary

  if ! http_status="$(curl -sS -o "$body_file" -w "%{http_code}" "$@" 2>"$body_file.err")"; then
    curl_error="$(tr '\n' ' ' < "$body_file.err" | redact_text)"
    warn "$label curl failed: $curl_error"
    FAILURES=$((FAILURES + 1))
    rm -f "$body_file.err"
    return 1
  fi

  rm -f "$body_file.err"

  if [[ ",$expected," == *",$http_status,"* ]]; then
    log "PASS: $label -> HTTP $http_status"
    return 0
  fi

  summary="$(response_summary "$body_file")"
  warn "$label expected HTTP $expected but got $http_status"
  warn "$label response: $summary"
  FAILURES=$((FAILURES + 1))
  return 1
}

domestic_e2e_cleanup_request() {
  local label="$1"
  shift

  local body_file
  local http_status
  body_file="$(mktemp)"

  if http_status="$(curl -sS -o "$body_file" -w "%{http_code}" "$@" 2>/dev/null)"; then
    if [[ ",200,204," == *",$http_status,"* ]]; then
      log "cleanup: $label -> HTTP $http_status"
    else
      warn "cleanup: $label returned HTTP $http_status"
    fi
  else
    warn "cleanup: $label curl failed"
  fi

  rm -f "$body_file"
}

cleanup_domestic_payment_e2e() {
  if [[ "$RUN_DOMESTIC_PAYMENT_E2E" != "1" ]]; then
    return 0
  fi
  if [[ -z "$DOMESTIC_E2E_SUPABASE_URL" || -z "$DOMESTIC_E2E_SERVICE_ROLE_KEY" ]]; then
    return 0
  fi

  local rest_url
  rest_url="${DOMESTIC_E2E_SUPABASE_URL%/}/rest/v1"

  if [[ -n "$DOMESTIC_E2E_EVENT_ID" ]]; then
    domestic_e2e_cleanup_request "payment event" \
      -X DELETE "$rest_url/payment_events?provider=eq.$DOMESTIC_E2E_PROVIDER&event_id=eq.$DOMESTIC_E2E_EVENT_ID" \
      -H "apikey: $DOMESTIC_E2E_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $DOMESTIC_E2E_SERVICE_ROLE_KEY"
  fi

  if [[ -n "$DOMESTIC_E2E_ORDER_NO" ]]; then
    domestic_e2e_cleanup_request "subscription projection" \
      -X DELETE "$rest_url/user_subscriptions?source_order_no=eq.$DOMESTIC_E2E_ORDER_NO" \
      -H "apikey: $DOMESTIC_E2E_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $DOMESTIC_E2E_SERVICE_ROLE_KEY"

    domestic_e2e_cleanup_request "payment order" \
      -X DELETE "$rest_url/payment_orders?order_no=eq.$DOMESTIC_E2E_ORDER_NO" \
      -H "apikey: $DOMESTIC_E2E_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $DOMESTIC_E2E_SERVICE_ROLE_KEY"
  fi

  if [[ -n "$DOMESTIC_E2E_USER_ID" ]]; then
    domestic_e2e_cleanup_request "auth user" \
      -X DELETE "${DOMESTIC_E2E_SUPABASE_URL%/}/auth/v1/admin/users/$DOMESTIC_E2E_USER_ID" \
      -H "apikey: $DOMESTIC_E2E_SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $DOMESTIC_E2E_SERVICE_ROLE_KEY"
  fi
}

run_domestic_payment_e2e_smoke() {
  local supabase_url="$1"
  local base_url="$2"
  local anon_key="$3"
  local service_role_key="$4"
  local domestic_token="$5"

  local smoke_id
  local smoke_email
  local smoke_password
  local user_body
  local token_body
  local order_body
  local webhook_body
  local subscription_body
  local access_token
  local token_user_id
  local expected_tier
  local now_iso

  smoke_id="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:16])
PY
)"
  smoke_email="jive-smoke-$smoke_id@example.com"
  smoke_password="Jive-smoke-$smoke_id-Aa1!"
  DOMESTIC_E2E_EVENT_ID="jive_smoke_event_$smoke_id"
  DOMESTIC_E2E_PROVIDER_TRADE_NO="jive_smoke_trade_$smoke_id"
  DOMESTIC_E2E_SUPABASE_URL="$supabase_url"
  DOMESTIC_E2E_SERVICE_ROLE_KEY="$service_role_key"

  log "domestic payment E2E smoke enabled; creating temporary staging user/order"

  user_body="$(mktemp)"
  if ! domestic_e2e_request "domestic E2E creates temporary auth user" "200,201" "$user_body" \
    -X POST "${supabase_url%/}/auth/v1/admin/users" \
    -H "apikey: $service_role_key" \
    -H "Authorization: Bearer $service_role_key" \
    -H "Content-Type: application/json" \
    --data "{\"email\":\"$smoke_email\",\"password\":\"$smoke_password\",\"email_confirm\":true,\"user_metadata\":{\"source\":\"jive_domestic_payment_smoke\"}}"; then
    rm -f "$user_body"
    return 0
  fi
  if ! DOMESTIC_E2E_USER_ID="$(json_get "$user_body" "id")"; then
    warn "domestic E2E could not read temporary user id"
    FAILURES=$((FAILURES + 1))
    rm -f "$user_body"
    return 0
  fi
  rm -f "$user_body"

  token_body="$(mktemp)"
  if ! domestic_e2e_request "domestic E2E signs in temporary user" "200" "$token_body" \
    -X POST "${supabase_url%/}/auth/v1/token?grant_type=password" \
    -H "apikey: $anon_key" \
    -H "Content-Type: application/json" \
    --data "{\"email\":\"$smoke_email\",\"password\":\"$smoke_password\"}"; then
    rm -f "$token_body"
    return 0
  fi
  if ! access_token="$(json_get "$token_body" "access_token")"; then
    warn "domestic E2E could not read temporary user access token"
    FAILURES=$((FAILURES + 1))
    rm -f "$token_body"
    return 0
  fi
  if ! token_user_id="$(json_get "$token_body" "user.id")"; then
    warn "domestic E2E could not read signed-in user id"
    FAILURES=$((FAILURES + 1))
    rm -f "$token_body"
    return 0
  fi
  rm -f "$token_body"

  if [[ "$token_user_id" != "$DOMESTIC_E2E_USER_ID" ]]; then
    warn "domestic E2E signed-in user id did not match created user id"
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  order_body="$(mktemp)"
  if ! domestic_e2e_request "domestic E2E creates payment order" "201" "$order_body" \
    -X POST "$base_url/create-payment-order" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $access_token" \
    -H "Content-Type: application/json" \
    --data "{\"provider\":\"$DOMESTIC_E2E_PROVIDER\",\"product_id\":\"$DOMESTIC_E2E_PRODUCT_ID\",\"plan_code\":\"$DOMESTIC_E2E_PLAN_CODE\",\"client_channel\":\"$DOMESTIC_E2E_CLIENT_CHANNEL\"}"; then
    rm -f "$order_body"
    return 0
  fi
  if ! DOMESTIC_E2E_ORDER_NO="$(json_get "$order_body" "order.order_no")"; then
    warn "domestic E2E could not read payment order number"
    FAILURES=$((FAILURES + 1))
    rm -f "$order_body"
    return 0
  fi
  rm -f "$order_body"

  now_iso="$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"))
PY
)"
  webhook_body="$(mktemp)"
  if ! domestic_e2e_request "domestic E2E posts paid webhook" "200" "$webhook_body" \
    -X POST "$base_url/domestic-payment-webhook" \
    -H "apikey: $anon_key" \
    -H "x-domestic-payment-token: $domestic_token" \
    -H "Content-Type: application/json" \
    --data "{\"provider\":\"$DOMESTIC_E2E_PROVIDER\",\"event_id\":\"$DOMESTIC_E2E_EVENT_ID\",\"event_type\":\"payment.paid\",\"order_no\":\"$DOMESTIC_E2E_ORDER_NO\",\"status\":\"paid\",\"provider_trade_no\":\"$DOMESTIC_E2E_PROVIDER_TRADE_NO\",\"paid_at\":\"$now_iso\",\"payload\":{\"source\":\"jive_domestic_payment_e2e_smoke\"}}"; then
    rm -f "$webhook_body"
    return 0
  fi
  if [[ "$(json_get "$webhook_body" "order_status" 2>/dev/null || true)" != "paid" ]]; then
    warn "domestic E2E webhook did not report paid order status"
    FAILURES=$((FAILURES + 1))
    rm -f "$webhook_body"
    return 0
  fi
  rm -f "$webhook_body"

  expected_tier="$(domestic_e2e_expected_tier)"
  subscription_body="$(mktemp)"
  if ! domestic_e2e_request "domestic E2E reads projected subscription" "200" "$subscription_body" \
    -X GET "${supabase_url%/}/rest/v1/user_subscriptions?source_order_no=eq.$DOMESTIC_E2E_ORDER_NO&select=user_id,platform,purchase_token,entitlement_tier,status,source_order_no" \
    -H "apikey: $service_role_key" \
    -H "Authorization: Bearer $service_role_key"; then
    rm -f "$subscription_body"
    return 0
  fi
  if json_expect_subscription_projection "$subscription_body" "$DOMESTIC_E2E_USER_ID" \
    "$DOMESTIC_E2E_PROVIDER" "$DOMESTIC_E2E_ORDER_NO" \
    "$DOMESTIC_E2E_PROVIDER_TRADE_NO" "$expected_tier"; then
    log "PASS: domestic E2E subscription projection matches temporary order"
  else
    warn "domestic E2E subscription projection did not match expected shape"
    FAILURES=$((FAILURES + 1))
  fi
  rm -f "$subscription_body"
}

trap cleanup_domestic_payment_e2e EXIT INT TERM

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
  local service_role_key
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
  service_role_key=""
  package_name=""

  if [[ "$PROFILE" == "full" ]]; then
    pubsub_token="$(require_key "PUBSUB_BEARER_TOKEN")"
    domestic_token="$(require_key "DOMESTIC_PAYMENT_WEBHOOK_TOKEN")"
    package_name="$(value_from_env_file "GOOGLE_PLAY_PACKAGE_NAME" "$ENV_FILE")"
  fi
  if [[ "$RUN_DOMESTIC_PAYMENT_E2E" == "1" ]]; then
    service_role_key="$(require_key "SUPABASE_SERVICE_ROLE_KEY")"
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

    expect_status "create-payment-order requires a real user session" "401" \
      -X POST "$base_url/create-payment-order" \
      -H "apikey: $anon_key" \
      -H "Authorization: Bearer $anon_key" \
      -H "Content-Type: application/json" \
      --data '{"provider":"wechat_pay","product_id":"jive_paid_unlock","plan_code":"pro_lifetime","client_channel":"self_hosted_web"}'

    expect_json_error "domestic-payment-webhook rejects missing token" "401" "admin_token_required" \
      -X POST "$base_url/domestic-payment-webhook" \
      -H "apikey: $anon_key" \
      -H "Content-Type: application/json" \
      --data '{"provider":"wechat_pay","event_id":"smoke-missing-token","event_type":"payment.paid","order_no":"missing","status":"paid"}'

    expect_json_error "domestic-payment-webhook accepts token and checks order existence" "404" "payment_order_not_found" \
      -X POST "$base_url/domestic-payment-webhook" \
      -H "apikey: $anon_key" \
      -H "x-domestic-payment-token: $domestic_token" \
      -H "Content-Type: application/json" \
      --data '{"provider":"wechat_pay","event_id":"smoke-missing-order","event_type":"payment.paid","order_no":"jive_missing_smoke_order","status":"paid","provider_trade_no":"smoke_trade"}'

    if [[ "$RUN_DOMESTIC_PAYMENT_E2E" == "1" ]]; then
      run_domestic_payment_e2e_smoke "$supabase_url" "$base_url" "$anon_key" \
        "$service_role_key" "$domestic_token"
    fi
  fi

  if [[ "$FAILURES" -gt 0 ]]; then
    die "function smoke found $FAILURES issue(s)"
  fi

  log "function smoke passed"
}

main "$@"
