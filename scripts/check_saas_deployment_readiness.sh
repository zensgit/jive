#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
PROFILE="${JIVE_SAAS_STAGING_PROFILE:-core}"
STRICT=0
ONLINE=0
RUN_SMOKE=0
SKIP_GITHUB=0
FAILURES=0
WARNINGS=0

REQUIRED_REPO_FILES=(
  docs/jive-saas-staging.env.example
  docs/2026-04-10-saas-fast-track-checklist.md
  docs/2026-04-10-saas-staging-apply-runbook.md
  docs/2026-04-10-saas-staging-troubleshooting.md
  scripts/build_saas_staging_apk.sh
  scripts/check_saas_github_secrets.sh
  scripts/init_saas_staging_env.sh
  scripts/run_saas_core_staging_lane.sh
  scripts/run_saas_staging_function_smoke.sh
  scripts/run_saas_staging_rollout.sh
  scripts/run_saas_wave0_smoke.sh
)

REQUIRED_MIGRATIONS=(
  supabase/migrations/004_add_book_key.sql
  supabase/migrations/006_add_sync_tombstones.sql
  supabase/migrations/007_create_user_subscriptions.sql
  supabase/migrations/008_add_sync_keys_for_core_sync.sql
  supabase/migrations/009_webhook_idempotency.sql
  supabase/migrations/010_create_analytics_events.sql
  supabase/migrations/011_create_notification_queue.sql
  supabase/migrations/012_allow_admin_subscription_override.sql
)

REQUIRED_FUNCTIONS=(
  supabase/functions/subscription-webhook/index.ts
  supabase/functions/verify-subscription/index.ts
  supabase/functions/analytics/index.ts
  supabase/functions/send-notification/index.ts
  supabase/functions/admin/index.ts
)

REQUIRED_ENV_VARS=(
  SUPABASE_ACCESS_TOKEN
  STAGING_PROJECT_REF
  STAGING_DB_PASSWORD
)

CORE_ENV_FILE_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_SERVICE_ROLE_KEY
  PUBSUB_BEARER_TOKEN
  WEBHOOK_HMAC_SECRET
  ADMIN_API_TOKEN
  ADMIN_API_ALLOWED_ORIGINS
  ANALYTICS_ADMIN_TOKEN
  NOTIFICATION_ADMIN_TOKEN
)

BILLING_PROVIDER_ENV_FILE_KEYS=(
  GOOGLE_SERVICE_ACCOUNT_EMAIL
  GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
  GOOGLE_PLAY_PACKAGE_NAME
  APPLE_APP_STORE_BUNDLE_ID
  APPLE_APP_STORE_SHARED_SECRET
  APPLE_APP_STORE_APPLE_ID
  APPLE_APP_STORE_ENVIRONMENT
)

usage() {
  cat <<'EOF'
Usage:
  scripts/check_saas_deployment_readiness.sh [options]

Options:
  --env-file <path>  Secrets env file to check. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --profile <name>   core or full. Defaults to JIVE_SAAS_STAGING_PROFILE or core.
  --strict           Treat missing environment values and env-file keys as failures instead of warnings.
  --online           Also check GitHub main CI and Supabase CLI availability through npx.
  --run-smoke        Run scripts/run_saas_wave0_smoke.sh after static readiness checks.
  --skip-github      Skip GitHub CLI checks, even when --online is set.
  --help             Show this help.

Examples:
  scripts/check_saas_deployment_readiness.sh
  scripts/check_saas_deployment_readiness.sh --profile core
  scripts/check_saas_deployment_readiness.sh --profile full
  scripts/check_saas_deployment_readiness.sh --strict --env-file /tmp/jive-saas-staging.env
  scripts/check_saas_deployment_readiness.sh --online
  scripts/check_saas_deployment_readiness.sh --online --run-smoke

Notes:
  This script only reports whether secrets are present. It never prints secret values.
EOF
}

log() {
  printf '[saas-readiness] %s\n' "$*"
}

pass() {
  log "PASS: $*"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf '[saas-readiness] WARN: %s\n' "$*" >&2
}

fail() {
  FAILURES=$((FAILURES + 1))
  printf '[saas-readiness] FAIL: %s\n' "$*" >&2
}

warn_or_fail() {
  if [[ "$STRICT" -eq 1 ]]; then
    fail "$*"
  else
    warn "$*"
  fi
}

parse_args() {
  while (( "$#" )); do
    case "$1" in
      --env-file)
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --strict)
        STRICT=1
        shift
        ;;
      --online)
        ONLINE=1
        shift
        ;;
      --run-smoke)
        RUN_SMOKE=1
        shift
        ;;
      --skip-github)
        SKIP_GITHUB=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "unknown argument: $1"
        usage
        exit 2
        ;;
    esac
  done

  case "$PROFILE" in
    core|full)
      ;;
    *)
      fail "unknown profile: $PROFILE"
      usage
      exit 2
      ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

resolve_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$FLUTTER_BIN"
    return 0
  fi

  local candidate
  for candidate in \
    "$APP_DIR/../../.flutter_sdk/bin/flutter" \
    "$APP_DIR/../.flutter_sdk/bin/flutter" \
    "$APP_DIR/.flutter_sdk/bin/flutter" \
    "$HOME/development/flutter/bin/flutter" \
    "$HOME/flutter/bin/flutter" \
    "/opt/homebrew/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  command -v flutter 2>/dev/null
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

check_repo_files() {
  local path

  log "repo root: $APP_DIR"
  for path in "${REQUIRED_REPO_FILES[@]}"; do
    if [[ -f "$APP_DIR/$path" ]]; then
      pass "file exists: $path"
    else
      fail "missing required file: $path"
    fi
  done

  for path in "${REQUIRED_MIGRATIONS[@]}"; do
    if [[ -f "$APP_DIR/$path" ]]; then
      pass "migration exists: $path"
    else
      fail "missing migration: $path"
    fi
  done

  for path in "${REQUIRED_FUNCTIONS[@]}"; do
    if [[ -f "$APP_DIR/$path" ]]; then
      pass "function exists: $path"
    else
      fail "missing function entrypoint: $path"
    fi
  done
}

check_local_tools() {
  local flutter_bin

  if command_exists gh; then
    pass "gh CLI available"
  else
    warn_or_fail "gh CLI missing; GitHub CI checks and PR ops will be unavailable"
  fi

  if command_exists npx; then
    pass "npx available for Supabase CLI runner"
  else
    warn_or_fail "npx missing; install Node.js or set up a Supabase CLI binary"
  fi

  flutter_bin="$(resolve_flutter_bin || true)"
  if [[ -n "$flutter_bin" ]]; then
    pass "Flutter available: $flutter_bin"
  else
    warn_or_fail "Flutter not found; set FLUTTER_BIN or install Flutter before app smoke/build"
  fi
}

check_environment_values() {
  local key value
  local required_keys=("${CORE_ENV_FILE_KEYS[@]}")

  if [[ "$PROFILE" == "full" ]]; then
    required_keys+=("${BILLING_PROVIDER_ENV_FILE_KEYS[@]}")
  fi

  for key in "${REQUIRED_ENV_VARS[@]}"; do
    value="${!key:-}"
    if [[ -n "$value" ]]; then
      pass "env:$key present"
    else
      warn_or_fail "env:$key missing"
    fi
  done

  if [[ ! -f "$ENV_FILE" ]]; then
    warn_or_fail "env file missing: $ENV_FILE"
    return 0
  fi

  pass "env file exists: $ENV_FILE"
  log "env profile: $PROFILE"
  if [[ "$PROFILE" == "core" ]]; then
    log "core profile skips Google/Apple provider credential requirements for first staging smoke"
  fi

  for key in "${required_keys[@]}"; do
    value="$(value_from_env_file "$key" "$ENV_FILE")"
    if [[ -n "$value" ]]; then
      pass "env-file:$key present"
    else
      warn_or_fail "env-file:$key missing or empty"
    fi
  done
}

check_github_main_ci() {
  local run_info conclusion status url head_sha

  if [[ "$SKIP_GITHUB" -eq 1 ]]; then
    warn "GitHub checks skipped by --skip-github"
    return 0
  fi

  if ! command_exists gh; then
    warn_or_fail "gh CLI missing; cannot check main CI"
    return 0
  fi

  if ! gh auth status -h github.com >/dev/null 2>&1; then
    warn_or_fail "gh is not authenticated; run gh auth login before deployment ops"
    return 0
  fi

  run_info="$(gh run list \
    --repo zensgit/jive \
    --workflow flutter_ci.yml \
    --branch main \
    --limit 1 \
    --json conclusion,status,url,headSha \
    --jq '.[0] | "\(.status)|\(.conclusion)|\(.headSha)|\(.url)"' \
    2>/dev/null || true)"

  if [[ -z "$run_info" || "$run_info" == "null|"* ]]; then
    warn_or_fail "no main flutter_ci.yml run found"
    return 0
  fi

  IFS='|' read -r status conclusion head_sha url <<< "$run_info"

  if [[ "$status" == "completed" && "$conclusion" == "success" ]]; then
    pass "main CI is green at ${head_sha:-unknown}: ${url:-no-url}"
  else
    warn_or_fail "main CI is not green yet (status=${status:-unknown}, conclusion=${conclusion:-unknown}, url=${url:-no-url})"
  fi
}

check_supabase_cli_online() {
  local version

  if ! command_exists npx; then
    warn_or_fail "npx missing; cannot probe Supabase CLI"
    return 0
  fi

  version="$(cd "$APP_DIR" && npx -y supabase@latest --version 2>/dev/null || true)"
  if [[ -n "$version" ]]; then
    pass "Supabase CLI reachable via npx: $version"
  else
    warn_or_fail "Supabase CLI probe failed; check Node/npm network access before staging deploy"
  fi
}

run_wave0_smoke() {
  if [[ "$RUN_SMOKE" -ne 1 ]]; then
    return 0
  fi

  if [[ ! -x "$APP_DIR/scripts/run_saas_wave0_smoke.sh" && ! -f "$APP_DIR/scripts/run_saas_wave0_smoke.sh" ]]; then
    fail "cannot run Wave0 smoke; script missing"
    return 0
  fi

  log "running Wave0 smoke"
  if (cd "$APP_DIR" && bash scripts/run_saas_wave0_smoke.sh); then
    pass "Wave0 smoke passed"
  else
    fail "Wave0 smoke failed"
  fi
}

print_next_steps() {
  cat <<EOF
[saas-readiness] next:
[saas-readiness]   1. If only secrets are missing, copy docs/jive-saas-staging.env.example to $ENV_FILE and fill it locally.
[saas-readiness]   2. Run: scripts/check_saas_deployment_readiness.sh --strict --env-file $ENV_FILE
[saas-readiness]   3. Run staging deploy with scripts/run_saas_staging_rollout.sh preflight/apply/deploy.
[saas-readiness]   4. Build the app with SUPABASE_URL and SUPABASE_ANON_KEY passed by --dart-define.
EOF
}

main() {
  parse_args "$@"

  check_repo_files
  check_local_tools
  check_environment_values

  if [[ "$ONLINE" -eq 1 ]]; then
    check_github_main_ci
    check_supabase_cli_online
  fi

  run_wave0_smoke
  print_next_steps

  log "summary: failures=$FAILURES warnings=$WARNINGS profile=$PROFILE strict=$STRICT online=$ONLINE run_smoke=$RUN_SMOKE"
  if [[ "$FAILURES" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
