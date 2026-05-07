#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/test_saas_wave0_smoke_trigger.sh

Runs host-only contract tests for scripts/should_run_saas_wave0_smoke.sh.
No Flutter SDK, device, secrets, or network access is required.
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/should_run_saas_wave0_smoke.sh"

fail() {
  printf '[saas-wave0-trigger-test] %s\n' "$*" >&2
  exit 1
}

assert_stdin() {
  local expected="$1"
  local label="$2"
  local input="$3"
  local actual

  actual="$(printf '%s' "$input" | "$TARGET")"
  if [[ "$actual" != "$expected" ]]; then
    fail "$label: expected $expected, got $actual"
  fi

  printf '[saas-wave0-trigger-test] ok stdin %-46s => %s\n' "$label" "$actual"
}

assert_args() {
  local expected="$1"
  local label="$2"
  shift 2
  local actual

  actual="$("$TARGET" "$@")"
  if [[ "$actual" != "$expected" ]]; then
    fail "$label: expected $expected, got $actual"
  fi

  printf '[saas-wave0-trigger-test] ok args  %-46s => %s\n' "$label" "$actual"
}

assert_stdin false "empty input" ""
assert_stdin false "docs-only change" $'docs/readme.md\n'
assert_stdin false "category-icon asset-only change" $'assets/category_icons/foo.svg\n'

assert_stdin true "workflow change" $'.github/workflows/flutter_ci.yml\n'
assert_stdin true "artifact guard script change" $'scripts/guard_saas_report_artifacts.sh\n'
assert_stdin true "artifact guard self-test change" $'scripts/test_saas_report_artifact_guard.sh\n'
assert_stdin true "trigger script change" $'scripts/should_run_saas_wave0_smoke.sh\n'
assert_stdin true "trigger self-test change" $'scripts/test_saas_wave0_smoke_trigger.sh\n'
assert_stdin true "payment service change" $'lib/core/payment/payment_service.dart\n'
assert_stdin true "sync service change" $'lib/core/service/sync_runtime_service.dart\n'
assert_stdin true "supabase function change" $'supabase/functions/admin/index.ts\n'
assert_stdin true "supabase migration change" $'supabase/migrations/20260420000000_init.sql\n'
assert_stdin true "mixed irrelevant and SaaS paths" $'docs/readme.md\nlib/core/payment/payment_service.dart\n'

assert_args false "argv docs-only change" docs/readme.md
assert_args true "argv multiple paths with SaaS hit" docs/readme.md lib/core/sync/sync_engine.dart

printf '[saas-wave0-trigger-test] all checks passed\n'
