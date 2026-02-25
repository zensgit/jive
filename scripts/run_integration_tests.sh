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
PUB_GET_ONCE="${FLUTTER_TEST_PUB_GET_ONCE:-1}"
PUB_GET_TIMEOUT_SECONDS="${FLUTTER_TEST_PUB_GET_TIMEOUT_SECONDS:-300}"
SKIP_PUB_GET_ONCE="${FLUTTER_TEST_SKIP_PUB_GET:-0}"
COMBINED_SUITE_MODE="${FLUTTER_TEST_COMBINED_SUITE_MODE:-0}"
DRY_RUN="${FLUTTER_TEST_DRY_RUN:-0}"
PRINT_SUMMARY_JSON="${FLUTTER_TEST_PRINT_SUMMARY_JSON:-0}"
COLLECT_ON_FAIL=1
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_DIR="${FLUTTER_TEST_ARTIFACT_DIR:-/tmp/jive-integration-${STAMP}}"
SUMMARY_FILE="${FLUTTER_TEST_SUMMARY_FILE:-}"
SUITE_STARTED_AT="$(date +%s)"
TEST_RUN_SUMMARY=()
FAILED_TESTS=()
SUMMARY_WRITTEN=0
SCRIPT_EXIT_CODE=0
INTERRUPTED_REASON=""
SUITE_FINISHED_AT=0
SUITE_ELAPSED_SECONDS=0

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
  --pub-get-once          Run 'flutter pub get' once before test suite and use '--no-pub' for each test (default).
  --no-pub-get-once       Run flutter test without '--no-pub' (pub resolution per invocation).
  --pub-get-timeout <seconds>
                         Timeout for the one-time 'flutter pub get'. 0 disables timeout. Default: 300.
  --skip-pub-get         Skip one-time 'flutter pub get' (requires pre-resolved dependencies).
  --no-skip-pub-get      Do not skip one-time 'flutter pub get' (default).
  --combined-suite        Run all selected test files in one flutter test invocation per attempt.
  --no-combined-suite     Run selected tests file-by-file (default).
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
  --summary-file <path>  Path to write suite summary file. Default: <artifact-dir>/suite-summary.txt.
  --dry-run              Validate inputs/config, write summary, and exit without running flutter/adb.
  --print-summary-json   Print machine-readable JSON summary to stdout at exit.
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
  FLUTTER_TEST_PUB_GET_ONCE
  FLUTTER_TEST_PUB_GET_TIMEOUT_SECONDS
  FLUTTER_TEST_SKIP_PUB_GET
  FLUTTER_TEST_COMBINED_SUITE_MODE
  FLUTTER_TEST_DRY_RUN
  FLUTTER_TEST_PRINT_SUMMARY_JSON
  FLUTTER_ADB_TIMEOUT_SECONDS
  FLUTTER_DEVICE_RECOVERY_ENABLED
  FLUTTER_DEVICE_RECOVERY_RETRY_COUNT
  FLUTTER_DEVICE_RECOVERY_WAIT_SECONDS
  FLUTTER_DEVICE_RECOVERY_ALLOW_EMULATOR_REBOOT
  FLUTTER_TIMEOUT_RECOVERY_RERUNS
  FLUTTER_TEST_ARTIFACT_DIR
  FLUTTER_TEST_SUMMARY_FILE
EOF
}

log() {
  echo "[integration] $*"
}

format_duration() {
  local total_seconds="$1"
  if (( total_seconds < 0 )); then
    total_seconds=0
  fi
  local minutes=$((total_seconds / 60))
  local seconds=$((total_seconds % 60))
  printf "%dm%02ds" "${minutes}" "${seconds}"
}

trim_spaces() {
  local text="$1"
  # trim leading spaces
  text="${text#"${text%%[![:space:]]*}"}"
  # trim trailing spaces
  text="${text%"${text##*[![:space:]]}"}"
  printf "%s" "${text}"
}

truncate_for_summary() {
  local value="$1"
  local max_len="${2:-80}"
  if (( ${#value} > max_len )); then
    printf "%s..." "${value:0:max_len}"
    return 0
  fi
  printf "%s" "${value}"
}

is_sensitive_config_key() {
  local key="$1"
  local key_upper
  key_upper="$(printf "%s" "${key}" | tr '[:lower:]' '[:upper:]')"
  [[ "${key_upper}" == *"TOKEN"* ]] || \
    [[ "${key_upper}" == *"SECRET"* ]] || \
    [[ "${key_upper}" == *"PASSWORD"* ]] || \
    [[ "${key_upper}" == *"PASS"* ]] || \
    [[ "${key_upper}" == *"API_KEY"* ]] || \
    [[ "${key_upper}" == *"AUTH"* ]] || \
    [[ "${key_upper}" == *"CREDENTIAL"* ]]
}

format_dart_define_for_summary() {
  local raw="$1"
  if [[ -z "${raw}" ]]; then
    echo "unset"
    return 0
  fi

  local normalized="${raw}"
  normalized="${normalized//, /,}"
  normalized="${normalized// ,/,}"

  local define_parts=()
  IFS=',' read -r -a define_parts <<< "${normalized}"

  local rendered_parts=()
  local define_part=""
  for define_part in "${define_parts[@]}"; do
    define_part="$(trim_spaces "${define_part}")"
    if [[ -z "${define_part}" ]]; then
      continue
    fi

    if [[ "${define_part}" == *"="* ]]; then
      local define_key="${define_part%%=*}"
      local define_value="${define_part#*=}"
      define_key="$(trim_spaces "${define_key}")"
      define_value="$(trim_spaces "${define_value}")"
      if is_sensitive_config_key "${define_key}"; then
        rendered_parts+=("${define_key}=<redacted>")
      else
        rendered_parts+=("${define_key}=$(truncate_for_summary "${define_value}")")
      fi
    else
      rendered_parts+=("$(truncate_for_summary "${define_part}")")
    fi
  done

  if [[ "${#rendered_parts[@]}" -eq 0 ]]; then
    echo "unset"
    return 0
  fi

  local joined=""
  local rendered_part=""
  for rendered_part in "${rendered_parts[@]}"; do
    if [[ -z "${joined}" ]]; then
      joined="${rendered_part}"
    else
      joined="${joined},${rendered_part}"
    fi
  done
  echo "${joined}"
}

list_tests() {
  local test_file
  for test_file in "${DEFAULT_TEST_FILES[@]}"; do
    echo "${test_file}"
  done
}

log_effective_config() {
  log "effective config:"
  log "  - device_id=${DEVICE_ID:-auto}"
  log "  - flavor=${FLAVOR}"
  log "  - dart_define=$(format_dart_define_for_summary "${DART_DEFINE}")"
  log "  - retry_count=${RETRY_COUNT}"
  log "  - test_timeout_seconds=${TEST_TIMEOUT_SECONDS}"
  log "  - test_case_timeout=${TEST_CASE_TIMEOUT:-unset}"
  log "  - ignore_test_timeouts=${IGNORE_TEST_TIMEOUTS}"
  log "  - pub_get_once=${PUB_GET_ONCE}"
  log "  - skip_pub_get_once=${SKIP_PUB_GET_ONCE}"
  log "  - combined_suite_mode=${COMBINED_SUITE_MODE}"
  log "  - dry_run=${DRY_RUN}"
  log "  - print_summary_json=${PRINT_SUMMARY_JSON}"
  log "  - timeout_recovery_reruns=${TIMEOUT_RECOVERY_RERUNS}"
  log "  - device_recovery_enabled=${DEVICE_RECOVERY_ENABLED}"
  log "  - device_recovery_retry_count=${DEVICE_RECOVERY_RETRY_COUNT}"
  log "  - device_recovery_wait_seconds=${DEVICE_RECOVERY_WAIT_SECONDS}"
  log "  - allow_emulator_reboot=${ALLOW_EMULATOR_REBOOT}"
  log "  - artifacts_dir=${ARTIFACT_DIR}"
  log "  - summary_file=${SUMMARY_FILE}"
  log "  - test_files_count=${#TEST_FILES[@]}"
  local test_file
  for test_file in "${TEST_FILES[@]}"; do
    log "  - test_file=${test_file}"
  done
}

json_escape() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//\"/\\\"}"
  raw="${raw//$'\n'/\\n}"
  raw="${raw//$'\r'/\\r}"
  raw="${raw//$'\t'/\\t}"
  printf "%s" "${raw}"
}

json_array_from_args() {
  local first=1
  local item=""
  printf "["
  for item in "$@"; do
    if (( first == 0 )); then
      printf ","
    fi
    printf "\"%s\"" "$(json_escape "${item}")"
    first=0
  done
  printf "]"
}

print_suite_summary_json() {
  local script_result="failure"
  if (( SCRIPT_EXIT_CODE == 0 )); then
    script_result="success"
  fi

  printf "{"
  printf "\"suite_started_at\":%s," "${SUITE_STARTED_AT}"
  printf "\"suite_finished_at\":%s," "${SUITE_FINISHED_AT}"
  printf "\"suite_elapsed_seconds\":%s," "${SUITE_ELAPSED_SECONDS}"
  printf "\"suite_elapsed_human\":\"%s\"," "$(json_escape "$(format_duration "${SUITE_ELAPSED_SECONDS}")")"
  printf "\"script_exit_code\":%s," "${SCRIPT_EXIT_CODE}"
  printf "\"script_result\":\"%s\"," "$(json_escape "${script_result}")"
  printf "\"interrupted_reason\":"
  if [[ -n "${INTERRUPTED_REASON}" ]]; then
    printf "\"%s\"," "$(json_escape "${INTERRUPTED_REASON}")"
  else
    printf "null,"
  fi
  printf "\"combined_suite_mode\":\"%s\"," "$(json_escape "${COMBINED_SUITE_MODE}")"
  printf "\"retry_count\":\"%s\"," "$(json_escape "${RETRY_COUNT}")"
  printf "\"dry_run\":\"%s\"," "$(json_escape "${DRY_RUN}")"
  printf "\"print_summary_json\":\"%s\"," "$(json_escape "${PRINT_SUMMARY_JSON}")"
  printf "\"test_files_count\":%s," "${#TEST_FILES[@]}"
  printf "\"failed_tests_count\":%s," "${#FAILED_TESTS[@]}"
  printf "\"test_files\":"
  json_array_from_args "${TEST_FILES[@]}"
  printf ",\"summary_entries\":"
  json_array_from_args "${TEST_RUN_SUMMARY[@]}"
  printf ",\"failed_tests\":"
  json_array_from_args "${FAILED_TESTS[@]}"
  printf ",\"artifacts_dir\":\"%s\"," "$(json_escape "${ARTIFACT_DIR}")"
  printf "\"summary_file\":\"%s\"," "$(json_escape "${SUMMARY_FILE}")"
  printf "\"config\":{"
  printf "\"device_id\":\"%s\"," "$(json_escape "${DEVICE_ID:-auto}")"
  printf "\"flavor\":\"%s\"," "$(json_escape "${FLAVOR}")"
  printf "\"dart_define\":\"%s\"," "$(json_escape "$(format_dart_define_for_summary "${DART_DEFINE}")")"
  printf "\"test_timeout_seconds\":\"%s\"," "$(json_escape "${TEST_TIMEOUT_SECONDS}")"
  printf "\"test_case_timeout\":\"%s\"," "$(json_escape "${TEST_CASE_TIMEOUT:-unset}")"
  printf "\"ignore_test_timeouts\":\"%s\"," "$(json_escape "${IGNORE_TEST_TIMEOUTS}")"
  printf "\"pub_get_once\":\"%s\"," "$(json_escape "${PUB_GET_ONCE}")"
  printf "\"skip_pub_get_once\":\"%s\"," "$(json_escape "${SKIP_PUB_GET_ONCE}")"
  printf "\"timeout_recovery_reruns\":\"%s\"," "$(json_escape "${TIMEOUT_RECOVERY_RERUNS}")"
  printf "\"device_recovery_enabled\":\"%s\"," "$(json_escape "${DEVICE_RECOVERY_ENABLED}")"
  printf "\"device_recovery_retry_count\":\"%s\"," "$(json_escape "${DEVICE_RECOVERY_RETRY_COUNT}")"
  printf "\"device_recovery_wait_seconds\":\"%s\"," "$(json_escape "${DEVICE_RECOVERY_WAIT_SECONDS}")"
  printf "\"allow_emulator_reboot\":\"%s\"" "$(json_escape "${ALLOW_EMULATOR_REBOOT}")"
  printf "}}"
  printf "\n"
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
    --summary-file)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --summary-file" >&2
        exit 2
      fi
      SUMMARY_FILE="$1"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --print-summary-json)
      PRINT_SUMMARY_JSON=1
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
    --pub-get-once)
      PUB_GET_ONCE=1
      ;;
    --no-pub-get-once)
      PUB_GET_ONCE=0
      ;;
    --pub-get-timeout)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --pub-get-timeout" >&2
        exit 2
      fi
      PUB_GET_TIMEOUT_SECONDS="$1"
      ;;
    --skip-pub-get)
      SKIP_PUB_GET_ONCE=1
      ;;
    --no-skip-pub-get)
      SKIP_PUB_GET_ONCE=0
      ;;
    --combined-suite)
      COMBINED_SUITE_MODE=1
      ;;
    --no-combined-suite)
      COMBINED_SUITE_MODE=0
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

VALIDATION_ERRORS=()

add_validation_error() {
  VALIDATION_ERRORS+=("$1")
}

validate_non_negative_integer() {
  local value="$1"
  local message_prefix="$2"
  if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
    add_validation_error "${message_prefix}${value}"
  fi
}

validate_binary_flag() {
  local value="$1"
  local message_prefix="$2"
  if ! [[ "${value}" =~ ^[01]$ ]]; then
    add_validation_error "${message_prefix}${value}"
  fi
}

emit_validation_errors_and_exit() {
  if (( ${#VALIDATION_ERRORS[@]} == 0 )); then
    return 0
  fi

  echo "configuration validation failed (${#VALIDATION_ERRORS[@]}):" >&2
  local validation_error
  for validation_error in "${VALIDATION_ERRORS[@]}"; do
    echo "  - ${validation_error}" >&2
  done
  exit 2
}

validate_non_negative_integer "${RETRY_COUNT}" "--retry must be a non-negative integer, got: "
validate_non_negative_integer "${TEST_TIMEOUT_SECONDS}" "--timeout must be a non-negative integer, got: "
validate_non_negative_integer "${ADB_TIMEOUT_SECONDS}" "FLUTTER_ADB_TIMEOUT_SECONDS must be a non-negative integer, got: "
validate_binary_flag "${DEVICE_RECOVERY_ENABLED}" "device recovery enabled flag must be 0 or 1, got: "
validate_non_negative_integer "${DEVICE_RECOVERY_RETRY_COUNT}" "device recovery retry count must be a non-negative integer, got: "
validate_non_negative_integer "${DEVICE_RECOVERY_WAIT_SECONDS}" "device recovery timeout must be a non-negative integer, got: "
validate_binary_flag "${ALLOW_EMULATOR_REBOOT}" "allow emulator reboot flag must be 0 or 1, got: "
validate_non_negative_integer "${TIMEOUT_RECOVERY_RERUNS}" "timeout recovery rerun count must be a non-negative integer, got: "
validate_binary_flag "${IGNORE_TEST_TIMEOUTS}" "FLUTTER_TEST_IGNORE_TIMEOUTS must be 0 or 1, got: "
validate_binary_flag "${PUB_GET_ONCE}" "pub-get-once flag must be 0 or 1, got: "
validate_non_negative_integer "${PUB_GET_TIMEOUT_SECONDS}" "pub-get-timeout must be a non-negative integer, got: "
validate_binary_flag "${SKIP_PUB_GET_ONCE}" "skip-pub-get flag must be 0 or 1, got: "
validate_binary_flag "${COMBINED_SUITE_MODE}" "combined-suite flag must be 0 or 1, got: "
validate_binary_flag "${DRY_RUN}" "dry-run flag must be 0 or 1, got: "
validate_binary_flag "${PRINT_SUMMARY_JSON}" "print-summary-json flag must be 0 or 1, got: "

if [[ "${#TEST_FILES[@]}" -eq 0 ]]; then
  add_validation_error "no integration tests selected"
fi

DEDUPED_TEST_FILES=()
DUPLICATE_TEST_COUNT=0
for test_file in "${TEST_FILES[@]}"; do
  is_duplicate=0
  for existing_test in "${DEDUPED_TEST_FILES[@]}"; do
    if [[ "${existing_test}" == "${test_file}" ]]; then
      is_duplicate=1
      break
    fi
  done
  if (( is_duplicate == 1 )); then
    DUPLICATE_TEST_COUNT=$((DUPLICATE_TEST_COUNT + 1))
    continue
  fi
  DEDUPED_TEST_FILES+=("${test_file}")
done
if (( DUPLICATE_TEST_COUNT > 0 )); then
  log "deduplicated ${DUPLICATE_TEST_COUNT} duplicate test entries"
fi
TEST_FILES=("${DEDUPED_TEST_FILES[@]}")

for test_file in "${TEST_FILES[@]}"; do
  if [[ ! -f "${test_file}" ]]; then
    add_validation_error "integration test file not found: ${test_file}"
  fi
done

if [[ -z "${SUMMARY_FILE}" ]]; then
  SUMMARY_FILE="${ARTIFACT_DIR}/suite-summary.txt"
fi

emit_validation_errors_and_exit

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
  local log_file="$1"
  shift
  local test_path
  local cmd=(
    flutter test
    --flavor "${FLAVOR}"
    --dart-define="${DART_DEFINE}"
  )
  for test_path in "$@"; do
    cmd+=("${test_path}")
  done
  if [[ -n "${TEST_CASE_TIMEOUT}" ]]; then
    cmd+=(--timeout "${TEST_CASE_TIMEOUT}")
  fi
  if (( PUB_GET_ONCE == 1 )); then
    cmd+=(--no-pub)
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

run_pub_get_once() {
  if (( SKIP_PUB_GET_ONCE == 1 )); then
    if [[ ! -f ".dart_tool/package_config.json" ]]; then
      echo "skip-pub-get requested but .dart_tool/package_config.json is missing" >&2
      return 2
    fi
    log "skipping flutter pub get once (requested)"
    return 0
  fi

  log "running flutter pub get once before integration suite"
  if [[ -n "${TIMEOUT_BIN}" ]] && (( PUB_GET_TIMEOUT_SECONDS > 0 )); then
    "${TIMEOUT_BIN}" --signal=TERM --kill-after=15s "${PUB_GET_TIMEOUT_SECONDS}s" flutter pub get
  else
    flutter pub get
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
  run_flutter_test "${log_file}" "${file}"
}

run_combined_suite_invocation() {
  local log_file="$1"

  : > "${log_file}"
  if ! ensure_device_ready_for_run; then
    echo "[integration] device not ready before running combined suite" | tee -a "${log_file}" >/dev/null
    return 1
  fi

  run_adb logcat -c >/dev/null 2>&1 || true
  run_flutter_test "${log_file}" "${TEST_FILES[@]}"
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
  local test_started_at
  test_started_at="$(date +%s)"
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
      local elapsed_seconds=$(( $(date +%s) - test_started_at ))
      local elapsed_label
      elapsed_label="$(format_duration "${elapsed_seconds}")"
      TEST_RUN_SUMMARY+=("${file}: PASS in ${elapsed_label} (attempt ${attempt}/${max_attempts})")
      log "duration: ${file} => ${elapsed_label}"
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

  local elapsed_seconds=$(( $(date +%s) - test_started_at ))
  local elapsed_label
  elapsed_label="$(format_duration "${elapsed_seconds}")"
  TEST_RUN_SUMMARY+=("${file}: FAIL in ${elapsed_label} (${max_attempts} attempts)")
  log "duration: ${file} => ${elapsed_label}"

  return 1
}

run_combined_suite_with_retry() {
  local max_attempts=$((RETRY_COUNT + 1))
  local attempt=1
  local suite_started_at
  suite_started_at="$(date +%s)"
  local suite_label="combined_suite"

  while (( attempt <= max_attempts )); do
    local log_file="${ARTIFACT_DIR}/${suite_label}.attempt${attempt}.test.log"
    local rerun_log_file="${ARTIFACT_DIR}/${suite_label}.attempt${attempt}.recovery-rerun.test.log"
    local exit_code=0
    local recovered_rerun=0
    local timeout_reruns_done=0
    log "running: ${suite_label} (${#TEST_FILES[@]} files, attempt ${attempt}/${max_attempts})"
    set +e
    run_combined_suite_invocation "${log_file}"
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
        log "${rerun_reason} detected for ${suite_label}; recovering and rerunning same attempt"
        if recover_device_liveness; then
          recovered_rerun=1
          if [[ "${rerun_reason}" == "timeout/termination" ]]; then
            timeout_reruns_done=$((timeout_reruns_done + 1))
          fi
          set +e
          run_combined_suite_invocation "${rerun_log_file}"
          exit_code=$?
          set -e
        else
          log "recovery did not restore a ready device for same-attempt rerun"
        fi
      fi
    fi

    if (( exit_code == 0 )); then
      local elapsed_seconds=$(( $(date +%s) - suite_started_at ))
      local elapsed_label
      elapsed_label="$(format_duration "${elapsed_seconds}")"
      TEST_RUN_SUMMARY+=("${suite_label}(${#TEST_FILES[@]} files): PASS in ${elapsed_label} (attempt ${attempt}/${max_attempts})")
      log "duration: ${suite_label} => ${elapsed_label}"
      log "passed: ${suite_label} (attempt ${attempt})"
      return 0
    fi
    if is_timeout_exit_code "${exit_code}"; then
      local timeout_label="configured timeout"
      if (( TEST_TIMEOUT_SECONDS > 0 )); then
        timeout_label="${TEST_TIMEOUT_SECONDS}s"
      fi
      log "timed out or terminated: ${suite_label} after ${timeout_label} (attempt ${attempt}, exit=${exit_code})"
    fi
    log "failed: ${suite_label} (attempt ${attempt})"
    collect_failure_artifacts "${suite_label}" "${attempt}"
    if (( attempt < max_attempts )); then
      log "retrying: ${suite_label}"
    fi
    attempt=$((attempt + 1))
  done

  local elapsed_seconds=$(( $(date +%s) - suite_started_at ))
  local elapsed_label
  elapsed_label="$(format_duration "${elapsed_seconds}")"
  TEST_RUN_SUMMARY+=("${suite_label}(${#TEST_FILES[@]} files): FAIL in ${elapsed_label} (${max_attempts} attempts)")
  log "duration: ${suite_label} => ${elapsed_label}"

  return 1
}

print_timing_summary() {
  local suite_elapsed=$(( $(date +%s) - SUITE_STARTED_AT ))
  log "timing summary:"
  if [[ "${#TEST_RUN_SUMMARY[@]}" -eq 0 ]]; then
    log "  - no test timing data"
  else
    local summary_line
    for summary_line in "${TEST_RUN_SUMMARY[@]}"; do
      log "  - ${summary_line}"
    done
  fi
  log "suite elapsed: $(format_duration "${suite_elapsed}")"
}

write_suite_summary_file() {
  if (( SUMMARY_WRITTEN == 1 )); then
    return 0
  fi

  SUITE_FINISHED_AT="$(date +%s)"
  SUITE_ELAPSED_SECONDS=$(( SUITE_FINISHED_AT - SUITE_STARTED_AT ))

  if [[ -n "${SUMMARY_FILE}" ]]; then
    mkdir -p "$(dirname "${SUMMARY_FILE}")"
  fi

  {
    echo "suite_started_at=${SUITE_STARTED_AT}"
    echo "suite_finished_at=${SUITE_FINISHED_AT}"
    echo "suite_elapsed_seconds=${SUITE_ELAPSED_SECONDS}"
    echo "suite_elapsed_human=$(format_duration "${SUITE_ELAPSED_SECONDS}")"
    echo "script_exit_code=${SCRIPT_EXIT_CODE}"
    if (( SCRIPT_EXIT_CODE == 0 )); then
      echo "script_result=success"
    else
      echo "script_result=failure"
    fi
    if [[ -n "${INTERRUPTED_REASON}" ]]; then
      echo "interrupted_reason=${INTERRUPTED_REASON}"
    fi
    echo "combined_suite_mode=${COMBINED_SUITE_MODE}"
    echo "retry_count=${RETRY_COUNT}"
    echo "test_files_count=${#TEST_FILES[@]}"
    local test_file
    for test_file in "${TEST_FILES[@]}"; do
      echo "test_file=${test_file}"
    done
    echo "config_entry=device_id=${DEVICE_ID:-auto}"
    echo "config_entry=dry_run=${DRY_RUN}"
    echo "config_entry=print_summary_json=${PRINT_SUMMARY_JSON}"
    echo "config_entry=flavor=${FLAVOR}"
    echo "config_entry=dart_define=$(format_dart_define_for_summary "${DART_DEFINE}")"
    echo "config_entry=test_timeout_seconds=${TEST_TIMEOUT_SECONDS}"
    echo "config_entry=test_case_timeout=${TEST_CASE_TIMEOUT:-unset}"
    echo "config_entry=ignore_test_timeouts=${IGNORE_TEST_TIMEOUTS}"
    echo "config_entry=pub_get_once=${PUB_GET_ONCE}"
    echo "config_entry=skip_pub_get_once=${SKIP_PUB_GET_ONCE}"
    echo "config_entry=timeout_recovery_reruns=${TIMEOUT_RECOVERY_RERUNS}"
    echo "config_entry=device_recovery_enabled=${DEVICE_RECOVERY_ENABLED}"
    echo "config_entry=device_recovery_retry_count=${DEVICE_RECOVERY_RETRY_COUNT}"
    echo "config_entry=device_recovery_wait_seconds=${DEVICE_RECOVERY_WAIT_SECONDS}"
    echo "config_entry=allow_emulator_reboot=${ALLOW_EMULATOR_REBOOT}"
    echo "summary_entries_count=${#TEST_RUN_SUMMARY[@]}"
    local summary_line
    for summary_line in "${TEST_RUN_SUMMARY[@]}"; do
      echo "summary_entry=${summary_line}"
    done
    echo "failed_tests_count=${#FAILED_TESTS[@]}"
    local failed
    for failed in "${FAILED_TESTS[@]}"; do
      echo "failed_test=${failed}"
    done
    echo "artifacts_dir=${ARTIFACT_DIR}"
  } > "${SUMMARY_FILE}"

  SUMMARY_WRITTEN=1
  log "suite summary file: ${SUMMARY_FILE}"
  if (( PRINT_SUMMARY_JSON == 1 )); then
    print_suite_summary_json
  fi
}

on_script_signal() {
  local signal_name="$1"
  local signal_exit="$2"
  INTERRUPTED_REASON="${signal_name}"
  exit "${signal_exit}"
}

finalize_summary_on_exit() {
  local exit_code="${1:-0}"
  SCRIPT_EXIT_CODE="${exit_code}"
  set +e
  write_suite_summary_file
  set -e
}

trap 'on_script_signal SIGTERM 143' TERM
trap 'on_script_signal SIGINT 130' INT
trap 'finalize_summary_on_exit $?' EXIT

if (( DRY_RUN == 1 )); then
  log "dry-run mode enabled: validation only (skip flutter/adb execution)"
  TEST_RUN_SUMMARY+=("dry_run(${#TEST_FILES[@]} files): SKIPPED (validation only)")
  log_effective_config
  print_timing_summary
  log "all integration tests passed (dry-run)"
  log "artifacts: ${ARTIFACT_DIR}"
  exit 0
fi

if (( PUB_GET_ONCE == 1 )); then
  run_pub_get_once
fi
if (( COMBINED_SUITE_MODE == 1 )); then
  log "combined suite mode enabled (${#TEST_FILES[@]} files)"
  if ! run_combined_suite_with_retry; then
    FAILED_TESTS+=("${TEST_FILES[@]}")
  fi
else
  for test_file in "${TEST_FILES[@]}"; do
    if ! run_test_with_retry "${test_file}"; then
      FAILED_TESTS+=("${test_file}")
    fi
  done
fi

print_timing_summary

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
