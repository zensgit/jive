#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${1:-}"
SUMMARY_JSON_FILE="${2:-${SUMMARY_JSON_FILE:-}}"
RAW_SUMMARY_MAX_LINES="${SUMMARY_RAW_MAX_LINES:-200}"
JQ_BIN="$(command -v jq || true)"

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
  echo "usage: bash scripts/render_integration_summary.sh <suite-summary-file> [suite-summary-json-file]" >&2
  exit 2
fi

if [[ ! -f "${SUMMARY_FILE}" ]]; then
  print_missing_summary
  exit 0
fi

if [[ -z "${SUMMARY_JSON_FILE}" ]]; then
  SUMMARY_JSON_CANDIDATE="${SUMMARY_FILE%.txt}.json"
  if [[ "${SUMMARY_JSON_CANDIDATE}" != "${SUMMARY_FILE}" ]]; then
    SUMMARY_JSON_FILE="${SUMMARY_JSON_CANDIDATE}"
  fi
fi

if ! [[ "${RAW_SUMMARY_MAX_LINES}" =~ ^[0-9]+$ ]]; then
  RAW_SUMMARY_MAX_LINES=200
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

if [[ -n "${SUMMARY_JSON_FILE}" ]]; then
  echo "### Summary JSON"
  if [[ ! -f "${SUMMARY_JSON_FILE}" ]]; then
    echo "- JSON summary file not found: \`${SUMMARY_JSON_FILE}\`"
  elif [[ -z "${JQ_BIN}" ]]; then
    echo "- JSON summary file: \`${SUMMARY_JSON_FILE}\`"
    echo "- \`jq\` not found; skipping JSON field rendering."
  else
    JSON_SCHEMA_VERSION="$("${JQ_BIN}" -r '.schema_version // "unknown"' "${SUMMARY_JSON_FILE}" 2>/dev/null || echo "unknown")"
    JSON_GENERATOR_VERSION="$("${JQ_BIN}" -r '.generator_version // "unknown"' "${SUMMARY_JSON_FILE}" 2>/dev/null || echo "unknown")"
    JSON_DRY_RUN="$("${JQ_BIN}" -r '.dry_run // "unknown"' "${SUMMARY_JSON_FILE}" 2>/dev/null || echo "unknown")"
    JSON_PRINT_SUMMARY="$("${JQ_BIN}" -r '.print_summary_json // "unknown"' "${SUMMARY_JSON_FILE}" 2>/dev/null || echo "unknown")"
    echo "- JSON summary file: \`${SUMMARY_JSON_FILE}\`"
    echo "- Schema version: \`${JSON_SCHEMA_VERSION}\`"
    echo "- Generator version: \`${JSON_GENERATOR_VERSION}\`"
    echo "- dry_run: \`${JSON_DRY_RUN}\`"
    echo "- print_summary_json: \`${JSON_PRINT_SUMMARY}\`"
  fi
  echo ""
fi

echo "### Raw summary"
echo '```text'
TOTAL_SUMMARY_LINES="$(wc -l < "${SUMMARY_FILE}")"
TOTAL_SUMMARY_LINES="${TOTAL_SUMMARY_LINES//[[:space:]]/}"
RAW_SUMMARY_TRUNCATED=0
if (( RAW_SUMMARY_MAX_LINES == 0 )); then
  cat "${SUMMARY_FILE}"
elif (( TOTAL_SUMMARY_LINES > RAW_SUMMARY_MAX_LINES )); then
  head -n "${RAW_SUMMARY_MAX_LINES}" "${SUMMARY_FILE}"
  RAW_SUMMARY_TRUNCATED=1
else
  cat "${SUMMARY_FILE}"
fi
echo '```'

if (( RAW_SUMMARY_TRUNCATED == 1 )); then
  echo "_Raw summary truncated: showing first ${RAW_SUMMARY_MAX_LINES} of ${TOTAL_SUMMARY_LINES} lines._"
fi
