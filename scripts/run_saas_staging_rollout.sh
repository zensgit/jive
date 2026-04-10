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

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_rollout.sh <mode> [options]

Modes:
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
