#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
TEMPLATE="$APP_DIR/docs/jive-saas-staging.env.example"
OVERWRITE=0

usage() {
  cat <<'EOF'
Usage:
  scripts/init_saas_staging_env.sh [options]

Options:
  --env-file <path>                 Env file to create or update. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --supabase-url <value>            Optional Supabase URL to write when the key is empty.
  --supabase-anon-key <value>       Optional Supabase anon key to write when the key is empty.
  --supabase-service-role-key <v>   Optional Supabase service role key to write when the key is empty.
  --admin-origins <value>           Optional comma-separated admin CORS origins.
  --overwrite                       Replace existing values for the managed core keys.
  --help                            Show this help.

Environment fallbacks:
  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, ADMIN_API_ALLOWED_ORIGINS

Notes:
  This script initializes a local staging env file for the core SaaS smoke path.
  It generates random webhook/admin/analytics/notification tokens but never prints them.
  Do not commit the generated env file.
EOF
}

log() {
  printf '[saas-env-init] %s\n' "$*"
}

die() {
  printf '[saas-env-init] ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf '[saas-env-init] WARN: %s\n' "$*" >&2
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
  local existing

  existing="$(value_from_env_file "$key" "$ENV_FILE")"
  if [[ -n "$existing" && "$OVERWRITE" -ne 1 ]]; then
    log "$key already set"
    return 0
  fi

  if [[ -z "$value" ]]; then
    warn "$key is empty; fill it before strict deployment preflight"
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
      --supabase-service-role-key)
        SUPABASE_SERVICE_ROLE_KEY="${2:-}"
        shift 2
        ;;
      --admin-origins)
        ADMIN_API_ALLOWED_ORIGINS="${2:-}"
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

  ensure_value "SUPABASE_URL" "${SUPABASE_URL:-}"
  ensure_value "SUPABASE_ANON_KEY" "${SUPABASE_ANON_KEY:-}"
  ensure_value "SUPABASE_SERVICE_ROLE_KEY" "${SUPABASE_SERVICE_ROLE_KEY:-}"
  ensure_value "ADMIN_API_ALLOWED_ORIGINS" \
    "${ADMIN_API_ALLOWED_ORIGINS:-http://localhost:3000,http://localhost:5173}"

  ensure_generated_token "PUBSUB_BEARER_TOKEN"
  ensure_generated_token "WEBHOOK_HMAC_SECRET"
  ensure_generated_token "ADMIN_API_TOKEN"
  ensure_generated_token "ANALYTICS_ADMIN_TOKEN"
  ensure_generated_token "NOTIFICATION_ADMIN_TOKEN"

  log "core env initialization complete"
  log "next: bash scripts/check_saas_deployment_readiness.sh --profile core --strict --env-file $ENV_FILE"
}

main "$@"
