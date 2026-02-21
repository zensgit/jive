#!/usr/bin/env bash
set -euo pipefail

# Run Jive integration tests with consistent flags across local and CI.
#
# Usage:
#   bash scripts/run_integration_tests.sh [options] [device_id]
#
# Examples:
#   bash scripts/run_integration_tests.sh
#   bash scripts/run_integration_tests.sh emulator-5554
#   bash scripts/run_integration_tests.sh EP0110MZ0BC110087W
#   bash scripts/run_integration_tests.sh --test integration_test/transaction_search_flow_test.dart --retry 1

DEFAULT_TEST_FILES=(
  "integration_test/calendar_date_picker_flow_test.dart"
  "integration_test/transaction_search_flow_test.dart"
)

TEST_FILES=("${DEFAULT_TEST_FILES[@]}")
CUSTOM_TESTS=0
DEVICE_ID="${FLUTTER_DEVICE_ID:-}"
FLAVOR="${FLUTTER_TEST_FLAVOR:-dev}"
DART_DEFINE="${FLUTTER_TEST_DART_DEFINE:-JIVE_E2E=true}"
RETRY_COUNT="${FLUTTER_TEST_RETRY_COUNT:-0}"
TEST_TIMEOUT_SECONDS="${FLUTTER_TEST_TIMEOUT_SECONDS:-0}"
ADB_TIMEOUT_SECONDS="${FLUTTER_ADB_TIMEOUT_SECONDS:-20}"
DEVICE_RECOVERY_ENABLED="${FLUTTER_DEVICE_RECOVERY_ENABLED:-1}"
DEVICE_RECOVERY_RETRY_COUNT="${FLUTTER_DEVICE_RECOVERY_RETRY_COUNT:-2}"
DEVICE_RECOVERY_WAIT_SECONDS="${FLUTTER_DEVICE_RECOVERY_WAIT_SECONDS:-20}"
ALLOW_EMULATOR_REBOOT="${FLUTTER_DEVICE_RECOVERY_ALLOW_EMULATOR_REBOOT:-0}"
TIMEOUT_RECOVERY_RERUNS="${FLUTTER_TIMEOUT_RECOVERY_RERUNS:-0}"
TEST_CASE_TIMEOUT="${FLUTTER_TEST_CASE_TIMEOUT:-}"
IGNORE_TEST_TIMEOUTS="${FLUTTER_TEST_IGNORE_TIMEOUTS:-0}"
COLLECT_ON_FAIL=1
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_DIR="${FLUTTER_TEST_ARTIFACT_DIR:-/tmp/jive-integration-${STAMP}}"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/run_integration_tests.sh [options] [device_id]

Options:
  --test <path>          Run only specified test file. Can be passed multiple times.
  --retry <count>        Retry each failed test up to <count> times. Default: 0.
  --timeout <seconds>    Per-test timeout in seconds. 0 disables timeout. Default: 0.
  --test-case-timeout <duration>
                         Pass through to 'flutter test --timeout'. Example: 20m.
  --ignore-test-timeouts
                         Pass through to 'flutter test --ignore-timeouts'.
  --device-recovery      Enable adb device liveness recovery. Default: enabled.
  --no-device-recovery   Disable adb device liveness recovery.
  --device-recovery-retry <count>
                         Number of recovery rounds when device is offline. Default: 2.
  --device-recovery-timeout <seconds>
                         Wait timeout for each recovery round. 0 disables waiting. Default: 20.
  --allow-emulator-reboot
                         Allow adb reboot for emulator-* devices during recovery. Default: disabled.
  --no-allow-emulator-reboot
                         Disable emulator reboot during recovery.
  --timeout-recovery-rerun <count>
                         Rerun same attempt on timeout/termination up to <count> times. Default: 0.
  --artifact-dir <path>  Directory to store test logs/artifacts.
  --no-collect-on-fail   Disable adb artifact collection on failure.
  --list                 Print default integration test files and exit.
  -h, --help             Show this help message.

Env:
  FLUTTER_DEVICE_ID
  FLUTTER_TEST_FLAVOR
  FLUTTER_TEST_DART_DEFINE
  FLUTTER_TEST_RETRY_COUNT
  FLUTTER_TEST_TIMEOUT_SECONDS
  FLUTTER_TEST_CASE_TIMEOUT
  FLUTTER_TEST_IGNORE_TIMEOUTS
  FLUTTER_ADB_TIMEOUT_SECONDS
  FLUTTER_DEVICE_RECOVERY_ENABLED
  FLUTTER_DEVICE_RECOVERY_RETRY_COUNT
  FLUTTER_DEVICE_RECOVERY_WAIT_SECONDS
  FLUTTER_DEVICE_RECOVERY_ALLOW_EMULATOR_REBOOT
  FLUTTER_TIMEOUT_RECOVERY_RERUNS
  FLUTTER_TEST_ARTIFACT_DIR
EOF
}

log() {
  echo "[integration] $*"
}

list_tests() {
  local test_file
  for test_file in "${DEFAULT_TEST_FILES[@]}"; do
    echo "${test_file}"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --test" >&2
        exit 2
      fi
      if [[ "${CUSTOM_TESTS}" -eq 0 ]]; then
        TEST_FILES=()
        CUSTOM_TESTS=1
      fi
      TEST_FILES+=("$1")
      ;;
    --retry)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --retry" >&2
        exit 2
      fi
      RETRY_COUNT="$1"
      ;;
    --artifact-dir)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --artifact-dir" >&2
        exit 2
      fi
      ARTIFACT_DIR="$1"
      ;;
    --timeout)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --timeout" >&2
        exit 2
      fi
      TEST_TIMEOUT_SECONDS="$1"
      ;;
    --test-case-timeout)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --test-case-timeout" >&2
        exit 2
      fi
      TEST_CASE_TIMEOUT="$1"
      ;;
    --ignore-test-timeouts)
      IGNORE_TEST_TIMEOUTS=1
      ;;
    --device-recovery)
      DEVICE_RECOVERY_ENABLED=1
      ;;
    --no-device-recovery)
      DEVICE_RECOVERY_ENABLED=0
      ;;
    --device-recovery-retry)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --device-recovery-retry" >&2
        exit 2
      fi
      DEVICE_RECOVERY_RETRY_COUNT="$1"
      ;;
    --device-recovery-timeout)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --device-recovery-timeout" >&2
        exit 2
      fi
      DEVICE_RECOVERY_WAIT_SECONDS="$1"
      ;;
    --allow-emulator-reboot)
      ALLOW_EMULATOR_REBOOT=1
      ;;
    --no-allow-emulator-reboot)
      ALLOW_EMULATOR_REBOOT=0
      ;;
    --timeout-recovery-rerun)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --timeout-recovery-rerun" >&2
        exit 2
      fi
      TIMEOUT_RECOVERY_RERUNS="$1"
      ;;
    --no-collect-on-fail)
      COLLECT_ON_FAIL=0
      ;;
    --list)
      list_tests
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      if [[ -z "${DEVICE_ID}" ]]; then
        DEVICE_ID="$1"
      else
        echo "unexpected argument: $1" >&2
        usage
        exit 2
      fi
      ;;
  esac
  shift
done

if ! [[ "${RETRY_COUNT}" =~ ^[0-9]+$ ]]; then
  echo "--retry must be a non-negative integer, got: ${RETRY_COUNT}" >&2
  exit 2
fi

if ! [[ "${TEST_TIMEOUT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "--timeout must be a non-negative integer, got: ${TEST_TIMEOUT_SECONDS}" >&2
  exit 2
fi

if ! [[ "${ADB_TIMEOUT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "FLUTTER_ADB_TIMEOUT_SECONDS must be a non-negative integer, got: ${ADB_TIMEOUT_SECONDS}" >&2
  exit 2
fi

if ! [[ "${DEVICE_RECOVERY_ENABLED}" =~ ^[01]$ ]]; then
  echo "device recovery enabled flag must be 0 or 1, got: ${DEVICE_RECOVERY_ENABLED}" >&2
  exit 2
fi

if ! [[ "${DEVICE_RECOVERY_RETRY_COUNT}" =~ ^[0-9]+$ ]]; then
  echo "device recovery retry count must be a non-negative integer, got: ${DEVICE_RECOVERY_RETRY_COUNT}" >&2
  exit 2
fi

if ! [[ "${DEVICE_RECOVERY_WAIT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "device recovery timeout must be a non-negative integer, got: ${DEVICE_RECOVERY_WAIT_SECONDS}" >&2
  exit 2
fi

if ! [[ "${ALLOW_EMULATOR_REBOOT}" =~ ^[01]$ ]]; then
  echo "allow emulator reboot flag must be 0 or 1, got: ${ALLOW_EMULATOR_REBOOT}" >&2
  exit 2
fi

if ! [[ "${TIMEOUT_RECOVERY_RERUNS}" =~ ^[0-9]+$ ]]; then
  echo "timeout recovery rerun count must be a non-negative integer, got: ${TIMEOUT_RECOVERY_RERUNS}" >&2
  exit 2
fi

if ! [[ "${IGNORE_TEST_TIMEOUTS}" =~ ^[01]$ ]]; then
  echo "FLUTTER_TEST_IGNORE_TIMEOUTS must be 0 or 1, got: ${IGNORE_TEST_TIMEOUTS}" >&2
  exit 2
fi

if [[ "${#TEST_FILES[@]}" -eq 0 ]]; then
  echo "no integration tests selected" >&2
  exit 2
fi

mkdir -p "${ARTIFACT_DIR}"

TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  if (( TEST_TIMEOUT_SECONDS > 0 )); then
    log "timeout command not found; --timeout ignored"
  fi
  if (( ADB_TIMEOUT_SECONDS > 0 || DEVICE_RECOVERY_WAIT_SECONDS > 0 )); then
    log "timeout command not found; adb timeout controls are best-effort only"
  fi
fi

adb_args=()
if [[ -n "${DEVICE_ID}" ]]; then
  adb_args=(-s "${DEVICE_ID}")
fi

run_flutter_test() {
  local file="$1"
  local log_file="$2"
  local cmd=(
    flutter test
    "${file}"
    --flavor "${FLAVOR}"
    --dart-define="${DART_DEFINE}"
  )
  if [[ -n "${TEST_CASE_TIMEOUT}" ]]; then
    cmd+=(--timeout "${TEST_CASE_TIMEOUT}")
  fi
  if (( IGNORE_TEST_TIMEOUTS == 1 )); then
    cmd+=(--ignore-timeouts)
  fi
  if [[ -n "${DEVICE_ID}" ]]; then
    cmd+=(-d "${DEVICE_ID}")
  fi

  if [[ -n "${TIMEOUT_BIN}" ]] && (( TEST_TIMEOUT_SECONDS > 0 )); then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=30s "${TEST_TIMEOUT_SECONDS}s" "${cmd[@]}" 2>&1 | tee "${log_file}"
  else
    "${cmd[@]}" 2>&1 | tee "${log_file}"
  fi
}

run_adb() {
  local cmd=(adb "${adb_args[@]}" "$@")
  if [[ -n "${TIMEOUT_BIN}" ]] && (( ADB_TIMEOUT_SECONDS > 0 )); then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=5s "${ADB_TIMEOUT_SECONDS}s" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

run_adb_raw() {
  local cmd=(adb "$@")
  if [[ -n "${TIMEOUT_BIN}" ]] && (( ADB_TIMEOUT_SECONDS > 0 )); then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=5s "${ADB_TIMEOUT_SECONDS}s" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

first_ready_device_id() {
  local devices_output=""
  set +e
  devices_output="$(run_adb_raw devices 2>/dev/null)"
  local devices_rc=$?
  set -e
  if (( devices_rc != 0 )); then
    return 1
  fi

  echo "${devices_output}" | awk '/\tdevice$/{print $1; exit}'
}

first_connected_device_id() {
  local devices_output=""
  set +e
  devices_output="$(run_adb_raw devices 2>/dev/null)"
  local devices_rc=$?
  set -e
  if (( devices_rc != 0 )); then
    return 1
  fi

  echo "${devices_output}" | awk '/\t(device|offline|unauthorized)$/{print $1; exit}'
}

device_boot_completed() {
  local target_device="$1"
  if [[ -z "${target_device}" ]]; then
    return 1
  fi

  local boot_completed=""
  set +e
  boot_completed="$(run_adb_raw -s "${target_device}" shell getprop sys.boot_completed 2>/dev/null)"
  local boot_rc=$?
  set -e

  if (( boot_rc != 0 )); then
    return 1
  fi

  boot_completed="$(echo "${boot_completed}" | tr -d '[:space:]')"
  [[ "${boot_completed}" == "1" ]]
}

device_is_ready() {
  if ! command -v adb >/dev/null 2>&1; then
    return 0
  fi

  if [[ -n "${DEVICE_ID}" ]]; then
    local state=""
    set +e
    state="$(run_adb_raw -s "${DEVICE_ID}" get-state 2>/dev/null)"
    local state_rc=$?
    set -e
    state="$(echo "${state}" | tr -d '\r\n')"
    if (( state_rc == 0 )) && [[ "${state}" == "device" ]]; then
      if device_boot_completed "${DEVICE_ID}"; then
        return 0
      fi
    fi
    return 1
  fi

  local auto_device=""
  auto_device="$(first_ready_device_id || true)"
  if [[ -z "${auto_device}" ]]; then
    return 1
  fi

  if device_boot_completed "${auto_device}"; then
    return 0
  fi

  return 1
}

log_adb_devices_snapshot() {
  if ! command -v adb >/dev/null 2>&1; then
    return 0
  fi

  local devices_output=""
  set +e
  devices_output="$(run_adb_raw devices 2>&1)"
  set -e
  while IFS= read -r line; do
    log "adb devices: ${line}"
  done <<< "${devices_output}"
}

wait_for_target_device() {
  local cmd=(adb)
  if [[ -n "${DEVICE_ID}" ]]; then
    cmd+=(-s "${DEVICE_ID}")
  fi
  cmd+=(wait-for-device)

  if [[ -n "${TIMEOUT_BIN}" ]] && (( DEVICE_RECOVERY_WAIT_SECONDS > 0 )); then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=5s "${DEVICE_RECOVERY_WAIT_SECONDS}s" "${cmd[@]}"
    return $?
  fi

  if (( DEVICE_RECOVERY_WAIT_SECONDS == 0 )); then
    device_is_ready
    return $?
  fi

  local waited=0
  while (( waited < DEVICE_RECOVERY_WAIT_SECONDS )); do
    if device_is_ready; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done

  return 1
}

recover_device_liveness() {
  if (( DEVICE_RECOVERY_ENABLED == 0 )); then
    return 1
  fi

  if ! command -v adb >/dev/null 2>&1; then
    log "adb not found; cannot perform device recovery"
    return 1
  fi

  local round=1
  local recovery_target="${DEVICE_ID}"
  while (( round <= DEVICE_RECOVERY_RETRY_COUNT )); do
    if [[ -z "${recovery_target}" ]]; then
      recovery_target="$(first_connected_device_id || true)"
    fi

    log "device recovery round ${round}/${DEVICE_RECOVERY_RETRY_COUNT}"
    run_adb_raw reconnect offline >/dev/null 2>&1 || true
    run_adb_raw reconnect >/dev/null 2>&1 || true
    run_adb_raw kill-server >/dev/null 2>&1 || true
    run_adb_raw start-server >/dev/null 2>&1 || true

    if (( ALLOW_EMULATOR_REBOOT == 1 )) && [[ -n "${recovery_target}" ]] && [[ "${recovery_target}" =~ ^emulator-[0-9]+$ ]]; then
      log "attempting emulator reboot on ${recovery_target}"
      run_adb_raw -s "${recovery_target}" reboot >/dev/null 2>&1 || true
    fi

    if wait_for_target_device && device_is_ready; then
      log "device is online after recovery round ${round}"
      return 0
    fi

    log "device still not ready after recovery round ${round}"
    log_adb_devices_snapshot
    recovery_target=""
    round=$((round + 1))
  done

  return 1
}

ensure_device_ready_for_run() {
  if device_is_ready; then
    return 0
  fi

  log "device not ready before test run"
  log_adb_devices_snapshot

  if (( DEVICE_RECOVERY_ENABLED == 0 )); then
    log "device recovery disabled; run will fail without recovery"
    return 1
  fi

  if recover_device_liveness; then
    return 0
  fi

  log "device recovery failed"
  return 1
}

is_disconnect_failure_log() {
  local log_file="$1"
  if [[ ! -f "${log_file}" ]]; then
    return 1
  fi

  grep -Eiq \
    "no supported devices|no devices connected|no devices are connected|device offline|adb:.*device.*offline|adb:.*no devices|lost connection to device|unable to find devices|error: device .* not found" \
    "${log_file}"
}

is_timeout_exit_code() {
  local exit_code="$1"
  [[ "${exit_code}" -eq 124 || "${exit_code}" -eq 137 || "${exit_code}" -eq 143 ]]
}

run_single_test_invocation() {
  local file="$1"
  local log_file="$2"

  : > "${log_file}"
  if ! ensure_device_ready_for_run; then
    echo "[integration] device not ready before running ${file}" | tee -a "${log_file}" >/dev/null
    return 1
  fi

  run_adb logcat -c >/dev/null 2>&1 || true
  run_flutter_test "${file}" "${log_file}"
}

collect_failure_artifacts() {
  local file="$1"
  local attempt="$2"
  local safe_name="${file//\//_}"
  safe_name="${safe_name//./_}"
  local prefix="${ARTIFACT_DIR}/${safe_name}.attempt${attempt}"

  if [[ "${COLLECT_ON_FAIL}" -eq 0 ]]; then
    return 0
  fi

  if ! command -v adb >/dev/null 2>&1; then
    log "adb not found, skip failure artifact collection"
    return 0
  fi

  log "collecting failure artifacts for ${file} (attempt ${attempt})"
  run_adb logcat -d > "${prefix}.logcat.txt" 2>/dev/null || true
  run_adb exec-out screencap -p > "${prefix}.screen.png" 2>/dev/null || true
  run_adb shell uiautomator dump /sdcard/jive_integration_fail.xml >/dev/null 2>&1 || true
  run_adb pull /sdcard/jive_integration_fail.xml "${prefix}.ui.xml" >/dev/null 2>&1 || true
}

run_test_with_retry() {
  local file="$1"
  local max_attempts=$((RETRY_COUNT + 1))
  local attempt=1
  local safe_name="${file//\//_}"
  safe_name="${safe_name//./_}"

  while (( attempt <= max_attempts )); do
    local log_file="${ARTIFACT_DIR}/${safe_name}.attempt${attempt}.test.log"
    local rerun_log_file="${ARTIFACT_DIR}/${safe_name}.attempt${attempt}.recovery-rerun.test.log"
    local exit_code=0
    local recovered_rerun=0
    local timeout_reruns_done=0
    log "running: ${file} (attempt ${attempt}/${max_attempts})"
    set +e
    run_single_test_invocation "${file}" "${log_file}"
    exit_code=$?
    set -e

    if (( exit_code != 0 )) && (( DEVICE_RECOVERY_ENABLED == 1 )) && (( recovered_rerun == 0 )); then
      local rerun_reason=""
      if is_disconnect_failure_log "${log_file}"; then
        rerun_reason="device disconnect"
      elif is_timeout_exit_code "${exit_code}" && (( timeout_reruns_done < TIMEOUT_RECOVERY_RERUNS )); then
        rerun_reason="timeout/termination"
      fi

      if [[ -n "${rerun_reason}" ]]; then
        log "${rerun_reason} detected for ${file}; recovering and rerunning same attempt"
        if recover_device_liveness; then
          recovered_rerun=1
          if [[ "${rerun_reason}" == "timeout/termination" ]]; then
            timeout_reruns_done=$((timeout_reruns_done + 1))
          fi
          set +e
          run_single_test_invocation "${file}" "${rerun_log_file}"
          exit_code=$?
          set -e
        else
          log "recovery did not restore a ready device for same-attempt rerun"
        fi
      fi
    fi

    if (( exit_code == 0 )); then
      log "passed: ${file} (attempt ${attempt})"
      return 0
    fi
    if is_timeout_exit_code "${exit_code}"; then
      local timeout_label="configured timeout"
      if (( TEST_TIMEOUT_SECONDS > 0 )); then
        timeout_label="${TEST_TIMEOUT_SECONDS}s"
      fi
      log "timed out or terminated: ${file} after ${timeout_label} (attempt ${attempt}, exit=${exit_code})"
    fi
    log "failed: ${file} (attempt ${attempt})"
    collect_failure_artifacts "${file}" "${attempt}"
    if (( attempt < max_attempts )); then
      log "retrying: ${file}"
    fi
    attempt=$((attempt + 1))
  done

  return 1
}

FAILED_TESTS=()
for test_file in "${TEST_FILES[@]}"; do
  if ! run_test_with_retry "${test_file}"; then
    FAILED_TESTS+=("${test_file}")
  fi
done

if [[ "${#FAILED_TESTS[@]}" -gt 0 ]]; then
  log "failed test files:"
  for failed in "${FAILED_TESTS[@]}"; do
    log "  - ${failed}"
  done
  log "artifacts: ${ARTIFACT_DIR}"
  exit 1
fi

log "all integration tests passed"
log "artifacts: ${ARTIFACT_DIR}"
