#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$SCRIPT_DIR/run_saas_core_staging_lane.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_core_staging_lane.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_saas_core_staging_lane.sh.
The test uses fake gh, npx, and Flutter binaries plus temporary env files.
It skips local smoke, migrations, deploy, function smoke, sync smoke, APK build,
and online readiness probes. It does not call GitHub, Supabase, Flutter, a
device, or any real secret store.
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
      printf '[saas-core-lane-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-core-lane-test.XXXXXX)"
BIN_DIR="$ROOT/bin"
mkdir -p "$BIN_DIR"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-core-lane-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-core-lane-test] %s\n' "$*"
}

fail() {
  printf '[saas-core-lane-test] FAIL: %s\n' "$*" >&2
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
printf '[fake-gh] core lane self-test should not call gh with args: %s\n' "$*" >&2
exit 2
EOF

  cat > "$BIN_DIR/npx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '[fake-npx] core lane self-test should not call npx with args: %s\n' "$*" >&2
exit 2
EOF

  cat > "$BIN_DIR/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'Flutter fixture\n'
EOF

  chmod +x "$BIN_DIR/gh" "$BIN_DIR/npx" "$BIN_DIR/flutter"
}

write_core_env_file() {
  local path="$1"

  {
    printf 'SUPABASE_URL=https://fixture.supabase.co\n'
    printf 'SUPABASE_ANON_KEY=fixture-secret-anon-key\n'
    printf 'SUPABASE_SERVICE_ROLE_KEY=fixture-secret-service-role\n'
    printf 'PUBSUB_BEARER_TOKEN=fixture-secret-pubsub\n'
    printf 'WEBHOOK_HMAC_SECRET=fixture-secret-webhook\n'
    printf 'ADMIN_API_TOKEN=fixture-secret-admin\n'
    printf 'ADMIN_API_ALLOWED_ORIGINS=https://admin.example.test\n'
    printf 'ANALYTICS_ADMIN_TOKEN=fixture-secret-analytics\n'
    printf 'NOTIFICATION_ADMIN_TOKEN=fixture-secret-notification\n'
  } > "$path"
}

run_lane() {
  local label="$1"
  shift

  local stdout="$ROOT/$label.stdout"
  local stderr="$ROOT/$label.stderr"
  local status_file="$ROOT/$label.status"

  set +e
  PATH="$BIN_DIR:$PATH" \
  FLUTTER_BIN="$BIN_DIR/flutter" \
  SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}" \
  STAGING_PROJECT_REF="${STAGING_PROJECT_REF:-}" \
  STAGING_DB_PASSWORD="${STAGING_DB_PASSWORD:-}" \
    bash "$TARGET" "$@" > "$stdout" 2> "$stderr"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$status_file"
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

safe_skip_args=(
  --skip-local-smoke
  --skip-dry-run
  --skip-apply
  --skip-deploy
  --skip-function-smoke
  --skip-apk
  --skip-online-readiness
)

write_fake_bins

CORE_ENV="$ROOT/core.env"
write_core_env_file "$CORE_ENV"

SUPABASE_ACCESS_TOKEN="fixture-secret-access-token" \
STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
  run_lane all-skipped \
    --env-file "$CORE_ENV" \
    --project-ref "fixture-project-ref-from-arg" \
    --db-password "fixture-secret-db-password-from-arg" \
    --access-token "fixture-secret-access-token-from-arg" \
    --db-url "postgres://fixture.example.test:5432/postgres" \
    --functions-url "https://functions.example.test/functions/v1" \
    --pg-fallback \
    --pg-lock-timeout "5s" \
    --pg-statement-timeout "70s" \
    "${safe_skip_args[@]}"
assert_status all-skipped 0
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] initializing core env file"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] running strict readiness"
assert_contains "$ROOT/all-skipped.stdout" "[saas-readiness] summary: failures=0 warnings=0 profile=core strict=1 online=0 run_smoke=0"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping local Wave0 SaaS smoke"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping migration dry-run"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping migration apply"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping staging core sync smoke"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping Edge Functions deploy"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping deployed Functions smoke"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] skipping staging APK build"
assert_contains "$ROOT/all-skipped.stdout" "[saas-core-lane] core staging lane completed"
assert_no_secret_values all-skipped
log "pass fixture ok: all destructive/online operations skipped"

SUPABASE_ACCESS_TOKEN="" \
STAGING_PROJECT_REF="fixture-project-ref" \
STAGING_DB_PASSWORD="fixture-secret-db-password" \
  run_lane missing-access-token --env-file "$CORE_ENV" \
    --skip-local-smoke \
    --skip-apply \
    --skip-deploy \
    --skip-function-smoke \
    --skip-apk \
    --skip-online-readiness
assert_status missing-access-token 1
assert_contains "$ROOT/missing-access-token.stderr" "[saas-readiness] FAIL: env:SUPABASE_ACCESS_TOKEN missing"
assert_contains "$ROOT/missing-access-token.stdout" "[saas-readiness] summary: failures=1 warnings=0 profile=core strict=1 online=0 run_smoke=0"
assert_no_secret_values missing-access-token
log "negative fixture ok: deploy-required path blocks missing access token before rollout"

run_lane invalid-argument --definitely-not-a-real-flag
assert_status invalid-argument 1
assert_contains "$ROOT/invalid-argument.stderr" "[saas-core-lane] ERROR: unknown argument: --definitely-not-a-real-flag"
log "negative fixture ok: invalid argument exits non-zero before initialization"

log "all core staging lane self-tests passed"
