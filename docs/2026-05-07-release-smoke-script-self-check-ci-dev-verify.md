# Release Smoke Script Self-Check CI Dev Verify

- Date: 2026-05-07
- Branch: `codex/release-smoke-ci-self-check`
- Base: `main` @ `e59aa43363c2268d9aaad0666d91416559fd43e3`
- Worktree: `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-release-smoke-ci-self-check`

## Changes

- Added a lightweight `release_smoke_script_self_check` job to `.github/workflows/flutter_ci.yml`.
- The job checks release smoke shell syntax, release Android artifact verifier help, summary renderer help, verifier self-test help, and the host-only verifier self-test.
- Updated `docs/release_smoke_lane_mvp.md` to document the CI job.

## CI Job Contract

The job intentionally does not install Flutter, start an emulator, build APKs, upload artifacts, or read secrets.

It covers:

- `scripts/run_release_smoke.sh`
- `scripts/run_release_android_smoke.sh`
- `scripts/run_android_local_feature_smoke.sh`
- `scripts/verify_release_android_smoke_artifacts.sh`
- `scripts/render_release_android_smoke_summary.sh`
- `scripts/test_release_android_smoke_artifact_verifier.sh`

## Commands

Local reproduction of the new CI job:

```bash
for script in \
  scripts/run_release_smoke.sh \
  scripts/run_release_android_smoke.sh \
  scripts/run_android_local_feature_smoke.sh \
  scripts/verify_release_android_smoke_artifacts.sh \
  scripts/render_release_android_smoke_summary.sh \
  scripts/test_release_android_smoke_artifact_verifier.sh; do
  bash -n "$script"
done

scripts/verify_release_android_smoke_artifacts.sh --help >/dev/null
scripts/render_release_android_smoke_summary.sh --help >/dev/null
scripts/test_release_android_smoke_artifact_verifier.sh --help >/dev/null
scripts/test_release_android_smoke_artifact_verifier.sh
```

Additional checks:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "workflow yaml parsed"'
git diff --check
flutter analyze --no-fatal-infos
```

## Results

Local reproduction passed:

```text
[release-android-smoke-verifier-test] pass fixture ok: guest-home
[release-android-smoke-verifier-test] pass fixture ok: all
[release-android-smoke-verifier-test] negative fixture ok: missing required transaction result anchor
[release-android-smoke-verifier-test] all verifier self-tests passed
```

Additional checks passed:

```text
workflow yaml parsed
git diff --check: passed
flutter analyze --no-fatal-infos: passed with 83 existing info-level lints
```

The analyzer infos are the existing project baseline in unrelated Dart files.
This PR changes workflow/docs only and does not add Dart analyzer errors or warnings.

## Notes

- This job protects release smoke script contracts on every PR/push without requiring device infrastructure.
- It does not replace the real local Android smoke lane or staging deployment tests.
- A follow-up should add the same host-only self-test coverage for `scripts/render_release_android_smoke_summary.sh`.
