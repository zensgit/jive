import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
  }
}

Future<bool> waitForFinderMaybe(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  if (await waitForFinderMaybe(tester, finder, timeout: timeout, step: step)) {
    return;
  }
  fail('Timed out waiting for finder: $finder');
}

Future<void> tapWhenVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await waitForFinder(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
  await pumpUntilSettled(tester);
}

Future<void> dismissAutoPermissionDialogIfPresent(WidgetTester tester) async {
  if (find.text('自动记账权限未开启').evaluate().isEmpty) {
    return;
  }
  final later = find.text('稍后');
  if (later.evaluate().isNotEmpty) {
    await tester.tap(later.first);
    await pumpUntilSettled(tester);
  }
}

Future<void> openAllTransactionsScreen(
  WidgetTester tester, {
  String pageTitle = '全部账单',
  Duration pageReadyTimeout = const Duration(seconds: 30),
  Duration filterReadyTimeout = const Duration(seconds: 40),
  int maxAttempts = 2,
}) async {
  final homeViewAllButton = find.byKey(const Key('home_view_all_button'));
  final screenReadyMarker = find.byKey(const Key('transactions_screen_ready'));
  final filterButton = find.byKey(const Key('transaction_filter_open_button'));

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    if (screenReadyMarker.evaluate().isEmpty &&
        find.text(pageTitle).evaluate().isEmpty &&
        homeViewAllButton.evaluate().isNotEmpty) {
      await tapWhenVisible(
        tester,
        homeViewAllButton,
        timeout: pageReadyTimeout,
      );
    }

    final hasReadyMarker = await waitForFinderMaybe(
      tester,
      screenReadyMarker,
      timeout: pageReadyTimeout,
    );
    final hasPageTitle = await waitForFinderMaybe(
      tester,
      find.text(pageTitle),
      timeout: pageReadyTimeout,
    );
    final hasFilterButton = await waitForFinderMaybe(
      tester,
      filterButton,
      timeout: filterReadyTimeout,
    );

    if ((hasReadyMarker || hasPageTitle) && hasFilterButton) {
      return;
    }
    await pumpUntilSettled(tester, maxSteps: 80);
  }

  fail(
    'Timed out entering all-transactions screen '
    '(missing ready marker/title or filter button).',
  );
}

Future<void> selectMonthFromJiveCalendar(
  WidgetTester tester, {
  required int year,
  required int month,
}) async {
  await tapWhenVisible(
    tester,
    find.byKey(const Key('jive_calendar_month_picker')),
  );
  await tapWhenVisible(tester, find.byType(DropdownButtonFormField<int>).first);
  await waitForFinder(tester, find.text(year.toString()));
  await tester.tap(find.text(year.toString()).last);
  await pumpUntilSettled(tester);

  final monthLabel = month.toString().padLeft(2, '0');
  await waitForFinder(tester, find.widgetWithText(ChoiceChip, monthLabel));
  await tester.tap(find.widgetWithText(ChoiceChip, monthLabel));
  await pumpUntilSettled(tester);

  await tapWhenVisible(tester, find.text('确定'));
}
