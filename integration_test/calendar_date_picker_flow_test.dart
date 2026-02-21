import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/core/widgets/jive_calendar/jive_calendar_day_cell.dart';
import 'package:jive/main.dart' as app;
import 'support/e2e_flow_helpers.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Date range picker holiday corner mark does not overlap', (
    tester,
  ) async {
    app.main();
    await pumpUntilSettled(tester);
    await dismissAutoPermissionDialogIfPresent(tester);

    // Home -> View All (全部账单)
    await openAllTransactionsScreen(tester);

    // Open transaction filter sheet.
    await tapWhenVisible(
      tester,
      find.byKey(const Key('transaction_filter_open_button')),
    );

    // Open date range picker.
    await tapWhenVisible(
      tester,
      find.byKey(const Key('transaction_filter_date_range_tile')),
    );

    // Switch to Feb 2026 which should contain holiday/workday adjustments.
    await selectMonthFromJiveCalendar(tester, year: 2026, month: 2);
    expect(find.text('2026-02'), findsOneWidget);

    // Enable holiday corner marks.
    await tapWhenVisible(
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
    await waitForFinder(tester, find.text('10'));
    await tester.tap(find.text('10').first);
    await pumpUntilSettled(tester);
    await waitForFinder(tester, find.text('13'));
    await tester.tap(find.text('13').first);
    await pumpUntilSettled(tester);

    expect(find.text('2026-02-10 - 2026-02-13'), findsOneWidget);
  });
}
