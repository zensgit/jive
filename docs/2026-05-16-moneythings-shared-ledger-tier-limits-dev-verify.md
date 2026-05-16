# MoneyThings Shared Ledger Tier Limits Dev Verify

Date: 2026-05-16

Branch: `codex/moneythings-shared-ledger-limits`

Base: `origin/main@31bb01d9`

## Scope

This slice completes the first-stage MoneyThings family-collaboration limit
item without changing payment verification, SaaS entitlement truth, Supabase
migrations, or sync protocol.

It maps the existing local `UserTier` values to the shared-ledger product copy
from `SPRINT_DESIGN_AND_VALIDATION.md`:

- `free` -> Free: shared ledger entry blocked with upgrade copy.
- `paid` -> Pro: 1 shared ledger, 2 members per ledger.
- `subscriber` -> Family: 5 shared ledgers, 10 members per ledger.

## Changes

- Added `SharedLedgerLimitPolicy` as a pure client-side presentation policy.
- Added Free / Pro / Family create, join, and invite decisions.
- Updated `SharedLedgerScreen` to:
  - Show the current shared-ledger allowance banner.
  - Gate create and join entry points.
  - Gate invite-code copying when the current ledger already reached member
    capacity.
  - Keep existing local shared-ledger persistence and role logic unchanged.
- Updated the MoneyThings closure TODO to mark tier limits and policy tests as
  complete.

## Non-Goals

- No server-side entitlement changes.
- No payment provider or subscription status changes.
- No shared-ledger migration.
- No object-level RLS or object-level sharing table.
- No downgrade/delete semantics when a user loses entitlement.

## Verification

Local commands run:

```bash
/Users/chauhua/development/flutter/bin/dart format \
  lib/core/service/shared_ledger_limit_policy.dart \
  lib/feature/shared/shared_ledger_screen.dart \
  test/shared_ledger_limit_policy_test.dart
git diff --check
/Users/chauhua/development/flutter/bin/flutter test \
  test/shared_ledger_limit_policy_test.dart \
  test/shared_ledger_service_test.dart
/Users/chauhua/development/flutter/bin/flutter analyze --no-fatal-infos
```

Results:

- `dart format`: passed.
- `git diff --check`: passed.
- Restricted path check: passed; no `supabase/migrations`, `lib/core/sync`,
  `.github/workflows`, SaaS payment, or Supabase subscription/payment function
  files were changed.
- Focused Flutter tests: passed, 11 tests.
- `flutter analyze --no-fatal-infos`: passed with existing repo info-level
  analyzer findings.

## Manual Smoke

1. Set tier to Free and open `家庭共享账本`.
2. Confirm create/join shows upgrade copy instead of opening the form.
3. Set tier to Pro, create one shared ledger, then confirm creating or joining a
   second ledger is blocked.
4. On Pro, with `memberCount == 2`, confirm invite copy is blocked.
5. Set tier to Family, confirm up to 5 ledgers / 10 members are allowed by the
   policy copy.
