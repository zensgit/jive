# SaaS Internal Test Release Finalizer Dev Verify

Date: 2026-05-12

Branch: `codex/saas-internal-test-release-finalizer`

Base: `origin/main` at `4691d2e93cbc6c83fe87e9a85d7e22293e2db6aa`

## Summary

This pass adds the final local release entrypoint for Google Play internal-test packaging. The previous runner could execute the three `SaaS Release Candidate` workflow passes after GitHub Actions secrets were ready. The new finalizer now covers the step before that: validate the production env file, upload production release secrets, verify the full production-release secret set including Android signing, and then delegate to the three-step release candidate sequence.

The script defaults to a safe dry-run. It uploads secrets and triggers workflows only when `--apply` is passed.

## Changes

| File | Change |
| --- | --- |
| `scripts/run_saas_internal_test_release.sh` | Added final local entrypoint for env validation, production secret upload, full secret check, and release-candidate sequence execution. |
| `scripts/test_saas_internal_test_release_finalizer.sh` | Added host-only fixture tests for dry-run, apply, skip-sequence, readiness-failure, and missing-env behavior. |
| `.github/workflows/flutter_ci.yml` | Added the finalizer and its test to SaaS production readiness self-checks. |
| `docs/saas-ops-checklist.md` | Documented the recommended one-command internal-test release flow. |

## Usage

Dry-run only:

```bash
scripts/run_saas_internal_test_release.sh --repo zensgit/jive --env-file /tmp/jive-saas-production.env --artifact-dir /tmp/jive-saas-release-candidate
```

Upload secrets and run the full release sequence:

```bash
scripts/run_saas_internal_test_release.sh --repo zensgit/jive --env-file /tmp/jive-saas-production.env --artifact-dir /tmp/jive-saas-release-candidate --apply
```

Upload/check secrets without running the three workflow passes:

```bash
scripts/run_saas_internal_test_release.sh --repo zensgit/jive --env-file /tmp/jive-saas-production.env --apply --skip-sequence
```

## Safety Properties

- The script never prints secret values.
- Missing production env file fails before any child script runs.
- Production readiness failure blocks before GitHub secret upload.
- Dry-run validates env shape and required secret values without remote mutation.
- `--apply` uploads only production-release client values by default; Android signing secrets are expected to already exist.
- The full secret check still requires Android signing secrets before workflow dispatch.

## Verification

Syntax checks:

```bash
bash -n scripts/run_saas_internal_test_release.sh scripts/test_saas_internal_test_release_finalizer.sh
```

Result: passed.

Finalizer host-only tests:

```bash
scripts/test_saas_internal_test_release_finalizer.sh
```

Result:

```text
[saas-internal-release-test] dry-run fixture ok: validates env and secret values without remote mutation
[saas-internal-release-test] apply fixture ok: uploads, verifies, and runs sequence
[saas-internal-release-test] skip-sequence fixture ok: supports upload-only cut point
[saas-internal-release-test] readiness-failure fixture ok: blocks before upload
[saas-internal-release-test] missing-env fixture ok: fails before child scripts
[saas-internal-release-test] all checks passed
```

Existing release self-tests:

```bash
scripts/test_saas_release_candidate_sequence_runner.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_github_secrets.sh
```

Result: passed.

Real finalizer preflight:

```bash
scripts/run_saas_internal_test_release.sh --repo zensgit/jive --env-file /tmp/jive-saas-production.env --artifact-dir /tmp/jive-finalizer-real-preflight
```

Result: expected block before child scripts because `/tmp/jive-saas-production.env` is not present locally.

Real repository status before this pass:

```text
main: 4691d2e93cbc6c83fe87e9a85d7e22293e2db6aa
latest main Flutter CI: run 25742017919, success
```

Current external blocker remains unchanged:

```text
PRODUCTION_SUPABASE_URL
PRODUCTION_SUPABASE_ANON_KEY
PRODUCTION_ADMOB_APP_ID
PRODUCTION_ADMOB_BANNER_ID
```

Android release signing secrets are already present in GitHub Actions.
