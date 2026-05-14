# MoneyThings Credit Analysis Account Paths Dev & Verification

Date: 2026-05-14
Branch: `codex/moneythings-credit-analysis-account-paths`

## Scope

- Credit analysis account labels now use the shared MoneyThings-style account display path.
- Grouped credit accounts are easier to distinguish in utilization views.
- Missing account fallback remains `未知`.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No credit utilization or payment-rate calculation change.

## Files

- `lib/core/service/credit_analysis_service.dart`
- `test/credit_analysis_account_path_test.dart`

## Verification

- `dart format lib/core/service/credit_analysis_service.dart test/credit_analysis_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/credit_analysis_service.dart test/credit_analysis_account_path_test.dart`
- `flutter test test/credit_analysis_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create grouped credit accounts such as `招商银行 / 信用卡 / CNY`, open credit utilization analysis, and confirm account labels show grouped paths while utilization and payment-rate values remain unchanged.
