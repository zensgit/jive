#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

log() {
  printf '[saas-wave0-smoke] %s\n' "$*"
}

have_all() {
  local path
  for path in "$@"; do
    if [[ ! -e "$path" ]]; then
      return 1
    fi
  done
}

append_if_exists() {
  local array_name="$1"
  local candidate="$2"
  if [[ -e "$candidate" ]]; then
    eval "$array_name+=(\"\$candidate\")"
  fi
}

resolve_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$FLUTTER_BIN"
    return 0
  fi

  local candidate
  for candidate in \
    "$APP_DIR/../../.flutter_sdk/bin/flutter" \
    "$APP_DIR/../.flutter_sdk/bin/flutter" \
    "$APP_DIR/.flutter_sdk/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  command -v flutter
}

resolve_dart_bin() {
  local flutter_bin="$1"

  if [[ -n "${DART_BIN:-}" ]]; then
    printf '%s\n' "$DART_BIN"
    return 0
  fi

  local dart_from_flutter
  dart_from_flutter="$(cd "$(dirname "$flutter_bin")/cache/dart-sdk/bin" && pwd 2>/dev/null || true)"
  if [[ -n "$dart_from_flutter" && -x "$dart_from_flutter/dart" ]]; then
    printf '%s\n' "$dart_from_flutter/dart"
    return 0
  fi

  command -v dart
}

FLUTTER_CMD="$(resolve_flutter_bin)"
DART_CMD="$(resolve_dart_bin "$FLUTTER_CMD")"
if [[ -n "${DENO_CMD:-}" ]]; then
  read -r -a DENO_RUNNER <<< "$DENO_CMD"
else
  DENO_RUNNER=(npx -y deno-bin@2.2.7)
fi

run_deno() {
  local max_attempts="${DENO_RETRY_ATTEMPTS:-3}"
  local attempt=1

  while true; do
    if "${DENO_RUNNER[@]}" "$@"; then
      return 0
    fi

    if (( attempt >= max_attempts )); then
      return 1
    fi

    log "deno command failed; retrying ($attempt/$max_attempts): $*"
    sleep $(( attempt * 5 ))
    attempt=$(( attempt + 1 ))
  done
}

need_flutter=0
if have_all test/sync_book_scope_test.dart test/sync_delete_marker_service_test.dart test/sync_tombstone_store_test.dart; then
  need_flutter=1
fi
if [[ -e test/subscription_status_service_test.dart || -e test/subscription_lifecycle_gate_test.dart || -e test/app_store_payment_service_test.dart ]]; then
  need_flutter=1
fi
if [[ -e test/auth_service_test.dart || -e test/auth_screen_test.dart ]]; then
  need_flutter=1
fi

if [[ "$need_flutter" -eq 1 ]]; then
  log "flutter pub get"
  "$FLUTTER_CMD" pub get
fi

if have_all test/sync_book_scope_test.dart test/sync_delete_marker_service_test.dart test/sync_tombstone_store_test.dart; then
  log "sync smoke"
  "$FLUTTER_CMD" test --no-pub \
    test/sync_book_scope_test.dart \
    test/sync_delete_marker_service_test.dart \
    test/sync_tombstone_store_test.dart
else
  log "sync smoke skipped (required tombstone tests not present)"
fi

if have_all supabase/functions/subscription-webhook/index.ts supabase/functions/subscription-webhook/index_test.ts; then
  log "billing webhook smoke"
  "${DENO_RUNNER[@]}" check \
    supabase/functions/subscription-webhook/index.ts \
    supabase/functions/subscription-webhook/index_test.ts
  "${DENO_RUNNER[@]}" test supabase/functions/subscription-webhook/index_test.ts
else
  log "billing webhook smoke skipped (subscription-webhook files not present)"
fi

client_billing_analyze=()
append_if_exists client_billing_analyze lib/core/payment/subscription_truth_repository.dart
append_if_exists client_billing_analyze lib/core/payment/supabase_subscription_truth_repository.dart
append_if_exists client_billing_analyze lib/core/payment/app_store_payment_service.dart
append_if_exists client_billing_analyze test/subscription_status_service_test.dart
append_if_exists client_billing_analyze test/subscription_lifecycle_gate_test.dart
append_if_exists client_billing_analyze test/app_store_payment_service_test.dart

client_billing_tests=()
append_if_exists client_billing_tests test/subscription_status_service_test.dart
append_if_exists client_billing_tests test/subscription_lifecycle_gate_test.dart
append_if_exists client_billing_tests test/app_store_payment_service_test.dart

if (( ${#client_billing_analyze[@]} > 0 )); then
  log "billing client/server-truth analyze"
  "$DART_CMD" analyze "${client_billing_analyze[@]}"
fi

if (( ${#client_billing_tests[@]} > 0 )); then
  log "billing client/server-truth flutter tests"
  "$FLUTTER_CMD" test --no-pub "${client_billing_tests[@]}"
else
  log "billing client/server-truth flutter tests skipped (client billing tests not present)"
fi

if have_all supabase/functions/verify-subscription/index.ts supabase/functions/verify-subscription/index_test.ts; then
  log "billing verify-subscription smoke"
  "${DENO_RUNNER[@]}" check \
    supabase/functions/verify-subscription/index.ts \
    supabase/functions/verify-subscription/index_test.ts
  "${DENO_RUNNER[@]}" test supabase/functions/verify-subscription/index_test.ts
else
  log "billing verify-subscription smoke skipped (verify-subscription files not present)"
fi

auth_analyze=()
append_if_exists auth_analyze lib/core/auth/auth_service.dart
append_if_exists auth_analyze lib/core/auth/guest_auth_service.dart
append_if_exists auth_analyze lib/core/auth/supabase_auth_service.dart
append_if_exists auth_analyze lib/feature/auth/auth_screen.dart
append_if_exists auth_analyze test/auth_service_test.dart
append_if_exists auth_analyze test/auth_screen_test.dart

auth_tests=()
append_if_exists auth_tests test/auth_service_test.dart
append_if_exists auth_tests test/auth_screen_test.dart

if (( ${#auth_analyze[@]} > 0 )); then
  log "auth smoke analyze"
  "$DART_CMD" analyze "${auth_analyze[@]}"
fi

if (( ${#auth_tests[@]} > 0 )); then
  log "auth smoke flutter tests"
  "$FLUTTER_CMD" test --no-pub "${auth_tests[@]}"
else
  log "auth smoke skipped (auth tests not present)"
fi

if have_all supabase/functions/analytics/index.ts supabase/functions/analytics/index_test.ts; then
  log "ops analytics smoke"
  "${DENO_RUNNER[@]}" check \
    supabase/functions/analytics/index.ts \
    supabase/functions/analytics/index_test.ts
  "${DENO_RUNNER[@]}" test supabase/functions/analytics/index_test.ts
else
  log "ops analytics smoke skipped (analytics files not present)"
fi

if have_all supabase/functions/send-notification/index.ts supabase/functions/send-notification/index_test.ts; then
  log "ops notification smoke"
  "${DENO_RUNNER[@]}" check \
    supabase/functions/send-notification/index.ts \
    supabase/functions/send-notification/index_test.ts
  "${DENO_RUNNER[@]}" test supabase/functions/send-notification/index_test.ts
else
  log "ops notification smoke skipped (send-notification files not present)"
fi

if have_all supabase/functions/admin/index.ts supabase/functions/admin/index_test.ts; then
  log "ops admin smoke"
  "${DENO_RUNNER[@]}" check \
    supabase/functions/admin/index.ts \
    supabase/functions/admin/index_test.ts
  "${DENO_RUNNER[@]}" test supabase/functions/admin/index_test.ts
else
  log "ops admin smoke skipped (admin files not present)"
fi

log "Wave 0 SaaS smoke completed"
