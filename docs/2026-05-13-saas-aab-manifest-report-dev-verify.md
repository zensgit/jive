# SaaS AAB Manifest Report Dev Verify

Date: 2026-05-13

## Summary

This change strengthens the internal-test release artifact report with optional Android App Bundle manifest inspection.

The report already validates the release-candidate JSON, AAB bytes, SHA-256, signing mode, dry-run status, and secret-like filenames. It now can also inspect the downloaded AAB manifest with `bundletool dump manifest --bundle=<aab>`, verify the package id, and record manifest version details in the Markdown completion report.

The check is best-effort by default so existing automation does not fail when `bundletool` is not installed locally. Operators can make it blocking with `--require-manifest-check` or `JIVE_SAAS_INTERNAL_TEST_REQUIRE_MANIFEST_CHECK=true`.

## Changed Files

- `scripts/report_saas_internal_test_release_artifact.sh`
  - Added `--expected-package`, `--bundletool`, `--manifest-dump`, `--require-manifest-check`, and `--skip-manifest-check`.
  - Defaults expected package to `com.jivemoney.app`.
  - Records manifest package, versionName, versionCode, and source when available.
  - Fails when the parsed package does not match the expected package.
- `scripts/test_saas_internal_test_release_artifact_report.sh`
  - Added fixture coverage for passing manifest checks, wrong package rejection, and required bundletool absence.
- `docs/saas-ops-checklist.md`
  - Documented standalone and finalizer-driven manifest check usage.

## Verification

Local checks run:

```bash
git diff --check
bash -n scripts/report_saas_internal_test_release_artifact.sh scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_internal_test_release_artifact_report.sh
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_github_secrets.sh
```

Results:

- `git diff --check`: pass
- `bash -n scripts/report_saas_internal_test_release_artifact.sh scripts/test_saas_internal_test_release_artifact_report.sh`: pass
- `scripts/test_saas_internal_test_release_artifact_report.sh`: pass
- `scripts/test_saas_internal_test_release_finalizer.sh`: pass
- `scripts/test_saas_release_candidate_sequence_runner.sh`: pass
- `scripts/test_saas_github_secrets.sh`: pass

New manifest fixtures covered:

- Valid manifest package `com.jivemoney.app` is accepted and reported with versionName/versionCode.
- Unexpected manifest package is rejected.
- `--require-manifest-check` rejects missing bundletool before writing a misleading completion report.

Expected current production blocker remains unchanged:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Android release signing secrets are already present.

## Operator Command

After a prod AAB artifact is available and `bundletool` is installed:

```bash
scripts/report_saas_internal_test_release_artifact.sh \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --output docs/$(date +%F)-saas-internal-test-release-completion.md \
  --require-manifest-check \
  --bundletool bundletool
```

For the finalizer path:

```bash
JIVE_SAAS_INTERNAL_TEST_REQUIRE_MANIFEST_CHECK=true \
JIVE_BUNDLETOOL_BIN=bundletool \
scripts/run_saas_internal_test_release.sh \
  --repo zensgit/jive \
  --use-existing-secrets \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --completion-report docs/$(date +%F)-saas-internal-test-release-completion.md \
  --apply
```
