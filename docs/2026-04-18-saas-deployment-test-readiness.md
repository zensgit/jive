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

Initialize a local core env draft first:

```bash
bash scripts/init_saas_staging_env.sh \
  --env-file /tmp/jive-saas-staging.env
```

If `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are exported in the shell, the script will copy them into the local env file. Otherwise it leaves those fields empty and generates only local webhook/admin/analytics/notification tokens.

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

Once `SUPABASE_ACCESS_TOKEN`, `STAGING_PROJECT_REF`, and `STAGING_DB_PASSWORD` are exported, the fastest path is:

```bash
bash scripts/run_saas_core_staging_lane.sh \
  --env-file /tmp/jive-saas-staging.env
```

That lane initializes the env file, runs strict readiness, runs local Wave0 smoke, previews and applies migrations, deploys Edge Functions, runs deployed Function smoke, and builds the dev debug APK.

The same lane can also run from GitHub Actions through the manual `SaaS Core Staging` workflow. Add these repository secrets before using it:

- `STAGING_SUPABASE_ACCESS_TOKEN`
- `STAGING_PROJECT_REF`
- `STAGING_DB_PASSWORD`
- `STAGING_SUPABASE_URL`
- `STAGING_SUPABASE_ANON_KEY`
- `STAGING_SUPABASE_SERVICE_ROLE_KEY`
- `STAGING_PUBSUB_BEARER_TOKEN`
- `STAGING_WEBHOOK_HMAC_SECRET`
- `STAGING_ADMIN_API_TOKEN`
- `STAGING_ADMIN_API_ALLOWED_ORIGINS`
- `STAGING_ANALYTICS_ADMIN_TOKEN`
- `STAGING_NOTIFICATION_ADMIN_TOKEN`

By default, the workflow does not apply migrations or deploy Functions. Enable `apply_migrations`, `deploy_functions`, and `run_function_smoke` only when the staging secrets are ready.

Before running the workflow, check repository secret coverage without exposing values:

```bash
bash scripts/check_saas_github_secrets.sh \
  --profile core \
  --repo zensgit/jive
```

To print a safe setup template for missing GitHub Actions secrets:

```bash
bash scripts/check_saas_github_secrets.sh \
  --profile core \
  --repo zensgit/jive \
  --print-template
```

If the local env file and shell deployment variables are already prepared, upload the repository secrets in one safe pass:

```bash
bash scripts/push_saas_github_secrets.sh \
  --profile core \
  --repo zensgit/jive \
  --env-file /tmp/jive-saas-staging.env \
  --apply
```

Without `--apply`, the upload helper performs a dry run and reports only whether each value is present.

For manual execution, use the steps below.

1. Rotate exposed Supabase credentials in the Supabase dashboard.
2. Create or select the staging Supabase project.
3. Run `bash scripts/init_saas_staging_env.sh --env-file /tmp/jive-saas-staging.env`.
4. Fill any remaining Supabase fields locally. Do not commit the filled file.
5. Export `SUPABASE_ACCESS_TOKEN`, `STAGING_PROJECT_REF`, and `STAGING_DB_PASSWORD`.
6. Run `bash scripts/check_saas_deployment_readiness.sh --profile core --strict --online --env-file /tmp/jive-saas-staging.env`.
7. Run `bash scripts/run_saas_staging_rollout.sh preflight --profile core --env-file /tmp/jive-saas-staging.env`.
8. Run `bash scripts/run_saas_staging_rollout.sh apply --profile core --env-file /tmp/jive-saas-staging.env`.
9. Run `bash scripts/run_saas_staging_rollout.sh deploy --profile core --env-file /tmp/jive-saas-staging.env`.
10. Run deployed Functions smoke:

```bash
bash scripts/run_saas_staging_function_smoke.sh \
  --env-file /tmp/jive-saas-staging.env
```

11. Build a test app with staging Supabase config passed by `--dart-define`:

```bash
bash scripts/build_saas_staging_apk.sh \
  --env-file /tmp/jive-saas-staging.env \
  --flavor dev \
  --mode debug
```

The build helper only passes `SUPABASE_URL` and `SUPABASE_ANON_KEY` to Flutter. `SUPABASE_SERVICE_ROLE_KEY` stays server-side and is never passed into the app build.

## Minimum Smoke Scope

The first deployment test should verify only the SaaS-critical path:

- Supabase migrations apply cleanly.
- `subscription-webhook`, `verify-subscription`, `analytics`, `send-notification`, and `admin` deploy successfully.
- Custom-token Functions are deployed with in-function auth (`--no-verify-jwt`), while `verify-subscription` keeps Supabase JWT verification.
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
- `scripts/build_saas_staging_apk.sh`
- `scripts/check_saas_github_secrets.sh`
- `scripts/init_saas_staging_env.sh`
- `scripts/push_saas_github_secrets.sh`
- `scripts/run_saas_core_staging_lane.sh`
- `scripts/run_saas_staging_function_smoke.sh`
- `scripts/run_saas_staging_rollout.sh`
- `scripts/run_saas_wave0_smoke.sh`
