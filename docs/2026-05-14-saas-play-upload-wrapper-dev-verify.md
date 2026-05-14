# SaaS Play Internal Upload Wrapper Dev Verify

Date: 2026-05-14
Branch: `codex/saas-play-upload-wrapper`
Base: `origin/main` at `52c271a1`

## Summary

This change closes the next Google Play internal-test automation gap after release candidate artifact generation. It adds a safe, host-only readiness gate and a dry-run-first upload wrapper for the existing prod AAB artifact.

The default path still does not upload to Google Play. Real upload only happens when `--apply` is passed with a local service account JSON path.

## Changes

- Added `scripts/check_saas_play_upload_readiness.sh`.
- Added `scripts/upload_saas_google_play_internal_test.sh`.
- Added fixture coverage for readiness and upload dry-run/apply behavior.
- Added `Gemfile` with `fastlane` for operators who want a pinned local upload tool.
- Wired the new script syntax checks and fixture tests into `.github/workflows/flutter_ci.yml`.
- Updated `docs/saas-ops-checklist.md` with readiness, dry-run, and apply commands.

## Guardrails

- Rejects non-`internal` Play track for this lane.
- Rejects package names outside `com.jivemoney.app`.
- Rejects dev/staging package ids.
- Revalidates `release-candidate.json` status, flavor, strict signing, dry-run flag, signing mode, dart defines, AAB bytes, and SHA-256.
- Rejects secret-like files in the downloaded artifact.
- Supports optional `bundletool` or pre-rendered manifest checks.
- Requires service account JSON only for upload `--apply`.
- Does not read or print service account JSON contents.

## Verification

Commands run:

```bash
bash -n scripts/check_saas_play_upload_readiness.sh scripts/upload_saas_google_play_internal_test.sh scripts/test_saas_play_upload_readiness.sh scripts/test_saas_google_play_internal_upload.sh
scripts/test_saas_play_upload_readiness.sh
scripts/test_saas_google_play_internal_upload.sh
scripts/test_saas_play_internal_upload_handoff.sh
scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_release_candidate_sequence_runner.sh
git diff --check
```

Result: all passed.

## Not Done

- No real Google Play upload was executed.
- No production service account JSON was added to the repository.
- No Play Console release id, tester link, or rollout status exists yet because the real upload remains an operator action.
