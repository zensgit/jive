#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/run_saas_internal_test_release.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_internal_test_release_finalizer.sh [--keep-fixtures]

Runs host-only fixture tests for scripts/run_saas_internal_test_release.sh.
No real GitHub secret store, GitHub Actions workflow, Flutter build, Android
signing, or network access is used.
EOF
}

KEEP_FIXTURES=0
while (($#)); do
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
      printf '[saas-internal-release-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT="$(mktemp -d /tmp/jive-saas-internal-release-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-internal-release-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-internal-release-test] %s\n' "$*"
}

fail() {
  printf '[saas-internal-release-test] FAIL: %s\n' "$*" >&2
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

assert_status() {
  local label="$1"
  local expected="$2"
  local actual
  actual="$(cat "$ROOT/$label/status.txt")"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s\n' '--- stdout ---' >&2
    cat "$ROOT/$label/stdout.txt" >&2 || true
    printf '%s\n' '--- stderr ---' >&2
    cat "$ROOT/$label/stderr.txt" >&2 || true
    printf '%s\n' '--- calls ---' >&2
    cat "$ROOT/$label/calls.log" >&2 || true
    fail "$label expected exit $expected, got $actual"
  fi
}

create_fake_script() {
  local path="$1"
  local name="$2"
  local exit_code="${3:-0}"

  cat > "$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\\n' "$name" "\$*" >> "\${JIVE_FAKE_FINALIZER_CALLS:?JIVE_FAKE_FINALIZER_CALLS is required}"
exit $exit_code
EOF
  chmod +x "$path"
}

create_env_file() {
  local file="$1"

  cat > "$file" <<'EOF'
SUPABASE_URL=https://prod-demo.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.signature
ADMOB_APP_ID=ca-app-pub-1234567890123456~1234567890
ADMOB_BANNER_ID=ca-app-pub-1234567890123456/1234567890
PAYMENT_CHANNEL=google_play
ENABLE_STORE_BILLING=true
ENABLE_WECHAT_PAY=false
ENABLE_ALIPAY=false
DOMESTIC_PAYMENT_MOCK_BASE_URL=
EOF
}

run_case() {
  local label="$1"
  local readiness_exit="$2"
  shift 2

  local fixture="$ROOT/$label"
  local env_file="$fixture/production.env"
  mkdir -p "$fixture"
  create_env_file "$env_file"
  : > "$fixture/calls.log"

  create_fake_script "$fixture/readiness" readiness "$readiness_exit"
  create_fake_script "$fixture/push" push 0
  create_fake_script "$fixture/check" check 0
  create_fake_script "$fixture/sequence" sequence 0
  create_fake_script "$fixture/report" report 0

  set +e
  env \
    JIVE_FAKE_FINALIZER_CALLS="$fixture/calls.log" \
    JIVE_SAAS_PROD_READINESS_SCRIPT="$fixture/readiness" \
    JIVE_SAAS_SECRET_PUSH_SCRIPT="$fixture/push" \
    JIVE_SAAS_SECRET_CHECK_SCRIPT="$fixture/check" \
    JIVE_SAAS_RELEASE_SEQUENCE_SCRIPT="$fixture/sequence" \
    JIVE_SAAS_INTERNAL_TEST_REPORT_SCRIPT="$fixture/report" \
    "$TARGET" \
      --repo zensgit/jive \
      --env-file "$env_file" \
      --artifact-dir "$fixture/artifacts" \
      "$@" \
      > "$fixture/stdout.txt" \
      2> "$fixture/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture/status.txt"
}

run_missing_env_case() {
  local label="missing-env"
  local fixture="$ROOT/$label"
  mkdir -p "$fixture"
  : > "$fixture/calls.log"
  create_fake_script "$fixture/readiness" readiness 0

  set +e
  env \
    JIVE_FAKE_FINALIZER_CALLS="$fixture/calls.log" \
    JIVE_SAAS_PROD_READINESS_SCRIPT="$fixture/readiness" \
    "$TARGET" \
      --repo zensgit/jive \
      --env-file "$fixture/missing.env" \
      > "$fixture/stdout.txt" \
      2> "$fixture/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture/status.txt"
}

run_existing_secrets_case() {
  local label="$1"
  local check_exit="$2"
  shift 2

  local fixture="$ROOT/$label"
  mkdir -p "$fixture"
  : > "$fixture/calls.log"

  create_fake_script "$fixture/check" check "$check_exit"
  create_fake_script "$fixture/sequence" sequence 0
  create_fake_script "$fixture/report" report 0

  set +e
  env \
    JIVE_FAKE_FINALIZER_CALLS="$fixture/calls.log" \
    JIVE_SAAS_SECRET_CHECK_SCRIPT="$fixture/check" \
    JIVE_SAAS_RELEASE_SEQUENCE_SCRIPT="$fixture/sequence" \
    JIVE_SAAS_INTERNAL_TEST_REPORT_SCRIPT="$fixture/report" \
    "$TARGET" \
      --repo zensgit/jive \
      --env-file "$fixture/missing.env" \
      --artifact-dir "$fixture/artifacts" \
      --use-existing-secrets \
      "$@" \
      > "$fixture/stdout.txt" \
      2> "$fixture/stderr.txt"
  local status=$?
  set -e

  printf '%s\n' "$status" > "$fixture/status.txt"
}

run_case dry-run 0
assert_status dry-run 0
assert_contains "$ROOT/dry-run/calls.log" "readiness --env-file $ROOT/dry-run/production.env --profile app --store android"
assert_contains "$ROOT/dry-run/calls.log" "push --profile production-release --env-file $ROOT/dry-run/production.env --repo zensgit/jive"
assert_not_contains "$ROOT/dry-run/calls.log" " --apply"
assert_not_contains "$ROOT/dry-run/calls.log" "check "
assert_not_contains "$ROOT/dry-run/calls.log" "sequence "
assert_not_contains "$ROOT/dry-run/calls.log" "report "
log "dry-run fixture ok: validates env and secret values without remote mutation"

run_case apply 0 --apply --build-name 1.2.3 --build-number 45
assert_status apply 0
assert_contains "$ROOT/apply/calls.log" "push --profile production-release --env-file $ROOT/apply/production.env --apply --repo zensgit/jive"
assert_contains "$ROOT/apply/calls.log" "check --profile production-release --include-signing --repo zensgit/jive"
assert_contains "$ROOT/apply/calls.log" "sequence --artifact-dir $ROOT/apply/artifacts --repo zensgit/jive --build-name 1.2.3 --build-number 45"
assert_contains "$ROOT/apply/calls.log" "report --artifact-dir $ROOT/apply/artifacts --output "
assert_contains "$ROOT/apply/calls.log" "--play-track internal"
log "apply fixture ok: uploads, verifies, runs sequence, and renders completion report"

run_existing_secrets_case existing-secrets-dry-run 0
assert_status existing-secrets-dry-run 0
assert_contains "$ROOT/existing-secrets-dry-run/calls.log" "check --profile production-release --include-signing --repo zensgit/jive"
assert_not_contains "$ROOT/existing-secrets-dry-run/calls.log" "readiness "
assert_not_contains "$ROOT/existing-secrets-dry-run/calls.log" "push "
assert_not_contains "$ROOT/existing-secrets-dry-run/calls.log" "sequence "
assert_not_contains "$ROOT/existing-secrets-dry-run/calls.log" "report "
log "existing-secrets dry-run fixture ok: checks GitHub secrets without env upload"

run_existing_secrets_case existing-secrets-apply 0 --apply --build-name 1.2.3 --build-number 45
assert_status existing-secrets-apply 0
assert_contains "$ROOT/existing-secrets-apply/calls.log" "check --profile production-release --include-signing --repo zensgit/jive"
assert_contains "$ROOT/existing-secrets-apply/calls.log" "sequence --artifact-dir $ROOT/existing-secrets-apply/artifacts --repo zensgit/jive --build-name 1.2.3 --build-number 45"
assert_contains "$ROOT/existing-secrets-apply/calls.log" "report --artifact-dir $ROOT/existing-secrets-apply/artifacts --output "
assert_not_contains "$ROOT/existing-secrets-apply/calls.log" "readiness "
assert_not_contains "$ROOT/existing-secrets-apply/calls.log" "push "
log "existing-secrets apply fixture ok: runs sequence from preconfigured GitHub secrets"

run_existing_secrets_case existing-secrets-missing 9 --apply
assert_status existing-secrets-missing 9
assert_contains "$ROOT/existing-secrets-missing/calls.log" "check --profile production-release --include-signing --repo zensgit/jive"
assert_not_contains "$ROOT/existing-secrets-missing/calls.log" "sequence "
assert_not_contains "$ROOT/existing-secrets-missing/calls.log" "report "
log "existing-secrets missing fixture ok: blocks before workflow dispatch"

run_case report-options 0 --apply --completion-report "$ROOT/report-options/completion.md" --play-track closed-test --play-version 1.2.3+45
assert_status report-options 0
assert_contains "$ROOT/report-options/calls.log" "report --artifact-dir $ROOT/report-options/artifacts --output $ROOT/report-options/completion.md --play-track closed-test --play-version 1.2.3+45"
log "report-options fixture ok: passes report output and Play labels"

run_case skip-report 0 --apply --skip-completion-report
assert_status skip-report 0
assert_contains "$ROOT/skip-report/calls.log" "sequence --artifact-dir $ROOT/skip-report/artifacts --repo zensgit/jive"
assert_not_contains "$ROOT/skip-report/calls.log" "report "
log "skip-report fixture ok: keeps report generation optional"

run_case skip-sequence 0 --apply --skip-sequence
assert_status skip-sequence 0
assert_contains "$ROOT/skip-sequence/calls.log" "check --profile production-release --include-signing --repo zensgit/jive"
assert_not_contains "$ROOT/skip-sequence/calls.log" "sequence "
assert_not_contains "$ROOT/skip-sequence/calls.log" "report "
log "skip-sequence fixture ok: supports upload-only cut point"

run_case readiness-failure 7 --apply
assert_status readiness-failure 7
assert_contains "$ROOT/readiness-failure/calls.log" "readiness --env-file $ROOT/readiness-failure/production.env --profile app --store android"
assert_not_contains "$ROOT/readiness-failure/calls.log" "push "
assert_not_contains "$ROOT/readiness-failure/calls.log" "sequence "
assert_not_contains "$ROOT/readiness-failure/calls.log" "report "
log "readiness-failure fixture ok: blocks before upload"

run_missing_env_case
assert_status missing-env 1
assert_contains "$ROOT/missing-env/stderr.txt" "production env file not found"
assert_not_contains "$ROOT/missing-env/calls.log" "readiness "
log "missing-env fixture ok: fails before child scripts"

printf '[saas-internal-release-test] all checks passed\n'
