# SaaS Finalizer Report Hook Dev Verify

Date: 2026-05-12

## Summary

This change folds the internal-test completion report into the existing SaaS internal release finalizer. After `scripts/run_saas_internal_test_release.sh --apply` uploads production client secrets, verifies Android signing secrets, runs the three-step release candidate sequence, and downloads the final AAB artifact, it now automatically renders the validated Markdown completion report.

The dry-run path remains non-mutating and does not generate a report. The report is only generated after a successful release sequence, so we do not create a misleading completion record when no production AAB exists.

## Changed Files

- `scripts/run_saas_internal_test_release.sh`
  - Added `--completion-report`, `--play-track`, `--play-version`, and `--skip-completion-report`.
  - Added `JIVE_SAAS_INTERNAL_TEST_REPORT_SCRIPT`, `JIVE_SAAS_INTERNAL_TEST_REPORT_FILE`, `JIVE_SAAS_INTERNAL_TEST_PLAY_TRACK`, and `JIVE_SAAS_INTERNAL_TEST_PLAY_VERSION` overrides.
  - Calls `scripts/report_saas_internal_test_release_artifact.sh` after the release sequence succeeds.
- `scripts/test_saas_internal_test_release_finalizer.sh`
  - Added fixture coverage for automatic report generation.
  - Added coverage for custom report output, Play labels, explicit report skipping, sequence skipping, readiness failures, and missing env failures.
- `docs/saas-ops-checklist.md`
  - Documented that the finalizer now renders the completion report automatically.
  - Kept the standalone artifact report command as a re-render option.

## Verification

Local checks run:

```bash
git diff --check
bash -n scripts/run_saas_internal_test_release.sh scripts/test_saas_internal_test_release_finalizer.sh scripts/report_saas_internal_test_release_artifact.sh
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_github_secrets.sh
```

Results:

- `git diff --check`: pass
- `bash -n ...`: pass
- `scripts/test_saas_internal_test_release_finalizer.sh`: pass
- `scripts/test_saas_internal_test_release_artifact_report.sh`: pass
- `scripts/test_saas_release_candidate_sequence_runner.sh`: pass
- `scripts/test_saas_release_candidate_workflow.sh`: pass
- `scripts/test_saas_github_secrets.sh`: pass

Non-mutating real entrypoint preflight:

```bash
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --env-file /tmp/jive-saas-production.env \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md
```

Result: blocked before child scripts because `/tmp/jive-saas-production.env` is not present locally. No GitHub secrets were uploaded and no GitHub Actions workflows were triggered.

Real production release remains blocked until these required GitHub Actions secrets are provided:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Android release signing secrets are already configured.

## Operator Flow After Secrets Are Ready

```bash
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --env-file /tmp/jive-saas-production.env \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --apply
```

Expected output artifacts:

- Downloaded release candidate artifact under `/tmp/jive-saas-release-candidate`.
- Validated prod AAB with matching SHA-256 in `release-candidate.json`.
- Internal-test completion report at the requested Markdown path.
