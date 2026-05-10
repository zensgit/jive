#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW="$APP_DIR/.github/workflows/saas_release_candidate.yml"
BUILD_SCRIPT="$APP_DIR/scripts/build_release_candidate.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_release_candidate_workflow.sh

Runs host-only contract checks for the SaaS release candidate workflow. The test
does not call GitHub, Flutter, Android tooling, Supabase, signing services, or
any real secret store.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if (($# > 0)); then
  printf '[saas-release-candidate-workflow-test] unknown argument: %s\n' "$1" >&2
  usage >&2
  exit 2
fi

fail() {
  printf '[saas-release-candidate-workflow-test] FAIL: %s\n' "$*" >&2
  exit 1
}

ok() {
  printf '[saas-release-candidate-workflow-test] ok: %s\n' "$*"
}

assert_file() {
  local file="$1"
  [[ -f "$file" ]] || fail "missing file: $file"
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

assert_count() {
  local file="$1"
  local pattern="$2"
  local expected="$3"
  local actual

  actual="$(grep -F -- "$pattern" "$file" | wc -l | tr -d '[:space:]')"
  [[ "$actual" == "$expected" ]] ||
    fail "expected '$pattern' count $expected in $file, got $actual"
}

assert_file "$WORKFLOW"
assert_file "$BUILD_SCRIPT"

assert_contains "$WORKFLOW" "name: SaaS Release Candidate"
assert_contains "$WORKFLOW" "build_appbundle:"
assert_contains "$WORKFLOW" "strict_signing:"
assert_contains "$WORKFLOW" "default: false"
assert_contains "$WORKFLOW" "flavor:"
assert_contains "$WORKFLOW" "options:"
assert_contains "$WORKFLOW" "- prod"
ok "workflow exposes explicit build/signing/flavor inputs"

for key in \
  PRODUCTION_SUPABASE_URL \
  PRODUCTION_SUPABASE_ANON_KEY \
  PRODUCTION_ADMOB_APP_ID \
  PRODUCTION_ADMOB_BANNER_ID; do
  assert_contains "$WORKFLOW" "$key"
done
ok "production client runtime values are required for every run"

assert_contains "$WORKFLOW" 'if [[ "${{ inputs.strict_signing }}" == "true" ]]; then'
for key in \
  ANDROID_RELEASE_KEYSTORE_BASE64 \
  ANDROID_RELEASE_STORE_PASSWORD \
  ANDROID_RELEASE_KEY_ALIAS \
  ANDROID_RELEASE_KEY_PASSWORD; do
  assert_contains "$WORKFLOW" "$key"
done
ok "release signing secrets stay tied to strict_signing"

assert_contains "$WORKFLOW" 'if: ${{ inputs.build_appbundle }}'
assert_count "$WORKFLOW" 'if: ${{ inputs.build_appbundle }}' 2
assert_contains "$WORKFLOW" "flutter-version: 3.35.5"
assert_contains "$WORKFLOW" 'JIVE_RELEASE_CANDIDATE_DRY_RUN: ${{ inputs.build_appbundle != true }}'
assert_contains "$WORKFLOW" "bash scripts/build_release_candidate.sh"
ok "Flutter setup and real appbundle build remain opt-in"

assert_contains "$WORKFLOW" "printf 'ENABLE_STORE_BILLING=true\\n'"
assert_contains "$WORKFLOW" "printf 'ENABLE_WECHAT_PAY=false\\n'"
assert_contains "$WORKFLOW" "printf 'ENABLE_ALIPAY=false\\n'"
assert_contains "$WORKFLOW" "printf 'DOMESTIC_PAYMENT_MOCK_BASE_URL=\\n'"
assert_contains "$WORKFLOW" "echo \"PRODUCTION_ENV_FILE=\$env_file\" >> \"\$GITHUB_ENV\""
ok "production env file keeps production-safe payment defaults"

assert_contains "$WORKFLOW" "base64 --decode > \"\$keystore_file\""
assert_contains "$WORKFLOW" "printf 'JIVE_ANDROID_STORE_FILE=%s\\n' \"\$keystore_file\""
assert_contains "$WORKFLOW" "printf 'JIVE_ANDROID_STORE_PASSWORD=%s\\n' \"\$ANDROID_RELEASE_STORE_PASSWORD\""
assert_contains "$WORKFLOW" "printf 'JIVE_ANDROID_KEY_ALIAS=%s\\n' \"\$ANDROID_RELEASE_KEY_ALIAS\""
assert_contains "$WORKFLOW" "printf 'JIVE_ANDROID_KEY_PASSWORD=%s\\n' \"\$ANDROID_RELEASE_KEY_PASSWORD\""
ok "strict signing restores keystore only through runner temp env"

assert_contains "$WORKFLOW" "scripts/guard_saas_report_artifacts.sh"
assert_contains "$WORKFLOW" "--label \"Release candidate\""
assert_contains "$WORKFLOW" "--root build/reports/release-candidate"
assert_contains "$WORKFLOW" "--root build/release-candidate"
assert_contains "$WORKFLOW" "if: always() && steps.guard_release_candidate_artifacts.outcome == 'success'"
for key in \
  PRODUCTION_SUPABASE_ANON_KEY \
  ANDROID_RELEASE_KEYSTORE_BASE64 \
  ANDROID_RELEASE_STORE_PASSWORD \
  ANDROID_RELEASE_KEY_PASSWORD; do
  assert_contains "$WORKFLOW" "--secret-env $key"
done
ok "release candidate artifact upload remains guarded"

assert_contains "$WORKFLOW" "summary_file=\"build/reports/release-candidate/latest.md\""
assert_contains "$WORKFLOW" "cat \"\$summary_file\" >> \"\$GITHUB_STEP_SUMMARY\""
assert_contains "$WORKFLOW" "name: saas-release-candidate-\${{ github.run_id }}"
assert_contains "$WORKFLOW" "build/reports/release-candidate"
assert_contains "$WORKFLOW" "build/release-candidate"
ok "workflow publishes summary and uploads the expected report roots"

assert_contains "$BUILD_SCRIPT" "scripts/check_saas_production_readiness.sh"
assert_contains "$BUILD_SCRIPT" "--require-release-signing"
assert_contains "$BUILD_SCRIPT" "build_dart_define_file"
assert_contains "$BUILD_SCRIPT" "write_report"
assert_contains "$BUILD_SCRIPT" "dry run requested; skipping Flutter build"
assert_contains "$BUILD_SCRIPT" "flutter \"\${build_args[@]}\""
assert_not_contains "$BUILD_SCRIPT" "SUPABASE_SERVICE_ROLE_KEY"
ok "build script keeps production readiness gate, dry-run, and client-safe defines"

printf '[saas-release-candidate-workflow-test] all checks passed\n'
