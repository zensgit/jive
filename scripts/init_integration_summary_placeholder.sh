#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${1:-}"
ARTIFACTS_DIR="${2:-}"
SUMMARY_JSON_FILE="${3:-}"
SUMMARY_SCHEMA_VERSION="1"
SUMMARY_GENERATOR_VERSION="init_integration_summary_placeholder.sh@v1"

json_escape() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//\"/\\\"}"
  raw="${raw//$'\n'/\\n}"
  raw="${raw//$'\r'/\\r}"
  raw="${raw//$'\t'/\\t}"
  printf "%s" "${raw}"
}

if [[ -z "${SUMMARY_FILE}" ]]; then
  echo "usage: bash scripts/init_integration_summary_placeholder.sh <summary-file> [artifacts-dir] [summary-json-file]" >&2
  exit 2
fi

if [[ -z "${ARTIFACTS_DIR}" ]]; then
  ARTIFACTS_DIR="$(dirname "${SUMMARY_FILE}")"
fi

if [[ -z "${SUMMARY_JSON_FILE}" ]]; then
  if [[ "${SUMMARY_FILE}" == *.txt ]]; then
    SUMMARY_JSON_FILE="${SUMMARY_FILE%.txt}.json"
  else
    SUMMARY_JSON_FILE="${SUMMARY_FILE}.json"
  fi
fi

mkdir -p "$(dirname "${SUMMARY_FILE}")"
mkdir -p "$(dirname "${SUMMARY_JSON_FILE}")"

cat > "${SUMMARY_FILE}" <<EOF
suite_started_at=0
suite_finished_at=0
suite_elapsed_seconds=0
suite_elapsed_human=unknown
script_exit_code=999
script_result=unknown
interrupted_reason=not_started_or_emulator_boot_failure
combined_suite_mode=1
retry_count=0
test_files_count=0
summary_entries_count=0
failed_tests_count=0
artifacts_dir=${ARTIFACTS_DIR}
config_entry=summary_schema_version=${SUMMARY_SCHEMA_VERSION}
config_entry=summary_generator_version=${SUMMARY_GENERATOR_VERSION}
config_entry=summary_json_file=${SUMMARY_JSON_FILE}
EOF

cat > "${SUMMARY_JSON_FILE}" <<EOF
{"schema_version":${SUMMARY_SCHEMA_VERSION},"generator_version":"$(json_escape "${SUMMARY_GENERATOR_VERSION}")","suite_started_at":0,"suite_finished_at":0,"suite_elapsed_seconds":0,"suite_elapsed_human":"unknown","script_exit_code":999,"script_result":"unknown","interrupted_reason":"not_started_or_emulator_boot_failure","combined_suite_mode":"1","retry_count":"0","dry_run":"0","print_summary_json":"0","test_files_count":0,"failed_tests_count":0,"test_files":[],"summary_entries":[],"failed_tests":[],"artifacts_dir":"$(json_escape "${ARTIFACTS_DIR}")","summary_file":"$(json_escape "${SUMMARY_FILE}")","summary_json_file":"$(json_escape "${SUMMARY_JSON_FILE}")","config":{"summary_schema_version":"${SUMMARY_SCHEMA_VERSION}","summary_generator_version":"$(json_escape "${SUMMARY_GENERATOR_VERSION}")"}}
EOF
