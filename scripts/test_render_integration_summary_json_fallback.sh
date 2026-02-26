#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER_SCRIPT="${ROOT_DIR}/scripts/render_integration_summary.sh"

if [[ ! -x "${RENDER_SCRIPT}" ]]; then
  echo "expected executable script: ${RENDER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-summary-json-fallback.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SUMMARY_FILE="${WORK_DIR}/suite-summary.txt"
SUMMARY_JSON_FILE="${WORK_DIR}/custom-suite-summary.json"

cat > "${SUMMARY_FILE}" <<EOF
suite_started_at=1
suite_finished_at=2
suite_elapsed_seconds=1
suite_elapsed_human=0m01s
script_exit_code=0
script_result=success
combined_suite_mode=1
retry_count=0
test_files_count=1
summary_entries_count=1
summary_entry=combined_suite(1 files): PASS in 0m01s (attempt 1/1)
failed_tests_count=0
artifacts_dir=${WORK_DIR}
config_entry=summary_json_file=${SUMMARY_JSON_FILE}
EOF

cat > "${SUMMARY_JSON_FILE}" <<'EOF'
{"schema_version":1,"generator_version":"run_integration_tests.sh@v1","dry_run":"0","print_summary_json":"0"}
EOF

VALID_OUT="${WORK_DIR}/valid.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${VALID_OUT}"
grep -q "### Summary JSON" "${VALID_OUT}"
grep -q "JSON summary file: \`${SUMMARY_JSON_FILE}\`" "${VALID_OUT}"
grep -q "Schema version: \`1\`" "${VALID_OUT}"
grep -q "Generator version: \`run_integration_tests.sh@v1\`" "${VALID_OUT}"

printf '{"broken_json":\n' > "${SUMMARY_JSON_FILE}"
INVALID_OUT="${WORK_DIR}/invalid.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${INVALID_OUT}"
grep -q "invalid JSON content; skipping JSON field rendering" "${INVALID_OUT}"

rm -f "${SUMMARY_JSON_FILE}"
MISSING_OUT="${WORK_DIR}/missing.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${MISSING_OUT}"
grep -q "JSON summary file not found: \`${SUMMARY_JSON_FILE}\`" "${MISSING_OUT}"

echo "integration summary json fallback: OK"
