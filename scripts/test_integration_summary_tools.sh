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
ARTIFACTS_DIR="${WORK_DIR}/artifacts"

bash "${INIT_SCRIPT}" "${SUMMARY_FILE}" "${ARTIFACTS_DIR}"

grep -q '^script_result=unknown$' "${SUMMARY_FILE}"
grep -q '^script_exit_code=999$' "${SUMMARY_FILE}"
grep -q '^interrupted_reason=not_started_or_emulator_boot_failure$' "${SUMMARY_FILE}"
grep -q "^artifacts_dir=${ARTIFACTS_DIR}$" "${SUMMARY_FILE}"

PLACEHOLDER_OUT="${WORK_DIR}/placeholder.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${PLACEHOLDER_OUT}"
grep -q "summary is placeholder-only" "${PLACEHOLDER_OUT}"
grep -q "\`unknown\` (exit \`999\`)" "${PLACEHOLDER_OUT}"

cat >> "${SUMMARY_FILE}" <<'EOF'
summary_entry=combined_suite(2 files): FAIL in 0m01s (1 attempts)
failed_test=integration_test/transaction_search_flow_test.dart
EOF

REAL_OUT="${WORK_DIR}/real.out"
bash "${RENDER_SCRIPT}" "${SUMMARY_FILE}" > "${REAL_OUT}"
grep -q "### Test timing" "${REAL_OUT}"
grep -q "### Failed tests" "${REAL_OUT}"
grep -q "integration_test/transaction_search_flow_test.dart" "${REAL_OUT}"

echo "integration summary tools: OK"
