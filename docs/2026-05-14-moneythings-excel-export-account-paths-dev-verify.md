# MoneyThings Excel Export Account Paths Dev & Verification

Date: 2026-05-14
Branch: `codex/moneythings-excel-export-account-paths`

## Scope

- Excel transaction export now uses the shared MoneyThings-style account display path.
- Grouped accounts are exported as `账户组 / 子账户 / 币种`.
- Missing account fallback remains empty.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No export column schema change.

## Files

- `lib/core/service/excel_export_service.dart`
- `test/excel_export_account_path_test.dart`

## Verification

- `dart format lib/core/service/excel_export_service.dart test/excel_export_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/excel_export_service.dart test/excel_export_account_path_test.dart`
- `flutter test test/excel_export_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create grouped accounts such as `中国银行 / 活期 / CNY`, export transactions to Excel, and confirm the account column shows the grouped path while the transaction still references the concrete account ID.
