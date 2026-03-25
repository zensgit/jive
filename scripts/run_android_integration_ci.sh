#!/usr/bin/env bash

set -euo pipefail

ARTIFACT_DIR="${CI_ARTIFACT_DIR:-ci_artifacts/android_integration}"
LOG_DIR="$ARTIFACT_DIR/logs"
SCREENSHOT_DIR="$ARTIFACT_DIR/screenshots"
DEVICE_SERIAL="${ANDROID_DEVICE_SERIAL:-emulator-5554}"
ADB_TIMEOUT_SECONDS="${ADB_TIMEOUT_SECONDS:-30}"
FLUTTER_TIMEOUT_SECONDS="${FLUTTER_TIMEOUT_SECONDS:-1800}"

mkdir -p "$LOG_DIR" "$SCREENSHOT_DIR"

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  TIMEOUT_BIN=""
  echo "timeout command not found; running without timeout guard." >&2
fi

run_with_timeout() {
  local timeout_seconds="$1"
  shift
  if [[ -n "$TIMEOUT_BIN" ]]; then
    "$TIMEOUT_BIN" "${timeout_seconds}s" "$@"
  else
    "$@"
  fi
}

normalize_test_target() {
  local raw="$1"
  local target="$raw"

  if [[ "$target" == integration_test/* ]]; then
    :
  elif [[ "$target" == *.dart ]]; then
    target="integration_test/$target"
  else
    target="integration_test/${target}_test.dart"
  fi

  if [[ "$target" != *.dart ]]; then
    target="${target}.dart"
  fi

  if [[ "$target" != *_test.dart ]]; then
    target="${target%.dart}_test.dart"
  fi

  printf '%s\n' "$target"
}

collect_device_artifacts() {
  run_with_timeout "$ADB_TIMEOUT_SECONDS" adb devices -l >"$LOG_DIR/adb_devices_after.log" 2>&1 || true
  run_with_timeout "$ADB_TIMEOUT_SECONDS" adb -s "$DEVICE_SERIAL" logcat -d >"$LOG_DIR/adb_logcat.log" 2>&1 || true

  if ! run_with_timeout "$ADB_TIMEOUT_SECONDS" adb -s "$DEVICE_SERIAL" exec-out screencap -p >"$SCREENSHOT_DIR/final_screen.png" 2>"$LOG_DIR/adb_screencap.log"; then
    rm -f "$SCREENSHOT_DIR/final_screen.png"
  fi
}

declare -a requested_tests
if (( $# > 0 )); then
  requested_tests=("$@")
else
  requested_tests=(
    "transaction_search_flow"
  )
fi

declare -a test_targets=()
for requested in "${requested_tests[@]}"; do
  target="$(normalize_test_target "$requested")"
  if [[ ! -f "$target" ]]; then
    echo "Missing integration test file: $target (from '$requested')." >&2
    exit 2
  fi
  test_targets+=("$target")
done

{
  printf 'device_serial=%s\n' "$DEVICE_SERIAL"
  printf 'adb_timeout_seconds=%s\n' "$ADB_TIMEOUT_SECONDS"
  printf 'flutter_timeout_seconds=%s\n' "$FLUTTER_TIMEOUT_SECONDS"
  printf 'requested_tests=%s\n' "${requested_tests[*]}"
  printf 'resolved_tests=%s\n' "${test_targets[*]}"
} >"$ARTIFACT_DIR/metadata.txt"

run_with_timeout "$ADB_TIMEOUT_SECONDS" adb devices -l >"$LOG_DIR/adb_devices_before.log" 2>&1 || true

set +e
run_with_timeout "$ADB_TIMEOUT_SECONDS" adb -s "$DEVICE_SERIAL" wait-for-device >"$LOG_DIR/adb_wait_for_device.log" 2>&1
wait_exit_code=$?
set -e
if (( wait_exit_code != 0 )); then
  echo "adb wait-for-device failed with exit code $wait_exit_code." | tee "$LOG_DIR/failure_reason.log" >&2
  collect_device_artifacts
  exit "$wait_exit_code"
fi

flutter_cmd=(
  flutter
  test
  "${test_targets[@]}"
  -d
  "$DEVICE_SERIAL"
  --flavor
  dev
  --dart-define=JIVE_E2E=true
)

printf '%q ' "${flutter_cmd[@]}" >"$LOG_DIR/flutter_command.sh"
printf '\n' >>"$LOG_DIR/flutter_command.sh"

set +e
run_with_timeout "$FLUTTER_TIMEOUT_SECONDS" "${flutter_cmd[@]}" 2>&1 | tee "$LOG_DIR/flutter_test_output.log"
flutter_exit_code=${PIPESTATUS[0]}
set -e

collect_device_artifacts

exit "$flutter_exit_code"
