# Reconcile Design

## Goals
- Provide account-level reconciliation with a date range, running balance, and summary totals.
- Make discrepancies easier to spot by comparing a statement balance and highlighting likely days.
- Allow quick drill-down to transaction detail, edit, or delete.

## Data Model
- `ReconcileSummary`: start/end balance, income, expense, transfer in/out, net change.
- `ReconcileEntry`: transaction + signed amount + running balance + day key.
- `ReconcileResult`: summary, entries, day counts, day net changes, balance series.

## Service Flow
- Source: `ReconcileService.reconcileAccount`.
- Signed amount rules:
  - Income: +amount (accountId matches).
  - Expense: -amount (accountId matches).
  - Transfer: -amount if accountId is from, +amount if toAccountId is target.
  - Transfers with identical from/to account are ignored.
- Compute:
  - current balance = openingBalance + all signed amounts.
  - end balance = current balance - (signed amounts after end).
  - start balance = end balance - (signed amounts in range).
  - day net changes accumulated from in-range signed amounts.

## UI Structure
- Accounts list: add a secondary "对账" action per account.
- Reconcile screen:
  - Date range card + quick ranges (本月/上月/近7天).
  - Filter chips (全部/收入/支出/转账).
  - Summary card with totals, start/end balances, statement input, discrepancy, and summary scope toggle.
  - List grouped by day with running balance per entry.
  - Highlight top 3 days whose net change most closely matches discrepancy.
- Transaction detail:
  - Structured fields for type, time, accounts, category, source, raw text.
  - Edit (opens AddTransactionScreen in edit mode) and delete actions.
 - Transaction edit:
   - Date/time selectable via keypad or time label tap.
   - Note input field plus quick tags tailored by transaction type and ordered by recent use.

## Performance
- Add indexes on `accountId` and `toAccountId` for faster account-scoped queries.

## Statement Balance Persistence
- Store per account + date range using `SharedPreferences`.
- Key format: `reconcile_statement_v1_{accountId}_{start}_{end}`.

## Note Tag Persistence
- Track quick-tag usage per transaction type via `SharedPreferences`.
- Key format: `note_tag_usage_v1_{type}` (JSON map of tag to count).

## Debug Tools
- Reconcile screen provides a debug-only "测试数据" quick-range chip to inject sample transactions for the current account/date range.

## Known Limitations
- Discrepancy highlight uses a heuristic (closest day net change).
- Manual statement balance is optional; no discrepancy shown without input.
