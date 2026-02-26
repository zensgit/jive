#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER_SCRIPT="${ROOT_DIR}/scripts/run_integration_tests.sh"

if [[ ! -f "${RUNNER_SCRIPT}" ]]; then
  echo "runner script not found: ${RUNNER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-runner-args.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

run_expect_exit2() {
  local case_name="$1"
  local expect_msg="$2"
  shift 2

  local err_file="${WORK_DIR}/${case_name}.stderr"
  set +e
  (
    cd "${ROOT_DIR}"
    bash "${RUNNER_SCRIPT}" "$@"
  ) > /dev/null 2> "${err_file}"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 2 ]]; then
    echo "expected exit 2 for ${case_name}, got ${rc}" >&2
    cat "${err_file}" >&2 || true
    exit 1
  fi

  if ! grep -Fq "${expect_msg}" "${err_file}"; then
    echo "expected message '${expect_msg}' for ${case_name}" >&2
    cat "${err_file}" >&2 || true
    exit 1
  fi
}

run_expect_success_with_output() {
  local case_name="$1"
  shift

  local out_file="${WORK_DIR}/${case_name}.stdout"
  local err_file="${WORK_DIR}/${case_name}.stderr"
  set +e
  (
    cd "${ROOT_DIR}"
    bash "${RUNNER_SCRIPT}" "$@"
  ) > "${out_file}" 2> "${err_file}"
  local rc=$?
  set -e

  if [[ "${rc}" -ne 0 ]]; then
    echo "expected success for ${case_name}, got ${rc}" >&2
    cat "${err_file}" >&2 || true
    exit 1
  fi

  cat "${out_file}"
}

run_expect_exit2 "invalid_retry" "must be a non-negative integer" \
  --test integration_test/calendar_date_picker_flow_test.dart \
  --retry invalid \
  emulator-5554

run_expect_exit2 "missing_test_value" "missing value for --test" \
  --test

run_expect_exit2 "missing_retry_value" "missing value for --retry" \
  --retry

run_expect_exit2 "missing_summary_json_file_value" "missing value for --summary-json-file" \
  --summary-json-file

run_expect_exit2 "missing_test_file" "integration test file not found" \
  --test integration_test/does_not_exist_smoke.dart \
  emulator-5554

run_expect_exit2 "unknown_option" "unknown option: --does-not-exist" \
  --does-not-exist

MULTI_INVALID_ERR="${WORK_DIR}/multi_invalid.stderr"
MULTI_INVALID_OUT="${WORK_DIR}/multi_invalid.stdout"
MULTI_INVALID_SUMMARY="${WORK_DIR}/multi-invalid-summary.txt"
MULTI_INVALID_SUMMARY_JSON="${WORK_DIR}/multi-invalid-summary.json"
MULTI_INVALID_ARTIFACT_DIR="${WORK_DIR}/multi-invalid-artifacts"
set +e
(
  cd "${ROOT_DIR}"
  FLUTTER_TEST_TIMEOUT_SECONDS=bad \
  FLUTTER_TEST_IGNORE_TIMEOUTS=9 \
  FLUTTER_TEST_PUB_GET_ONCE=9 \
  bash "${RUNNER_SCRIPT}" \
    --dry-run \
    --print-summary-json \
    --summary-file "${MULTI_INVALID_SUMMARY}" \
    --summary-json-file "${MULTI_INVALID_SUMMARY_JSON}" \
    --artifact-dir "${MULTI_INVALID_ARTIFACT_DIR}" \
    --test integration_test/does_not_exist_smoke.dart \
    --retry invalid \
    emulator-5554
) > "${MULTI_INVALID_OUT}" 2> "${MULTI_INVALID_ERR}"
MULTI_INVALID_RC=$?
set -e

if [[ "${MULTI_INVALID_RC}" -ne 2 ]]; then
  echo "expected exit 2 for multi_invalid_validation, got ${MULTI_INVALID_RC}" >&2
  cat "${MULTI_INVALID_ERR}" >&2 || true
  exit 1
fi
grep -Fq "configuration validation failed (5):" "${MULTI_INVALID_ERR}"
grep -Fq -- "--retry must be a non-negative integer, got: invalid" "${MULTI_INVALID_ERR}"
grep -Fq -- "--timeout must be a non-negative integer, got: bad" "${MULTI_INVALID_ERR}"
grep -Fq "FLUTTER_TEST_IGNORE_TIMEOUTS must be 0 or 1, got: 9" "${MULTI_INVALID_ERR}"
grep -Fq "pub-get-once flag must be 0 or 1, got: 9" "${MULTI_INVALID_ERR}"
grep -Fq "integration test file not found: integration_test/does_not_exist_smoke.dart" "${MULTI_INVALID_ERR}"
if [[ ! -f "${MULTI_INVALID_SUMMARY}" ]]; then
  echo "expected validation failure summary file: ${MULTI_INVALID_SUMMARY}" >&2
  exit 1
fi
if [[ ! -f "${MULTI_INVALID_SUMMARY_JSON}" ]]; then
  echo "expected validation failure summary json file: ${MULTI_INVALID_SUMMARY_JSON}" >&2
  exit 1
fi
grep -Fq "script_exit_code=2" "${MULTI_INVALID_SUMMARY}"
grep -Fq "script_result=failure" "${MULTI_INVALID_SUMMARY}"
grep -Fq "interrupted_reason=configuration_validation_failed" "${MULTI_INVALID_SUMMARY}"
grep -Fq "summary_entry=validation_failed(5 errors): FAIL (preflight)" "${MULTI_INVALID_SUMMARY}"
grep -Fq "validation_errors_count=5" "${MULTI_INVALID_SUMMARY}"
grep -Fq "validation_error=--retry must be a non-negative integer, got: invalid" "${MULTI_INVALID_SUMMARY}"
jq -e \
  '
  (.script_exit_code == 2) and
  (.script_result == "failure") and
  (.interrupted_reason == "configuration_validation_failed") and
  (.validation_errors_count == 5) and
  (.validation_errors | type == "array" and length == 5) and
  (.summary_entries | type == "array" and .[0] == "validation_failed(5 errors): FAIL (preflight)")
  ' \
  "${MULTI_INVALID_SUMMARY_JSON}" >/dev/null
tail -n 1 "${MULTI_INVALID_OUT}" | jq -e '.script_exit_code == 2 and .validation_errors_count == 5' >/dev/null

LIST_OUTPUT="$(run_expect_success_with_output "list_defaults" --list)"
if ! echo "${LIST_OUTPUT}" | grep -Fq "integration_test/calendar_date_picker_flow_test.dart"; then
  echo "expected --list to contain calendar_date_picker_flow_test.dart" >&2
  exit 1
fi
if ! echo "${LIST_OUTPUT}" | grep -Fq "integration_test/transaction_search_flow_test.dart"; then
  echo "expected --list to contain transaction_search_flow_test.dart" >&2
  exit 1
fi

DRY_RUN_SUMMARY="${WORK_DIR}/dry-run-summary.txt"
DRY_RUN_SUMMARY_JSON="${WORK_DIR}/dry-run-summary.json"
DRY_RUN_ARTIFACT_DIR="${WORK_DIR}/dry-run-artifacts"
DRY_RUN_STDOUT="${WORK_DIR}/dry-run.stdout"
DRY_RUN_STDERR="${WORK_DIR}/dry-run.stderr"
set +e
(
  cd "${ROOT_DIR}"
  FLUTTER_TEST_DART_DEFINE="API_TOKEN=abc123,JIVE_E2E=true" \
  bash "${RUNNER_SCRIPT}" \
    --dry-run \
    --print-summary-json \
    --test integration_test/calendar_date_picker_flow_test.dart \
    --test integration_test/calendar_date_picker_flow_test.dart \
    --summary-file "${DRY_RUN_SUMMARY}" \
    --summary-json-file "${DRY_RUN_SUMMARY_JSON}" \
    --artifact-dir "${DRY_RUN_ARTIFACT_DIR}" \
    emulator-5554
) > "${DRY_RUN_STDOUT}" 2> "${DRY_RUN_STDERR}"
DRY_RUN_RC=$?
set -e

if [[ "${DRY_RUN_RC}" -ne 0 ]]; then
  echo "expected --dry-run path to succeed, got ${DRY_RUN_RC}" >&2
  cat "${DRY_RUN_STDERR}" >&2 || true
  exit 1
fi
if ! grep -Fq "dry-run mode enabled" "${DRY_RUN_STDOUT}"; then
  echo "expected dry-run log to be present" >&2
  cat "${DRY_RUN_STDOUT}" >&2 || true
  exit 1
fi
if ! grep -Fq "test_files_count=1" "${DRY_RUN_STDOUT}"; then
  echo "expected dry-run log to show deduplicated test count" >&2
  cat "${DRY_RUN_STDOUT}" >&2 || true
  exit 1
fi
if [[ ! -f "${DRY_RUN_SUMMARY}" ]]; then
  echo "expected dry-run summary file: ${DRY_RUN_SUMMARY}" >&2
  exit 1
fi
if [[ ! -f "${DRY_RUN_SUMMARY_JSON}" ]]; then
  echo "expected dry-run summary json file: ${DRY_RUN_SUMMARY_JSON}" >&2
  exit 1
fi
grep -Fq "script_result=success" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=dry_run=1" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=print_summary_json=1" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=summary_json_file=${DRY_RUN_SUMMARY_JSON}" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=summary_schema_version=1" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=summary_generator_version=run_integration_tests.sh@v1" "${DRY_RUN_SUMMARY}"
grep -Fq "test_files_count=1" "${DRY_RUN_SUMMARY}"
grep -Fq "summary_entry=dry_run(1 files): SKIPPED (validation only)" "${DRY_RUN_SUMMARY}"
grep -Fq "config_entry=dart_define=API_TOKEN=<redacted>,JIVE_E2E=true" "${DRY_RUN_SUMMARY}"
grep -Fq "\"schema_version\":1" "${DRY_RUN_STDOUT}"
grep -Fq "\"generator_version\":\"run_integration_tests.sh@v1\"" "${DRY_RUN_STDOUT}"
grep -Fq "\"script_result\":\"success\"" "${DRY_RUN_STDOUT}"
grep -Fq "\"dry_run\":\"1\"" "${DRY_RUN_STDOUT}"
grep -Fq "\"print_summary_json\":\"1\"" "${DRY_RUN_STDOUT}"
grep -Fq "\"summary_entries\":[\"dry_run(1 files): SKIPPED (validation only)\"]" "${DRY_RUN_STDOUT}"
jq -e '.summary_json_file == "'"${DRY_RUN_SUMMARY_JSON}"'" and .summary_file == "'"${DRY_RUN_SUMMARY}"'" and .script_result == "success" and .schema_version == 1 and .generator_version == "run_integration_tests.sh@v1"' "${DRY_RUN_SUMMARY_JSON}" >/dev/null

echo "integration runner args smoke: OK"
