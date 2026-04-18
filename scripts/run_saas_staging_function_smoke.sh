#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-}"
FAILURES=0

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_function_smoke.sh [options]

Options:
  --env-file <path>      Staging env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --functions-url <url>  Optional functions base URL. Defaults to SUPABASE_URL/functions/v1.
  --help                 Show this help.

Required env-file keys:
  SUPABASE_URL
  SUPABASE_ANON_KEY
  PUBSUB_BEARER_TOKEN
  ADMIN_API_TOKEN
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN

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
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
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

expect_status() {
  local label="$1"
  local expected="$2"
  shift 2

  local body_file
  local http_status
  body_file="$(mktemp)"

  if ! http_status="$(curl -sS -o "$body_file" -w "%{http_code}" "$@" 2>"$body_file.err")"; then
    warn "$label curl failed: $(tr '\n' ' ' < "$body_file.err")"
    FAILURES=$((FAILURES + 1))
    rm -f "$body_file" "$body_file.err"
    return 0
  fi

  rm -f "$body_file.err"

  if [[ ",$expected," == *",$http_status,"* ]]; then
    log "PASS: $label -> HTTP $http_status"
  else
    warn "$label expected HTTP $expected but got $http_status"
    warn "$label response: $(head -c 500 "$body_file" | tr '\n' ' ')"
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
  local package_name
  local base_url
  local webhook_payload

  supabase_url="$(require_key "SUPABASE_URL")"
  anon_key="$(require_key "SUPABASE_ANON_KEY")"
  pubsub_token="$(require_key "PUBSUB_BEARER_TOKEN")"
  admin_token="$(require_key "ADMIN_API_TOKEN")"
  analytics_token="$(require_key "ANALYTICS_ADMIN_TOKEN")"
  notification_token="$(require_key "NOTIFICATION_ADMIN_TOKEN")"
  package_name="$(value_from_env_file "GOOGLE_PLAY_PACKAGE_NAME" "$ENV_FILE")"

  if [[ -z "$FUNCTIONS_URL" ]]; then
    base_url="${supabase_url%/}/functions/v1"
  else
    base_url="${FUNCTIONS_URL%/}"
  fi

  log "functions url: $base_url"
  log "checking deployed function auth and core responses"

  expect_status "verify-subscription requires a real user session" "401" \
    -X POST "$base_url/verify-subscription" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $anon_key" \
    -H "Content-Type: application/json" \
    --data '{"platform":"google_play","product_id":"jive_subscriber_monthly","purchase_token":"smoke"}'

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

  webhook_payload="$(json_google_test_notification "$package_name")"
  expect_status "subscription-webhook accepts Google test notification" "200" \
    -X POST "$base_url/subscription-webhook" \
    -H "apikey: $anon_key" \
    -H "Authorization: Bearer $pubsub_token" \
    -H "Content-Type: application/json" \
    --data "$webhook_payload"

  if [[ "$FAILURES" -gt 0 ]]; then
    die "function smoke found $FAILURES issue(s)"
  fi

  log "function smoke passed"
}

main "$@"
