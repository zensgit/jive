#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER_SCRIPT="${ROOT_DIR}/scripts/run_integration_tests.sh"

if [[ ! -f "${RUNNER_SCRIPT}" ]]; then
  echo "runner script not found: ${RUNNER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-runner-summary-json.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SUMMARY_FILE="${WORK_DIR}/suite-summary.txt"
SUMMARY_JSON_FILE="${WORK_DIR}/suite-summary.json"
ARTIFACT_DIR="${WORK_DIR}/artifacts"
STDOUT_FILE="${WORK_DIR}/runner.stdout"
STDERR_FILE="${WORK_DIR}/runner.stderr"
STDOUT_JSON_FILE="${WORK_DIR}/runner.stdout.json"

set +e
(
  cd "${ROOT_DIR}"
  FLUTTER_TEST_DART_DEFINE="API_TOKEN=abc123,JIVE_E2E=true" \
  bash "${RUNNER_SCRIPT}" \
    --dry-run \
    --print-summary-json \
    --summary-file "${SUMMARY_FILE}" \
    --summary-json-file "${SUMMARY_JSON_FILE}" \
    --artifact-dir "${ARTIFACT_DIR}" \
    --test integration_test/calendar_date_picker_flow_test.dart \
    emulator-5554
) > "${STDOUT_FILE}" 2> "${STDERR_FILE}"
RC=$?
set -e

if [[ "${RC}" -ne 0 ]]; then
  echo "expected summary-json run to succeed, got ${RC}" >&2
  cat "${STDERR_FILE}" >&2 || true
  exit 1
fi

if [[ ! -f "${SUMMARY_FILE}" ]]; then
  echo "missing summary file: ${SUMMARY_FILE}" >&2
  exit 1
fi
if [[ ! -f "${SUMMARY_JSON_FILE}" ]]; then
  echo "missing summary json file: ${SUMMARY_JSON_FILE}" >&2
  exit 1
fi

tail -n 1 "${STDOUT_FILE}" > "${STDOUT_JSON_FILE}"
jq -e . "${STDOUT_JSON_FILE}" >/dev/null
jq -e . "${SUMMARY_JSON_FILE}" >/dev/null
if ! cmp -s "${STDOUT_JSON_FILE}" "${SUMMARY_JSON_FILE}"; then
  echo "stdout json and summary-json-file output differ" >&2
  exit 1
fi

jq -e \
  --arg summary_file "${SUMMARY_FILE}" \
  --arg summary_json_file "${SUMMARY_JSON_FILE}" \
  --arg artifact_dir "${ARTIFACT_DIR}" \
  '
  (.suite_started_at | type == "number") and
  (.suite_finished_at | type == "number") and
  (.suite_elapsed_seconds | type == "number") and
  (.suite_elapsed_human | type == "string") and
  (.script_exit_code == 0) and
  (.script_result == "success") and
  (.interrupted_reason == null) and
  (.combined_suite_mode == "0") and
  (.dry_run == "1") and
  (.print_summary_json == "1") and
  (.test_files_count == 1) and
  (.failed_tests_count == 0) and
  (.summary_file == $summary_file) and
  (.summary_json_file == $summary_json_file) and
  (.artifacts_dir == $artifact_dir) and
  (.test_files | type == "array" and length == 1 and .[0] == "integration_test/calendar_date_picker_flow_test.dart") and
  (.summary_entries | type == "array" and length == 1 and .[0] == "dry_run(1 files): SKIPPED (validation only)") and
  (.failed_tests | type == "array" and length == 0) and
  (.config | type == "object") and
  (.config.device_id == "emulator-5554") and
  (.config.flavor == "dev") and
  (.config.dart_define == "API_TOKEN=<redacted>,JIVE_E2E=true")
  ' \
  "${SUMMARY_JSON_FILE}" >/dev/null

grep -Fq "config_entry=summary_json_file=${SUMMARY_JSON_FILE}" "${SUMMARY_FILE}"

echo "integration runner summary json schema smoke: OK"
