# Android CI E2E Stabilization

Date: 2026-02-21

## Rationale

- The Android integration test job previously executed `flutter test` inline, which made timeout behavior and diagnostics hard to control.
- CI flakes were harder to triage because logcat output, screenshots, and command context were not consistently preserved as artifacts.
- Moving execution into a script keeps the workflow minimal while letting us enforce command-level timeouts and preserve the real test exit code.

## Implementation

- Added `scripts/run_android_integration_ci.sh`.
  - Accepts integration test targets as positional args.
  - Defaults to:
    - `calendar_date_picker_flow`
    - `transaction_search_flow`
  - Normalizes args to `integration_test/*_test.dart`.
  - Enforces timeout for `adb` operations and `flutter test` when `timeout`/`gtimeout` exists.
  - If timeout binary is unavailable (local macOS), script degrades to non-timeout mode and still executes.
  - Writes test output, adb diagnostics, metadata, and screenshots to `ci_artifacts/android_integration`.
  - Exits with the underlying failure code from `adb wait-for-device` or `flutter test`.
- Updated `.github/workflows/flutter_ci.yml`:
  - Kept existing job gating unchanged.
  - Replaced inline `flutter test` invocation with `bash scripts/run_android_integration_ci.sh`.
  - Added an `actions/upload-artifact@v4` step (`if: always()`) for `ci_artifacts/android_integration`.

## Verification

- `bash -n scripts/run_android_integration_ci.sh`
- local dry-run (missing test target):
  - `CI_ARTIFACT_DIR=/tmp/jive-ci-dry-run bash scripts/run_android_integration_ci.sh __missing_case__`
- local device run (single test):
  - `ANDROID_DEVICE_SERIAL=EP0110MZ0BC110087W CI_ARTIFACT_DIR=/tmp/jive-ci-local-run bash scripts/run_android_integration_ci.sh transaction_search_flow`
- `shellcheck scripts/run_android_integration_ci.sh` (if available in the environment)
- Workflow reference sanity check:
  - `grep -n "run_android_integration_ci.sh\\|upload-artifact\\|android_integration_test" .github/workflows/flutter_ci.yml`

### Verification Results (local)

- `bash -n scripts/run_android_integration_ci.sh` -> PASS
- `CI_ARTIFACT_DIR=/tmp/jive-ci-dry-run bash scripts/run_android_integration_ci.sh __missing_case__` -> PASS（按预期返回 2，验证参数与失败码透传）
- `ANDROID_DEVICE_SERIAL=EP0110MZ0BC110087W CI_ARTIFACT_DIR=/tmp/jive-ci-local-run bash scripts/run_android_integration_ci.sh transaction_search_flow` -> PASS（integration test 通过；输出目录含 metadata/logcat/screenshot）
- `shellcheck scripts/run_android_integration_ci.sh` -> `shellcheck: NOT INSTALLED`
- `yq '.jobs.android_integration_test' .github/workflows/flutter_ci.yml >/dev/null` -> `yq: NOT INSTALLED (used grep sanity check)`
- `grep -n "run_android_integration_ci.sh\\|upload-artifact\\|android_integration_test\\|run_android_e2e\\|contains(github.event.pull_request.labels" .github/workflows/flutter_ci.yml` output:
  - `10:      run_android_e2e:`
  - `48:  android_integration_test:`
  - `52:      (github.event_name == 'workflow_dispatch' && github.event.inputs.run_android_e2e == 'true') ||`
  - `53:      (github.event_name == 'pull_request' && contains(github.event.pull_request.labels.*.name, 'e2e'))`
  - `83:            bash scripts/run_android_integration_ci.sh`
  - `87:        uses: actions/upload-artifact@v4`
