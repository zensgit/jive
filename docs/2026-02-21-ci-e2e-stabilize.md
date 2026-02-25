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
    - `transaction_search_flow`
  - Normalizes args to `integration_test/*_test.dart`.
  - Enforces timeout for `adb` operations and `flutter test` when `timeout`/`gtimeout` exists.
  - If timeout binary is unavailable (local macOS), script degrades to non-timeout mode and still executes.
  - Writes test output, adb diagnostics, metadata, and screenshots to `ci_artifacts/android_integration`.
  - Exits with the underlying failure code from `adb wait-for-device` or `flutter test`.
- Updated `.github/workflows/flutter_ci.yml`:
  - Kept existing job gating unchanged.
  - Replaced inline `flutter test` invocation with `bash scripts/run_android_integration_ci.sh transaction_search_flow`.
  - Added explicit step env for timeout policy (`FLUTTER_IGNORE_TIMEOUTS=1`, `FLUTTER_TEST_TIMEOUT=none`).
  - Added an `actions/upload-artifact@v4` step (`if: always()`) for `ci_artifacts/android_integration`.
  - Added `continue-on-error: true` to artifact upload step to avoid masking test result when Actions artifact quota is exhausted.

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
  - `87:            bash scripts/run_android_integration_ci.sh transaction_search_flow`
  - `92:        uses: actions/upload-artifact@v4`

## Timeout Guard Follow-up (2026-02-23)

- Trigger: after PR #56 (`run_android_integration_ci.sh transaction_search_flow`), CI still failed due Flutter test default suite timeout in cold-start emulator path.
- Root cause: outer command timeout existed, but Flutter internal timeout (`12 minutes`) could still fail first.
- Change:
  - Added `FLUTTER_IGNORE_TIMEOUTS` (default `1`) and `FLUTTER_TEST_TIMEOUT` (default `none`) to `scripts/run_android_integration_ci.sh`.
  - Runner now appends `--ignore-timeouts --timeout none` to `flutter test` by default.
  - Keeps existing outer guard via `FLUTTER_TIMEOUT_SECONDS` to prevent infinite hangs.
  - Extended `metadata.txt` to include timeout-related runtime config for postmortem.
- Expected effect:
  - Avoid false failures from Flutter internal timeout while preserving hard-stop protection at script level.

## Emulator Boot Timeout Follow-up (2026-02-23)

- Trigger: workflow run `22307125615` failed before entering script execution.
- Root cause: `reactivecircus/android-emulator-runner` hit default boot timeout (10m) and aborted with `Timeout waiting for emulator to boot`.
- Change:
  - Set `emulator-boot-timeout: 1200` in `.github/workflows/flutter_ci.yml` for `android_integration_test`.
- Expected effect:
  - Allow slower hosted runner cold boots to finish and reach the scripted integration test stage.

## Job Budget Follow-up (2026-02-23)

- Trigger: workflow run `22307818273` still ended `cancelled` at ~35 minutes.
- Evidence:
  - Emulator boot completed in ~899s (`Boot completed in 898776 ms`).
  - `assembleDevDebug` alone took ~1017s.
  - Job reached APK install phase, then was canceled by workflow timeout window.
- Change:
  - Increased `android_integration_test.timeout-minutes` from `35` to `60`.
  - Increased script outer guard via workflow env `FLUTTER_TIMEOUT_SECONDS=2700`.
- Expected effect:
  - Keep hard-stop safety while providing enough budget for cold boot + dependency install + debug assemble + test execution.

## ADB Animation Toggle Follow-up (2026-02-23)

- Trigger: workflow run `22309250248` failed after emulator boot with:
  - `cmd: Failure calling service settings: Broken pipe (32)`
  - `/usr/local/lib/android/sdk/platform-tools/adb` exit code `224`
- Root cause: emulator-runner's animation disabling step can fail on unstable ADB transport right after long cold boot.
- Change:
  - Set `disable-animations: false` in `android_emulator_runner` configuration.
- Expected effect:
  - Remove the fragile `adb shell settings put global ...` path and proceed directly to scripted integration execution.

## Final Budget Follow-up (2026-02-23)

- Trigger: workflow run `22310006019` reached test success log (`✅ Transaction list supports search + filter + date range clear flow`) but was canceled before step completion.
- Root cause: end-to-end runtime still exceeded configured job timeout margin (boot + setup + assemble + install + test + cleanup).
- Change:
  - Increased `android_integration_test.timeout-minutes` from `60` to `75`.
  - Increased script guard env `FLUTTER_TIMEOUT_SECONDS` from `2700` to `4200`.
- Expected effect:
  - Keep timeout protection while leaving enough post-test teardown buffer for a fully green completion state.

## Runtime Reduction Follow-up (2026-02-23)

- Trigger: repeated CI logs showed duplicated dependency resolution inside `flutter test` despite workflow already running `flutter pub get`.
- Change:
  - Added `FLUTTER_TEST_SKIP_PUB` (default `1`) in `scripts/run_android_integration_ci.sh`.
  - Runner appends `--no-pub` when this flag is enabled.
  - Wired `FLUTTER_TEST_SKIP_PUB=1` in workflow env for Android integration step.
- Expected effect:
  - Remove redundant pub resolution during integration test execution and recover several minutes of runtime budget.

## Long-tail Timeout Follow-up (2026-02-23)

- Trigger: workflow run `22312898972` still canceled at 75-minute boundary while APK install was in progress.
- Change:
  - Increased `android_integration_test.timeout-minutes` from `75` to `120`.
  - Increased workflow env `FLUTTER_TIMEOUT_SECONDS` from `4200` to `6600`.
- Rationale:
  - Cold hosted runners show high variance in boot + build + install duration; extended budget prevents false negatives caused by infrastructure slowness.

## Home Entry Selector Follow-up (2026-02-24)

- Trigger: workflow run `22334017333` failed in integration stage with:
  - `integration_test/transaction_search_flow_test.dart:56`
  - `Finder: Found 0 widgets with text "View All"`
- Root cause:
  - Integration flows depended on a locale-specific `find.text('View All')` selector for the home entry into `全部账单`.
  - On non-English/home variants this selector is brittle.
- Change:
  - Added stable key `home_view_all_button` to the home "View All" tap target in `lib/main.dart`.
  - Updated:
    - `integration_test/transaction_search_flow_test.dart`
    - `integration_test/calendar_date_picker_flow_test.dart`
  - Both tests now open the page via fallback order:
    1) key `home_view_all_button`
    2) text `View All`
    3) text `查看全部`
- Verification:
  - `flutter analyze --no-fatal-infos` -> PASS
  - Workflow-dispatch rerun started on head `eaeb93e`:
    - run id: `22337649712`
    - url: `https://github.com/zensgit/jive/actions/runs/22337649712`

## Emulator Install Flake Follow-up (2026-02-24)

- Trigger: workflow run `22337649712` failed in Android integration job even before test case execution.
- Failure signature:
  - `adb: failed to install ... app-dev-debug.apk`
  - `java.lang.NullPointerException ... StorageManager.getVolumes()`
  - `Failed to load ... Unable to start the app on the device.`
- Root cause:
  - Emulator package installer occasionally fails with a transient storage service NPE after long cold boot/build phases.
- Change:
  - `scripts/run_android_integration_ci.sh` now:
    - waits for `pm list packages` readiness before running `flutter test`;
    - retries `flutter test` once after first failure (transient signature or defensive fallback);
    - records retry reason and per-attempt logs (`flutter_test_output_attempt*.log`).
  - Workflow env adds `FLUTTER_TEST_RETRY_INSTALL_FAILURE=1` (explicit).
- Expected effect:
  - Convert emulator-side transient install failures into auto-recovered retries without masking real deterministic test failures.

## Emulator Crash/No-Trace Follow-up (2026-02-24)

- Trigger: workflow run `22343795400` failed after long `android_emulator_runner` execution with:
  - `detected a hanging thread 'QEMU2 main loop'`
  - crashpad ptrace errors near teardown
  - no explicit flutter assertion in action summary
- Risk:
  - single-attempt emulator execution makes infra-level emulator crashes look like deterministic test regressions.
  - missing step-level error annotation reduces triage speed.
- Change:
  - increased Android integration job timeout to `180` minutes to safely hold two full emulator attempts on slow runners.
  - split Android integration execution into two `android-emulator-runner` attempts:
    - attempt 1: `id=android_e2e_attempt_1`, `continue-on-error: true`
    - attempt 2: conditional on attempt 1 failure, fresh emulator instance
  - added explicit final guard step that fails the job only when all attempts fail.
  - increased emulator cores from `2` to `4` for both attempts.
  - isolated artifacts by attempt using:
    - `CI_ARTIFACT_DIR=ci_artifacts/android_integration/attempt1`
    - `CI_ARTIFACT_DIR=ci_artifacts/android_integration/attempt2`
  - improved script diagnostics in `run_android_integration_ci.sh`:
    - prints per-attempt start/end and elapsed seconds
    - records explicit timeout-hit message for exit `124`
    - writes `failure_reason.log` with exit code and resolved targets on final failure
- Expected effect:
  - absorb transient emulator process instability via fresh-emulator retry.
  - guarantee structured failure reason in artifacts when retries are exhausted.

## Hosted Runner Disconnect Follow-up (2026-02-24)

- Trigger: workflow run `22354477566` failed with check annotation:
  - `The hosted runner lost communication with the server...`
- Observation:
  - failure occurred during emulator attempt step; step logs were incomplete and later steps never started.
  - this behavior is consistent with runner resource starvation/crash rather than deterministic test assertion failure.
- Change:
  - reduced emulator CPU back to `cores: 2` (from `4`) for both attempts.
  - reduced `FLUTTER_TIMEOUT_SECONDS` to `2400` (40 min) for both attempts to avoid prolonged hangs inside a single emulator session.
- Expected effect:
  - lower runner pressure and avoid agent disconnect.
  - force earlier deterministic timeout/hand-off to retry path when emulator hangs.

## Retry Control-Flow Fix Follow-up (2026-02-25)

- Trigger: local run on connected Android device exited after attempt 1 (`exit 79`) without entering retry path.
- Root cause:
  - `run_flutter_test_attempt` toggled `set -e` internally and returned non-zero while `errexit` was re-enabled.
  - this caused the script to terminate before the retry branch could execute.
- Change:
  - preserved/restore `errexit` state inside `run_flutter_test_attempt` instead of unconditionally forcing `set -e`.
- Expected effect:
  - first-attempt failures now correctly flow into retry logic.
  - failure classification and artifact writing run reliably after retries.

## CI Budget Blocker (2026-02-25)

- Latest verification runs on this branch:
  - `22382862065` (pull_request)
  - `22382867788` (workflow_dispatch)
  - `22388635399` (pull_request)
- Result:
  - GitHub Actions annotation reports: `The job was not started because an Actions budget is preventing further use.`
  - blocker is external quota; not a repository workflow syntax/runtime regression.
- Local fallback verification (physical Android device):
  - command:
    - `ANDROID_DEVICE_SERIAL=EP0110MZ0BC110087W CI_ARTIFACT_DIR=/tmp/jive-ci-local-run-20260225-162547 FLUTTER_TIMEOUT_SECONDS=2400 FLUTTER_TEST_RETRY_INSTALL_FAILURE=1 bash scripts/run_android_integration_ci.sh transaction_search_flow`
  - outcome:
    - retry flow executes as expected (`attempt 1` fail -> `attempt 2` run).
    - final `failure_reason.log` is emitted with exit code and resolved target.
