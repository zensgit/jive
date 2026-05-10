#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW="$APP_DIR/.github/workflows/saas_full_billing_staging_smoke.yml"
FUNCTION_SMOKE="$APP_DIR/scripts/run_saas_staging_function_smoke.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/test_saas_full_billing_staging_smoke_workflow.sh

Runs host-only contract checks for the SaaS full billing staging smoke workflow.
No GitHub, Supabase, payment provider, Flutter SDK, device, or secret access is
required. The checks keep the workflow's destructive/write-capable behavior
explicitly opt-in and verify that report upload remains guarded.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if (($# > 0)); then
  printf '[saas-full-billing-workflow-test] unknown argument: %s\n' "$1" >&2
  usage >&2
  exit 2
fi

fail() {
  printf '[saas-full-billing-workflow-test] FAIL: %s\n' "$*" >&2
  exit 1
}

ok() {
  printf '[saas-full-billing-workflow-test] ok: %s\n' "$*"
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
assert_file "$FUNCTION_SMOKE"

assert_contains "$WORKFLOW" "name: SaaS Full Billing Staging Smoke"
assert_contains "$WORKFLOW" "sync_domestic_payment_secret:"
assert_contains "$WORKFLOW" "deploy_payment_smoke_functions:"
assert_contains "$WORKFLOW" "run_domestic_payment_e2e:"
assert_contains "$WORKFLOW" "default: false"
ok "workflow exposes opt-in domestic payment E2E input"

for key in \
  STAGING_SUPABASE_URL \
  STAGING_SUPABASE_ANON_KEY \
  STAGING_PUBSUB_BEARER_TOKEN \
  STAGING_ADMIN_API_TOKEN \
  STAGING_ANALYTICS_ADMIN_TOKEN \
  STAGING_NOTIFICATION_ADMIN_TOKEN \
  STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN; do
  assert_contains "$WORKFLOW" "$key"
done
ok "core full-billing smoke secrets are guarded"

assert_count "$WORKFLOW" "required_secrets+=(STAGING_SUPABASE_ACCESS_TOKEN STAGING_PROJECT_REF)" 2
assert_contains "$WORKFLOW" 'if [[ "${{ inputs.run_domestic_payment_e2e }}" == "true" ]]; then'
assert_contains "$WORKFLOW" "required_secrets+=(STAGING_SUPABASE_SERVICE_ROLE_KEY)"
assert_contains "$WORKFLOW" "printf 'SUPABASE_SERVICE_ROLE_KEY=%s\\n' \"\$SUPABASE_SERVICE_ROLE_KEY\""
ok "deploy/runtime/E2E-only secrets stay conditional"

assert_contains "$WORKFLOW" "DOMESTIC_PAYMENT_WEBHOOK_TOKEN=\$DOMESTIC_PAYMENT_WEBHOOK_TOKEN"
assert_contains "$WORKFLOW" "npx -y supabase@latest secrets set"
assert_contains "$WORKFLOW" "functions deploy create-payment-order"
assert_contains "$WORKFLOW" "functions deploy domestic-payment-webhook"
assert_contains "$WORKFLOW" "--no-verify-jwt"
ok "domestic payment runtime secret and deploy commands are present"

assert_contains "$WORKFLOW" "args=(--profile full --env-file \"\$STAGING_ENV_FILE\")"
assert_contains "$WORKFLOW" "args+=(--run-domestic-payment-e2e)"
assert_contains "$WORKFLOW" "bash scripts/run_saas_staging_function_smoke.sh \"\${args[@]}\""
ok "workflow invokes full function smoke with E2E still opt-in"

assert_contains "$WORKFLOW" "scripts/guard_saas_report_artifacts.sh"
assert_contains "$WORKFLOW" "--label \"SaaS full billing\""
assert_contains "$WORKFLOW" "if: always() && steps.guard_full_billing_smoke_artifacts.outcome == 'success'"
for key in \
  STAGING_SUPABASE_ANON_KEY \
  STAGING_SUPABASE_ACCESS_TOKEN \
  STAGING_SUPABASE_SERVICE_ROLE_KEY \
  STAGING_PUBSUB_BEARER_TOKEN \
  STAGING_ADMIN_API_TOKEN \
  STAGING_ANALYTICS_ADMIN_TOKEN \
  STAGING_NOTIFICATION_ADMIN_TOKEN \
  STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN; do
  assert_contains "$WORKFLOW" "--secret-env $key"
done
ok "report upload remains guarded by secret artifact scan"

assert_contains "$FUNCTION_SMOKE" "--run-domestic-payment-e2e requires --profile full"
assert_contains "$FUNCTION_SMOKE" "service_role_key=\"\$(require_key \"SUPABASE_SERVICE_ROLE_KEY\")\""
assert_contains "$FUNCTION_SMOKE" "domestic-payment-webhook rejects missing token"
assert_contains "$FUNCTION_SMOKE" "domestic-payment-webhook accepts token and checks order existence"
assert_contains "$FUNCTION_SMOKE" "function smoke passed"
ok "function smoke script keeps billing auth and optional write-path checks"

printf '[saas-full-billing-workflow-test] all checks passed\n'
