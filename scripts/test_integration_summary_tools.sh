#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_SCRIPT="${ROOT_DIR}/scripts/init_integration_summary_placeholder.sh"
RENDER_SCRIPT="${ROOT_DIR}/scripts/render_integration_summary.sh"

for script_path in "${INIT_SCRIPT}" "${RENDER_SCRIPT}"; do
  if [[ ! -x "${script_path}" ]]; then
    echo "expected executable script: ${script_path}" >&2
    exit 1
  fi
done

WORK_DIR="$(mktemp -d /tmp/jive-summary-tools-test.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SUMMARY_FILE="${WORK_DIR}/suite-summary.txt"
SUMMARY_JSON_FILE="${WORK_DIR}/suite-summary.json"
ARTIFACTS_DIR="${WORK_DIR}/artifacts"

bash "${INIT_SCRIPT}" "${SUMMARY_FILE}" "${ARTIFACTS_DIR}" "${SUMMARY_JSON_FILE}"

grep -q '^script_result=unknown$' "${SUMMARY_FILE}"
grep -q '^script_exit_code=999$' "${SUMMARY_FILE}"
grep -q '^interrupted_reason=not_started_or_emulator_boot_failure$' "${SUMMARY_FILE}"
grep -q "^artifacts_dir=${ARTIFACTS_DIR}$" "${SUMMARY_FILE}"
grep -q "^config_entry=summary_schema_version=1$" "${SUMMARY_FILE}"
grep -q "^config_entry=summary_generator_version=init_integration_summary_placeholder.sh@v1$" "${SUMMARY_FILE}"
grep -q "^config_entry=summary_json_file=${SUMMARY_JSON_FILE}$" "${SUMMARY_FILE}"
if [[ ! -f "${SUMMARY_JSON_FILE}" ]]; then
  echo "expected placeholder summary json file: ${SUMMARY_JSON_FILE}" >&2
  exit 1
fi

PLACEHOLDER_OUT="${WORK_DIR}/placeholder.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" "${SUMMARY_JSON_FILE}" > "${PLACEHOLDER_OUT}"
grep -q "summary is placeholder-only" "${PLACEHOLDER_OUT}"
grep -q "\`unknown\` (exit \`999\`)" "${PLACEHOLDER_OUT}"
grep -q "### Summary JSON" "${PLACEHOLDER_OUT}"
grep -q "Schema version: \`1\`" "${PLACEHOLDER_OUT}"
grep -q "Generator version: \`init_integration_summary_placeholder.sh@v1\`" "${PLACEHOLDER_OUT}"

cat >> "${SUMMARY_FILE}" <<'EOF'
config_entry=device_id=emulator-5554
config_entry=flavor=dev
summary_entry=combined_suite(2 files): FAIL in 0m01s (1 attempts)
failed_test=integration_test/transaction_search_flow_test.dart
EOF

cat > "${SUMMARY_JSON_FILE}" <<EOF
{"schema_version":1,"generator_version":"run_integration_tests.sh@v1","dry_run":"0","print_summary_json":"0"}
EOF

REAL_OUT="${WORK_DIR}/real.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" "${SUMMARY_JSON_FILE}" > "${REAL_OUT}"
grep -q "### Test timing" "${REAL_OUT}"
grep -q "### Runtime config" "${REAL_OUT}"
grep -q "device_id=emulator-5554" "${REAL_OUT}"
grep -q "### Failed tests" "${REAL_OUT}"
grep -q "integration_test/transaction_search_flow_test.dart" "${REAL_OUT}"
grep -q "### Summary JSON" "${REAL_OUT}"
grep -q "Schema version: \`1\`" "${REAL_OUT}"
grep -q "Generator version: \`run_integration_tests.sh@v1\`" "${REAL_OUT}"

echo "integration summary tools: OK"
