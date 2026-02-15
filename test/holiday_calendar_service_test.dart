import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/holiday_calendar_service.dart';

void main() {
  test('parseCnHolidayJson parses days map', () {
    const json = '''
{
  "schema": 1,
  "country": "CN",
  "days": {
    "2026-02-14": "work",
    "2026-02-15": "rest"
  }
}
''';

    final map = JiveHolidayCalendarService.parseCnHolidayJson(json);
    expect(map[20260214], JiveHolidayType.work);
    expect(map[20260215], JiveHolidayType.rest);
  });

  test('parseCnHolidayJson supports boolean values', () {
    const json = '''
{
  "schema": 1,
  "days": {
    "2026-02-14": true,
    "2026-02-15": false
  }
}
''';

    final map = JiveHolidayCalendarService.parseCnHolidayJson(json);
    expect(map[20260214], JiveHolidayType.work);
    expect(map[20260215], JiveHolidayType.rest);
  });
}

