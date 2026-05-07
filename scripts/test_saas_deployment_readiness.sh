#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$SCRIPT_DIR/check_saas_deployment_readiness.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_deployment_readiness.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/check_saas_deployment_readiness.sh.
The test uses fake gh, npx, and Flutter binaries plus temporary env files.
It does not call GitHub, Supabase, Flutter, a device, or any real secret store.
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
      printf '[saas-deployment-readiness-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-deployment-readiness-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
mkdir -p "$BIN_DIR"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-deployment-readiness-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-deployment-readiness-test] %s\n' "$*"
}

fail() {
  printf '[saas-deployment-readiness-test] FAIL: %s\n' "$*" >&2
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

write_fake_bins() {
  cat > "$BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 0
fi

if [[ "${1:-}" == "run" && "${2:-}" == "list" ]]; then
  printf 'completed|success|abcdef1234567890|https://example.test/actions/runs/1\n'
  exit 0
fi

printf '[fake-gh] unsupported args: %s\n' "$*" >&2
exit 2
EOF

  cat > "$BIN_DIR/npx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == *"supabase@latest --version"* ]]; then
  printf '2.20.0\n'
  exit 0
fi

printf '[fake-npx] unsupported args: %s\n' "$*" >&2
exit 2
EOF

  cat > "$BIN_DIR/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'Flutter fixture\n'
EOF

  chmod +x "$BIN_DIR/gh" "$BIN_DIR/npx" "$BIN_DIR/flutter"
}

write_env_file() {
  local path="$1"
  local include_billing="${2:-0}"

  {
    printf 'SUPABASE_URL=fixture-secret-supabase-url\n'
    printf 'SUPABASE_ANON_KEY=fixture-secret-anon-key\n'
    printf 'SUPABASE_SERVICE_ROLE_KEY=fixture-secret-service-role\n'
    printf 'PUBSUB_BEARER_TOKEN=fixture-secret-pubsub\n'
    printf 'WEBHOOK_HMAC_SECRET=fixture-secret-webhook\n'
    printf 'ADMIN_API_TOKEN=fixture-secret-admin\n'
    printf 'ADMIN_API_ALLOWED_ORIGINS=https://admin.example.test\n'
    printf 'ANALYTICS_ADMIN_TOKEN=fixture-secret-analytics\n'
    printf 'NOTIFICATION_ADMIN_TOKEN=fixture-secret-notification\n'

    if [[ "$include_billing" -eq 1 ]]; then
      printf 'GOOGLE_SERVICE_ACCOUNT_EMAIL=service-account@example.test\n'
      printf 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY=fixture-secret-google-private-key\n'
      printf 'GOOGLE_PLAY_PACKAGE_NAME=com.example.jive\n'
      printf 'APPLE_APP_STORE_BUNDLE_ID=com.example.jive\n'
      printf 'APPLE_APP_STORE_SHARED_SECRET=fixture-secret-apple-shared-secret\n'
      printf 'APPLE_APP_STORE_APPLE_ID=1234567890\n'
      printf 'APPLE_APP_STORE_ENVIRONMENT=sandbox\n'
      printf 'DOMESTIC_PAYMENT_WEBHOOK_TOKEN=fixture-secret-domestic-webhook\n'
    fi
  } > "$path"
}

run_readiness() {
  local label="$1"
  shift

  local stdout="$ROOT/$label.stdout"
  local stderr="$ROOT/$label.stderr"
  local status_file="$ROOT/$label.status"

  set +e
  PATH="$BIN_DIR:$PATH" \
  FLUTTER_BIN="$BIN_DIR/flutter" \
  SUPABASE_ACCESS_TOKEN="fixture-secret-access-token" \
  STAGING_PROJECT_REF="fixture-project-ref" \
  STAGING_DB_PASSWORD="fixture-secret-db-password" \
    bash "$TARGET" "$@" > "$stdout" 2> "$stderr"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$status_file"
  printf '%s\n' "$stdout"
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
    fail "$label expected exit $expected, got $actual"
  fi
}

assert_no_secret_values() {
  local label="$1"
  assert_not_contains "$ROOT/$label.stdout" "fixture-secret"
  assert_not_contains "$ROOT/$label.stderr" "fixture-secret"
}

write_fake_bins

CORE_ENV="$ROOT/core.env"
FULL_ENV="$ROOT/full.env"
MISSING_ENV="$ROOT/missing.env"
write_env_file "$CORE_ENV" 0
write_env_file "$FULL_ENV" 1

run_readiness core-strict --profile core --strict --env-file "$CORE_ENV" --skip-github >/dev/null
assert_status core-strict 0
assert_contains "$ROOT/core-strict.stdout" "PASS: env-file:ADMIN_API_TOKEN present"
assert_contains "$ROOT/core-strict.stdout" "core profile skips Google/Apple provider credential requirements"
assert_contains "$ROOT/core-strict.stdout" "summary: failures=0 warnings=0 profile=core strict=1 online=0 run_smoke=0"
assert_no_secret_values core-strict
log "pass fixture ok: core strict readiness"

run_readiness full-strict --profile full --strict --env-file "$FULL_ENV" --skip-github >/dev/null
assert_status full-strict 0
assert_contains "$ROOT/full-strict.stdout" "PASS: env-file:GOOGLE_SERVICE_ACCOUNT_EMAIL present"
assert_contains "$ROOT/full-strict.stdout" "PASS: env-file:DOMESTIC_PAYMENT_WEBHOOK_TOKEN present"
assert_contains "$ROOT/full-strict.stdout" "summary: failures=0 warnings=0 profile=full strict=1 online=0 run_smoke=0"
assert_no_secret_values full-strict
log "pass fixture ok: full strict readiness"

run_readiness full-missing-billing --profile full --strict --env-file "$CORE_ENV" --skip-github >/dev/null
assert_status full-missing-billing 1
assert_contains "$ROOT/full-missing-billing.stderr" "FAIL: env-file:GOOGLE_SERVICE_ACCOUNT_EMAIL missing or empty"
assert_contains "$ROOT/full-missing-billing.stdout" "summary: failures="
assert_no_secret_values full-missing-billing
log "negative fixture ok: full strict detects missing billing keys"

run_readiness missing-env-file-nonstrict --profile core --env-file "$MISSING_ENV" --skip-github >/dev/null
assert_status missing-env-file-nonstrict 0
assert_contains "$ROOT/missing-env-file-nonstrict.stderr" "WARN: env file missing: $MISSING_ENV"
assert_contains "$ROOT/missing-env-file-nonstrict.stdout" "summary: failures=0 warnings=1 profile=core strict=0 online=0 run_smoke=0"
assert_no_secret_values missing-env-file-nonstrict
log "pass fixture ok: non-strict missing env file warns"

run_readiness online-fake-tools --profile core --strict --env-file "$CORE_ENV" --online >/dev/null
assert_status online-fake-tools 0
assert_contains "$ROOT/online-fake-tools.stdout" "PASS: main CI is green at abcdef1234567890: https://example.test/actions/runs/1"
assert_contains "$ROOT/online-fake-tools.stdout" "PASS: Supabase CLI reachable via npx: 2.20.0"
assert_contains "$ROOT/online-fake-tools.stdout" "summary: failures=0 warnings=0 profile=core strict=1 online=1 run_smoke=0"
assert_no_secret_values online-fake-tools
log "pass fixture ok: online checks use fake tools"

run_readiness invalid-profile --profile nope --env-file "$CORE_ENV" --skip-github >/dev/null
assert_status invalid-profile 2
assert_contains "$ROOT/invalid-profile.stderr" "FAIL: unknown profile: nope"
log "negative fixture ok: invalid profile exits 2"

log "all deployment readiness self-tests passed"
