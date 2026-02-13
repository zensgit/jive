import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jive/core/widgets/jive_calendar/jive_calendar_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  testWidgets('JiveCalendarDayCell does not overflow with chinese labels', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final errors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: JiveCalendarDayCell(
                  day: DateTime(2026, 2, 17),
                  style: const CalendarStyle(
                    cellMargin: EdgeInsets.zero,
                    cellPadding: EdgeInsets.zero,
                    cellAlignment: Alignment.center,
                  ),
                  decoration: const BoxDecoration(),
                  textStyle: const TextStyle(fontSize: 14),
                  lunarLabel: '国庆中秋',
                  showTodayLabel: true,
                  holidayCornerMark: const JiveHolidayCornerMark(
                    JiveHolidayCornerType.rest,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
    } finally {
      FlutterError.onError = oldOnError;
    }

    expect(errors, isEmpty);
  });
}
