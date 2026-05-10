# SaaS Release Candidate Workflow Self-Test Dev Verify

Date: 2026-05-10
Branch: `codex/saas-release-candidate-workflow-self-test`

## Goal

Add host-only contract coverage for the `SaaS Release Candidate` workflow, protecting the final production package lane before any real appbundle build, signing, or release artifact upload.

This slice is intentionally non-destructive:

- No production secrets were read.
- No Android appbundle was built.
- No signing keystore was decoded.
- No Supabase project or payment provider was contacted.
- No release artifact was uploaded.

## Changes

- Added `scripts/test_saas_release_candidate_workflow.sh`.
- Wired the self-test into `.github/workflows/flutter_ci.yml` under `saas_production_readiness_self_check`.
- Updated `scripts/should_run_saas_wave0_smoke.sh` so release candidate workflow/self-test changes trigger Wave0 smoke.
- Updated `scripts/test_saas_wave0_smoke_trigger.sh` with release candidate workflow trigger coverage.

## Contract Coverage

The new self-test verifies:

- `build_appbundle` and `strict_signing` remain explicit opt-in inputs.
- Production Supabase and AdMob client values are required for every release candidate run.
- Android release signing secrets are tied to `strict_signing`.
- Java/Flutter setup and real appbundle builds only run when `build_appbundle=true`.
- Release dry-run behavior remains `JIVE_RELEASE_CANDIDATE_DRY_RUN: ${{ inputs.build_appbundle != true }}`.
- Production env file keeps store billing on, domestic payment off, and mock payment URL empty.
- Strict signing restores keystore material only through runner temp files and env.
- Release candidate artifacts are scanned with `scripts/guard_saas_report_artifacts.sh` before upload.
- The workflow publishes `latest.md` to the step summary and uploads the expected report roots.
- `scripts/build_release_candidate.sh` keeps production readiness, dry-run behavior, client-safe dart defines, and does not reference `SUPABASE_SERVICE_ROLE_KEY`.

## Verification

Passed:

```bash
bash -n scripts/test_saas_release_candidate_workflow.sh \
  scripts/should_run_saas_wave0_smoke.sh \
  scripts/test_saas_wave0_smoke_trigger.sh \
  scripts/build_release_candidate.sh
```

Passed:

```bash
scripts/test_saas_release_candidate_workflow.sh --help >/dev/null
scripts/test_saas_release_candidate_workflow.sh
```

Passed:

```bash
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Passed:

```bash
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_production_release_readiness_report.sh
```

Passed:

```bash
scripts/test_saas_report_artifact_guard.sh
scripts/test_release_report_summary_renderer.sh
scripts/test_release_android_smoke_artifact_verifier.sh
scripts/test_release_android_smoke_summary_renderer.sh
```

Passed:

```bash
ruby -e 'require "yaml"; %w[.github/workflows/flutter_ci.yml .github/workflows/saas_release_candidate.yml .github/workflows/saas_full_billing_staging_smoke.yml].each { |f| YAML.load_file(f); puts "parsed #{f}" }'
```

Passed with existing info-level lints only:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Passed:

```bash
scripts/run_saas_wave0_smoke.sh
```

Passed:

```bash
git diff --check
```

## Notes

`scripts/run_saas_wave0_smoke.sh` needed sandbox escalation locally because Flutter attempted to update `/Users/chauhua/.dart-tool/dart-flutter-telemetry-session.json`; the rerun passed. This was an environment permission issue, not a code failure.

`flutter analyze --no-fatal-infos` reported 83 existing info-level lint messages and no errors or warnings. This change did not touch Dart source.
