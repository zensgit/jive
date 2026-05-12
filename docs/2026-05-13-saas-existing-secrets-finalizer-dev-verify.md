# SaaS Existing Secrets Finalizer Dev Verify

Date: 2026-05-13

## Summary

This change adds a `--use-existing-secrets` mode to the SaaS internal-test release finalizer.

The original finalizer path is still unchanged for the normal case where `/tmp/jive-saas-production.env` is available: validate the env file, upload production-release secrets, verify GitHub Actions secrets, run the release candidate sequence, download the AAB artifact, and render the internal-test completion report.

The new path is for operators who already configured production Supabase, AdMob, and Android signing secrets in GitHub Actions. In that case, the finalizer can skip the local production env file and upload steps, check the existing GitHub Actions secrets, and then run the same release sequence and report renderer.

## Changed Files

- `scripts/run_saas_internal_test_release.sh`
  - Added `--use-existing-secrets`.
  - Skips local env validation and secret upload in existing-secrets mode.
  - Still requires `scripts/check_saas_github_secrets.sh --profile production-release --include-signing` to pass before any workflow dispatch.
  - Reuses the same sequence/report path after successful secret checks.
- `scripts/test_saas_internal_test_release_finalizer.sh`
  - Added fixture coverage for existing-secrets dry-run, apply, and missing-secret failure paths.
- `docs/saas-ops-checklist.md`
  - Documented the no-local-env release command for GitHub UI configured secrets.

## Verification

Local checks run:

```bash
git diff --check
bash -n scripts/run_saas_internal_test_release.sh scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_github_secrets.sh
```

Results:

- `git diff --check`: pass
- `bash -n scripts/run_saas_internal_test_release.sh scripts/test_saas_internal_test_release_finalizer.sh`: pass
- `scripts/test_saas_internal_test_release_finalizer.sh`: pass
- `scripts/test_saas_release_candidate_sequence_runner.sh`: pass
- `scripts/test_saas_internal_test_release_artifact_report.sh`: pass
- `scripts/test_saas_github_secrets.sh`: pass

Real non-mutating check:

```bash
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --use-existing-secrets \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md
```

Expected current result: the command stops before workflow dispatch because required production client secrets are still missing from GitHub Actions. This is the safe behavior.

Actual current result: stopped at `scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive` with 4 missing required production client secrets. No release workflow was dispatched.

Current missing required GitHub Actions secrets:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Android release signing secrets are already present.

## Operator Flow After Secrets Are Ready

If using a local production env file:

```bash
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --env-file /tmp/jive-saas-production.env \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --apply
```

If secrets were configured directly in GitHub Actions:

```bash
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --use-existing-secrets \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --apply
```
