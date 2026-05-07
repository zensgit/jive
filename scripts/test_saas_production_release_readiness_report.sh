#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTER="$SCRIPT_DIR/report_saas_production_release_readiness.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_production_release_readiness_report.sh [--keep-fixtures]

Creates fake GitHub secret-check fixtures and validates the SaaS production
release readiness report renderer. This is host-only and does not call GitHub,
read real secrets, build artifacts, or deploy anything.
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
      printf '[saas-prod-release-report-test] unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$APP_DIR"

ROOT="$(mktemp -d /tmp/jive-saas-prod-release-report-test.XXXXXX)"

cleanup() {
  if [[ "$KEEP_FIXTURES" -eq 1 ]]; then
    printf '[saas-prod-release-report-test] kept fixtures: %s\n' "$ROOT"
  else
    rm -rf "$ROOT"
  fi
}

trap cleanup EXIT INT TERM

log() {
  printf '[saas-prod-release-report-test] %s\n' "$*"
}

fail() {
  printf '[saas-prod-release-report-test] FAIL: %s\n' "$*" >&2
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

write_secret_check_fixture() {
  local path="$1"
  local mode="$2"

  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

mode="${JIVE_FAKE_SECRET_CHECK_MODE:-dry-run-ready}"
include_signing=0
for arg in "$@"; do
  if [[ "$arg" == "--include-signing" ]]; then
    include_signing=1
  fi
done

printf '[fake-secret-check] profile=production-release includeSigning=%s\n' "$include_signing"

case "$mode" in
  blocked)
    printf '[fake-secret-check] MISS: missing required secret: PRODUCTION_SUPABASE_URL\n' >&2
    exit 1
    ;;
  dry-run-ready)
    if [[ "$include_signing" -eq 1 ]]; then
      printf '[fake-secret-check] MISS: missing required secret: ANDROID_RELEASE_KEYSTORE_BASE64\n' >&2
      exit 1
    fi
    printf '[fake-secret-check] all minimum release secrets present\n'
    ;;
  signed-build-ready)
    printf '[fake-secret-check] all release secrets present\n'
    ;;
  *)
    printf '[fake-secret-check] unknown mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
EOF

  chmod +x "$path"
  printf '%s\n' "$mode" > "$path.mode"
}

run_report() {
  local label="$1"
  local mode="$2"
  local workflow_state="$3"
  local strict_flag="${4:-}"
  local output="$ROOT/$label.md"
  local secret_check="$ROOT/$label-secret-check.sh"

  write_secret_check_fixture "$secret_check" "$mode"

  local args=(--repo zensgit/jive --output "$output")
  if [[ "$strict_flag" == "strict" ]]; then
    args+=(--strict)
  fi

  JIVE_FAKE_SECRET_CHECK_MODE="$mode" \
  JIVE_SAAS_GITHUB_SECRETS_CHECK_SCRIPT="$secret_check" \
  JIVE_PROD_RELEASE_MAIN_SHA="0123456789abcdef0123456789abcdef01234567" \
  JIVE_PROD_RELEASE_WORKFLOW_STATE="$workflow_state" \
  JIVE_PROD_RELEASE_LATEST_CI="run=123 status=completed conclusion=success head=0123456789abcdef0123456789abcdef01234567 url=https://example.test/run/123" \
    "$REPORTER" "${args[@]}" > "$ROOT/$label.stdout" 2> "$ROOT/$label.stderr"

  printf '%s\n' "$output"
}

assert_report_pass() {
  local label="$1"
  local mode="$2"
  local workflow_state="$3"
  local expected_status="$4"
  local output

  output="$(run_report "$label" "$mode" "$workflow_state")"
  assert_contains "$output" "# SaaS Production Release Readiness"
  assert_contains "$output" "Repository: \`zensgit/jive\`"
  assert_contains "$output" "- Status: \`$expected_status\`"
  assert_contains "$output" "- \`main\`: \`0123456789abcdef0123456789abcdef01234567\`"
  assert_contains "$output" "- \`SaaS Release Candidate\` workflow: \`$workflow_state\`"
  assert_contains "$output" "Latest main Flutter CI: \`run=123 status=completed conclusion=success"
  assert_contains "$output" "Minimum dry-run secret check exit:"
  assert_contains "$output" "Strict signing secret check exit:"
  assert_contains "$output" "scripts/check_saas_github_secrets.sh --profile production-release --repo zensgit/jive"
  assert_not_contains "$output" "super-secret"

  log "pass fixture ok: $label => $expected_status"
}

assert_strict_block_fails() {
  local label="strict-blocked"
  local output="$ROOT/$label.md"
  local secret_check="$ROOT/$label-secret-check.sh"
  write_secret_check_fixture "$secret_check" blocked

  if JIVE_FAKE_SECRET_CHECK_MODE=blocked \
    JIVE_SAAS_GITHUB_SECRETS_CHECK_SCRIPT="$secret_check" \
    JIVE_PROD_RELEASE_MAIN_SHA="0123456789abcdef0123456789abcdef01234567" \
    JIVE_PROD_RELEASE_WORKFLOW_STATE="active" \
    JIVE_PROD_RELEASE_LATEST_CI="run=123 status=completed conclusion=success head=0123456789abcdef0123456789abcdef01234567 url=https://example.test/run/123" \
      "$REPORTER" --repo zensgit/jive --output "$output" --strict \
      > "$ROOT/$label.stdout" 2> "$ROOT/$label.stderr"; then
    fail "strict blocked report expected non-zero exit"
  fi

  assert_contains "$output" "- Status: \`blocked\`"
  assert_contains "$ROOT/$label.stderr" "production release readiness is blocked"
  log "negative fixture ok: strict blocked exits non-zero"
}

assert_report_pass blocked-workflow dry-run-ready disabled blocked
assert_report_pass missing-secrets blocked active blocked
assert_report_pass dry-run-ready dry-run-ready active dry-run-ready
assert_report_pass signed-build-ready signed-build-ready active signed-build-ready
assert_strict_block_fails

log "all production release readiness report self-tests passed"
