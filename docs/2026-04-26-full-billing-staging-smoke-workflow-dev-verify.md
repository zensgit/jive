# Full Billing Staging Smoke Workflow Dev Verify

Date: 2026-04-26

## Summary

Added an independent manual GitHub Actions workflow for full-profile SaaS billing function smoke.

This keeps the existing `SaaS Core Staging` lane scoped to core functions while giving staging a safe button for the full billing/webhook surface.

## Changed Files

- `.github/workflows/saas_full_billing_staging_smoke.yml`
- `scripts/check_saas_github_secrets.sh`
- `scripts/push_saas_github_secrets.sh`

## Behavior

The new `SaaS Full Billing Staging Smoke` workflow:

- Is `workflow_dispatch` only.
- Runs `scripts/run_saas_staging_function_smoke.sh --profile full`.
- Accepts an optional `run_domestic_payment_e2e` boolean input.
- Defaults `run_domestic_payment_e2e` to `false`, so the default workflow path is non-writing.
- Requires `STAGING_SUPABASE_SERVICE_ROLE_KEY` only when `run_domestic_payment_e2e=true`.
- Writes `SUPABASE_SERVICE_ROLE_KEY` into the temporary env file only when `run_domestic_payment_e2e=true`.
- Does not deploy functions, apply migrations, build APKs, or alter the existing core staging lane.

The full-profile secret helper scripts now include:

- `STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN`

This aligns the GitHub secret check/upload tooling with the full function smoke script, which already requires `DOMESTIC_PAYMENT_WEBHOOK_TOKEN` for `--profile full`.

## Required Secrets

Default full smoke:

- `STAGING_SUPABASE_URL`
- `STAGING_SUPABASE_ANON_KEY`
- `STAGING_PUBSUB_BEARER_TOKEN`
- `STAGING_ADMIN_API_TOKEN`
- `STAGING_ANALYTICS_ADMIN_TOKEN`
- `STAGING_NOTIFICATION_ADMIN_TOKEN`
- `STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN`

Only when `run_domestic_payment_e2e=true`:

- `STAGING_SUPABASE_SERVICE_ROLE_KEY`

Optional:

- `STAGING_SUPABASE_FUNCTIONS_URL`
- `STAGING_GOOGLE_PLAY_PACKAGE_NAME`

## Validation

```bash
for f in \
  scripts/run_saas_staging_function_smoke.sh \
  scripts/check_saas_github_secrets.sh \
  scripts/push_saas_github_secrets.sh; do
  bash -n "$f"
done
```

Passed.

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/saas_full_billing_staging_smoke.yml"); puts "yaml ok"'
```

Passed.

```bash
scripts/check_saas_github_secrets.sh \
  --profile full \
  --repo zensgit/jive \
  --print-template | rg STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN
```

Passed. The full-profile template now includes the domestic webhook token.

```bash
env_file="$(mktemp)"
cat > "$env_file" <<'EOF'
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
SUPABASE_SERVICE_ROLE_KEY=service
PUBSUB_BEARER_TOKEN=pubsub
WEBHOOK_HMAC_SECRET=hmac
ADMIN_API_TOKEN=admin
ADMIN_API_ALLOWED_ORIGINS=https://example.com
ANALYTICS_ADMIN_TOKEN=analytics
NOTIFICATION_ADMIN_TOKEN=notification
GOOGLE_SERVICE_ACCOUNT_EMAIL=google@example.com
GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY=private
GOOGLE_PLAY_PACKAGE_NAME=com.jivemoney.app.dev
APPLE_APP_STORE_BUNDLE_ID=com.jivemoney.app.dev
APPLE_APP_STORE_SHARED_SECRET=apple-secret
APPLE_APP_STORE_APPLE_ID=1234567890
APPLE_APP_STORE_ENVIRONMENT=Sandbox
DOMESTIC_PAYMENT_WEBHOOK_TOKEN=domestic
EOF
STAGING_SUPABASE_ACCESS_TOKEN=access \
STAGING_PROJECT_REF=project \
STAGING_DB_PASSWORD=password \
  scripts/push_saas_github_secrets.sh \
    --profile full \
    --repo zensgit/jive \
    --env-file "$env_file"
rm -f "$env_file"
```

Passed. The dry run reports a ready value for `STAGING_DOMESTIC_PAYMENT_WEBHOOK_TOKEN`.

## Live Staging Status

The new workflow was not run from GitHub Actions in this PR because it requires staging runtime secrets and deployed full billing functions. After merge, run it manually from Actions:

```text
Actions -> SaaS Full Billing Staging Smoke -> Run workflow
```

Recommended first run:

```text
run_domestic_payment_e2e=false
```

After the non-writing full smoke passes, run the temporary write-path smoke:

```text
run_domestic_payment_e2e=true
```

## Notes

The existing `SaaS Core Staging` workflow remains core-only. It still uses `run_saas_core_staging_lane.sh`, which calls function smoke with `--profile core`.
