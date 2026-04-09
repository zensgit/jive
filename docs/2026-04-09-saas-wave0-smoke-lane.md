# SaaS Wave 0 Smoke Lane

## Goal
- Turn the manual Wave 0 SaaS smoke checklist into a repeatable command and optional CI lane.

## Entry Point
- Script: [run_saas_wave0_smoke.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/saas-wave0-smoke-lane/scripts/run_saas_wave0_smoke.sh)

## What It Covers
- Sync stack: `sync_book_scope` + tombstone tests when present
- Billing webhook: `subscription-webhook` Deno check/test when present
- Billing truth: `verify-subscription` Deno check/test plus client entitlement Flutter tests when present
- Auth stack: auth service and auth screen analyze/tests when present
- Ops stack: `analytics`, `send-notification`, `admin` Deno check/test when present

## Design Notes
- The script is branch-aware and skips suites whose files are not present in the current checkout.
- This keeps the lane usable for stacked PR branches without forcing every branch to carry the full SaaS surface.
- Flutter uses the repo-local SDK when available, then falls back to PATH.
- Deno defaults to `npx -y deno-bin@2.2.7` unless `DENO_CMD` is provided.

## Local Usage
```bash
bash scripts/run_saas_wave0_smoke.sh
```

## CI Usage
- The workflow adds a gated `saas_wave0_smoke` job.
- It runs on manual dispatch when `run_saas_wave0_smoke=true`.
- It also runs on PRs labeled `saas`.
