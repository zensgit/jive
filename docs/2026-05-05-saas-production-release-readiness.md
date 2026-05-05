# SaaS Production Release Readiness

Generated: 2026-05-05T12:08:36Z

Repository: `zensgit/jive`

## Summary

- Status: `blocked`
- `main`: `8c3a0abe099106e9d26dffb0f0efe50e594d7008`
- `SaaS Release Candidate` workflow: `active`
- Latest main Flutter CI: `run=25374986384 status=completed conclusion=success head=8c3a0abe099106e9d26dffb0f0efe50e594d7008 url=https://github.com/zensgit/jive/actions/runs/25374986384`

## Required Secrets

Minimum dry-run secret check exit: `1`

```text
[saas-github-secrets] repo: zensgit/jive
[saas-github-secrets] profile: production-release
[saas-github-secrets] MISS: missing required secret: PRODUCTION_SUPABASE_URL
[saas-github-secrets] MISS: missing required secret: PRODUCTION_SUPABASE_ANON_KEY
[saas-github-secrets] MISS: missing required secret: PRODUCTION_ADMOB_APP_ID
[saas-github-secrets] MISS: missing required secret: PRODUCTION_ADMOB_BANNER_ID
[saas-github-secrets] WARN: optional secret is not set: PRODUCTION_ADMIN_API_ALLOWED_ORIGINS
[saas-github-secrets] WARN: optional secret is not set: PRODUCTION_PAYMENT_CHANNEL
[saas-github-secrets] WARN: optional secret is not set: ANDROID_RELEASE_KEYSTORE_BASE64
[saas-github-secrets] WARN: optional secret is not set: ANDROID_RELEASE_STORE_PASSWORD
[saas-github-secrets] WARN: optional secret is not set: ANDROID_RELEASE_KEY_ALIAS
[saas-github-secrets] WARN: optional secret is not set: ANDROID_RELEASE_KEY_PASSWORD
[saas-github-secrets] ERROR: 4 required GitHub Actions secret(s) missing
```

Strict signing secret check exit: `1`

```text
[saas-github-secrets] repo: zensgit/jive
[saas-github-secrets] profile: production-release
[saas-github-secrets] MISS: missing required secret: PRODUCTION_SUPABASE_URL
[saas-github-secrets] MISS: missing required secret: PRODUCTION_SUPABASE_ANON_KEY
[saas-github-secrets] MISS: missing required secret: PRODUCTION_ADMOB_APP_ID
[saas-github-secrets] MISS: missing required secret: PRODUCTION_ADMOB_BANNER_ID
[saas-github-secrets] MISS: missing required secret: ANDROID_RELEASE_KEYSTORE_BASE64
[saas-github-secrets] MISS: missing required secret: ANDROID_RELEASE_STORE_PASSWORD
[saas-github-secrets] MISS: missing required secret: ANDROID_RELEASE_KEY_ALIAS
[saas-github-secrets] MISS: missing required secret: ANDROID_RELEASE_KEY_PASSWORD
[saas-github-secrets] WARN: optional secret is not set: PRODUCTION_ADMIN_API_ALLOWED_ORIGINS
[saas-github-secrets] WARN: optional secret is not set: PRODUCTION_PAYMENT_CHANNEL
[saas-github-secrets] ERROR: 8 required GitHub Actions secret(s) missing
```

## Next Commands

After the missing production secrets are configured:

```bash
scripts/check_saas_github_secrets.sh --profile production-release --repo zensgit/jive
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive
```

Then run GitHub Actions -> `SaaS Release Candidate` in this order:

1. `build_appbundle=false`, `strict_signing=false`
2. `build_appbundle=false`, `strict_signing=true`
3. `build_appbundle=true`, `strict_signing=true`
