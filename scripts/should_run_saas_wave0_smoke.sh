#!/usr/bin/env bash
set -euo pipefail

matches_saas_wave0_path() {
  local path="$1"

  case "$path" in
    .github/workflows/flutter_ci.yml | \
    analysis_options.yaml | \
    scripts/run_saas_wave0_smoke.sh | \
    scripts/run_saas_core_staging_lane.sh | \
    scripts/run_saas_staging_function_smoke.sh | \
    scripts/check_saas_deployment_readiness.sh | \
    scripts/should_run_saas_wave0_smoke.sh | \
    pubspec.yaml | \
    pubspec.lock)
      return 0
      ;;
    supabase/functions/* | \
    supabase/migrations/* | \
    lib/app/subscription_lifecycle_gate.dart | \
    lib/core/auth/* | \
    lib/core/database/sync_* | \
    lib/core/entitlement/* | \
    lib/core/payment/* | \
    lib/core/repository/*sync* | \
    lib/core/service/*sync* | \
    lib/core/sync/* | \
    lib/feature/auth/* | \
    lib/feature/settings/sync_* | \
    lib/feature/subscription/* | \
    lib/feature/sync/* | \
    test/*auth* | \
    test/*payment* | \
    test/*subscription* | \
    test/*sync*)
      return 0
      ;;
  esac

  return 1
}

check_path() {
  local path="$1"
  [[ -z "$path" ]] && return 0

  if matches_saas_wave0_path "$path"; then
    echo "true"
    exit 0
  fi
}

if (($# > 0)); then
  for path in "$@"; do
    check_path "$path"
  done
else
  while IFS= read -r path; do
    check_path "$path"
  done
fi

echo "false"
