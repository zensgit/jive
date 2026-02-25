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

  if ! grep -q "${expect_msg}" "${err_file}"; then
    echo "expected message '${expect_msg}' for ${case_name}" >&2
    cat "${err_file}" >&2 || true
    exit 1
  fi
}

run_expect_exit2 "invalid_retry" "must be a non-negative integer" \
  --test integration_test/calendar_date_picker_flow_test.dart \
  --retry invalid \
  emulator-5554

run_expect_exit2 "missing_test_file" "integration test file not found" \
  --test integration_test/does_not_exist_smoke.dart \
  emulator-5554

run_expect_exit2 "unknown_option" "unknown option: --does-not-exist" \
  --does-not-exist

echo "integration runner args smoke: OK"
