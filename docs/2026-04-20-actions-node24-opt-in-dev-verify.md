# GitHub Actions Node 24 Opt-In Dev & Verify

Date: 2026-04-20
Branch: `codex/actions-node24-opt-in`

## Goal

Remove the GitHub Actions Node.js 20 deprecation warning before it becomes a forced runner default.

The previous main CI run completed successfully but emitted this annotation on JavaScript actions such as `actions/checkout@v4` and `actions/setup-node@v4`:

- GitHub-hosted runners will force JavaScript actions to Node 24 by default later in 2026.
- Node 20 action runtime support will be removed later in 2026.
- GitHub suggests setting `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` to opt in early.

## Changes

- Upgraded official GitHub JavaScript actions in `.github/workflows/flutter_ci.yml`:
  - `actions/checkout@v4` -> `actions/checkout@v6`
  - `actions/setup-node@v4` -> `actions/setup-node@v6`
  - `actions/setup-java@v4` -> `actions/setup-java@v5`
  - `actions/upload-artifact@v4` -> `actions/upload-artifact@v7`
- Upgraded the same official actions in `.github/workflows/saas_core_staging.yml`.
- Added workflow-level `env` in `.github/workflows/flutter_ci.yml`:

```yaml
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
```

- Added the same workflow-level `env` in `.github/workflows/saas_core_staging.yml`.

## Scope

This change only affects GitHub Actions workflow infrastructure.

It does not change:

- Flutter version.
- Java version.
- The `actions/setup-node` `node-version: "20"` used by SaaS scripts.
- The SaaS smoke scripts.
- App code, tests, Supabase functions, or migrations.

Keeping `node-version: "20"` unchanged is intentional. The warning is about the action runtime, while the installed Node version is part of the project script environment.

## Local Verification

```bash
ruby -e "require 'yaml'; Dir['.github/workflows/*.yml'].each { |f| YAML.load_file(f); puts \"yaml ok: #{f}\" }"
```

Passed:

```text
yaml ok: .github/workflows/flutter_ci.yml
yaml ok: .github/workflows/saas_core_staging.yml
```

```bash
git diff --check
```

Passed.

```bash
curl -fsSL https://raw.githubusercontent.com/actions/checkout/v6/action.yml | rg "runs:|using:" -n -C 2
curl -fsSL https://raw.githubusercontent.com/actions/setup-node/v6/action.yml | rg "runs:|using:" -n -C 2
curl -fsSL https://raw.githubusercontent.com/actions/setup-java/v5/action.yml | rg "runs:|using:" -n -C 2
curl -fsSL https://raw.githubusercontent.com/actions/upload-artifact/v7/action.yml | rg "runs:|using:" -n -C 2
```

Confirmed all upgraded official actions declare `runs.using: node24`.

## CI Verification Plan

The `flutter_ci.yml` change should be verified by opening a PR:

- `analyze_and_test` should pass.
- `detect_saas_wave0_smoke` should pass.
- `saas_wave0_smoke` should auto-run because `.github/workflows/flutter_ci.yml` is a SaaS smoke trigger path.
- The previous Node.js 20 action-runtime annotation should no longer appear on the PR run.

`saas_core_staging.yml` is `workflow_dispatch` only and depends on staging secrets, so it should not be manually run just for this PR unless staging validation is explicitly needed.
