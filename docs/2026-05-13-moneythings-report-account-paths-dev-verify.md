# MoneyThings Report Account Paths Dev & Verification

Date: 2026-05-13
Branch: `codex/moneythings-report-account-paths`

## Scope

- Exported transaction reports now use the shared MoneyThings-style account path for the account column.
- Custom account groups are shown as `账户组 / 子账户 / 币种`.
- Legacy broad groups such as `资金账户` remain compact and continue to show the account name only.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No change to the report schema columns.

## Files

- `lib/core/service/data_backup_service.dart`
- `test/data_backup_report_account_path_test.dart`

## Verification

- `dart format lib/core/service/data_backup_service.dart test/data_backup_report_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/core/service/data_backup_service.dart test/data_backup_report_account_path_test.dart`
- `flutter test test/data_backup_report_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create grouped accounts such as `中国银行 / 活期 / CNY`, export a transaction report, and confirm the account column uses the grouped display path while the underlying transaction still points to the concrete `accountId`.
