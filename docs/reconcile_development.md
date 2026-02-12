# Reconcile Development

## Scope Delivered
- Reconcile service with summary, running balances, and day grouping.
- Account reconcile UI with date range, filters, statement balance, and discrepancy highlight.
- Transaction detail screen with edit/delete and edit-mode support in AddTransaction.
- Note quick tags with usage-based ordering.
- Reconcile screen debug "测试数据" quick-range chip to generate sample data for the current account/date range.
- Accounts/Stats reload on transaction changes, including reconcile test-data seeding via callback.

## Key Files
- `app/lib/core/service/reconcile_service.dart`
- `app/lib/feature/accounts/account_reconcile_screen.dart`
- `app/lib/feature/transactions/transaction_detail_screen.dart`
- `app/lib/feature/transactions/add_transaction_screen.dart`
- `app/lib/feature/transactions/note_field_with_chips.dart`
- `app/test/reconcile_service_test.dart`
- `app/test/note_field_with_chips_test.dart`

## Persistence
- Statement balance: `reconcile_statement_v1_{accountId}_{start}_{end}`.
- Reconcile filter: `reconcile_filter_v1_{accountId}`.
- Reconcile summary scope: `reconcile_summary_v1_{accountId}`.
- Note tag usage: `note_tag_usage_v1_{type}` (JSON map of tag to count).

## Tests Run
- `flutter test -j 1 test/reconcile_service_test.dart test/note_field_with_chips_test.dart` (PASS).
