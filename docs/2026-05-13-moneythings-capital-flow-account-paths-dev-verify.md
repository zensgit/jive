# MoneyThings Capital Flow Account Paths Dev & Verification

Date: 2026-05-13
Branch: `codex/moneythings-capital-flow-account-paths`

## Scope

- Capital flow transfer labels now use the shared MoneyThings-style account display path.
- Grouped subaccounts are easier to distinguish in transfer flow summaries.
- Missing account fallback remains `未知账户`.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No capital-flow aggregation math change.

## Files

- `lib/core/service/capital_flow_service.dart`
- `test/capital_flow_account_path_test.dart`

## Verification

- `dart format lib/core/service/capital_flow_service.dart test/capital_flow_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/capital_flow_service.dart test/capital_flow_account_path_test.dart`
- `flutter test test/capital_flow_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create two grouped subaccounts, record a transfer between them, open the capital flow view, and confirm the transfer flow shows grouped account paths while totals and transaction IDs remain unchanged.
