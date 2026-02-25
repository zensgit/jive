#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${1:-}"
ARTIFACTS_DIR="${2:-}"

if [[ -z "${SUMMARY_FILE}" ]]; then
  echo "usage: bash scripts/init_integration_summary_placeholder.sh <summary-file> [artifacts-dir]" >&2
  exit 2
fi

if [[ -z "${ARTIFACTS_DIR}" ]]; then
  ARTIFACTS_DIR="$(dirname "${SUMMARY_FILE}")"
fi

mkdir -p "$(dirname "${SUMMARY_FILE}")"

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
EOF
