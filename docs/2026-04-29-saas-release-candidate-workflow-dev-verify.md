# SaaS Release Candidate Workflow Dev Verify

Date: 2026-04-29

Branch: `codex/saas-release-candidate-workflow-stack`

Base: `codex/saas-production-readiness-gate`

## Scope

This stacked pass adds a manual GitHub Actions entrypoint for SaaS production release-candidate verification.

It depends on the production readiness gate introduced in PR `#212` and therefore targets that branch as its PR base.

## Design

Added `.github/workflows/saas_release_candidate.yml`.

The workflow is manual-only through `workflow_dispatch` and defaults to dry-run mode:

- `build_appbundle=false` runs the production readiness gate and release-candidate report generation without invoking Flutter build.
- `build_appbundle=true` builds the Android `prod` release appbundle through `scripts/build_release_candidate.sh`.
- `strict_signing=true` requires Android release signing secrets and passes strict signing into the release lane.
- `flavor` is locked to `prod` for this first production SaaS workflow.

The workflow explicitly maps GitHub-facing production secret names to the script-facing runtime names:

- `PRODUCTION_SUPABASE_URL` -> `SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY` -> `SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID` -> `ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID` -> `ADMOB_BANNER_ID`
- `ANDROID_RELEASE_*` -> `JIVE_ANDROID_*` when `strict_signing=true`
- `build_appbundle=false` -> `JIVE_RELEASE_CANDIDATE_DRY_RUN=true`

Updated `docs/saas-ops-checklist.md` with:

- Release candidate workflow entrypoint.
- Required production secrets.
- Strict signing secrets.
- Recommended dry-run to signed-build sequence.
- Production release secret check/upload commands.
- Artifact expectations and sensitivity guard behavior.

Updated secret helper scripts:

- `scripts/check_saas_github_secrets.sh --profile production-release`
- `scripts/check_saas_github_secrets.sh --profile production-release --include-signing`
- `scripts/push_saas_github_secrets.sh --profile production-release`
- `scripts/push_saas_github_secrets.sh --profile production-release --include-optional --include-signing`

Added `scripts/init_saas_production_env.sh`.

The initializer creates or updates `/tmp/jive-saas-production.env` from `docs/jive-saas-production.env.example`, preserves existing values by default, generates missing server-side operation tokens, and leaves production Supabase / AdMob / signing values for explicit operator input.

## Secrets

Required for dry-run:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Optional:

- `PRODUCTION_ADMIN_API_ALLOWED_ORIGINS`
- `PRODUCTION_PAYMENT_CHANNEL`

Required only when `strict_signing=true`:

- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_RELEASE_STORE_PASSWORD`
- `ANDROID_RELEASE_KEY_ALIAS`
- `ANDROID_RELEASE_KEY_PASSWORD`

## Safety

- The workflow writes production client values into `$RUNNER_TEMP/jive-saas-production.env`, not into the repository, and exports `PRODUCTION_ENV_FILE` so the release/readiness scripts read that exact file instead of their local `/tmp/jive-saas-production.env` default.
- Secret values are masked before the release lane runs.
- Android signing material is restored only when strict signing is enabled.
- Artifact upload is guarded against env, key, credential, secret, and dart-define filenames.
- Uploaded artifacts contain only release-candidate reports and optional release-candidate build outputs.

## Validation

### Workflow Parse

Command:

```bash
ruby -e "require 'psych'; Psych.parse_file('.github/workflows/saas_release_candidate.yml')"
```

Result: passed.

### Script Syntax

Command:

```bash
bash -n scripts/build_release_candidate.sh scripts/check_saas_production_readiness.sh scripts/check_saas_github_secrets.sh scripts/push_saas_github_secrets.sh
```

Result: passed.

Additional command after adding the production env initializer:

```bash
bash -n scripts/init_saas_production_env.sh
```

Result: passed.

### Production Secret Helpers

Commands:

```bash
scripts/check_saas_github_secrets.sh --profile production-release --print-template --repo zensgit/jive
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --print-template --repo zensgit/jive
scripts/push_saas_github_secrets.sh --profile production-release --env-file /tmp/<temp-prod-env>
scripts/init_saas_production_env.sh --env-file /tmp/<temp-prod-env>
```

Result: passed. The push helper dry-run reported values present without writing GitHub secrets, and the init helper created a chmod `600` env file without printing secret values.

The generated temporary env file was also passed through:

```bash
bash scripts/check_saas_production_readiness.sh --env-file /tmp/<temp-prod-env> --profile app --store android
bash scripts/push_saas_github_secrets.sh --profile production-release --repo zensgit/jive --env-file /tmp/<temp-prod-env>
```

Result: passed with the expected non-strict warning that Android release signing was not configured.

### Release Candidate Dry Run

Command used a temporary production-shaped env file with fake non-secret Supabase/AdMob values:

```bash
PRODUCTION_ENV_FILE=/tmp/<temp-prod-env> \
JIVE_RELEASE_CANDIDATE_DRY_RUN=true \
bash scripts/build_release_candidate.sh
```

Result: passed. The production readiness gate ran and the release lane stopped before Flutter build as expected.

### Linux Artifact Size Compatibility

Review follow-up: `scripts/build_release_candidate.sh` now uses a cross-platform `file_size_bytes` helper. It tries GNU/Linux `stat -c%s`, falls back to BSD/macOS `stat -f%z`, then falls back to `wc -c`.

Static check:

```bash
grep -n "file_size_bytes\\|stat -c%s\\|stat -f%z" scripts/build_release_candidate.sh
```

Result: the release candidate lane now matches the existing staging APK helper pattern. The helper is covered indirectly by script syntax validation and by the production dry-run path. The production dry-run intentionally does not create an AAB, so the final artifact-size branch is exercised by release builds.

### Diff Whitespace

Command:

```bash
git diff --check
```

Result: passed.

### SaaS Wave0 Smoke

Command:

```bash
bash scripts/run_saas_wave0_smoke.sh
```

Result: passed.

Covered:

- Sync book scope and tombstone tests.
- Subscription webhook, verify-subscription, Google Play / App Store trusted entitlement client tests.
- Domestic payment order and webhook smoke tests.
- Auth service and auth screen smoke tests.
- Analytics, notification, and admin Edge Function smoke tests.

### GitHub Production Secret Inventory

Commands:

```bash
scripts/check_saas_github_secrets.sh --profile production-release --repo zensgit/jive
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive
```

Result: failed as expected because production release secrets have not been configured yet.

Missing minimum dry-run secrets:

- `PRODUCTION_SUPABASE_URL`
- `PRODUCTION_SUPABASE_ANON_KEY`
- `PRODUCTION_ADMOB_APP_ID`
- `PRODUCTION_ADMOB_BANNER_ID`

Missing strict signing secrets:

- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_RELEASE_STORE_PASSWORD`
- `ANDROID_RELEASE_KEY_ALIAS`
- `ANDROID_RELEASE_KEY_PASSWORD`

Current GitHub workflow visibility check:

- `SaaS Core Staging`: active.
- `SaaS Full Billing Staging Smoke`: active.
- `SaaS Release Candidate`: not listed yet because this workflow is still in this stacked PR and has not been merged to the default branch.

## Residual Work

- After PR `#212` merges, rebase this branch onto `main` and open/retarget the final PR to `main`.
- Add real production secrets in GitHub Actions before running the workflow.
- Use `strict_signing=true` for any release candidate intended for store upload.
