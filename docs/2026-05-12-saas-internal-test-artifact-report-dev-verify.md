# SaaS Internal Test Artifact Report Dev Verify

Date: 2026-05-12

Branch: `codex/saas-internal-test-artifact-report`

Base: `origin/main` at `0fa50892480bdc198f51526f4e22629b9dd59415`

## Summary

This pass adds a redacted completion-report generator for the final Google Play internal-test artifact. After the release-candidate sequence downloads the signed production AAB, the new report script validates the artifact directory and renders a Markdown record suitable for release archives.

The repository still cannot produce a real AAB until production Supabase and AdMob client values are configured. This pass prepares the post-AAB evidence step so the final handoff is repeatable once those values exist.

## Changes

| File | Change |
| --- | --- |
| `scripts/report_saas_internal_test_release_artifact.sh` | Added a local artifact validator/report renderer for downloaded `saas-release-candidate-*` artifacts. |
| `scripts/test_saas_internal_test_release_artifact_report.sh` | Added host-only fixtures for valid artifacts, SHA mismatch, secret-like files, and missing report JSON. |
| `.github/workflows/flutter_ci.yml` | Added the new report script and test to SaaS production readiness self-checks. |
| `docs/saas-ops-checklist.md` | Documented the internal-test completion report command. |

## Report Checks

The report script validates:

- Exactly one `release-candidate.json` exists.
- Exactly one `.aab` exists.
- `status=passed`.
- `flavor=prod`.
- `dryRun=false`.
- `strictSigning=true`.
- `signingMode=release-configured`.
- `dartDefinesConfigured=true`.
- `artifactName`, `artifactBytes`, and `sha256` match the downloaded AAB.
- No forbidden secret-like filenames are present in the artifact directory.

## Usage

After a successful release-candidate sequence:

```bash
scripts/report_saas_internal_test_release_artifact.sh \
  --artifact-dir /tmp/jive-saas-release-candidate \
  --output docs/$(date +%F)-saas-internal-test-release-completion.md
```

The generated Markdown includes:

- Workflow run id, when discoverable from `saas-release-candidate-sequence-summary.md`.
- Play track and optional Play version.
- AAB path, byte size, and SHA-256.
- Build name/build number.
- Git branch/commit from the release-candidate report.
- Google Play internal-test smoke checklist.
- Deferred public-launch checklist.

## Verification

Syntax checks:

```bash
bash -n scripts/report_saas_internal_test_release_artifact.sh scripts/test_saas_internal_test_release_artifact_report.sh
```

Result: passed.

Host-only artifact report test:

```bash
scripts/test_saas_internal_test_release_artifact_report.sh
```

Result:

```text
[saas-internal-artifact-report-test] good fixture ok: renders validated internal test report
[saas-internal-artifact-report-test] bad-sha fixture ok: rejects mismatched digest
[saas-internal-artifact-report-test] leaky fixture ok: rejects secret-like artifact filenames
[saas-internal-artifact-report-test] missing-report fixture ok: requires release candidate JSON
[saas-internal-artifact-report-test] all checks passed
```

Existing release safety tests:

```bash
scripts/test_saas_internal_test_release_finalizer.sh
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_github_secrets.sh
```

Result: passed.

Current external blocker remains unchanged:

```text
PRODUCTION_SUPABASE_URL
PRODUCTION_SUPABASE_ANON_KEY
PRODUCTION_ADMOB_APP_ID
PRODUCTION_ADMOB_BANNER_ID
```
