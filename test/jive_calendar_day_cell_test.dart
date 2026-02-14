import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/widgets/jive_calendar/jive_calendar_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  testWidgets('JiveCalendarDayCell does not overflow with long labels', (
    tester,
  ) async {
    final style = const CalendarStyle();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 42,
              height: 42,
              child: JiveCalendarDayCell(
                day: DateTime(2026, 5, 1),
                style: style,
                decoration: const BoxDecoration(color: Colors.white),
                textStyle: const TextStyle(fontSize: 14, color: Colors.black),
                lunarLabel: '国际劳动节劳动节劳动节',
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

    expect(tester.takeException(), isNull);
    expect(find.text('休'), findsOneWidget);
  });
}

