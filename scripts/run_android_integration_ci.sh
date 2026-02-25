#!/usr/bin/env bash

set -euo pipefail

ARTIFACT_DIR="${CI_ARTIFACT_DIR:-ci_artifacts/android_integration}"
LOG_DIR="$ARTIFACT_DIR/logs"
SCREENSHOT_DIR="$ARTIFACT_DIR/screenshots"
DEVICE_SERIAL="${ANDROID_DEVICE_SERIAL:-emulator-5554}"
ADB_TIMEOUT_SECONDS="${ADB_TIMEOUT_SECONDS:-30}"
FLUTTER_TIMEOUT_SECONDS="${FLUTTER_TIMEOUT_SECONDS:-1800}"
FLUTTER_IGNORE_TIMEOUTS="${FLUTTER_IGNORE_TIMEOUTS:-1}"
FLUTTER_TEST_TIMEOUT="${FLUTTER_TEST_TIMEOUT:-none}"
FLUTTER_TEST_SKIP_PUB="${FLUTTER_TEST_SKIP_PUB:-1}"
FLUTTER_TEST_RETRY_INSTALL_FAILURE="${FLUTTER_TEST_RETRY_INSTALL_FAILURE:-1}"

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

is_retryable_flutter_failure() {
  local log_file="$1"
  grep -Eiq \
    "Unable to start the app on the device|StorageManager\\.getVolumes|failed to install .*apk|Error: ADB exited with exit code 1" \
    "$log_file"
}

wait_for_package_manager_ready() {
  local tries=15
  local i
  for ((i = 1; i <= tries; i++)); do
    if run_with_timeout "$ADB_TIMEOUT_SECONDS" adb -s "$DEVICE_SERIAL" shell pm list packages >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

run_flutter_test_attempt() {
  local attempt="$1"
  local attempt_log="$LOG_DIR/flutter_test_output_attempt${attempt}.log"
  local attempt_start_epoch
  attempt_start_epoch="$(date +%s)"
  local errexit_was_on=0
  if [[ $- == *e* ]]; then
    errexit_was_on=1
  fi

  echo "Running flutter integration attempt ${attempt}..."

  set +e
  run_with_timeout "$FLUTTER_TIMEOUT_SECONDS" "${flutter_cmd[@]}" 2>&1 | tee "$attempt_log"
  local exit_code=${PIPESTATUS[0]}
  if (( errexit_was_on == 1 )); then
    set -e
  fi

  local attempt_end_epoch
  attempt_end_epoch="$(date +%s)"
  local attempt_elapsed=$((attempt_end_epoch - attempt_start_epoch))
  echo "Flutter integration attempt ${attempt} finished with exit code ${exit_code} after ${attempt_elapsed}s."
  if (( exit_code == 124 )) && [[ -n "$TIMEOUT_BIN" ]]; then
    echo "Flutter integration attempt ${attempt} hit timeout guard (${FLUTTER_TIMEOUT_SECONDS}s)." | tee -a "$attempt_log"
  fi

  if [[ "$attempt" == "1" ]]; then
    cp "$attempt_log" "$LOG_DIR/flutter_test_output.log"
  else
    {
      printf '\n\n===== RETRY ATTEMPT %s =====\n' "$attempt"
      cat "$attempt_log"
    } >>"$LOG_DIR/flutter_test_output.log"
  fi

  return "$exit_code"
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
  printf 'flutter_ignore_timeouts=%s\n' "$FLUTTER_IGNORE_TIMEOUTS"
  printf 'flutter_test_timeout=%s\n' "$FLUTTER_TEST_TIMEOUT"
  printf 'flutter_test_skip_pub=%s\n' "$FLUTTER_TEST_SKIP_PUB"
  printf 'flutter_test_retry_install_failure=%s\n' "$FLUTTER_TEST_RETRY_INSTALL_FAILURE"
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

if ! wait_for_package_manager_ready; then
  echo "Package manager not ready before running integration tests." | tee "$LOG_DIR/package_manager_wait.log" >&2
else
  echo "Package manager ready." >"$LOG_DIR/package_manager_wait.log"
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

if [[ "$FLUTTER_IGNORE_TIMEOUTS" == "1" ]]; then
  flutter_cmd+=(
    --ignore-timeouts
  )
fi

if [[ -n "$FLUTTER_TEST_TIMEOUT" ]]; then
  flutter_cmd+=(
    --timeout
    "$FLUTTER_TEST_TIMEOUT"
  )
fi

if [[ "$FLUTTER_TEST_SKIP_PUB" == "1" ]]; then
  flutter_cmd+=(
    --no-pub
  )
fi

printf '%q ' "${flutter_cmd[@]}" >"$LOG_DIR/flutter_command.sh"
printf '\n' >>"$LOG_DIR/flutter_command.sh"

set +e
run_flutter_test_attempt 1
flutter_exit_code=$?
set -e

if (( flutter_exit_code != 0 )) && [[ "$FLUTTER_TEST_RETRY_INSTALL_FAILURE" == "1" ]]; then
  retry_reason="First attempt failed."
  if is_retryable_flutter_failure "$LOG_DIR/flutter_test_output_attempt1.log"; then
    retry_reason="Retrying flutter test once after transient install/start failure."
  else
    retry_reason="Retrying flutter test once after first attempt failure (defensive retry)."
  fi
  echo "$retry_reason" | tee "$LOG_DIR/retry_reason.log"

  run_with_timeout "$ADB_TIMEOUT_SECONDS" adb -s "$DEVICE_SERIAL" wait-for-device >"$LOG_DIR/adb_wait_for_retry.log" 2>&1 || true
  wait_for_package_manager_ready >/dev/null 2>&1 || true

  set +e
  run_flutter_test_attempt 2
  flutter_exit_code=$?
  set -e
fi

collect_device_artifacts

if (( flutter_exit_code != 0 )); then
  {
    echo "flutter test failed with exit code $flutter_exit_code"
    if (( flutter_exit_code == 124 )) && [[ -n "$TIMEOUT_BIN" ]]; then
      echo "reason=timeout_guard"
      echo "timeout_seconds=$FLUTTER_TIMEOUT_SECONDS"
    fi
    echo "resolved_tests=${test_targets[*]}"
  } | tee "$LOG_DIR/failure_reason.log" >&2
fi

exit "$flutter_exit_code"
