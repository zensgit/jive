#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER_SCRIPT="${ROOT_DIR}/scripts/run_integration_tests.sh"

if [[ ! -f "${RUNNER_SCRIPT}" ]]; then
  echo "runner script not found: ${RUNNER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-runner-smoke.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

MOCK_BIN="${WORK_DIR}/mock-bin"
mkdir -p "${MOCK_BIN}"

cat > "${MOCK_BIN}/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "pub" && "${2:-}" == "get" ]]; then
  echo "mock flutter pub get"
  exit 0
fi

if [[ "${1:-}" == "devices" ]]; then
  echo "1 connected device"
  exit 0
fi

if [[ "${1:-}" == "test" ]]; then
  for arg in "$@"; do
    if [[ "${arg}" == *"transaction_search_flow_test.dart"* ]]; then
      echo "mock flutter test failure for ${arg}" >&2
      exit 1
    fi
  done
  echo "mock flutter test success"
  exit 0
fi

echo "mock flutter: unsupported command, treating as success: $*"
exit 0
EOF
chmod +x "${MOCK_BIN}/flutter"

cat > "${MOCK_BIN}/adb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-s" ]]; then
  shift 2
fi

case "${1:-}" in
  get-state)
    echo "device"
    ;;
  devices)
    printf 'List of devices attached\nemulator-5554\tdevice\n'
    ;;
  shell)
    if [[ "${2:-}" == "getprop" && "${3:-}" == "sys.boot_completed" ]]; then
      echo "1"
    fi
    ;;
  logcat|exec-out|pull|wait-for-device|reconnect|kill-server|start-server|reboot)
    ;;
  *)
    ;;
esac
EOF
chmod +x "${MOCK_BIN}/adb"

export PATH="${MOCK_BIN}:${PATH}"
export FLUTTER_ADB_TIMEOUT_SECONDS=0
export FLUTTER_TEST_DART_DEFINE="API_TOKEN=abc123,JIVE_E2E=true"

SUCCESS_DIR="${WORK_DIR}/success"
SUCCESS_SUMMARY="${SUCCESS_DIR}/suite-summary.txt"
mkdir -p "${SUCCESS_DIR}"

bash "${RUNNER_SCRIPT}" \
  --combined-suite \
  --retry 0 \
  --timeout 0 \
  --pub-get-timeout 0 \
  --no-device-recovery \
  --device-recovery-timeout 0 \
  --no-collect-on-fail \
  --artifact-dir "${SUCCESS_DIR}" \
  --summary-file "${SUCCESS_SUMMARY}" \
  --test integration_test/calendar_date_picker_flow_test.dart \
  --test integration_test/calendar_date_picker_flow_test.dart \
  emulator-5554

grep -q '^script_result=success$' "${SUCCESS_SUMMARY}"
grep -q '^failed_tests_count=0$' "${SUCCESS_SUMMARY}"
grep -q '^test_files_count=1$' "${SUCCESS_SUMMARY}"
grep -q '^config_entry=dart_define=API_TOKEN=<redacted>,JIVE_E2E=true$' "${SUCCESS_SUMMARY}"
grep -q '^summary_entries_count=1$' "${SUCCESS_SUMMARY}"
grep -q '^summary_entry=combined_suite(1 files): PASS in ' "${SUCCESS_SUMMARY}"

FAIL_DIR="${WORK_DIR}/failure"
FAIL_SUMMARY="${FAIL_DIR}/suite-summary.txt"
mkdir -p "${FAIL_DIR}"

set +e
bash "${RUNNER_SCRIPT}" \
  --combined-suite \
  --retry 0 \
  --timeout 0 \
  --pub-get-timeout 0 \
  --no-device-recovery \
  --device-recovery-timeout 0 \
  --no-collect-on-fail \
  --artifact-dir "${FAIL_DIR}" \
  --summary-file "${FAIL_SUMMARY}" \
  --test integration_test/transaction_search_flow_test.dart \
  emulator-5554
FAIL_EXIT=$?
set -e

if [[ "${FAIL_EXIT}" -eq 0 ]]; then
  echo "expected failure run to exit non-zero" >&2
  exit 1
fi

grep -q '^script_result=failure$' "${FAIL_SUMMARY}"
grep -q '^failed_tests_count=1$' "${FAIL_SUMMARY}"
grep -q '^failed_test=integration_test/transaction_search_flow_test.dart$' "${FAIL_SUMMARY}"
grep -q '^summary_entry=combined_suite(1 files): FAIL in ' "${FAIL_SUMMARY}"

echo "integration runner smoke: OK"
