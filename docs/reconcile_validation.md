# Reconcile Validation

## Automated
- `flutter pub run build_runner build --delete-conflicting-outputs`
  - Purpose: regenerate Isar schemas after adding account indexes.
- `flutter test -j 1 test/reconcile_service_test.dart test/note_field_with_chips_test.dart`
  - Result: PASS.

## Manual (run on device)
1. Open Accounts → cash account → tap "对账"; page loads with quick range chips (including "测试数据").
2. Tap "测试数据" → confirm dialog → summary updates (income ¥1,820.00, expense ¥232.50, transfer in ¥150.00, transfer out ¥200.00, net ¥1,537.50).
3. Tap "测试数据" again → confirm dialog → summary doubles (income ¥3,640.00, expense ¥465.00, transfer in ¥300.00, transfer out ¥400.00, net ¥3,075.00).
4. Back to Assets → balances refresh automatically (cash ¥3,075.00; bank card ¥100.00; net assets ¥3,175.00).

## Manual (pending)
1. Verify date range updates via picker and quick range chips.
2. Enter a statement balance and confirm discrepancy display and day highlight.
3. Toggle summary scope (全部/筛选) and confirm totals change with filters.
4. Apply filters (收入/支出/转账) and confirm list grouping updates.
5. Tap an entry → verify detail screen → edit note/time → save and confirm list refreshes.
6. In the edit screen, tap note quick tags to add/remove and verify the note updates.
7. Re-tap the same tag and confirm frequently used tags float earlier in the list.
8. Reopen the same range and verify statement balance input is restored.
9. Add a new transaction from the main FAB and confirm the Accounts tab balance refreshes automatically.
