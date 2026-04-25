# Full Function Smoke Domestic Token Dev & Verify

Date: 2026-04-26 02:50 CST
Branch: `codex/require-domestic-token-full-smoke`
Base commit: `25702e68`

## Goal

Make `full` SaaS function smoke fail fast when domestic payment webhook credentials are missing.

Before this change, `run_saas_staging_function_smoke.sh --profile full` treated `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` as optional and silently skipped domestic payment webhook checks. That behavior no longer matched the rest of the staging/full-profile contract, where domestic payment webhook deployment requires the token.

## Development Changes

Updated `scripts/run_saas_staging_function_smoke.sh`.

- Changed help text from `DOMESTIC_PAYMENT_WEBHOOK_TOKEN (optional; enables domestic payment smoke)` to `DOMESTIC_PAYMENT_WEBHOOK_TOKEN (full profile only)`.
- In `full` profile, load `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` through `require_key`.
- Removed the conditional domestic payment smoke skip branch.
- `core` profile remains unchanged and does not require domestic payment secrets.

## Why This Shape

`core` profile is still the safe first staging deployment profile and should not require domestic payment secrets.

`full` profile means billing/webhook coverage is intentionally enabled. If domestic payment webhook token is missing, skipping that section creates a false sense that full webhook smoke passed. Failing fast is safer and aligns with:

- `scripts/check_saas_deployment_readiness.sh`
- `scripts/run_saas_staging_rollout.sh`
- `docs/2026-04-20-domestic-payment-restack-dev-verify.md`

## Validation

Static validation passed:

```bash
bash -n scripts/run_saas_staging_function_smoke.sh
scripts/run_saas_staging_function_smoke.sh --help
git diff --check
```

Fake-curl function smoke validation passed:

```text
core without domestic token: PASS
full missing domestic token: failed as expected
full with domestic token: PASS
```

Full SaaS Wave0 smoke passed:

```bash
bash scripts/run_saas_wave0_smoke.sh
```

Result:

```text
[saas-wave0-smoke] Wave 0 SaaS smoke completed
```

## Not Rerun

- Live staging `run_saas_staging_function_smoke.sh --profile full` was not rerun because this change only tightens local preflight behavior for an already-defined secret and no staging deploy was needed.
- Full `flutter analyze` / full `flutter test` were not run separately because this PR changes only a shell smoke script. The SaaS-targeted Flutter and Deno checks are covered by `bash scripts/run_saas_wave0_smoke.sh`.

## Follow-Up

The next useful staging reliability task is an opt-in domestic payment happy-path smoke that creates a temporary staging auth user, creates a domestic payment order, sends a paid webhook, verifies the trusted subscription projection, and cleans up all temporary rows.
