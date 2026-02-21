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

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  if (await _waitForFinderMaybe(tester, finder, timeout: timeout, step: step)) {
    return;
  }
  fail('Timed out waiting for finder: $finder');
}

Future<bool> _waitForFinderMaybe(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> _tapWhenVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await _waitForFinder(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
  await _pumpUntilSettled(tester);
}

Future<void> _dismissAutoPermissionDialogIfPresent(WidgetTester tester) async {
  if (find.text('自动记账权限未开启').evaluate().isEmpty) return;
  final later = find.text('稍后');
  if (later.evaluate().isNotEmpty) {
    await tester.tap(later.first);
    await _pumpUntilSettled(tester);
  }
}

Future<void> _openAllTransactionsScreen(WidgetTester tester) async {
  const pageTitle = '全部账单';
  final homeViewAllButton = find.byKey(const Key('home_view_all_button'));
  final filterButton = find.byKey(const Key('transaction_filter_open_button'));

  for (var attempt = 1; attempt <= 2; attempt++) {
    if (find.text(pageTitle).evaluate().isEmpty &&
        homeViewAllButton.evaluate().isNotEmpty) {
      await _tapWhenVisible(
        tester,
        homeViewAllButton,
        timeout: const Duration(seconds: 30),
      );
    }

    final hasPageTitle = await _waitForFinderMaybe(
      tester,
      find.text(pageTitle),
      timeout: const Duration(seconds: 30),
    );
    final hasFilterButton = await _waitForFinderMaybe(
      tester,
      filterButton,
      timeout: const Duration(seconds: 40),
    );

    if (hasPageTitle && hasFilterButton) return;

    await _pumpUntilSettled(tester, maxSteps: 80);
  }

  fail(
    'Timed out entering all-transactions screen '
    '(missing title or filter button).',
  );
}

Future<void> _selectMonth(
  WidgetTester tester, {
  required int year,
  required int month,
}) async {
  await _tapWhenVisible(
    tester,
    find.byKey(const Key('jive_calendar_month_picker')),
  );
  await _tapWhenVisible(
    tester,
    find.byType(DropdownButtonFormField<int>).first,
  );
  await _waitForFinder(tester, find.text(year.toString()));
  await tester.tap(find.text(year.toString()).last);
  await _pumpUntilSettled(tester);
  await _waitForFinder(
    tester,
    find.widgetWithText(ChoiceChip, month.toString().padLeft(2, '0')),
  );
  await tester.tap(
    find.widgetWithText(ChoiceChip, month.toString().padLeft(2, '0')),
  );
  await _pumpUntilSettled(tester);
  await _tapWhenVisible(tester, find.text('确定'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Transaction list supports search + filter + date range clear flow',
    (tester) async {
      app.main();
      await _pumpUntilSettled(tester);
      await _dismissAutoPermissionDialogIfPresent(tester);

      await _openAllTransactionsScreen(tester);
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'abc');
      await _pumpUntilSettled(tester);
      expect(find.text('abc'), findsOneWidget);

      await _tapWhenVisible(
        tester,
        find.byKey(const Key('transaction_filter_open_button')),
      );
      expect(find.text('查找账单（按条件）'), findsOneWidget);

      await _tapWhenVisible(
        tester,
        find.byKey(const Key('transaction_filter_date_range_tile')),
      );
      await _selectMonth(tester, year: 2026, month: 2);
      await _waitForFinder(tester, find.text('10'));
      await tester.tap(find.text('10').first);
      await _pumpUntilSettled(tester);
      await _waitForFinder(tester, find.text('13'));
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

      final clearAll = find.byKey(
        const Key('transaction_filter_clear_all_button'),
      );
      await _tapWhenVisible(tester, clearAll);

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
