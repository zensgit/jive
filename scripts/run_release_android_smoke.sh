#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_release_android_smoke.sh [run_android_local_feature_smoke options]

Defaults:
  Runs the full local Android release smoke lane:
    scripts/run_android_local_feature_smoke.sh \
      --scenario all \
      --fresh-install \
      --allow-uninstall-on-signature-mismatch

Environment:
  JIVE_RELEASE_ANDROID_SMOKE_SCENARIO       Defaults to all.
  JIVE_RELEASE_ANDROID_SMOKE_ARTIFACT_DIR   Defaults to build/reports/release-android-smoke/<timestamp>.

Examples:
  scripts/run_release_android_smoke.sh

  scripts/run_release_android_smoke.sh \
    --skip-build \
    --apk-path build/app/outputs/flutter-apk/app-dev-debug.apk

  scripts/run_release_android_smoke.sh \
    --device emulator-5554 \
    --preserve-data

Notes:
  This is a local pre-deployment smoke wrapper. It does not upload artifacts,
  does not read GitHub secrets, and does not prove production payment or cloud
  connectivity. Extra arguments are passed through after the defaults, so they
  can override scenario, artifact directory, install behavior, device, and build
  options.
  The default fresh install is intended for emulators. On a physical device,
  pass --preserve-data unless you explicitly accept resetting local app data.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
SCENARIO="${JIVE_RELEASE_ANDROID_SMOKE_SCENARIO:-all}"
ARTIFACT_DIR="${JIVE_RELEASE_ANDROID_SMOKE_ARTIFACT_DIR:-$APP_DIR/build/reports/release-android-smoke/$STAMP}"

exec bash "$SCRIPT_DIR/run_android_local_feature_smoke.sh" \
  --scenario "$SCENARIO" \
  --fresh-install \
  --allow-uninstall-on-signature-mismatch \
  --artifact-dir "$ARTIFACT_DIR" \
  "$@"
