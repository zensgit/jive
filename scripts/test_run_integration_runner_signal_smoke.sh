#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER_SCRIPT="${ROOT_DIR}/scripts/run_integration_tests.sh"

if [[ ! -f "${RUNNER_SCRIPT}" ]]; then
  echo "runner script not found: ${RUNNER_SCRIPT}" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/jive-runner-signal.XXXXXX)"
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

if [[ "${1:-}" == "test" ]]; then
  sleep 30
  echo "mock flutter test completed"
  exit 0
fi

if [[ "${1:-}" == "devices" ]]; then
  echo "1 connected device"
  exit 0
fi

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
  shell)
    if [[ "${2:-}" == "getprop" && "${3:-}" == "sys.boot_completed" ]]; then
      echo "1"
    fi
    ;;
  logcat|devices)
    ;;
  *)
    ;;
esac
EOF
chmod +x "${MOCK_BIN}/adb"

export PATH="${MOCK_BIN}:${PATH}"
export FLUTTER_ADB_TIMEOUT_SECONDS=0

RUN_DIR="${WORK_DIR}/signal"
SUMMARY_FILE="${RUN_DIR}/suite-summary.txt"
RUN_LOG="${RUN_DIR}/runner.log"
mkdir -p "${RUN_DIR}"

set +e
bash "${RUNNER_SCRIPT}" \
  --combined-suite \
  --retry 0 \
  --timeout 0 \
  --pub-get-timeout 0 \
  --no-device-recovery \
  --device-recovery-timeout 0 \
  --no-collect-on-fail \
  --artifact-dir "${RUN_DIR}" \
  --summary-file "${SUMMARY_FILE}" \
  --test integration_test/signal_smoke_flow_test.dart \
  emulator-5554 \
  > "${RUN_LOG}" 2>&1 &
RUN_PID=$!
set -e

sleep 1
kill -TERM "${RUN_PID}" >/dev/null 2>&1

set +e
wait "${RUN_PID}"
RUN_EXIT=$?
set -e

if [[ "${RUN_EXIT}" -ne 143 ]]; then
  echo "expected signal-smoke exit 143, got ${RUN_EXIT}" >&2
  cat "${RUN_LOG}" >&2 || true
  exit 1
fi

grep -q '^script_exit_code=143$' "${SUMMARY_FILE}"
grep -q '^script_result=failure$' "${SUMMARY_FILE}"
grep -q '^interrupted_reason=SIGTERM$' "${SUMMARY_FILE}"

echo "integration runner signal smoke: OK"
