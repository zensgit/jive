#!/usr/bin/env bash
set -euo pipefail

# Run Jive integration tests with consistent flags across local and CI.
#
# Usage:
#   bash scripts/run_integration_tests.sh [device_id]
#
# Examples:
#   bash scripts/run_integration_tests.sh
#   bash scripts/run_integration_tests.sh emulator-5554
#   bash scripts/run_integration_tests.sh EP0110MZ0BC110087W

DEVICE_ID="${1:-${FLUTTER_DEVICE_ID:-}}"
FLAVOR="${FLUTTER_TEST_FLAVOR:-dev}"
DART_DEFINE="${FLUTTER_TEST_DART_DEFINE:-JIVE_E2E=true}"

TEST_FILES=(
  "integration_test/calendar_date_picker_flow_test.dart"
  "integration_test/transaction_search_flow_test.dart"
)

run_test_file() {
  local file="$1"
  local cmd=(
    flutter test
    "${file}"
    --flavor "${FLAVOR}"
    --dart-define="${DART_DEFINE}"
  )
  if [[ -n "${DEVICE_ID}" ]]; then
    cmd+=(-d "${DEVICE_ID}")
  fi

  echo "[integration] running: ${file}"
  "${cmd[@]}"
}

for test_file in "${TEST_FILES[@]}"; do
  run_test_file "${test_file}"
done

echo "[integration] all integration tests passed"
