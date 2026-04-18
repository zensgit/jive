# Jive SaaS Deployment Test Readiness

> Date: 2026-04-18
> Goal: make the first SaaS staging deployment test repeatable without exposing secrets in the repo or chat.

## Current Position

Code is close enough to start deployment testing once the staging environment is prepared. The remaining work is mainly operational:

- rotate any Supabase keys or tokens that were pasted into chat before using the project for real testing;
- prepare a local `/tmp/jive-saas-staging.env` from `docs/jive-saas-staging.env.example`;
- run the repository smoke lane and staging rollout script from a clean main checkout;
- build an Android test package with `SUPABASE_URL` and `SUPABASE_ANON_KEY` passed through `--dart-define`.

This document does not replace the detailed runbooks. It adds a fast readiness gate before executing them.

## New Readiness Gate

Run the static preflight first:

```bash
bash scripts/check_saas_deployment_readiness.sh --profile core
```

When the staging env file has been filled locally, run strict mode:

```bash
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --strict \
  --env-file /tmp/jive-saas-staging.env
```

When network access is available, add online checks:

```bash
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --online \
  --env-file /tmp/jive-saas-staging.env
```

Before applying migrations, run the smoke lane:

```bash
bash scripts/check_saas_deployment_readiness.sh \
  --profile core \
  --online \
  --run-smoke \
  --env-file /tmp/jive-saas-staging.env
```

The script only reports whether secret values are present. It never prints the values.

## Fast Path To Deployment Test

1. Rotate exposed Supabase credentials in the Supabase dashboard.
2. Create or select the staging Supabase project.
3. Copy `docs/jive-saas-staging.env.example` to `/tmp/jive-saas-staging.env`.
4. Fill the env file locally. Do not commit the filled file.
5. Export `SUPABASE_ACCESS_TOKEN`, `STAGING_PROJECT_REF`, and `STAGING_DB_PASSWORD`.
6. Run `bash scripts/check_saas_deployment_readiness.sh --profile core --strict --online --env-file /tmp/jive-saas-staging.env`.
7. Run `bash scripts/run_saas_staging_rollout.sh preflight --profile core --env-file /tmp/jive-saas-staging.env`.
8. Run `bash scripts/run_saas_staging_rollout.sh apply --profile core --env-file /tmp/jive-saas-staging.env`.
9. Run `bash scripts/run_saas_staging_rollout.sh deploy --profile core --env-file /tmp/jive-saas-staging.env`.
10. Build a test app with staging Supabase config passed by `--dart-define`.

## Minimum Smoke Scope

The first deployment test should verify only the SaaS-critical path:

- Supabase migrations apply cleanly.
- `subscription-webhook`, `verify-subscription`, `analytics`, `send-notification`, and `admin` deploy successfully.
- A user can sign in against staging auth.
- Subscriber-only sync remains locked for a free user.
- A trusted subscription state can unlock subscriber gates.
- A transaction created on one client syncs to another clean client.
- Admin and analytics endpoints reject requests without their tokens.

## Not Required For The First Deployment Test

These should not block the first staging deployment test:

- production Play Store release approval;
- real Apple subscription receipt validation;
- admin dashboard UI;
- outbound notification provider delivery;
- domestic payment and domestic ad SDK integrations;
- Web app deployment.

Use `--profile full` only when Google Play and Apple provider credentials are ready. The `core` profile still deploys the same SaaS Functions, but it does not require store-provider credentials during the first Supabase/Auth/Sync smoke.

## Time Estimate

If the staging credentials are ready, the first deployment test is roughly a one-day lane:

- 1-2 hours for credential rotation, env file preparation, and readiness checks;
- 1-2 hours for Supabase migrations and Edge Function deployment;
- 2-4 hours for Android staging build, auth, entitlement, and sync smoke;
- 2-4 hours buffer for environment-specific fixes.

If Google Play / Apple production purchase verification is included, add another 2-4 days because store-side configuration and review delays are outside the codebase.

## References

- `docs/2026-04-10-saas-fast-track-checklist.md`
- `docs/2026-04-10-saas-staging-apply-runbook.md`
- `docs/2026-04-10-saas-staging-troubleshooting.md`
- `docs/jive-saas-staging.env.example`
- `scripts/run_saas_staging_rollout.sh`
- `scripts/run_saas_wave0_smoke.sh`
