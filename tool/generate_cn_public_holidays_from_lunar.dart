import 'dart:convert';
import 'dart:io';

import 'package:lunar/lunar.dart';

String _ymd(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

void main(List<String> args) async {
  var startYear = 2010;
  var endYear = DateTime.now().year + 2;
  var outPath = 'assets/holidays/cn_public_holidays.json';

  for (final arg in args) {
    if (arg.startsWith('--start=')) {
      startYear = int.parse(arg.substring('--start='.length));
    } else if (arg.startsWith('--end=')) {
      endYear = int.parse(arg.substring('--end='.length));
    } else if (arg.startsWith('--out=')) {
      outPath = arg.substring('--out='.length);
    }
  }

  if (endYear < startYear) {
    stderr.writeln('endYear must be >= startYear');
    exitCode = 2;
    return;
  }

  final days = <String, String>{};
  for (var year = startYear; year <= endYear; year++) {
    for (var month = 1; month <= 12; month++) {
      for (var day = 1; day <= 31; day++) {
        DateTime date;
        try {
          date = DateTime(year, month, day);
        } catch (_) {
          continue;
        }
        if (date.year != year || date.month != month || date.day != day) {
          continue;
        }
        final holiday = HolidayUtil.getHolidayByYmd(year, month, day);
        if (holiday == null) continue;
        days[_ymd(date)] = holiday.isWork() ? 'work' : 'rest';
      }
    }
  }

  // Ensure stable ordering.
  final sortedKeys = days.keys.toList()
    ..sort((a, b) => a.compareTo(b));
  final sortedDays = <String, String>{for (final k in sortedKeys) k: days[k]!};

  final doc = <String, dynamic>{
    'schema': 1,
    'country': 'CN',
    'startYear': startYear,
    'endYear': endYear,
    'days': sortedDays,
  };

  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(doc)}\n');

  stdout.writeln(
    'Wrote ${sortedDays.length} holiday entries to $outPath (years: $startYear-$endYear)',
  );
}
