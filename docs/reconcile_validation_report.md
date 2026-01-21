# Reconcile Validation Report

## Environment
- Device: P0110 (Android)
- Build: debug via `flutter run`
- Package: `com.jivemoney.app.auto`
- Data state: reconcile test data already seeded (income/expense/transfer samples)

## Verified
1. Opened Assets tab and entered Reconcile for the cash account.
2. Quick range chips update the date range and summary totals:
   - Last 7 days -> range changed to 2026-01-13 to 2026-01-19; summary updated (transfer in CNY 300.00, transfer out CNY 400.00, net change CNY -100.00).
   - Last month -> range changed to 2025-12-01 to 2025-12-31; summary totals zero.
   - Current month -> range changed to 2026-01-01 to 2026-01-19; summary restored (income CNY 3,640.00, expense CNY 465.00, transfer in CNY 300.00, transfer out CNY 400.00, net change CNY 3,075.00).
3. Filter chip (Income) toggles selection state and updates summary scope:
   - Summary scope set to Filtered shows Period Summary (Filtered) with expense/transfer totals at zero and net change CNY 3,640.00.
4. Statement balance input:
   - Entered statement balance CNY 3,000.
   - Discrepancy displayed as CNY -75.00.
5. List visibility:
   - User confirmed the reconcile list appears (date-grouped entries visible).
6. Keyboard overflow:
   - User confirmed the statement balance input no longer triggers a bottom overflow.
7. Filtered list grouping:
   - User confirmed list grouping updates when switching Income/Expense/Transfer filters.
8. Statement balance persistence:
   - User confirmed the statement balance persists after leaving and re-entering the same range.
9. Asset refresh on add:
   - User confirmed adding a transaction updates Assets balances.
10. Reconcile list default order:
   - User confirmed list sorts by latest date/time first.
11. Add transaction screen overflow:
   - User confirmed no overflow after fix.
12. Transaction detail edit refresh:
   - User confirmed editing a transaction refreshes the reconcile list on return.
13. Search filter crash:
    - User confirmed the tag filter no longer triggers a red-screen crash.
14. Search filter behavior:
    - Filters now apply immediately without tapping Apply; sort control is icon-only.

## Blockers / Instability
- Multiple app variants were installed and surfaced during navigation: `com.jivemoney.app.auto`, `com.jivemoney.app.dev`, and `com.jivemoney.app.voice`.
- The UI focus frequently switched to other screens (Auto record confirmation, Tag manager, category editor, accessibility permission flow), which interrupted the flow and prevented reliable list interaction.

## Not Completed
1. Note quick tags: add/remove tags, re-tap to confirm ordering changes.

## Recommendations to Finish
- Temporarily uninstall/disable the other app variants (`com.jivemoney.app.dev`, `com.jivemoney.app.voice`) and disable auto-record prompts to avoid focus switching.
- If acceptable, reset the app state before the next run for a clean test environment.
