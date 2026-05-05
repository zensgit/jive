# SaaS Release Train Completion

Date: 2026-05-05

## Scope

This pass executed the previously agreed SaaS release-train handoff:

- Merge the independent staging deployment completion evidence PR.
- Merge the production readiness gate PR.
- Rebase the release candidate workflow stack onto updated `main`.
- Retarget the release candidate workflow PR to `main` and move it out of draft once checks are ready.

This is still a staging-to-release-candidate enablement pass. It does not configure production Supabase, AdMob, or Android signing secrets, and it does not run a production appbundle build.

## Development

Merged PRs:

| PR | Result | Merge commit |
| --- | --- | --- |
| #214 `docs(saas): record staging deployment completion` | Merged into `main` | `1ae877b6d6bb2eea275f8c5ad1613c0ae09c5724` |
| #212 `chore(saas): add production readiness gate` | Merged into `main` | `6e56a37d876606d20215c0d843a8385e27bfbac1` |

Release candidate workflow PR:

- PR #213 was rebased onto `origin/main` after #214 and #212 landed.
- The PR stack now carries only the release-candidate workflow changes on top of `main`.
- This completion note was added to PR #213 so the final handoff evidence lands with the workflow.

Current `main` after the two merges:

```text
6e56a37d876606d20215c0d843a8385e27bfbac1
```

## Validation

Pre-merge PR state:

- #214 was `OPEN`, non-draft, `CLEAN`, and GitHub Flutter CI was green before merge.
- #212 was `OPEN`, non-draft, `CLEAN`, and GitHub Flutter CI was green before merge.
- #213 was `OPEN`, draft, `CLEAN`, and green while stacked on #212 before rebase.

Rebase validation:

```bash
git fetch origin main codex/saas-release-candidate-workflow-stack
git rebase origin/main
```

Result: passed with no conflicts.

Local validation to run after this note:

```bash
git diff --check
bash -n scripts/build_release_candidate.sh scripts/check_saas_production_readiness.sh scripts/check_saas_github_secrets.sh scripts/push_saas_github_secrets.sh scripts/init_saas_production_env.sh
ruby -e "require 'psych'; Psych.parse_file('.github/workflows/saas_release_candidate.yml')"
PRODUCTION_ENV_FILE=/tmp/<temp-prod-env> JIVE_RELEASE_CANDIDATE_DRY_RUN=true bash scripts/build_release_candidate.sh
scripts/check_saas_github_secrets.sh --profile production-release --repo zensgit/jive
scripts/check_saas_github_secrets.sh --profile production-release --include-signing --repo zensgit/jive
```

Result:

- `git diff --check`: passed.
- Script syntax check: passed.
- Workflow YAML parse: passed.
- Production-shaped release-candidate dry-run with temporary non-secret Supabase/AdMob values: passed.
- GitHub production secret inventory: failed as expected because production release secrets are not configured yet.

Expected secret-check result before production configuration:

- Minimum release-candidate dry-run secrets are still missing:
  - `PRODUCTION_SUPABASE_URL`
  - `PRODUCTION_SUPABASE_ANON_KEY`
  - `PRODUCTION_ADMOB_APP_ID`
  - `PRODUCTION_ADMOB_BANNER_ID`
- Strict signing secrets are still missing:
  - `ANDROID_RELEASE_KEYSTORE_BASE64`
  - `ANDROID_RELEASE_STORE_PASSWORD`
  - `ANDROID_RELEASE_KEY_ALIAS`
  - `ANDROID_RELEASE_KEY_PASSWORD`

## Remaining Work

After PR #213 lands on `main`:

1. Configure real production Supabase and AdMob GitHub Actions secrets.
2. Configure Android release signing secrets before any store-bound build.
3. Run `SaaS Release Candidate` with `build_appbundle=false` first.
4. If the dry-run passes, run `strict_signing=true`.
5. Only then run `build_appbundle=true` for a store/internal-test AAB.
