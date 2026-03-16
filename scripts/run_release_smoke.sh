#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

DEVICE_ARGS=()
if [[ -n "${JIVE_SMOKE_DEVICE:-}" ]]; then
  DEVICE_ARGS=(-d "$JIVE_SMOKE_DEVICE")
fi

bash "$SCRIPT_DIR/run_release_regression_suite.sh"

flutter analyze \
  integration_test/import_center_failure_analytics_flow_test.dart \
  integration_test/category_icon_picker_flow_test.dart \
  lib/feature/import/import_center_screen.dart \
  lib/feature/category/category_icon_picker_screen.dart

for smoke_test in \
  integration_test/import_center_failure_analytics_flow_test.dart \
  integration_test/category_icon_picker_flow_test.dart; do
  flutter test \
    "$smoke_test" \
    "${DEVICE_ARGS[@]}" \
    --dart-define=JIVE_E2E=true
done
