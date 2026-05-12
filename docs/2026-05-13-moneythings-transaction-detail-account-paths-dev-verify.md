# MoneyThings Transaction Detail Account Paths Dev & Verification

Date: 2026-05-13
Branch: `codex/moneythings-transaction-detail-account-paths`

## Scope

- Transaction detail account labels now use the shared MoneyThings-style account path.
- Normal transaction detail rows, transfer subtitles, transfer source accounts, and transfer target accounts all resolve through the same account display helper.
- Missing accounts still show `未指定`.

## Non-Goals

- No database migration.
- No transaction save model change.
- No sync, entitlement, payment, or workflow change.
- No account picker or account creation behavior change.

## Files

- `lib/feature/transactions/transaction_detail_screen.dart`
- `test/transaction_detail_account_path_test.dart`

## Verification

- `dart format lib/feature/transactions/transaction_detail_screen.dart test/transaction_detail_account_path_test.dart`
- `flutter analyze --no-fatal-infos lib/feature/transactions/transaction_detail_screen.dart test/transaction_detail_account_path_test.dart`
- `flutter test test/transaction_detail_account_path_test.dart`
- `git diff --check`
- Restricted path check for `supabase/migrations`, `lib/core/sync`, `.github/workflows`.

## Manual Smoke

Create two accounts under a custom group such as `中国银行`, open a normal transaction detail and a transfer detail, and confirm `账户`, `转入账户`, and the transfer subtitle show grouped paths while the transaction still references concrete account IDs.
