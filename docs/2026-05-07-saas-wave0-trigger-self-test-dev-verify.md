# SaaS Wave0 Trigger Self-Test Dev & Verify

Date: 2026-05-07
Branch: `codex/saas-wave0-trigger-self-test`
Base: `origin/main@53c1097b8f2dc7a1db2bdaf97e8809c63d94154f`

## Goal

Add a small host-only safety net around the SaaS Wave0 smoke auto-trigger predicate.

The trigger script decides whether `.github/workflows/flutter_ci.yml` should run the SaaS Wave0 smoke lane for a PR or push. Before this change, the predicate had examples in documentation but no executable contract test in CI. This change makes the expected true/false path matrix explicit and repeatable.

## Changes

- Added `scripts/test_saas_wave0_smoke_trigger.sh`.
- Covered both stdin mode and argv mode for `scripts/should_run_saas_wave0_smoke.sh`.
- Added the new self-test script to the SaaS-sensitive path list so edits to the test itself run SaaS Wave0.
- Wired the self-test into the existing `release_smoke_script_self_check` GitHub Actions job.
- Updated `docs/release_smoke_lane_mvp.md` to mention the SaaS Wave0 trigger contract self-test.

## Trigger Contract Covered

Expected `false`:

- Empty input.
- `docs/readme.md`.
- `assets/category_icons/foo.svg`.

Expected `true`:

- `.github/workflows/flutter_ci.yml`.
- `scripts/should_run_saas_wave0_smoke.sh`.
- `scripts/test_saas_wave0_smoke_trigger.sh`.
- `lib/core/payment/payment_service.dart`.
- `lib/core/service/sync_runtime_service.dart`.
- `lib/core/sync/sync_engine.dart`.
- `supabase/functions/admin/index.ts`.
- `supabase/migrations/20260420000000_init.sql`.
- Mixed path input where at least one path is SaaS-sensitive.

## Local Verification

```bash
for script in scripts/should_run_saas_wave0_smoke.sh scripts/test_saas_wave0_smoke_trigger.sh scripts/run_release_smoke.sh scripts/run_release_android_smoke.sh scripts/run_android_local_feature_smoke.sh scripts/verify_release_android_smoke_artifacts.sh scripts/render_release_android_smoke_summary.sh scripts/test_release_android_smoke_artifact_verifier.sh scripts/test_release_android_smoke_summary_renderer.sh; do bash -n "$script"; done
```

Result: passed.

```bash
scripts/test_saas_wave0_smoke_trigger.sh
```

Result: passed.

```text
[saas-wave0-trigger-test] ok stdin empty input                                    => false
[saas-wave0-trigger-test] ok stdin docs-only change                               => false
[saas-wave0-trigger-test] ok stdin category-icon asset-only change                => false
[saas-wave0-trigger-test] ok stdin workflow change                                => true
[saas-wave0-trigger-test] ok stdin trigger script change                          => true
[saas-wave0-trigger-test] ok stdin trigger self-test change                       => true
[saas-wave0-trigger-test] ok stdin payment service change                         => true
[saas-wave0-trigger-test] ok stdin sync service change                            => true
[saas-wave0-trigger-test] ok stdin supabase function change                       => true
[saas-wave0-trigger-test] ok stdin supabase migration change                      => true
[saas-wave0-trigger-test] ok stdin mixed irrelevant and SaaS paths                => true
[saas-wave0-trigger-test] ok args  argv docs-only change                          => false
[saas-wave0-trigger-test] ok args  argv multiple paths with SaaS hit              => true
[saas-wave0-trigger-test] all checks passed
```

```bash
scripts/test_saas_wave0_smoke_trigger.sh --help
```

Result: passed.

```bash
scripts/test_release_android_smoke_artifact_verifier.sh
```

Result: passed.

```bash
scripts/test_release_android_smoke_summary_renderer.sh
```

Result: passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml"); puts "workflow yaml parsed"'
```

Result: passed.

```bash
git diff --check
```

Result: passed.

```bash
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Result: passed with 0 errors and 0 warnings. Existing info-level lints remain outside this change.

```bash
bash scripts/run_saas_wave0_smoke.sh
```

Result: passed.

Covered lanes included sync, subscription webhook, trusted subscription client/server tests, verify-subscription, create-payment-order, domestic-payment-webhook, auth, analytics, notification, and admin smoke tests.

## Notes

- No Flutter code, database schema, Supabase function behavior, secrets, emulator, or device flow changed.
- This PR intentionally freezes the current trigger path contract. If SaaS folders move later, update both `scripts/should_run_saas_wave0_smoke.sh` and `scripts/test_saas_wave0_smoke_trigger.sh` in the same PR.
