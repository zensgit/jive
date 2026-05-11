# SaaS GitHub Secrets Self-Test Dev/Verify

Date: 2026-05-11

## Goal

Add host-only safety coverage for the SaaS GitHub Actions secret helper scripts:

- `scripts/check_saas_github_secrets.sh`
- `scripts/push_saas_github_secrets.sh`

The test uses a fake `gh` CLI and never talks to GitHub, reads real repository secrets, writes real secrets, or requires network credentials.

## Changes

- Added `scripts/test_saas_github_secrets.sh`.
- Added the new test plus the check/push scripts to `.github/workflows/flutter_ci.yml` under `saas_production_readiness_self_check`.
- Added `check_saas_github_secrets.sh`, `push_saas_github_secrets.sh`, and `test_saas_github_secrets.sh` to `scripts/should_run_saas_wave0_smoke.sh`.
- Extended `scripts/test_saas_wave0_smoke_trigger.sh` to assert those paths trigger Wave0 smoke.
- Kept the change limited to script/CI validation. No Dart production code, Supabase schema, Edge Function, payment runtime, or app UI changed.

## Contract Coverage

- Both helper scripts expose `--help` without requiring a real `gh` session.
- `check_saas_github_secrets.sh --print-template` prints secret names/templates only and does not call `gh secret list`.
- Missing required core secrets fail clearly without printing fixture secret values.
- Complete core secret matrices pass.
- `push_saas_github_secrets.sh` dry-run validates values but does not call `gh secret set`.
- `push_saas_github_secrets.sh --apply` writes secret names through fake `gh`, then post-checks through `check_saas_github_secrets.sh`.
- Production-release profile validates production client secret names and does not print fixture values.
- Wave0 path detection now treats the GitHub secret helper scripts and their self-test as SaaS-sensitive.

## Verification

Run from `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-github-secrets-self-test`.

```bash
bash -n scripts/check_saas_github_secrets.sh scripts/push_saas_github_secrets.sh scripts/test_saas_github_secrets.sh scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh
scripts/test_saas_github_secrets.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "yaml ok"'
```

Result: passed.

```bash
scripts/test_saas_deployment_readiness.sh
scripts/test_saas_core_staging_lane.sh
scripts/test_saas_staging_rollout.sh
scripts/test_saas_full_billing_staging_smoke_workflow.sh
scripts/test_saas_release_candidate_workflow.sh
scripts/test_saas_staging_apk_builder.sh
scripts/test_saas_staging_apk_installer.sh
scripts/test_saas_staging_device_smoke.sh
scripts/test_saas_production_release_readiness_report.sh
scripts/test_saas_github_secrets.sh
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```bash
scripts/run_saas_wave0_smoke.sh
```

Result: passed.

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: exit 0. Existing info-level lints remain, with no analyzer errors or warnings.

```bash
git diff --check
```

Result: passed.

## Limitations

- This is a host-only fake-`gh` self-test. It does not verify real GitHub permissions, real organization policies, or real secret writes.
- The test intentionally checks that fixture secret values are not echoed, but it is not a substitute for GitHub Actions log redaction in production.
