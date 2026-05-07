# Release Android Smoke Verifier Self-Test Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-smoke-verifier-self-test`
- Base: `main` @ `cf5850ffd4d5e8014708c56f4593f779e1c5c34c`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-smoke-verifier-self-test`
- Fixture root: `/tmp/jive-release-android-smoke-verifier-test.4xBQOj`

## Changes

- Added `scripts/test_release_android_smoke_artifact_verifier.sh`.
- The self-test creates minimal local artifact fixtures and validates the artifact verifier without adb, emulator, APK build, uploads, or secrets.
- `scripts/run_release_smoke.sh` now runs the verifier self-test as part of the host release smoke lane.
- Updated `docs/release_smoke_lane_mvp.md` with the host-only self-test command.

## Fixture Coverage

Positive fixtures:

- `guest-home`: verifies common runner summary, launch artifacts, final home artifacts, empty crash/alert logs, and home anchors.
- `all`: verifies common evidence plus SaaS gates, settings navigation, quick-entry hub, and transaction-entry anchors.

Negative fixture:

- `missing-anchor`: removes the required `7.00` transaction result anchor and asserts the verifier fails with a targeted report failure.

## Commands

Static checks:

```bash
for script in scripts/verify_release_android_smoke_artifacts.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/run_release_smoke.sh; do
  bash -n "$script"
done
scripts/verify_release_android_smoke_artifacts.sh --help
scripts/test_release_android_smoke_artifact_verifier.sh --help
git diff --check
flutter analyze --no-fatal-infos
```

Self-test:

```bash
scripts/test_release_android_smoke_artifact_verifier.sh
```

Self-test with retained fixtures:

```bash
scripts/test_release_android_smoke_artifact_verifier.sh --keep-fixtures
```

Fixture report inspection:

```bash
sed -n '1,80p' /tmp/jive-release-android-smoke-verifier-test.4xBQOj/all-pass/release_android_smoke_artifact_verification.md
rg -n "status: failed|missing '7\\.00'|fail:" /tmp/jive-release-android-smoke-verifier-test.4xBQOj/missing-anchor/release_android_smoke_artifact_verification.md
```

## Results

Static checks passed:

```text
for script in scripts/verify_release_android_smoke_artifacts.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/run_release_smoke.sh; do bash -n "$script"; done: passed
scripts/verify_release_android_smoke_artifacts.sh --help: passed
scripts/test_release_android_smoke_artifact_verifier.sh --help: passed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated Dart files.
This PR changes shell/docs only and does not add Dart analyzer errors or warnings.

Self-test passed:

```text
[release-android-smoke-verifier-test] pass fixture ok: guest-home
[release-android-smoke-verifier-test] pass fixture ok: all
[release-android-smoke-verifier-test] negative fixture ok: missing required transaction result anchor
[release-android-smoke-verifier-test] all verifier self-tests passed
```

Retained fixture run passed:

```text
[release-android-smoke-verifier-test] kept fixtures: /tmp/jive-release-android-smoke-verifier-test.4xBQOj
```

All-scenario verifier report:

```text
status: passed
scenario: all
failures: 0
warnings: 0
```

Negative verifier report:

```text
status: failed
fail: transaction_entry_expression.summary.txt missing '7.00'
```

## Notes

- This self-test protects the verifier contract itself.
- It does not replace `scripts/run_release_android_smoke.sh`, which remains the real device/emulator pre-deployment smoke.
- Fixture `.png` files are intentionally minimal non-empty files because the verifier only requires screenshot artifacts to exist and be non-empty.
- Full `scripts/run_release_smoke.sh` was not rerun because this change only adds a host-only preflight to that lane; the self-test itself and shell syntax were run directly, and CI covers the normal Flutter analyze/test baseline.
