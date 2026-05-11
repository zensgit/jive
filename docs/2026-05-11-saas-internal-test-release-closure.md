# SaaS Internal Test Release Closure

Date: 2026-05-11

Branch: `codex/saas-internal-test-release-closure`

Base: `origin/main` at `2031e898d4878cb9330b785ff3cfab7a1ae1d7ee`

## Summary

The Google Play internal-test release lane is code-ready, but the production AAB is still blocked by missing production client configuration. This pass completed the part that can be safely automated from the local environment: Android release signing material was generated, uploaded to GitHub Actions secrets, and verified by the existing secret checker.

No release-candidate workflow run was triggered in this blocked state. Running it now would fail at the production secret guard because the production Supabase and AdMob client values are not configured yet.

## Completed

| Area | Result |
| --- | --- |
| Clean worktree | Used `/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-internal-test-release-closure`; dirty app worktree was not touched. |
| Main CI | Latest main Flutter CI is green: run `25679849138`, head `2031e898d4878cb9330b785ff3cfab7a1ae1d7ee`. |
| Release workflow | `SaaS Release Candidate` is active on GitHub Actions. |
| Android signing | Generated a new release upload keystore and uploaded all four signing secrets to GitHub Actions. |
| Secret verification | Signing secrets now pass the production-release checker; only production Supabase and AdMob values remain missing. |
| Script self-tests | Release workflow contract, GitHub secret helper, and production readiness report self-tests all passed locally. |

## Android Signing Material

Local secure directory:

```text
/Users/chauhua/.jive/release-signing/2026-05-11
```

Generated alias:

```text
jive_release_upload_20260511
```

Upload certificate SHA-256 fingerprint:

```text
FE:03:65:D5:8D:DE:65:7E:1C:3D:C4:94:71:32:BF:D2:0D:51:85:9C:67:36:62:80:C1:48:41:69:A3:84:7F:BF
```

Important: if the Google Play app has already been created with a different upload key, verify Play Console signing settings before using this generated key.

## Remaining Blocker

The following required GitHub Actions secrets are still missing:

| Secret | Purpose |
| --- | --- |
| `PRODUCTION_SUPABASE_URL` | Production Supabase client URL for the prod build. |
| `PRODUCTION_SUPABASE_ANON_KEY` | Production Supabase anon key for the prod build. |
| `PRODUCTION_ADMOB_APP_ID` | Production AdMob app id injected into Android manifest. |
| `PRODUCTION_ADMOB_BANNER_ID` | Production AdMob banner unit id passed as a Dart define. |

The release gate intentionally rejects staging Supabase values and Google test AdMob ids. Do not unblock this by reusing staging or test ids.

## Verification

Latest main CI:

```text
run=25679849138 status=completed conclusion=success head=2031e898d4878cb9330b785ff3cfab7a1ae1d7ee url=https://github.com/zensgit/jive/actions/runs/25679849138
```

Production secret check with strict signing:

```text
[saas-github-secrets] PASS: secret exists: ANDROID_RELEASE_KEYSTORE_BASE64
[saas-github-secrets] PASS: secret exists: ANDROID_RELEASE_STORE_PASSWORD
[saas-github-secrets] PASS: secret exists: ANDROID_RELEASE_KEY_ALIAS
[saas-github-secrets] PASS: secret exists: ANDROID_RELEASE_KEY_PASSWORD
[saas-github-secrets] ERROR: 4 required GitHub Actions secret(s) missing
```

Local self-tests:

```text
./scripts/test_saas_release_candidate_workflow.sh
./scripts/test_saas_github_secrets.sh
./scripts/test_saas_production_release_readiness_report.sh
```

Result:

```text
all checks passed
```

Readiness report generated locally:

```text
build/reports/saas-production-release-readiness/2026-05-11-internal-test-release.md
```

## Next Commands After Production Values Are Ready

Create `/tmp/jive-saas-production.env` with only production values:

```bash
SUPABASE_URL=<production supabase url>
SUPABASE_ANON_KEY=<production anon key>
ADMOB_APP_ID=<production admob app id>
ADMOB_BANNER_ID=<production admob banner id>
PAYMENT_CHANNEL=google_play
```

Upload production client values and verify. The Android signing secrets are already present, so `--include-signing` is not needed unless rotating the upload key:

```bash
scripts/push_saas_github_secrets.sh --profile production-release --repo zensgit/jive --env-file /tmp/jive-saas-production.env --apply
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive
```

Run GitHub Actions `SaaS Release Candidate` in this order:

1. `build_appbundle=false`, `strict_signing=false`
2. `build_appbundle=false`, `strict_signing=true`
3. `build_appbundle=true`, `strict_signing=true`

## Not Completed

No production AAB was generated in this pass because the production Supabase and AdMob client secrets are still missing.

No Google Play internal-test upload was attempted because there is no production AAB artifact yet.
