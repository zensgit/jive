#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${PRODUCTION_ENV_FILE:-/tmp/jive-saas-production.env}"
TEMPLATE="$APP_DIR/docs/jive-saas-production.env.example"
OVERWRITE=0

usage() {
  cat <<'EOF'
Usage:
  scripts/init_saas_production_env.sh [options]

Options:
  --env-file <path>             Env file to create or update. Defaults to PRODUCTION_ENV_FILE or /tmp/jive-saas-production.env.
  --supabase-url <value>        Optional production Supabase URL to write when the key is empty.
  --supabase-anon-key <value>   Optional production Supabase anon key to write when the key is empty.
  --admob-app-id <value>        Optional production AdMob app id to write when the key is empty.
  --admob-banner-id <value>     Optional production AdMob banner unit id to write when the key is empty.
  --admin-origins <value>       Optional comma-separated production admin CORS origins.
  --payment-channel <value>     Optional payment channel. Defaults to google_play when the key is empty.
  --overwrite                   Replace existing values for managed keys.
  --help                        Show this help.

Environment fallbacks:
  SUPABASE_URL, SUPABASE_ANON_KEY, ADMOB_APP_ID, ADMOB_BANNER_ID,
  ADMIN_API_ALLOWED_ORIGINS, PAYMENT_CHANNEL

Notes:
  This initializes a local production release-candidate env file and never prints secret values.
  It generates server-side operation tokens when they are missing.
  Do not commit the generated env file.
EOF
}

log() {
  printf '[saas-prod-env-init] %s\n' "$*"
}

warn() {
  printf '[saas-prod-env-init] WARN: %s\n' "$*" >&2
}

die() {
  printf '[saas-prod-env-init] ERROR: %s\n' "$*" >&2
  exit 1
}

random_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return 0
  fi

  dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n'
  printf '\n'
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

set_env_key() {
  local key="$1"
  local value="$2"
  local tmp

  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    $0 ~ "^[[:space:]]*" key "=" {
      print key "=" value
      updated = 1
      next
    }
    { print }
    END {
      if (updated == 0) {
        print key "=" value
      }
    }
  ' "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
}

ensure_value() {
  local key="$1"
  local value="$2"
  local required="${3:-optional}"
  local existing

  existing="$(value_from_env_file "$key" "$ENV_FILE")"
  if [[ -n "$existing" && "$OVERWRITE" -ne 1 ]]; then
    log "$key already set"
    return 0
  fi

  if [[ -z "$value" ]]; then
    if [[ "$required" == "required" ]]; then
      warn "$key is empty; fill it before release-candidate dry run"
    fi
    return 0
  fi

  set_env_key "$key" "$value"
  log "$key set"
}

ensure_default() {
  local key="$1"
  local value="$2"
  local existing

  existing="$(value_from_env_file "$key" "$ENV_FILE")"
  if [[ -n "$existing" && "$OVERWRITE" -ne 1 ]]; then
    log "$key already set"
    return 0
  fi

  set_env_key "$key" "$value"
  log "$key set"
}

ensure_generated_token() {
  local key="$1"
  local existing

  existing="$(value_from_env_file "$key" "$ENV_FILE")"
  if [[ -n "$existing" && "$OVERWRITE" -ne 1 ]]; then
    log "$key already set"
    return 0
  fi

  set_env_key "$key" "$(random_token)"
  log "$key generated"
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --supabase-url)
        SUPABASE_URL="${2:-}"
        shift 2
        ;;
      --supabase-anon-key)
        SUPABASE_ANON_KEY="${2:-}"
        shift 2
        ;;
      --admob-app-id)
        ADMOB_APP_ID="${2:-}"
        shift 2
        ;;
      --admob-banner-id)
        ADMOB_BANNER_ID="${2:-}"
        shift 2
        ;;
      --admin-origins)
        ADMIN_API_ALLOWED_ORIGINS="${2:-}"
        shift 2
        ;;
      --payment-channel)
        PAYMENT_CHANNEL="${2:-}"
        shift 2
        ;;
      --overwrite)
        OVERWRITE=1
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
}

main() {
  parse_args "$@"

  [[ -f "$TEMPLATE" ]] || die "template not found: $TEMPLATE"

  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$TEMPLATE" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    log "created env file: $ENV_FILE"
  else
    chmod 600 "$ENV_FILE"
    log "updating env file: $ENV_FILE"
  fi

  ensure_value "SUPABASE_URL" "${SUPABASE_URL:-}" required
  ensure_value "SUPABASE_ANON_KEY" "${SUPABASE_ANON_KEY:-}" required
  ensure_value "ADMOB_APP_ID" "${ADMOB_APP_ID:-}" required
  ensure_value "ADMOB_BANNER_ID" "${ADMOB_BANNER_ID:-}" required
  ensure_value "ADMIN_API_ALLOWED_ORIGINS" "${ADMIN_API_ALLOWED_ORIGINS:-}" optional

  ensure_default "PAYMENT_CHANNEL" "${PAYMENT_CHANNEL:-google_play}"
  ensure_default "ENABLE_STORE_BILLING" "true"
  ensure_default "ENABLE_WECHAT_PAY" "false"
  ensure_default "ENABLE_ALIPAY" "false"
  ensure_default "DOMESTIC_PAYMENT_MOCK_BASE_URL" ""

  ensure_generated_token "PUBSUB_BEARER_TOKEN"
  ensure_generated_token "WEBHOOK_HMAC_SECRET"
  ensure_generated_token "ADMIN_API_TOKEN"
  ensure_generated_token "ANALYTICS_ADMIN_TOKEN"
  ensure_generated_token "NOTIFICATION_ADMIN_TOKEN"

  log "production env initialization complete"
  log "next: bash scripts/check_saas_production_readiness.sh --profile app --store android --env-file $ENV_FILE"
  log "next: bash scripts/push_saas_github_secrets.sh --profile production-release --repo zensgit/jive --env-file $ENV_FILE --apply"
}

main "$@"
