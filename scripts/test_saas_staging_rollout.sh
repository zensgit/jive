#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$SCRIPT_DIR/run_saas_staging_rollout.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_staging_rollout.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_saas_staging_rollout.sh.
The test uses a fake Supabase CLI through SUPABASE_CMD plus temporary env files.
It does not call GitHub, Supabase, Postgres, Flutter, devices, or any real
secret store.
EOF
}

KEEP_FIXTURES=0
while (( "$#" )); do
  case "$1" in
    --keep-fixtures)
      KEEP_FIXTURES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf '[saas-staging-rollout-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-staging-rollout-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
SUPABASE_LOG="$ROOT/fake-supabase.log"
PYTHON_LOG="$ROOT/fake-python.log"
SECRETS_SNAPSHOT="$ROOT/fake-secrets.env"
mkdir -p "$BIN_DIR"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-staging-rollout-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-staging-rollout-test] %s\n' "$*"
}

fail() {
  printf '[saas-staging-rollout-test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$file"; then
    fail "did not expect '$unexpected' in $file"
  fi
}

write_fake_supabase() {
  cat > "$BIN_DIR/supabase-fixture" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_SUPABASE_LOG:?JIVE_FAKE_SUPABASE_LOG is required}"
printf '%s\n' "$*" >> "$log_file"

case "${1:-}" in
  --version)
    printf 'supabase-fixture 1.0.0\n'
    ;;
  link)
    printf '[fake-supabase] link\n'
    ;;
  db)
    if [[ "${2:-}" == "push" ]]; then
      if [[ "${JIVE_FAKE_SUPABASE_FAIL_DB_PUSH:-}" == "1" ]]; then
        printf '[fake-supabase] db push forced failure\n' >&2
        exit 19
      fi
      printf '[fake-supabase] db push\n'
    else
      printf '[fake-supabase] unsupported db args: %s\n' "$*" >&2
      exit 2
    fi
    ;;
  secrets)
    if [[ "${2:-}" == "set" ]]; then
      snapshot="${JIVE_FAKE_SECRETS_SNAPSHOT:-}"
      if [[ -n "$snapshot" ]]; then
        env_file=""
        previous=""
        for arg in "$@"; do
          if [[ "$previous" == "--env-file" ]]; then
            env_file="$arg"
            break
          fi
          previous="$arg"
        done
        if [[ -n "$env_file" && -f "$env_file" ]]; then
          {
            printf -- '--- secrets set ---\n'
            cat "$env_file"
          } >> "$snapshot"
        fi
      fi
      printf '[fake-supabase] secrets set\n'
    else
      printf '[fake-supabase] unsupported secrets args: %s\n' "$*" >&2
      exit 2
    fi
    ;;
  functions)
    if [[ "${2:-}" == "deploy" ]]; then
      printf '[fake-supabase] functions deploy %s\n' "${3:-}"
    else
      printf '[fake-supabase] unsupported functions args: %s\n' "$*" >&2
      exit 2
    fi
    ;;
  *)
    printf '[fake-supabase] unsupported args: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF

  chmod +x "$BIN_DIR/supabase-fixture"

  cat > "$BIN_DIR/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="${JIVE_FAKE_PYTHON_LOG:?JIVE_FAKE_PYTHON_LOG is required}"
printf '%s\n' "$*" >> "$log_file"

if [[ "${1:-}" == "-c" ]]; then
  exit 0
fi

if [[ "${1:-}" == *"supabase_db_fallback.py" ]]; then
  printf '[fake-python] fallback %s\n' "${2:-}"
  exit 0
fi

printf '[fake-python] unsupported args: %s\n' "$*" >&2
exit 2
EOF

  chmod +x "$BIN_DIR/python3"
}

write_env_file() {
  local path="$1"
  local profile="$2"

  {
    printf 'SUPABASE_URL=https://fixture.supabase.co\n'
    printf 'SUPABASE_ANON_KEY=fixture-secret-anon-key\n'
    printf 'SUPABASE_SERVICE_ROLE_KEY=fixture-secret-service-role\n'
    printf 'ADMIN_API_TOKEN=fixture-secret-admin\n'
    printf 'ADMIN_API_ALLOWED_ORIGINS=https://admin.example.test\n'
    printf 'ANALYTICS_ADMIN_TOKEN=fixture-secret-analytics\n'
    printf 'NOTIFICATION_ADMIN_TOKEN=fixture-secret-notification\n'

    if [[ "$profile" == "full" ]]; then
      printf 'GOOGLE_SERVICE_ACCOUNT_EMAIL=service-account@example.test\n'
      printf 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY=fixture-secret-google-private-key\n'
      printf 'GOOGLE_PLAY_PACKAGE_NAME=com.example.jive\n'
      printf 'APPLE_APP_STORE_BUNDLE_ID=com.example.jive\n'
      printf 'APPLE_APP_STORE_SHARED_SECRET=fixture-secret-apple-shared-secret\n'
      printf 'APPLE_APP_STORE_APPLE_ID=1234567890\n'
      printf 'APPLE_APP_STORE_ENVIRONMENT=sandbox\n'
      printf 'PUBSUB_BEARER_TOKEN=fixture-secret-pubsub\n'
      printf 'WEBHOOK_HMAC_SECRET=fixture-secret-webhook\n'
      printf 'DOMESTIC_PAYMENT_WEBHOOK_TOKEN=fixture-secret-domestic-webhook\n'
      printf 'DOMESTIC_PAYMENT_MOCK_BASE_URL=https://pay.example.test/mock\n'
    fi
  } > "$path"
}

run_rollout() {
  local label="$1"
  shift

  local stdout="$ROOT/$label.stdout"
  local stderr="$ROOT/$label.stderr"
  local status_file="$ROOT/$label.status"

  : > "$SUPABASE_LOG"
  : > "$PYTHON_LOG"
  : > "$SECRETS_SNAPSHOT"
  set +e
  PATH="$BIN_DIR:$PATH" \
  JIVE_FAKE_SUPABASE_LOG="$SUPABASE_LOG" \
  JIVE_FAKE_PYTHON_LOG="$PYTHON_LOG" \
  JIVE_FAKE_SECRETS_SNAPSHOT="$SECRETS_SNAPSHOT" \
  JIVE_FAKE_SUPABASE_FAIL_DB_PUSH="${JIVE_FAKE_SUPABASE_FAIL_DB_PUSH:-}" \
  SUPABASE_CMD="$BIN_DIR/supabase-fixture" \
  STAGING_PROJECT_REF="${STAGING_PROJECT_REF:-}" \
  STAGING_DB_PASSWORD="${STAGING_DB_PASSWORD:-}" \
  SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}" \
    bash "$TARGET" "$@" > "$stdout" 2> "$stderr"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$status_file"
  cp "$SUPABASE_LOG" "$ROOT/$label.supabase.log"
  cp "$PYTHON_LOG" "$ROOT/$label.python.log"
  cp "$SECRETS_SNAPSHOT" "$ROOT/$label.secrets.env"
}

assert_status() {
  local label="$1"
  local expected="$2"
  local actual

  actual="$(cat "$ROOT/$label.status")"
  if [[ "$actual" != "$expected" ]]; then
    printf '--- stdout ---\n' >&2
    cat "$ROOT/$label.stdout" >&2 || true
    printf '--- stderr ---\n' >&2
    cat "$ROOT/$label.stderr" >&2 || true
    printf '--- fake supabase ---\n' >&2
    cat "$ROOT/$label.supabase.log" >&2 || true
    printf '--- fake python ---\n' >&2
    cat "$ROOT/$label.python.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_no_secret_values() {
  local label="$1"
  assert_not_contains "$ROOT/$label.stdout" "fixture-secret"
  assert_not_contains "$ROOT/$label.stderr" "fixture-secret"
  assert_not_contains "$ROOT/$label.supabase.log" "fixture-secret"
  assert_not_contains "$ROOT/$label.python.log" "fixture-secret"
}

write_fake_supabase

CORE_ENV="$ROOT/core.env"
FULL_ENV="$ROOT/full.env"
write_env_file "$CORE_ENV" core
write_env_file "$FULL_ENV" full

STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
SUPABASE_ACCESS_TOKEN="fixture-secret-access-token" \
  run_rollout preflight-core preflight --profile core --env-file "$CORE_ENV"
assert_status preflight-core 0
assert_contains "$ROOT/preflight-core.stdout" "profile: core"
assert_contains "$ROOT/preflight-core.stdout" "supabase cli: supabase-fixture 1.0.0"
assert_contains "$ROOT/preflight-core.stdout" "core profile skips billing/webhook provider requirements"
assert_contains "$ROOT/preflight-core.stdout" "preflight passed"
assert_no_secret_values preflight-core
log "pass fixture ok: core preflight"

STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
SUPABASE_ACCESS_TOKEN="fixture-secret-access-token" \
  run_rollout preflight-full preflight --profile full --env-file "$FULL_ENV"
assert_status preflight-full 0
assert_contains "$ROOT/preflight-full.stdout" "profile: full"
assert_contains "$ROOT/preflight-full.stdout" "env:GOOGLE_SERVICE_ACCOUNT_EMAIL: ok"
assert_contains "$ROOT/preflight-full.stdout" "env:DOMESTIC_PAYMENT_WEBHOOK_TOKEN: ok"
assert_contains "$ROOT/preflight-full.stdout" "preflight passed"
assert_no_secret_values preflight-full
log "pass fixture ok: full preflight"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout dry-run-skip-link dry-run \
    --profile core \
    --env-file "$CORE_ENV" \
    --skip-link \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status dry-run-skip-link 0
assert_contains "$ROOT/dry-run-skip-link.stdout" "previewing pending migrations"
assert_contains "$ROOT/dry-run-skip-link.supabase.log" "db push --include-all --dry-run --workdir $APP_DIR"
assert_not_contains "$ROOT/dry-run-skip-link.supabase.log" "link --project-ref"
assert_no_secret_values dry-run-skip-link
log "pass fixture ok: dry-run skip-link"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout apply-skip-link apply \
    --profile core \
    --env-file "$CORE_ENV" \
    --skip-link \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status apply-skip-link 0
assert_contains "$ROOT/apply-skip-link.stdout" "applying pending migrations"
assert_contains "$ROOT/apply-skip-link.supabase.log" "db push --include-all --workdir $APP_DIR"
assert_not_contains "$ROOT/apply-skip-link.supabase.log" "--dry-run"
assert_not_contains "$ROOT/apply-skip-link.supabase.log" "link --project-ref"
assert_no_secret_values apply-skip-link
log "pass fixture ok: apply skip-link"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout deploy-core deploy \
    --profile core \
    --env-file "$CORE_ENV" \
    --project-ref fixture-project-ref-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status deploy-core 0
assert_contains "$ROOT/deploy-core.stdout" "pushing core staging secrets from $CORE_ENV"
assert_contains "$ROOT/deploy-core.stdout" "deploying function analytics"
assert_contains "$ROOT/deploy-core.stdout" "deploying function send-notification"
assert_contains "$ROOT/deploy-core.stdout" "deploying function admin"
assert_contains "$ROOT/deploy-core.supabase.log" "secrets set --env-file"
assert_contains "$ROOT/deploy-core.supabase.log" "functions deploy analytics --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_contains "$ROOT/deploy-core.supabase.log" "functions deploy send-notification --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_contains "$ROOT/deploy-core.supabase.log" "functions deploy admin --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_not_contains "$ROOT/deploy-core.stdout" "deploying function subscription-webhook"
assert_not_contains "$ROOT/deploy-core.stdout" "deploying function create-payment-order"
assert_not_contains "$ROOT/deploy-core.secrets.env" "SUPABASE_URL="
assert_not_contains "$ROOT/deploy-core.secrets.env" "SUPABASE_ANON_KEY="
assert_not_contains "$ROOT/deploy-core.secrets.env" "SUPABASE_SERVICE_ROLE_KEY="
assert_no_secret_values deploy-core
log "pass fixture ok: core deploy command shape"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout deploy-full deploy \
    --profile full \
    --env-file "$FULL_ENV" \
    --project-ref fixture-project-ref-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status deploy-full 0
assert_contains "$ROOT/deploy-full.stdout" "deploying function subscription-webhook"
assert_contains "$ROOT/deploy-full.stdout" "deploying function verify-subscription"
assert_contains "$ROOT/deploy-full.stdout" "deploying function create-payment-order"
assert_contains "$ROOT/deploy-full.stdout" "deploying function domestic-payment-webhook"
assert_contains "$ROOT/deploy-full.stdout" "deploying function analytics"
assert_contains "$ROOT/deploy-full.stdout" "deploying function send-notification"
assert_contains "$ROOT/deploy-full.stdout" "deploying function admin"
assert_contains "$ROOT/deploy-full.supabase.log" "functions deploy subscription-webhook --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_contains "$ROOT/deploy-full.supabase.log" "functions deploy verify-subscription --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR"
assert_not_contains "$ROOT/deploy-full.supabase.log" "functions deploy verify-subscription --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_contains "$ROOT/deploy-full.supabase.log" "functions deploy domestic-payment-webhook --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_not_contains "$ROOT/deploy-full.secrets.env" "SUPABASE_URL="
assert_not_contains "$ROOT/deploy-full.secrets.env" "SUPABASE_ANON_KEY="
assert_not_contains "$ROOT/deploy-full.secrets.env" "SUPABASE_SERVICE_ROLE_KEY="
assert_no_secret_values deploy-full
log "pass fixture ok: full deploy command shape"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout fallback-only-dry-run dry-run \
    --profile core \
    --env-file "$CORE_ENV" \
    --pg-fallback-only \
    --db-url "postgres://fixture.example.test:5432/postgres" \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status fallback-only-dry-run 0
assert_contains "$ROOT/fallback-only-dry-run.stdout" "running direct Postgres fallback (plan)"
assert_contains "$ROOT/fallback-only-dry-run.python.log" "supabase_db_fallback.py plan --db-url postgres://fixture.example.test:5432/postgres"
assert_not_contains "$ROOT/fallback-only-dry-run.supabase.log" "link"
assert_not_contains "$ROOT/fallback-only-dry-run.supabase.log" "db push"
assert_no_secret_values fallback-only-dry-run
log "pass fixture ok: dry-run pg fallback only"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout fallback-only-apply apply \
    --profile core \
    --env-file "$CORE_ENV" \
    --pg-fallback-only \
    --db-url "postgres://fixture.example.test:5432/postgres" \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status fallback-only-apply 0
assert_contains "$ROOT/fallback-only-apply.stdout" "running direct Postgres fallback (apply)"
assert_contains "$ROOT/fallback-only-apply.python.log" "supabase_db_fallback.py apply --db-url postgres://fixture.example.test:5432/postgres"
assert_not_contains "$ROOT/fallback-only-apply.supabase.log" "link"
assert_not_contains "$ROOT/fallback-only-apply.supabase.log" "db push"
assert_no_secret_values fallback-only-apply
log "pass fixture ok: apply pg fallback only"

JIVE_FAKE_SUPABASE_FAIL_DB_PUSH=1 \
STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout fallback-after-cli-failure dry-run \
    --profile core \
    --env-file "$CORE_ENV" \
    --skip-link \
    --pg-fallback \
    --db-url "postgres://fixture.example.test:5432/postgres" \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status fallback-after-cli-failure 0
assert_contains "$ROOT/fallback-after-cli-failure.stderr" "Supabase CLI dry-run failed; switching to direct Postgres fallback"
assert_contains "$ROOT/fallback-after-cli-failure.supabase.log" "db push --include-all --dry-run --workdir $APP_DIR"
assert_contains "$ROOT/fallback-after-cli-failure.python.log" "supabase_db_fallback.py plan --db-url postgres://fixture.example.test:5432/postgres"
assert_no_secret_values fallback-after-cli-failure
log "pass fixture ok: dry-run fallback after CLI failure"

STAGING_PROJECT_REF="" \
STAGING_DB_PASSWORD="" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout all-core-fallback-only all \
    --profile core \
    --env-file "$CORE_ENV" \
    --pg-fallback-only \
    --db-url "postgres://fixture.example.test:5432/postgres" \
    --project-ref fixture-project-ref-from-arg \
    --db-password fixture-secret-db-password-from-arg \
    --access-token fixture-secret-access-token-from-arg
assert_status all-core-fallback-only 0
assert_contains "$ROOT/all-core-fallback-only.python.log" "supabase_db_fallback.py plan --db-url postgres://fixture.example.test:5432/postgres"
assert_contains "$ROOT/all-core-fallback-only.python.log" "supabase_db_fallback.py apply --db-url postgres://fixture.example.test:5432/postgres"
assert_contains "$ROOT/all-core-fallback-only.supabase.log" "secrets set --env-file"
assert_contains "$ROOT/all-core-fallback-only.supabase.log" "functions deploy analytics --project-ref fixture-project-ref-from-arg --use-api --workdir $APP_DIR --no-verify-jwt"
assert_not_contains "$ROOT/all-core-fallback-only.supabase.log" "db push"
assert_no_secret_values all-core-fallback-only
log "pass fixture ok: all core pg fallback only"

STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
SUPABASE_ACCESS_TOKEN="" \
  run_rollout missing-access dry-run --profile core --env-file "$CORE_ENV" --skip-link
assert_status missing-access 1
assert_contains "$ROOT/missing-access.stderr" "[saas-staging-rollout] ERROR: missing required value: SUPABASE_ACCESS_TOKEN"
assert_not_contains "$ROOT/missing-access.supabase.log" "db push"
assert_no_secret_values missing-access
log "negative fixture ok: missing access token blocks dry-run"

STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
SUPABASE_ACCESS_TOKEN="fixture-secret-access-token" \
  run_rollout missing-fallback-db-url dry-run \
    --profile core \
    --env-file "$CORE_ENV" \
    --pg-fallback-only
assert_status missing-fallback-db-url 1
assert_contains "$ROOT/missing-fallback-db-url.stderr" "[saas-staging-rollout] ERROR: missing required value: STAGING_DB_URL"
assert_no_secret_values missing-fallback-db-url
log "negative fixture ok: fallback-only requires db url"

run_rollout invalid-profile preflight --profile nope --env-file "$CORE_ENV"
assert_status invalid-profile 1
assert_contains "$ROOT/invalid-profile.stderr" "[saas-staging-rollout] ERROR: unknown profile: nope"
log "negative fixture ok: invalid profile exits non-zero"

run_rollout invalid-mode definitely-not-a-mode
assert_status invalid-mode 1
assert_contains "$ROOT/invalid-mode.stderr" "[saas-staging-rollout] ERROR: unknown mode: definitely-not-a-mode"
log "negative fixture ok: invalid mode exits non-zero"

run_rollout invalid-argument preflight --definitely-not-a-real-flag
assert_status invalid-argument 1
assert_contains "$ROOT/invalid-argument.stderr" "[saas-staging-rollout] ERROR: unknown argument: --definitely-not-a-real-flag"
log "negative fixture ok: invalid argument exits non-zero"

log "all staging rollout self-tests passed"
