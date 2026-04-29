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

- The workflow writes production client values into `$RUNNER_TEMP/jive-saas-production.env`, not into the repository.
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
bash -n scripts/build_release_candidate.sh scripts/check_saas_production_readiness.sh
```

Result: passed.

### Release Candidate Dry Run

Command used a temporary production-shaped env file with fake non-secret Supabase/AdMob values:

```bash
PRODUCTION_ENV_FILE=/tmp/<temp-prod-env> \
JIVE_RELEASE_CANDIDATE_DRY_RUN=true \
bash scripts/build_release_candidate.sh
```

Result: passed. The production readiness gate ran and the release lane stopped before Flutter build as expected.

### Diff Whitespace

Command:

```bash
git diff --check
```

Result: passed.

## Residual Work

- After PR `#212` merges, rebase this branch onto `main` and open/retarget the final PR to `main`.
- Add real production secrets in GitHub Actions before running the workflow.
- Use `strict_signing=true` for any release candidate intended for store upload.

