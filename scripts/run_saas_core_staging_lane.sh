#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
PROJECT_REF="${STAGING_PROJECT_REF:-}"
DB_PASSWORD="${STAGING_DB_PASSWORD:-}"
ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
DB_URL="${STAGING_DB_URL:-}"
FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-}"
SKIP_LOCAL_SMOKE=0
RUN_SYNC_SMOKE=0
SKIP_DRY_RUN=0
SKIP_APPLY=0
SKIP_DEPLOY=0
SKIP_FUNCTION_SMOKE=0
SKIP_APK=0
SKIP_ONLINE_READINESS=0
PG_FALLBACK=0
PG_FALLBACK_ONLY=0
PG_LOCK_TIMEOUT="${STAGING_DB_LOCK_TIMEOUT:-4s}"
PG_STATEMENT_TIMEOUT="${STAGING_DB_STATEMENT_TIMEOUT:-60s}"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_core_staging_lane.sh [options]

Options:
  --env-file <path>       Staging env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --project-ref <ref>     Supabase project ref. Falls back to STAGING_PROJECT_REF.
  --db-password <value>   Supabase DB password. Falls back to STAGING_DB_PASSWORD.
  --access-token <value>  Supabase access token. Falls back to SUPABASE_ACCESS_TOKEN.
  --db-url <value>        Remote Postgres URL for migration fallback. Falls back to STAGING_DB_URL.
  --functions-url <url>   Optional functions base URL. Defaults to SUPABASE_URL/functions/v1.
  --pg-fallback           Allow direct Postgres fallback when Supabase CLI db push fails.
  --pg-fallback-only      Skip Supabase CLI db push and use the direct Postgres path immediately.
  --pg-lock-timeout <v>   Lock timeout used by the Postgres fallback. Defaults to STAGING_DB_LOCK_TIMEOUT or 4s.
  --pg-statement-timeout <v>
                          Statement timeout used by the Postgres fallback. Defaults to STAGING_DB_STATEMENT_TIMEOUT or 60s.
  --skip-local-smoke      Skip scripts/run_saas_wave0_smoke.sh.
  --run-sync-smoke        Run scripts/run_saas_staging_sync_smoke.sh against staging.
  --skip-dry-run          Skip migration dry-run.
  --skip-apply            Skip migration apply.
  --skip-deploy           Skip Edge Functions deploy.
  --skip-function-smoke   Skip deployed Edge Functions smoke.
  --skip-apk              Skip dev debug APK build.
  --skip-online-readiness Skip GitHub/Supabase CLI online readiness probes.
  --help                  Show this help.

Required for apply/deploy:
  SUPABASE_ACCESS_TOKEN
  STAGING_PROJECT_REF
  STAGING_DB_PASSWORD

Notes:
  This is the fastest core staging lane after credentials are available.
  It uses the core SaaS profile, so Google/Apple store-provider credentials do not block the first staging smoke.
  It never passes SUPABASE_SERVICE_ROLE_KEY into the app build.
EOF
}

log() {
  printf '[saas-core-lane] %s\n' "$*"
}

die() {
  printf '[saas-core-lane] ERROR: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
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
      --functions-url)
        FUNCTIONS_URL="${2:-}"
        shift 2
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
      --skip-local-smoke)
        SKIP_LOCAL_SMOKE=1
        shift
        ;;
      --run-sync-smoke)
        RUN_SYNC_SMOKE=1
        shift
        ;;
      --skip-dry-run)
        SKIP_DRY_RUN=1
        shift
        ;;
      --skip-apply)
        SKIP_APPLY=1
        shift
        ;;
      --skip-deploy)
        SKIP_DEPLOY=1
        shift
        ;;
      --skip-function-smoke)
        SKIP_FUNCTION_SMOKE=1
        shift
        ;;
      --skip-apk)
        SKIP_APK=1
        shift
        ;;
      --skip-online-readiness)
        SKIP_ONLINE_READINESS=1
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

require_deploy_values() {
  [[ -n "$ACCESS_TOKEN" ]] || die "SUPABASE_ACCESS_TOKEN is required"
  [[ -n "$PROJECT_REF" ]] || die "STAGING_PROJECT_REF is required"
  [[ -n "$DB_PASSWORD" ]] || die "STAGING_DB_PASSWORD is required"
}

with_staging_env() {
  STAGING_ENV_FILE="$ENV_FILE" \
  STAGING_PROJECT_REF="$PROJECT_REF" \
  STAGING_DB_PASSWORD="$DB_PASSWORD" \
  STAGING_DB_URL="$DB_URL" \
  STAGING_DB_LOCK_TIMEOUT="$PG_LOCK_TIMEOUT" \
  STAGING_DB_STATEMENT_TIMEOUT="$PG_STATEMENT_TIMEOUT" \
  SUPABASE_ACCESS_TOKEN="$ACCESS_TOKEN" \
  SUPABASE_FUNCTIONS_URL="$FUNCTIONS_URL" \
    "$@"
}

main() {
  parse_args "$@"

  log "env file: $ENV_FILE"
  log "initializing core env file"
  bash "$APP_DIR/scripts/init_saas_staging_env.sh" --env-file "$ENV_FILE"

  local -a rollout_pg_args=()
  if [[ "$PG_FALLBACK" -eq 1 ]]; then
    rollout_pg_args+=(--pg-fallback)
  fi
  if [[ "$PG_FALLBACK_ONLY" -eq 1 ]]; then
    rollout_pg_args+=(--pg-fallback-only)
  fi
  if [[ -n "$DB_URL" ]]; then
    rollout_pg_args+=(--db-url "$DB_URL")
  fi
  rollout_pg_args+=(
    --pg-lock-timeout "$PG_LOCK_TIMEOUT"
    --pg-statement-timeout "$PG_STATEMENT_TIMEOUT"
  )

  local readiness_args=(--profile core --strict --env-file "$ENV_FILE")
  if [[ "$SKIP_ONLINE_READINESS" -ne 1 ]]; then
    readiness_args+=(--online)
  fi

  log "running strict readiness"
  with_staging_env bash "$APP_DIR/scripts/check_saas_deployment_readiness.sh" "${readiness_args[@]}"

  if [[ "$SKIP_LOCAL_SMOKE" -ne 1 ]]; then
    log "running local Wave0 SaaS smoke"
    bash "$APP_DIR/scripts/run_saas_wave0_smoke.sh"
  else
    log "skipping local Wave0 SaaS smoke"
  fi

  if [[ "$SKIP_DRY_RUN" -ne 1 || "$SKIP_APPLY" -ne 1 || "$SKIP_DEPLOY" -ne 1 ]]; then
    require_deploy_values
  fi

  if [[ "$SKIP_DRY_RUN" -ne 1 ]]; then
    log "previewing staging migrations"
    with_staging_env bash "$APP_DIR/scripts/run_saas_staging_rollout.sh" \
      dry-run \
      --profile core \
      --env-file "$ENV_FILE" \
      "${rollout_pg_args[@]}"
  else
    log "skipping migration dry-run"
  fi

  if [[ "$SKIP_APPLY" -ne 1 ]]; then
    log "applying staging migrations"
    with_staging_env bash "$APP_DIR/scripts/run_saas_staging_rollout.sh" \
      apply \
      --profile core \
      --skip-link \
      --env-file "$ENV_FILE" \
      "${rollout_pg_args[@]}"
  else
    log "skipping migration apply"
  fi

  if [[ "$RUN_SYNC_SMOKE" -eq 1 ]]; then
    local sync_smoke_out="$APP_DIR/build/reports/saas-staging/sync-smoke-$(date +%Y%m%d-%H%M%S)"
    log "running staging core sync smoke"
    with_staging_env bash "$APP_DIR/scripts/run_saas_staging_sync_smoke.sh" \
      --env-file "$ENV_FILE" \
      --out-dir "$sync_smoke_out"
  else
    log "skipping staging core sync smoke"
  fi

  if [[ "$SKIP_DEPLOY" -ne 1 ]]; then
    log "deploying staging Edge Functions"
    with_staging_env bash "$APP_DIR/scripts/run_saas_staging_rollout.sh" \
      deploy \
      --profile core \
      --env-file "$ENV_FILE"
  else
    log "skipping Edge Functions deploy"
  fi

  if [[ "$SKIP_FUNCTION_SMOKE" -ne 1 ]]; then
    log "running deployed Functions smoke"
    local function_smoke_args=(--profile core --env-file "$ENV_FILE")
    if [[ -n "$FUNCTIONS_URL" ]]; then
      function_smoke_args+=(--functions-url "$FUNCTIONS_URL")
    fi
    bash "$APP_DIR/scripts/run_saas_staging_function_smoke.sh" "${function_smoke_args[@]}"
  else
    log "skipping deployed Functions smoke"
  fi

  if [[ "$SKIP_APK" -ne 1 ]]; then
    log "building dev debug staging APK"
    bash "$APP_DIR/scripts/build_saas_staging_apk.sh" \
      --env-file "$ENV_FILE" \
      --flavor dev \
      --mode debug \
      --kind apk
  else
    log "skipping staging APK build"
  fi

  log "core staging lane completed"
}

main "$@"
