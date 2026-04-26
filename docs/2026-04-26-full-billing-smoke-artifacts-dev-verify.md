# Full Billing Smoke Artifacts Dev Verify

Date: 2026-04-26
Branch: `codex/full-billing-smoke-artifacts`

## Summary

Improved the manual `SaaS Full Billing Staging Smoke` workflow so a successful or failed run leaves a compact, auditable evidence bundle instead of requiring maintainers to inspect raw Actions logs.

This is a deployment-test reliability change only. It does not change Dart app code, Supabase SQL schema, Edge Function behavior, payment projection logic, or staging data writes.

## Design

The workflow now prepares a temporary report directory at:

```text
$RUNNER_TEMP/saas-full-billing-staging-smoke
```

The directory contains:

- `metadata.md`: repository, run id, run attempt, ref, SHA, and the workflow inputs used for the run.
- `smoke.log`: stdout/stderr from `scripts/run_saas_staging_function_smoke.sh`, captured with `tee` while preserving `pipefail`.
- `summary.md`: a GitHub Step Summary friendly report with PASS/FAIL/SKIPPED status and the last 120 log lines.

The workflow appends `summary.md` to `$GITHUB_STEP_SUMMARY`, then uploads the report directory as:

```text
saas-full-billing-smoke-${{ github.run_id }}
```

## Safety Boundary

Before upload, `Guard full billing smoke artifacts` checks:

- no sensitive-looking file names are present, including `.env`, `.pem`, `.key`, `*secret*`, `*credential*`, and `*dart-defines*`;
- report files do not contain exact configured secret values for anon key, access token, service role key, admin tokens, notification token, Pub/Sub token, or domestic webhook token.

The upload step runs only when the artifact guard succeeds. If the guard fails, the workflow fails and the report artifact is not uploaded.

Supabase project URL / functions URL / project ref are not treated as secret values for this artifact guard because the smoke log intentionally records the deployed Functions base URL for traceability.

## Validation

Local workflow syntax:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_full_billing_staging_smoke.yml"); puts "yaml ok"'
```

Result:

```text
yaml ok
```

Pending post-merge live validation:

```bash
gh workflow run saas_full_billing_staging_smoke.yml \
  --repo zensgit/jive \
  --ref main \
  -f sync_domestic_payment_secret=true \
  -f deploy_payment_smoke_functions=true \
  -f run_domestic_payment_e2e=false
```

Expected result:

- workflow conclusion `success`;
- Step Summary contains full billing smoke metadata and log tail;
- artifact `saas-full-billing-smoke-<run_id>` is present;
- artifact contains `metadata.md`, `smoke.log`, and `summary.md`;
- artifact guard does not block the normal report bundle.

## Deferred

- No change to the existing core staging workflow; it already has its own report upload path.
- No new production payment provider integration.
- No new database migration or Supabase Function API.
