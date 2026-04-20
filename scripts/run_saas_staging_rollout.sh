#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-help}"
shift || true

PROJECT_REF="${STAGING_PROJECT_REF:-}"
DB_PASSWORD="${STAGING_DB_PASSWORD:-}"
ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
DB_URL="${STAGING_DB_URL:-}"
ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
PROFILE="${JIVE_SAAS_STAGING_PROFILE:-full}"
SKIP_LINK=0
PG_FALLBACK=0
PG_FALLBACK_ONLY=0
PG_LOCK_TIMEOUT="${STAGING_DB_LOCK_TIMEOUT:-4s}"
PG_STATEMENT_TIMEOUT="${STAGING_DB_STATEMENT_TIMEOUT:-60s}"
FAILURES=0
TEMP_FILES=()

SUPABASE_RUNNER=()
if [[ -n "${SUPABASE_CMD:-}" ]]; then
  # shellcheck disable=SC2206
  SUPABASE_RUNNER=(${SUPABASE_CMD})
else
  SUPABASE_RUNNER=(npx -y supabase@latest)
fi

FULL_FUNCTIONS=(
  subscription-webhook
  verify-subscription
  create-payment-order
  domestic-payment-webhook
  analytics
  send-notification
  admin
)

CORE_FUNCTIONS=(
  analytics
  send-notification
  admin
)

NO_VERIFY_JWT_FUNCTIONS=(
  subscription-webhook
  domestic-payment-webhook
  analytics
  send-notification
  admin
)

PLATFORM_DEFAULT_ENV_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_SERVICE_ROLE_KEY
)

CORE_REQUIRED_ENV_FILE_KEYS=(
  ADMIN_API_TOKEN
  ADMIN_API_ALLOWED_ORIGINS
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
)

FULL_REQUIRED_ENV_FILE_KEYS=(
  GOOGLE_SERVICE_ACCOUNT_EMAIL
  GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
  GOOGLE_PLAY_PACKAGE_NAME
  APPLE_APP_STORE_BUNDLE_ID
  APPLE_APP_STORE_SHARED_SECRET
  APPLE_APP_STORE_APPLE_ID
  APPLE_APP_STORE_ENVIRONMENT
  PUBSUB_BEARER_TOKEN
  WEBHOOK_HMAC_SECRET
  DOMESTIC_PAYMENT_WEBHOOK_TOKEN
  ADMIN_API_TOKEN
  ADMIN_API_ALLOWED_ORIGINS
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
)

OPTIONAL_ENV_FILE_KEYS=(
  DOMESTIC_PAYMENT_MOCK_BASE_URL
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_rollout.sh <mode> [options]

Modes:
  preflight Check local prerequisites, env vars, and secrets file completeness
  dry-run   Link staging project and preview pending migrations
  apply     Link staging project and apply pending migrations
  deploy    Push secrets and deploy SaaS Edge Functions
  all       Link, dry-run, apply, push secrets, and deploy functions
  help      Show this help

Options:
  --project-ref <ref>     Supabase project ref. Falls back to STAGING_PROJECT_REF.
  --db-password <value>   Remote database password. Falls back to STAGING_DB_PASSWORD.
  --access-token <value>  Supabase access token. Falls back to SUPABASE_ACCESS_TOKEN.
  --db-url <value>        Remote Postgres URL for direct migration fallback. Falls back to STAGING_DB_URL.
  --env-file <path>       Secrets env file. Falls back to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --profile <name>        full or core. Falls back to JIVE_SAAS_STAGING_PROFILE or full.
                          core deploys only core Functions and skips billing/webhook secrets.
  --core-only             Alias for --profile core.
  --pg-fallback           Allow direct Postgres fallback when Supabase CLI db push fails.
  --pg-fallback-only      Skip Supabase CLI db push and use the direct Postgres path immediately.
  --pg-lock-timeout <v>   Lock timeout used by the Postgres fallback. Falls back to STAGING_DB_LOCK_TIMEOUT or 4s.
  --pg-statement-timeout <v>
                          Statement timeout used by the Postgres fallback. Falls back to STAGING_DB_STATEMENT_TIMEOUT or 60s.
  --skip-link             Skip the explicit supabase link step.
  --help                  Show this help.

Examples:
  scripts/run_saas_staging_rollout.sh preflight --env-file /tmp/jive-saas-staging.env
  scripts/run_saas_staging_rollout.sh preflight --profile core --env-file /tmp/jive-saas-staging.env
  scripts/run_saas_staging_rollout.sh dry-run --project-ref "$STAGING_PROJECT_REF" --db-password "$STAGING_DB_PASSWORD"
  scripts/run_saas_staging_rollout.sh dry-run --pg-fallback-only --db-url "$STAGING_DB_URL"
  scripts/run_saas_staging_rollout.sh dry-run --pg-fallback --pg-lock-timeout 10s --pg-statement-timeout 180s
  scripts/run_saas_staging_rollout.sh apply --skip-link
  scripts/run_saas_staging_rollout.sh deploy --env-file /tmp/jive-saas-staging.env
  scripts/run_saas_staging_rollout.sh all --profile core
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

cleanup_temp_files() {
  if [[ "${#TEMP_FILES[@]}" -eq 0 ]]; then
    return 0
  fi

  local path
  for path in "${TEMP_FILES[@]}"; do
    [[ -n "$path" ]] || continue
    rm -f "$path"
  done
}

trap cleanup_temp_files EXIT INT TERM

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
      --db-url)
        DB_URL="${2:-}"
        shift 2
        ;;
      --env-file)
        ENV_FILE="${2:-}"
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
      --pg-fallback)
        PG_FALLBACK=1
        shift
        ;;
      --pg-fallback-only)
        PG_FALLBACK=1
        PG_FALLBACK_ONLY=1
        shift
        ;;
      --pg-lock-timeout)
        PG_LOCK_TIMEOUT="${2:-}"
        shift 2
        ;;
      --pg-statement-timeout)
        PG_STATEMENT_TIMEOUT="${2:-}"
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

  case "$PROFILE" in
    full|core)
      ;;
    *)
      die "unknown profile: $PROFILE"
      ;;
  esac
}

selected_env_keys() {
  if [[ "$PROFILE" == "core" ]]; then
    printf '%s\n' "${CORE_REQUIRED_ENV_FILE_KEYS[@]}"
  else
    printf '%s\n' "${FULL_REQUIRED_ENV_FILE_KEYS[@]}"
  fi
}

selected_secret_keys() {
  selected_env_keys
  printf '%s\n' "${OPTIONAL_ENV_FILE_KEYS[@]}"
}

selected_functions() {
  if [[ "$PROFILE" == "core" ]]; then
    printf '%s\n' "${CORE_FUNCTIONS[@]}"
  else
    printf '%s\n' "${FULL_FUNCTIONS[@]}"
  fi
}

function_uses_custom_auth() {
  local function_name="$1"
  local no_verify_function
  for no_verify_function in "${NO_VERIFY_JWT_FUNCTIONS[@]}"; do
    if [[ "$function_name" == "$no_verify_function" ]]; then
      return 0
    fi
  done
  return 1
}

platform_default_envs_csv() {
  local joined=""
  local key
  for key in "${PLATFORM_DEFAULT_ENV_KEYS[@]}"; do
    if [[ -n "$joined" ]]; then
      joined+=", "
    fi
    joined+="$key"
  done
  printf '%s' "$joined"
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
  log "profile: $PROFILE"
  log "supabase runner: ${SUPABASE_RUNNER[*]}"
  log "hosted default function envs (no secrets push required): $(platform_default_envs_csv)"
  if [[ "$PG_FALLBACK" -eq 1 ]]; then
    log "pg fallback timeouts: lock=$PG_LOCK_TIMEOUT statement=$PG_STATEMENT_TIMEOUT"
  fi
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
  if [[ "$PG_FALLBACK" -eq 1 ]]; then
    check_present "STAGING_DB_URL" "$DB_URL"
    if command -v python3 >/dev/null 2>&1; then
      if python3 -c 'import psycopg' >/dev/null 2>&1; then
        log "pg fallback runtime: python3 + psycopg: ok"
      else
        warn "pg fallback runtime missing psycopg; install with: python3 -m pip install --user 'psycopg[binary]'"
        FAILURES=$((FAILURES + 1))
      fi
    else
      warn "pg fallback runtime missing python3"
      FAILURES=$((FAILURES + 1))
    fi
  fi

  if [[ -f "$ENV_FILE" ]]; then
    log "env file: $ENV_FILE"
    local key value
    if [[ "$PROFILE" == "core" ]]; then
      log "core profile skips billing/webhook provider requirements for first staging smoke"
    fi
    while IFS= read -r key; do
      [[ -n "$key" ]] || continue
      value="$(value_from_env_file "$key" "$ENV_FILE")"
      if [[ -n "$value" ]]; then
        log "env:$key: ok"
      else
        warn "env:$key: missing or empty"
        FAILURES=$((FAILURES + 1))
      fi
    done < <(selected_env_keys)
  else
    warn "env file not found: $ENV_FILE"
    FAILURES=$((FAILURES + 1))
  fi

  if [[ "$FAILURES" -gt 0 ]]; then
    die "preflight found $FAILURES issue(s)"
  fi

  log "preflight passed"
}

run_pg_fallback() {
  local mode="$1"
  require_value "STAGING_DB_URL" "$DB_URL"

  log "running direct Postgres fallback ($mode)"
  python3 "$SCRIPT_DIR/supabase_db_fallback.py" \
    "$mode" \
    --db-url "$DB_URL" \
    --migrations-dir "$APP_DIR/supabase/migrations" \
    --lock-timeout "$PG_LOCK_TIMEOUT" \
    --statement-timeout "$PG_STATEMENT_TIMEOUT"
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
  if [[ "$PG_FALLBACK_ONLY" -eq 1 ]]; then
    run_pg_fallback plan
    return 0
  fi

  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  log "previewing pending migrations"
  local status=0
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase db push \
      --include-all \
      --dry-run \
      --workdir "$APP_DIR" || status=$?

  if [[ "$status" -eq 0 ]]; then
    return 0
  fi

  if [[ "$PG_FALLBACK" -eq 1 ]]; then
    warn "Supabase CLI dry-run failed; switching to direct Postgres fallback"
    run_pg_fallback plan
    return 0
  fi

  return "$status"
}

db_push_apply() {
  if [[ "$PG_FALLBACK_ONLY" -eq 1 ]]; then
    run_pg_fallback apply
    return 0
  fi

  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  log "applying pending migrations"
  local status=0
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase db push \
      --include-all \
      --workdir "$APP_DIR" || status=$?

  if [[ "$status" -eq 0 ]]; then
    return 0
  fi

  if [[ "$PG_FALLBACK" -eq 1 ]]; then
    warn "Supabase CLI apply failed; switching to direct Postgres fallback"
    run_pg_fallback apply
    return 0
  fi

  return "$status"
}

build_env_subset_file() {
  local output_file
  output_file="$(mktemp "${TMPDIR:-/tmp}/jive-saas-secrets.XXXXXX")"
  chmod 600 "$output_file"
  TEMP_FILES+=("$output_file")

  local key value
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    value="$(value_from_env_file "$key" "$ENV_FILE")"
    if [[ -n "$value" ]]; then
      printf '%s=%s\n' "$key" "$value" >> "$output_file"
    fi
  done < <(selected_secret_keys)

  printf '%s\n' "$output_file"
}

push_secrets() {
  require_value "STAGING_PROJECT_REF" "$PROJECT_REF"
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"
  [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"

  local subset_env_file
  subset_env_file="$(build_env_subset_file)"
  local status=0

  log "pushing $PROFILE staging secrets from $ENV_FILE"
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
    supabase secrets set \
      --env-file "$subset_env_file" \
      --project-ref "$PROJECT_REF" \
      --workdir "$APP_DIR" || status=$?

  rm -f "$subset_env_file"
  return "$status"
}

deploy_functions() {
  require_value "STAGING_PROJECT_REF" "$PROJECT_REF"
  require_value "SUPABASE_ACCESS_TOKEN" "$ACCESS_TOKEN"

  local function_name
  while IFS= read -r function_name; do
    [[ -n "$function_name" ]] || continue
    log "deploying function $function_name"
    local -a deploy_args
    deploy_args=(
      functions
      deploy
      "$function_name"
      --project-ref "$PROJECT_REF"
      --use-api
      --workdir "$APP_DIR"
    )
    if function_uses_custom_auth "$function_name"; then
      deploy_args+=(--no-verify-jwt)
    fi
    SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
      supabase "${deploy_args[@]}"
  done < <(selected_functions)
}

main() {
  parse_args "$@"

  case "$MODE" in
    preflight)
      preflight
      ;;
    dry-run)
      if [[ "$PG_FALLBACK_ONLY" -eq 0 ]]; then
        link_project
      fi
      db_push_dry_run
      ;;
    apply)
      if [[ "$PG_FALLBACK_ONLY" -eq 0 ]]; then
        link_project
      fi
      db_push_apply
      ;;
    deploy)
      push_secrets
      deploy_functions
      ;;
    all)
      if [[ "$PG_FALLBACK_ONLY" -eq 0 ]]; then
        link_project
      fi
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
