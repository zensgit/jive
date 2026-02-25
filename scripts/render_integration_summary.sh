#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${1:-}"

print_missing_summary() {
  echo "## Android integration summary"
  echo ""
  echo "summary file not found: ${SUMMARY_FILE}"
}

extract_single() {
  local key="$1"
  local fallback="${2:-unknown}"
  local value=""
  value="$(awk -F= -v k="${key}" '$1==k{print substr($0, index($0, "=")+1); exit}' "${SUMMARY_FILE}" || true)"
  if [[ -z "${value}" ]]; then
    echo "${fallback}"
    return 0
  fi
  echo "${value}"
}

if [[ -z "${SUMMARY_FILE}" ]]; then
  echo "usage: bash scripts/render_integration_summary.sh <suite-summary-file>" >&2
  exit 2
fi

if [[ ! -f "${SUMMARY_FILE}" ]]; then
  print_missing_summary
  exit 0
fi

SCRIPT_RESULT="$(extract_single script_result)"
SCRIPT_EXIT_CODE="$(extract_single script_exit_code)"
SUITE_ELAPSED="$(extract_single suite_elapsed_human)"
FAILED_COUNT="$(extract_single failed_tests_count)"
ARTIFACTS_DIR="$(extract_single artifacts_dir)"
INTERRUPTED_REASON="$(extract_single interrupted_reason "")"

echo "## Android integration summary"
echo ""
echo "- Result: \`${SCRIPT_RESULT}\` (exit \`${SCRIPT_EXIT_CODE}\`)"
echo "- Suite elapsed: \`${SUITE_ELAPSED}\`"
echo "- Failed tests: \`${FAILED_COUNT}\`"
echo "- Artifacts dir: \`${ARTIFACTS_DIR}\`"

if [[ -n "${INTERRUPTED_REASON}" ]]; then
  echo "- Interrupted reason: \`${INTERRUPTED_REASON}\`"
fi

if [[ "${SCRIPT_RESULT}" == "unknown" ]]; then
  echo ""
  echo "> summary is placeholder-only; integration script likely did not execute."
fi

echo ""
if grep -q '^summary_entry=' "${SUMMARY_FILE}"; then
  echo "### Test timing"
  while IFS= read -r line; do
    echo "- ${line#summary_entry=}"
  done < <(grep '^summary_entry=' "${SUMMARY_FILE}")
  echo ""
fi

if grep -q '^config_entry=' "${SUMMARY_FILE}"; then
  echo "### Runtime config"
  while IFS= read -r line; do
    echo "- ${line#config_entry=}"
  done < <(grep '^config_entry=' "${SUMMARY_FILE}")
  echo ""
fi

if grep -q '^failed_test=' "${SUMMARY_FILE}"; then
  echo "### Failed tests"
  while IFS= read -r line; do
    echo "- ${line#failed_test=}"
  done < <(grep '^failed_test=' "${SUMMARY_FILE}")
  echo ""
fi

echo "### Raw summary"
echo '```text'
cat "${SUMMARY_FILE}"
echo '```'
