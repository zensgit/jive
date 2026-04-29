# SaaS Production Readiness Gate Dev Verify

Date: 2026-04-29

Branch: `codex/saas-production-readiness-gate`

## Scope

This pass adds a release guard between staging SaaS validation and production/release-candidate packaging.

It does not add new SaaS features, database schema, Supabase Functions, payment providers, or UI flows.

## Design

### Production Readiness Gate

Added `scripts/check_saas_production_readiness.sh`.

The gate checks production app/billing safety without printing secret values:

- Client Supabase URL must be HTTPS and must not point to localhost or the known staging project unless explicitly allowed.
- Supabase anon key must not look like a Supabase access token.
- AdMob app/banner IDs must be present and must not be Google test IDs unless explicitly allowed.
- Android release signing can warn by default or fail under `--strict` / `--require-release-signing`.
- Domestic payment mock base URL must be empty.
- Domestic payment providers remain blocked for production until provider signature verification replaces staging shared-token webhook auth.
- Store billing must not be explicitly disabled.
- Billing/full profiles also check admin origins and store verification secret presence.

### Production Env Example

Added `docs/jive-saas-production.env.example`.

The example documents production-only values expected by the gate and release lane. Filled production env files must stay outside git, normally at `/tmp/jive-saas-production.env` or a CI secret-generated file.

### AdMob Injection

Updated Android/Dart AdMob config:

- `android/app/src/main/AndroidManifest.xml` now uses `${adMobApplicationId}` instead of a hardcoded test app ID.
- `android/app/build.gradle.kts` reads `ADMOB_APP_ID` from Gradle properties or environment, defaulting to the Google test ID for dev builds.
- `lib/core/ads/ad_config.dart` reads `ADMOB_BANNER_ID` from dart-define, defaulting to the Google test banner ID for dev builds.

This preserves local development behavior while making release-candidate builds injectable and guardable.

### Release Candidate Lane

Updated `scripts/build_release_candidate.sh`:

- Defaults to `/tmp/jive-saas-production.env` via `PRODUCTION_ENV_FILE`.
- Runs the SaaS production readiness gate before a `prod` release build.
- Builds a temporary `--dart-define-from-file` with client-safe values only.
- Exports `ADMOB_APP_ID` for Gradle manifest placeholder resolution.
- Adds `JIVE_RELEASE_CANDIDATE_DRY_RUN=true` for non-building verification.
- Records readiness/dry-run/dart-define state in release-candidate reports.

### Staging Lane Guard

Updated `scripts/build_saas_staging_apk.sh`:

- Refuses `--flavor prod` by default.
- Allows intentional diagnostics only with `--allow-prod-flavor` or `JIVE_SAAS_ALLOW_PROD_FLAVOR=1`.

This prevents staging artifacts from being confused with release-candidate artifacts.

## Validation

### Script Syntax

Command:

```bash
bash -n scripts/check_saas_production_readiness.sh scripts/build_saas_staging_apk.sh scripts/build_release_candidate.sh
```

Result: passed.

### Diff Whitespace

Command:

```bash
git diff --check
```

Result: passed.

### Readiness Gate Negative Case

Command used a temporary env with localhost Supabase, Supabase access-token-shaped anon key, AdMob test IDs, domestic payment enabled, and mock domestic base URL.

Result: failed as expected with 5 failures.

### Readiness Gate Positive App Case

Command used a temporary production-shaped env with HTTPS Supabase URL, JWT-shaped anon key, real-shaped AdMob IDs, Google Play channel, store billing enabled, domestic providers disabled, and empty domestic mock base URL.

Result: passed with one expected warning for missing Android release signing.

### Release Candidate Dry Run

Command:

```bash
PRODUCTION_ENV_FILE=/tmp/<temp-prod-env> \
JIVE_RELEASE_CANDIDATE_DRY_RUN=true \
scripts/build_release_candidate.sh
```

Result: passed. The script ran production readiness, generated release-candidate reports, and skipped Flutter build by design.

### Staging Prod Flavor Guard

Command:

```bash
scripts/build_saas_staging_apk.sh --env-file /tmp/<temp-staging-env> --flavor prod --mode debug
```

Result: failed as expected before Flutter build with:

```text
staging build refuses prod flavor
```

### Dart Analysis

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze lib/core/ads/ad_config.dart
```

Result: passed, no issues found.

Full repository analyze was also run:

```bash
/Users/chauhua/development/flutter/bin/flutter analyze
```

Result: no analyzer errors or warnings from this change, but the command returned non-zero because the current worktree has 146 pre-existing `info` items, mostly duplicate ` 2.dart` filenames, category-service brace hints, and existing deprecations. These were not changed in this pass.

### Android Build Smoke

Command:

```bash
/Users/chauhua/development/flutter/bin/flutter build apk --debug --flavor dev --dart-define=ADMOB_BANNER_ID=ca-app-pub-3940256099942544/6300978111
```

Result: passed.

Artifact:

```text
build/app/outputs/flutter-apk/app-dev-debug.apk
```

This validates the Android manifest placeholder path through a real Flutter/Gradle build.

## Residual Work

- Fill real production values in `/tmp/jive-saas-production.env` or CI-generated env files before building production release candidates.
- Run strict production release gate before real release:

```bash
scripts/check_saas_production_readiness.sh --profile full --store android --strict --require-release-signing --env-file /tmp/jive-saas-production.env
```

- Configure Android release signing before publishing.
- Keep domestic payment disabled in production until provider signature verification is implemented.
- Clean pre-existing analyzer info items in a separate lint hygiene pass.

