#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CHECK_SCRIPTS=(
  "scripts/init_integration_summary_placeholder.sh"
  "scripts/render_integration_summary.sh"
  "scripts/test_render_integration_summary_limits.sh"
  "scripts/run_integration_tests.sh"
  "scripts/test_integration_summary_tools.sh"
  "scripts/test_run_integration_runner_smoke.sh"
  "scripts/test_run_integration_runner_signal_smoke.sh"
  "scripts/test_run_integration_runner_args_smoke.sh"
)

for script_path in "${CHECK_SCRIPTS[@]}"; do
  if [[ ! -f "${script_path}" ]]; then
    echo "missing helper script: ${script_path}" >&2
    exit 1
  fi
done

chmod +x "${CHECK_SCRIPTS[@]}"

for script_path in "${CHECK_SCRIPTS[@]}"; do
  bash -n "${script_path}"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "${CHECK_SCRIPTS[@]}"
else
  echo "shellcheck not found; skipping shellcheck pass"
fi

bash scripts/test_integration_summary_tools.sh
bash scripts/test_render_integration_summary_limits.sh
bash scripts/test_run_integration_runner_smoke.sh
bash scripts/test_run_integration_runner_signal_smoke.sh
bash scripts/test_run_integration_runner_args_smoke.sh

echo "ci helper scripts: OK"
