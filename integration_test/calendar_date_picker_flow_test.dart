import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/core/widgets/jive_calendar/jive_calendar_day_cell.dart';
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
  // Best-effort: don't hard-fail here; the test will fail on missing finders.
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for finder: $finder');
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

Future<void> _waitForAnyText(
  WidgetTester tester,
  List<String> texts, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(step);
    for (final value in texts) {
      if (find.text(value).evaluate().isNotEmpty) return;
    }
  }
  fail('Timed out waiting for any of: ${texts.join(', ')}');
}

Future<void> _dismissAutoPermissionDialogIfPresent(WidgetTester tester) async {
  final title = find.text('自动记账权限未开启');
  if (title.evaluate().isEmpty) return;

  final later = find.text('稍后');
  if (later.evaluate().isNotEmpty) {
    await tester.tap(later);
    await _pumpUntilSettled(tester);
  }
}

Future<void> _selectMonth(
  WidgetTester tester, {
  required int year,
  required int month,
}) async {
  // Open month/year picker from calendar header.
  await _tapWhenVisible(
    tester,
    find.byKey(const Key('jive_calendar_month_picker')),
  );

  // Pick year (DropdownButtonFormField).
  final yearDropdown = find.byType(DropdownButtonFormField<int>);
  await _tapWhenVisible(tester, yearDropdown);
  await _waitForFinder(tester, find.text(year.toString()));
  await tester.tap(find.text(year.toString()).last);
  await _pumpUntilSettled(tester);

  // Pick month chip.
  final monthLabel = month.toString().padLeft(2, '0');
  await _waitForFinder(tester, find.widgetWithText(ChoiceChip, monthLabel));
  await tester.tap(find.widgetWithText(ChoiceChip, monthLabel));
  await _pumpUntilSettled(tester);

  await _tapWhenVisible(tester, find.text('确定'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Date range picker holiday corner mark does not overlap', (
    tester,
  ) async {
    app.main();
    await _pumpUntilSettled(tester);
    await _dismissAutoPermissionDialogIfPresent(tester);

    // Home -> View All (全部账单)
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('home_view_all_button')),
    );

    // Open transaction filter sheet.
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('transaction_filter_open_button')),
    );

    // Open date range picker.
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('transaction_filter_date_range_tile')),
    );

    // Switch to Feb 2026 which should contain holiday/workday adjustments.
    await _selectMonth(tester, year: 2026, month: 2);
    expect(find.text('2026-02'), findsOneWidget);

    // Enable holiday corner marks.
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('jive_calendar_filter_holiday')),
    );

    // Holiday data is loaded async (asset -> optional disk override). Wait for
    // the marks to appear instead of assuming the next frame has them.
    await _waitForAnyText(tester, ['班', '休']);

    final workMarks = find.text('班');
    final restMarks = find.text('休');
    expect(
      workMarks.evaluate().isNotEmpty || restMarks.evaluate().isNotEmpty,
      isTrue,
    );
    final badgeMark =
        (workMarks.evaluate().isNotEmpty ? workMarks : restMarks).first;

    // Validate that the corner mark and its day number do not overlap in the
    // same cell. (This guards against the "中文与数字重叠" regression.)
    final cell = find.ancestor(
      of: badgeMark,
      matching: find.byType(JiveCalendarDayCell),
    );
    expect(cell, findsOneWidget);

    String? dayLabel;
    for (final element
        in find.descendant(of: cell, matching: find.byType(Text)).evaluate()) {
      final widget = element.widget;
      if (widget is Text && widget.data != null) {
        final value = widget.data!.trim();
        if (RegExp(r'^\d{1,2}$').hasMatch(value)) {
          dayLabel = value;
          break;
        }
      }
    }
    expect(dayLabel, isNotNull);
    final dayNumber = find.descendant(of: cell, matching: find.text(dayLabel!));
    expect(dayNumber, findsOneWidget);

    final badgeRect = tester.getRect(badgeMark);
    final dayRect = tester.getRect(dayNumber);
    expect(dayRect.overlaps(badgeRect), isFalse);

    // Select a range and ensure it is reflected in the filter sheet.
    await _waitForFinder(tester, find.text('10'));
    await tester.tap(find.text('10').first);
    await _pumpUntilSettled(tester);
    await _waitForFinder(tester, find.text('13'));
    await tester.tap(find.text('13').first);
    await _pumpUntilSettled(tester);

    expect(find.text('2026-02-10 - 2026-02-13'), findsOneWidget);
  });
}
