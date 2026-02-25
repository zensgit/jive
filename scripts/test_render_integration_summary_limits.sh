#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER_SCRIPT="${ROOT_DIR}/scripts/render_integration_summary.sh"

if [[ ! -x "${RENDER_SCRIPT}" ]]; then
  echo "expected executable script: ${RENDER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-summary-limits.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SUMMARY_FILE="${WORK_DIR}/suite-summary.txt"
{
  echo "suite_started_at=1"
  echo "suite_finished_at=2"
  echo "suite_elapsed_seconds=1"
  echo "suite_elapsed_human=0m01s"
  echo "script_exit_code=0"
  echo "script_result=success"
  echo "combined_suite_mode=1"
  echo "retry_count=0"
  echo "test_files_count=1"
  echo "summary_entries_count=1"
  echo "summary_entry=combined_suite(1 files): PASS in 0m01s (attempt 1/1)"
  echo "failed_tests_count=0"
  echo "artifacts_dir=${WORK_DIR}"
} > "${SUMMARY_FILE}"

for i in $(seq 1 140); do
  printf "extra_line_%03d=value_%03d\n" "${i}" "${i}" >> "${SUMMARY_FILE}"
done

LIMITED_OUT="${WORK_DIR}/limited.out"
SUMMARY_RAW_MAX_LINES=40 bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${LIMITED_OUT}"
grep -q "Raw summary truncated: showing first 40 of" "${LIMITED_OUT}"
grep -q "extra_line_020=value_020" "${LIMITED_OUT}"
if grep -q "extra_line_140=value_140" "${LIMITED_OUT}"; then
  echo "expected limited output to exclude tail summary lines" >&2
  exit 1
fi

UNLIMITED_OUT="${WORK_DIR}/unlimited.out"
SUMMARY_RAW_MAX_LINES=0 bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${UNLIMITED_OUT}"
if grep -q "Raw summary truncated" "${UNLIMITED_OUT}"; then
  echo "did not expect truncation notice when SUMMARY_RAW_MAX_LINES=0" >&2
  exit 1
fi
grep -q "extra_line_140=value_140" "${UNLIMITED_OUT}"

echo "integration summary limits: OK"
