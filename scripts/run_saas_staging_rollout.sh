#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-help}"
shift || true

PROJECT_REF="${STAGING_PROJECT_REF:-}"
DB_PASSWORD="${STAGING_DB_PASSWORD:-}"
ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
SKIP_LINK=0
FAILURES=0

SUPABASE_RUNNER=()
if [[ -n "${SUPABASE_CMD:-}" ]]; then
  # shellcheck disable=SC2206
  SUPABASE_RUNNER=(${SUPABASE_CMD})
else
  SUPABASE_RUNNER=(npx -y supabase@latest)
fi

FUNCTIONS=(
  subscription-webhook
  verify-subscription
  analytics
  send-notification
  admin
)

REQUIRED_ENV_FILE_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_SERVICE_ROLE_KEY
  GOOGLE_SERVICE_ACCOUNT_EMAIL
  GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
  GOOGLE_PLAY_PACKAGE_NAME
  APPLE_APP_STORE_BUNDLE_ID
  APPLE_APP_STORE_SHARED_SECRET
  APPLE_APP_STORE_APPLE_ID
  APPLE_APP_STORE_ENVIRONMENT
  PUBSUB_BEARER_TOKEN
  WEBHOOK_HMAC_SECRET
  ADMIN_API_TOKEN
  ADMIN_API_ALLOWED_ORIGINS
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_rollout.sh <mode> [options]

Modes:
  preflight Check local prerequisites, env vars, and secrets file completeness
  dry-run   Link staging project and preview pending migrations
  apply     Link staging project and apply pending migrations
  deploy    Push secrets and deploy the 5 SaaS Edge Functions
  all       Link, dry-run, apply, push secrets, and deploy functions
  help      Show this help

Options:
  --project-ref <ref>     Supabase project ref. Falls back to STAGING_PROJECT_REF.
  --db-password <value>   Remote database password. Falls back to STAGING_DB_PASSWORD.
  --access-token <value>  Supabase access token. Falls back to SUPABASE_ACCESS_TOKEN.
  --env-file <path>       Secrets env file. Falls back to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --skip-link             Skip the explicit supabase link step.
  --help                  Show this help.

Examples:
  scripts/run_saas_staging_rollout.sh preflight --env-file /tmp/jive-saas-staging.env
  scripts/run_saas_staging_rollout.sh dry-run --project-ref "$STAGING_PROJECT_REF" --db-password "$STAGING_DB_PASSWORD"
  scripts/run_saas_staging_rollout.sh apply --skip-link
  scripts/run_saas_staging_rollout.sh deploy --env-file /tmp/jive-saas-staging.env
  scripts/run_saas_staging_rollout.sh all
EOF
}

log() {
  printf '[saas-staging-rollout] %s\n' "$*"
}

die() {
  printf '[saas-staging-rollout] ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf '[saas-staging-rollout] WARN: %s\n' "$*" >&2
}

require_value() {
  local name="$1"
  local value="$2"
  [[ -n "$value" ]] || die "missing required value: $name"
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --project-ref)
        PROJECT_REF="${2:-}"
        shift 2
        ;;
      --db-password)
        DB_PASSWORD="${2:-}"
        shift 2
        ;;
      --access-token)
        ACCESS_TOKEN="${2:-}"
        shift 2
        ;;
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --skip-link)
        SKIP_LINK=1
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

supabase() {
  (cd "$APP_DIR" && "${SUPABASE_RUNNER[@]}" "$@")
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

check_present() {
  local label="$1"
  local value="$2"
  if [[ -n "$value" ]]; then
    log "$label: ok"
  else
    warn "$label: missing"
    FAILURES=$((FAILURES + 1))
  fi
}

preflight() {
  log "app dir: $APP_DIR"
  log "supabase runner: ${SUPABASE_RUNNER[*]}"
  if ! supabase --version >/dev/null 2>&1; then
    die "unable to run Supabase CLI via: ${SUPABASE_RUNNER[*]}"
  fi
  log "supabase cli: $(supabase --version)"

  if [[ -f "$APP_DIR/docs/jive-saas-staging.env.example" ]]; then
    log "secrets template: ok"
  else
    warn "secrets template missing: $APP_DIR/docs/jive-saas-staging.env.example"
    FAILURES=$((FAILURES + 1))
  fi

  check_present "STAGING_PROJECT_REF" "$PROJECT_REF"
  check_present "STAGING_DB_PASSWORD" "$DB_PASSWORD"
  check_present "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  if [[ -f "$ENV_FILE" ]]; then
    log "env file: $ENV_FILE"
    local key value
    for key in "${REQUIRED_ENV_FILE_KEYS[@]}"; do
      value="$(value_from_env_file "$key" "$ENV_FILE")"
      if [[ -n "$value" ]]; then
        log "env:$key: ok"
      else
        warn "env:$key: missing or empty"
        FAILURES=$((FAILURES + 1))
      fi
    done
  else
    warn "env file not found: $ENV_FILE"
    FAILURES=$((FAILURES + 1))
  fi

  if [[ "$FAILURES" -gt 0 ]]; then
    die "preflight found $FAILURES issue(s)"
  fi

  log "preflight passed"
}

link_project() {
  if [[ "$SKIP_LINK" -eq 1 ]]; then
    log "skipping link step"
    return 0
  fi

  require_value "STAGING_PROJECT_REF" "$PROJECT_REF"
  require_value "STAGING_DB_PASSWORD" "$DB_PASSWORD"
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  log "linking Supabase project $PROJECT_REF"
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase link \
      --project-ref "$PROJECT_REF" \
      --password "$DB_PASSWORD" \
      --workdir "$APP_DIR"
}

db_push_dry_run() {
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  log "previewing pending migrations"
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase db push \
      --include-all \
      --dry-run \
      --workdir "$APP_DIR"
}

db_push_apply() {
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  log "applying pending migrations"
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase db push \
      --include-all \
      --workdir "$APP_DIR"
}

push_secrets() {
  require_value "STAGING_PROJECT_REF" "$PROJECT_REF"
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"
  [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"

  log "pushing staging secrets from $ENV_FILE"
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase secrets set \
      --env-file "$ENV_FILE" \
      --project-ref "$PROJECT_REF" \
      --workdir "$APP_DIR"
}

deploy_functions() {
  require_value "STAGING_PROJECT_REF" "$PROJECT_REF"
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  local function_name
  for function_name in "${FUNCTIONS[@]}"; do
    log "deploying function $function_name"
    SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
      supabase functions deploy "$function_name" \
        --project-ref "$PROJECT_REF" \
        --use-api \
        --workdir "$APP_DIR"
  done
}

main() {
  parse_args "$@"

  case "$MODE" in
    preflight)
      preflight
      ;;
    dry-run)
      link_project
      db_push_dry_run
      ;;
    apply)
      link_project
      db_push_apply
      ;;
    deploy)
      push_secrets
      deploy_functions
      ;;
    all)
      link_project
      db_push_dry_run
      db_push_apply
      push_secrets
      deploy_functions
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      die "unknown mode: $MODE"
      ;;
  esac
}

main "$@"
