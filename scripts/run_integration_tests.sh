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

if [[ "${#TEST_FILES[@]}" -eq 0 ]]; then
  echo "no integration tests selected" >&2
  exit 2
fi

mkdir -p "${ARTIFACT_DIR}"

TIMEOUT_BIN=""
if (( TEST_TIMEOUT_SECONDS > 0 )); then
  if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN="timeout"
  elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
  else
    log "timeout command not found; --timeout ignored"
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
  if [[ -n "${DEVICE_ID}" ]]; then
    cmd+=(-d "${DEVICE_ID}")
  fi

  if [[ -n "${TIMEOUT_BIN}" ]]; then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=30s "${TEST_TIMEOUT_SECONDS}s" "${cmd[@]}" 2>&1 | tee "${log_file}"
  else
    "${cmd[@]}" 2>&1 | tee "${log_file}"
  fi
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
  adb "${adb_args[@]}" logcat -d > "${prefix}.logcat.txt" 2>/dev/null || true
  adb "${adb_args[@]}" exec-out screencap -p > "${prefix}.screen.png" 2>/dev/null || true
  adb "${adb_args[@]}" shell uiautomator dump /sdcard/jive_integration_fail.xml >/dev/null 2>&1 || true
  adb "${adb_args[@]}" pull /sdcard/jive_integration_fail.xml "${prefix}.ui.xml" >/dev/null 2>&1 || true
}

run_test_with_retry() {
  local file="$1"
  local max_attempts=$((RETRY_COUNT + 1))
  local attempt=1
  local safe_name="${file//\//_}"
  safe_name="${safe_name//./_}"

  while (( attempt <= max_attempts )); do
    local log_file="${ARTIFACT_DIR}/${safe_name}.attempt${attempt}.test.log"
    local exit_code=0
    log "running: ${file} (attempt ${attempt}/${max_attempts})"
    adb "${adb_args[@]}" logcat -c >/dev/null 2>&1 || true
    if run_flutter_test "${file}" "${log_file}"; then
      log "passed: ${file} (attempt ${attempt})"
      return 0
    fi
    exit_code=$?
    if [[ "${exit_code}" -eq 124 ]]; then
      log "timed out: ${file} after ${TEST_TIMEOUT_SECONDS}s (attempt ${attempt})"
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
