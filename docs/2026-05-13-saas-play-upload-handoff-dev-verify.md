# SaaS Play Upload Handoff Dev Verify

Date: 2026-05-13

## Summary

This change adds a no-secret, no-upload handoff step for Google Play internal testing.

After the SaaS release candidate sequence downloads a production AAB and the internal-test completion report validates it, operators still need a clear record for the Play Console upload step. The new handoff script validates the same downloaded AAB artifact, renders a redacted fastlane `supply` command shape, and records the Play track, release status, tester link, release id, rollout status, AAB SHA-256, and smoke checklist.

The script never reads the Google Play service account JSON and never uploads. It only records the local path placeholder that an operator can use from a secure machine.

## Changed Files

- `scripts/render_saas_play_internal_upload_handoff.sh`
  - Validates the downloaded prod release-candidate artifact.
  - Renders a Google Play internal testing upload handoff Markdown file.
  - Includes a fastlane `supply` command template without executing it.
  - Supports post-upload record fields: release id, tester link, rollout status.
- `scripts/test_saas_play_internal_upload_handoff.sh`
  - Adds host-only fixture coverage for successful handoff rendering, default service-account placeholder, bad release-candidate rejection, and missing completion-report rejection.
- `.github/workflows/flutter_ci.yml`
  - Adds shell syntax and fixture self-test coverage to the SaaS production readiness job.
- `docs/saas-ops-checklist.md`
  - Documents how to generate and later re-render the Play internal upload handoff report.

## Verification

Local checks run:

```bash
git diff --check
bash -n scripts/render_saas_play_internal_upload_handoff.sh scripts/test_saas_play_internal_upload_handoff.sh
scripts/test_saas_play_internal_upload_handoff.sh
scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_github_secrets.sh
```

Results:

- `git diff --check`: pass
- `bash -n scripts/render_saas_play_internal_upload_handoff.sh scripts/test_saas_play_internal_upload_handoff.sh`: pass
- `scripts/test_saas_play_internal_upload_handoff.sh`: pass
- `scripts/test_saas_internal_test_release_artifact_report.sh`: pass
- `scripts/test_saas_internal_test_release_finalizer.sh`: pass
- `scripts/test_saas_release_candidate_sequence_runner.sh`: pass
- `scripts/test_saas_github_secrets.sh`: pass

Current production blocker remains unchanged:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Android release signing secrets are already present.

## Operator Command

After the production AAB artifact exists:

```bash
scripts/render_saas_play_internal_upload_handoff.sh \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --output docs/$(date +%F)-saas-play-internal-upload-handoff.md \
  --service-account-json /secure/google-play-service-account.json \
  --release-status completed
```

After upload, re-render with Play Console details:

```bash
scripts/render_saas_play_internal_upload_handoff.sh \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --output docs/$(date +%F)-saas-play-internal-upload-handoff.md \
  --service-account-json /secure/google-play-service-account.json \
  --release-status completed \
  --play-release-id PLAY_RELEASE_ID \
  --tester-link PLAY_INTERNAL_TEST_LINK \
  --rollout-status internal-available
```
