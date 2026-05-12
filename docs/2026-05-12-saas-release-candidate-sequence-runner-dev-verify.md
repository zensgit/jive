# SaaS Release Candidate Sequence Runner Dev Verify

Date: 2026-05-12

Branch: `codex/saas-release-candidate-sequence-runner`

Base: `origin/main` at `8a8bfba2ed907bd193c0bd72af12ee0b40ca8cae`

## Summary

This pass removes the remaining manual choreography from the production release-candidate lane. Once production Supabase and AdMob client secrets are configured, a single local command can run the three required `SaaS Release Candidate` workflow passes, wait for each one, download the final artifact, and validate the final AAB report.

The current repository is still blocked from producing a real production AAB because four production client secrets are missing. The new runner intentionally stops before dispatching GitHub Actions when that preflight fails.

## Changes

| File | Change |
| --- | --- |
| `scripts/run_saas_release_candidate_sequence.sh` | Added a safe three-step GitHub Actions runner for production release-candidate dry-run, strict-signing dry-run, and signed prod AAB build. |
| `scripts/test_saas_release_candidate_sequence_runner.sh` | Added host-only fake-gh coverage for successful three-step execution, artifact download, report validation, and missing-secret fast fail. |
| `scripts/build_release_candidate.sh` | Final successful AAB builds now write `status=passed` and a success message into `release-candidate.json`. Dry-runs keep the existing preflight status. |
| `scripts/test_saas_release_candidate_workflow.sh` | Tightened the workflow contract test so the final passed status behavior stays protected. |
| `.github/workflows/flutter_ci.yml` | Added the new runner and test to SaaS production readiness self-checks. |
| `docs/saas-ops-checklist.md` | Documented the one-command sequence runner and its pre-dispatch secret guard. |

## Runner Behavior

Command after production secrets are ready:

```bash
scripts/run_saas_release_candidate_sequence.sh --repo zensgit/jive --artifact-dir /tmp/jive-saas-release-candidate
```

The runner performs:

1. `build_appbundle=false`, `strict_signing=false`
2. `build_appbundle=false`, `strict_signing=true`
3. `build_appbundle=true`, `strict_signing=true`

After the third run succeeds, it downloads `saas-release-candidate-<run_id>` and validates:

| Field | Expected |
| --- | --- |
| `status` | `passed` |
| `dryRun` | `false` |
| `strictSigning` | `true` |
| `signingMode` | `release-configured` |
| `dartDefinesConfigured` | `true` |
| `sha256` | Must match the downloaded AAB bytes. |

It also writes:

```text
saas-release-candidate-sequence-summary.md
```

## Verification

Syntax checks:

```bash
bash -n scripts/run_saas_release_candidate_sequence.sh scripts/test_saas_release_candidate_sequence_runner.sh scripts/build_release_candidate.sh scripts/test_saas_release_candidate_workflow.sh .github/workflows/flutter_ci.yml
```

Result: passed.

Host-only sequence runner test:

```bash
scripts/test_saas_release_candidate_sequence_runner.sh
```

Result:

```text
[saas-release-sequence-test] success fixture ok: dispatches three runs and validates final artifact
[saas-release-sequence-test] missing-secrets fixture ok: blocks before dispatch
[saas-release-sequence-test] all checks passed
```

Release workflow contract:

```bash
scripts/test_saas_release_candidate_workflow.sh
```

Result: passed.

Production readiness report self-test:

```bash
scripts/test_saas_production_release_readiness_report.sh
```

Result: passed.

Real repository preflight:

```bash
scripts/run_saas_release_candidate_sequence.sh --repo zensgit/jive --artifact-dir /tmp/jive-release-sequence-real-preflight --timeout-seconds 5 --poll-interval 0
```

Result: expected block before workflow dispatch because the following secrets are still missing:

```text
PRODUCTION_SUPABASE_URL
PRODUCTION_SUPABASE_ANON_KEY
PRODUCTION_ADMOB_APP_ID
PRODUCTION_ADMOB_BANNER_ID
```

Android release signing secrets are already present:

```text
ANDROID_RELEASE_KEYSTORE_BASE64
ANDROID_RELEASE_STORE_PASSWORD
ANDROID_RELEASE_KEY_ALIAS
ANDROID_RELEASE_KEY_PASSWORD
```

## Remaining External Action

Configure production Supabase and AdMob client values as GitHub Actions secrets. After that, run the sequence runner command above to produce and validate the Google Play internal-test AAB.
