import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/main.dart' as app;
import 'support/e2e_flow_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Transaction list supports search + filter + date range clear flow',
    (tester) async {
      app.main();
      await pumpUntilSettled(tester);
      await dismissAutoPermissionDialogIfPresent(tester);

      await openAllTransactionsScreen(tester);
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'abc');
      await pumpUntilSettled(tester);
      expect(find.text('abc'), findsOneWidget);

      await tapWhenVisible(
        tester,
        find.byKey(const Key('transaction_filter_open_button')),
      );
      expect(find.text('查找账单（按条件）'), findsOneWidget);

      await tapWhenVisible(
        tester,
        find.byKey(const Key('transaction_filter_date_range_tile')),
      );
      await selectMonthFromJiveCalendar(tester, year: 2026, month: 2);
      await waitForFinder(tester, find.text('10'));
      await tester.tap(find.text('10').first);
      await pumpUntilSettled(tester);
      await waitForFinder(tester, find.text('13'));
      await tester.tap(find.text('13').first);
      await pumpUntilSettled(tester);
      expect(find.text('2026-02-10 - 2026-02-13'), findsOneWidget);

      final categorySelector = find.text('全部分类');
      if (categorySelector.evaluate().isNotEmpty) {
        await tester.tap(categorySelector.first);
        await pumpUntilSettled(tester);
        final food = find.text('餐饮');
        if (food.evaluate().isNotEmpty) {
          await tester.tap(food.last);
          await pumpUntilSettled(tester);
        }
      }

      final clearAll = find.byKey(
        const Key('transaction_filter_clear_all_button'),
      );
      await tapWhenVisible(tester, clearAll);

      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first, warnIfMissed: false);
        await pumpUntilSettled(tester);
      }

      await tester.enterText(find.byType(TextField).first, '');
      await pumpUntilSettled(tester);
    },
  );
}
