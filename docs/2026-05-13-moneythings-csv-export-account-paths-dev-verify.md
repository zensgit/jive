# MoneyThings CSV Export Account Paths Dev & Verification

Date: 2026-05-13
Branch: `codex/moneythings-csv-export-account-paths`

## Scope

- User-facing CSV transaction export now uses the shared MoneyThings-style account display path.
- Transfer CSV rows show both source and target account paths.
- Missing account fallback behavior is preserved.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No change to raw account IDs in other export formats.

## Files

- `lib/core/service/csv_export_service.dart`
- `test/csv_export_account_path_test.dart`

## Verification

- `dart format lib/core/service/csv_export_service.dart test/csv_export_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/csv_export_service.dart test/csv_export_account_path_test.dart`
- `flutter test test/csv_export_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create grouped accounts such as `中国银行 / 活期 / CNY` and `中国银行 / 定期 / USD`, export transactions to CSV, and confirm the account column shows grouped paths while transactions still reference concrete account IDs.
