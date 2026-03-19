import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/main.dart' as app;

Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
}

Future<void> _dismissAutoPermissionDialogIfPresent(WidgetTester tester) async {
  if (find.text('自动记账权限未开启').evaluate().isEmpty) return;
  final later = find.text('稍后');
  if (later.evaluate().isNotEmpty) {
    await tester.tap(later.first);
    await _pumpUntilSettled(tester);
  }
}

Future<void> _openTransactionListFromHome(WidgetTester tester) async {
  final viewAllByKey = find.byKey(
    const Key('home_view_all_transactions_button'),
  );
  final viewAllByText = find.text('View All');
  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(seconds: 10)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (viewAllByKey.evaluate().isNotEmpty) {
      await tester.tap(viewAllByKey.first);
      await _pumpUntilSettled(tester);
      return;
    }
    if (viewAllByText.evaluate().isNotEmpty) {
      await tester.tap(viewAllByText.first);
      await _pumpUntilSettled(tester);
      return;
    }
  }
  fail('Timed out waiting for home transaction entry point.');
}

Future<void> _selectMonth(
  WidgetTester tester, {
  required int year,
  required int month,
}) async {
  await tester.tap(find.byKey(const Key('jive_calendar_month_picker')));
  await _pumpUntilSettled(tester);
  await tester.tap(find.byType(DropdownButtonFormField<int>).first);
  await _pumpUntilSettled(tester);
  await tester.tap(find.text(year.toString()).last);
  await _pumpUntilSettled(tester);
  await tester.tap(
    find.widgetWithText(ChoiceChip, month.toString().padLeft(2, '0')),
  );
  await _pumpUntilSettled(tester);
  await tester.tap(find.text('确定'));
  await _pumpUntilSettled(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Transaction list supports search + filter + date range clear flow',
    (tester) async {
      app.main();
      await _pumpUntilSettled(tester);
      await _dismissAutoPermissionDialogIfPresent(tester);

      await _openTransactionListFromHome(tester);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'abc');
      await _pumpUntilSettled(tester);
      expect(find.text('abc'), findsOneWidget);

      await tester.tap(find.byKey(const Key('transaction_filter_open_button')));
      await _pumpUntilSettled(tester);
      expect(find.text('查找账单（按条件）'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('transaction_filter_date_range_tile')),
      );
      await _pumpUntilSettled(tester);
      await _selectMonth(tester, year: 2026, month: 2);
      await tester.tap(find.text('10').first);
      await _pumpUntilSettled(tester);
      await tester.tap(find.text('13').first);
      await _pumpUntilSettled(tester);
      expect(find.text('2026-02-10 - 2026-02-13'), findsOneWidget);

      final categorySelector = find.text('全部分类');
      if (categorySelector.evaluate().isNotEmpty) {
        await tester.tap(categorySelector.first);
        await _pumpUntilSettled(tester);
        final food = find.text('餐饮');
        if (food.evaluate().isNotEmpty) {
          await tester.tap(food.last);
          await _pumpUntilSettled(tester);
        }
      }

      final clearAll = find.text('全部清除');
      await tester.ensureVisible(clearAll.first);
      await tester.tap(clearAll.first, warnIfMissed: false);
      await _pumpUntilSettled(tester);

      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first, warnIfMissed: false);
        await _pumpUntilSettled(tester);
      }

      await tester.enterText(find.byType(TextField).first, '');
      await _pumpUntilSettled(tester);
    },
  );
}
