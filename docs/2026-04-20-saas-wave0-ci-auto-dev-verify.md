# SaaS Wave0 CI Auto Trigger Dev & Verify

Date: 2026-04-20
Branch: `codex/saas-wave0-ci-auto`

## Goal

Make the SaaS Wave0 smoke lane run automatically when SaaS-sensitive code changes, while preserving the existing manual `workflow_dispatch` input and `saas` PR label override.

This keeps normal Flutter PRs fast, but makes payment, auth, sync, Supabase function, and SaaS script changes harder to merge without the relevant smoke checks.

## Changes

- Added `scripts/should_run_saas_wave0_smoke.sh`.
- Added a `detect_saas_wave0_smoke` job in `.github/workflows/flutter_ci.yml`.
- Changed `saas_wave0_smoke` to read `needs.detect_saas_wave0_smoke.outputs.should_run`.
- Kept existing behavior:
  - `workflow_dispatch` with `run_saas_wave0_smoke=true` still runs the lane.
  - PRs labeled `saas` still run the lane.
- Added automatic path-based triggering for:
  - SaaS workflow and smoke scripts.
  - `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`.
  - Supabase functions and migrations.
  - Auth, entitlement, payment, subscription, and sync app code.
  - Auth, payment, subscription, and sync tests.

## Local Verification

```bash
bash -n scripts/should_run_saas_wave0_smoke.sh
```

Passed.

```bash
printf '' | scripts/should_run_saas_wave0_smoke.sh
printf 'lib/core/payment/payment_service.dart\n' | scripts/should_run_saas_wave0_smoke.sh
printf 'docs/readme.md\n' | scripts/should_run_saas_wave0_smoke.sh
printf '.github/workflows/flutter_ci.yml\n' | scripts/should_run_saas_wave0_smoke.sh
printf 'lib/core/service/sync_runtime_service.dart\n' | scripts/should_run_saas_wave0_smoke.sh
```

Results:

```text
false
true
false
true
true
```

```bash
printf 'supabase/functions/admin/index.ts\n' | scripts/should_run_saas_wave0_smoke.sh
printf 'assets/category_icons/foo.svg\n' | scripts/should_run_saas_wave0_smoke.sh
```

Results:

```text
true
false
```

```bash
ruby -e "require 'yaml'; YAML.load_file('.github/workflows/flutter_ci.yml'); puts 'yaml ok'"
```

Passed.

```bash
git diff --check
```

Passed.

```bash
bash scripts/run_saas_wave0_smoke.sh
```

Passed.

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Passed with existing info-level lints only. No errors or warnings were introduced.

## Notes

- The detector uses full fetch depth for its lightweight checkout so push events can compare `github.event.before` to `HEAD`, not just the last commit.
- The workflow does not use top-level `paths` filters. That is intentional, because top-level path filters would block label-only reruns.
- The smoke lane itself was not changed. This PR only changes when it is triggered.
