# Transaction List Search Report

## Scope
- Added a bottom search bar with instant filtering.
- Added an advanced filter sheet (category/account/tag) that applies immediately.
- Added date range filtering via a bottom-sheet calendar (auto close on range selection).
- Made the Home "View All" entry open the full transaction list.

## Status
- Implementation complete.
- Validation pending.

## Verification Checklist
1. Home -> View All opens the full list.
2. Typing in the search field filters the list immediately.
3. Filter sheet opens from the bottom; selections apply instantly.
4. Clear icon resets search text + filters.
5. Empty state appears when no results match.
6. Category filter matches by key or displayed category name.

## References
- `app/lib/feature/category/category_transactions_screen.dart`
- `app/lib/core/widgets/transaction_filter_sheet.dart`
