import 'package:flutter/material.dart';

import '../date_picker_sheet.dart';
import '../date_range_picker_sheet.dart';

/// System calendar entry points for picking a day / a date range.
///
/// These helpers wrap the internal sheet widgets and provide a stable API
/// for callers across the app.
class JiveDatePicker {
  static Future<({DateTime? value, bool didChange})> pickDateResult(
    BuildContext context, {
    required DateTime? initialDay,
    DateTime? firstDay,
    DateTime? lastDay,
    String bottomLabel = '选择日期',
    String clearLabel = '清除',
    bool allowClear = false,
    Set<int>? enabledYears,
    DateTime? minSelectableDay,
    DateTime? maxSelectableDay,
  }) async {
    DateTime? picked;
    var didChange = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DatePickerSheet(
          initialDay: initialDay,
          firstDay: firstDay,
          lastDay: lastDay,
          bottomLabel: bottomLabel,
          clearLabel: clearLabel,
          allowClear: allowClear,
          enabledYears: enabledYears,
          minSelectableDay: minSelectableDay,
          maxSelectableDay: maxSelectableDay,
          onChanged: (value) {
            didChange = true;
            picked = value;
          },
        );
      },
    );
    return (value: picked, didChange: didChange);
  }

  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime? initialDay,
    DateTime? firstDay,
    DateTime? lastDay,
    String bottomLabel = '选择日期',
    String clearLabel = '清除',
    bool allowClear = false,
    Set<int>? enabledYears,
    DateTime? minSelectableDay,
    DateTime? maxSelectableDay,
  }) async {
    final result = await pickDateResult(
      context,
      initialDay: initialDay,
      firstDay: firstDay,
      lastDay: lastDay,
      bottomLabel: bottomLabel,
      clearLabel: clearLabel,
      allowClear: allowClear,
      enabledYears: enabledYears,
      minSelectableDay: minSelectableDay,
      maxSelectableDay: maxSelectableDay,
    );
    return result.didChange ? result.value : initialDay;
  }

  static Future<({DateTimeRange? value, bool didChange})> pickDateRangeResult(
    BuildContext context, {
    required DateTimeRange? initialRange,
    DateTime? firstDay,
    DateTime? lastDay,
    String bottomLabel = '选择日历范围',
    String clearLabel = '清除',
    Set<int>? enabledYears,
    DateTime? minSelectableDay,
    DateTime? maxSelectableDay,
  }) async {
    DateTimeRange? picked;
    var didChange = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DateRangePickerSheet(
          initialRange: initialRange,
          firstDay: firstDay,
          lastDay: lastDay,
          bottomLabel: bottomLabel,
          clearLabel: clearLabel,
          enabledYears: enabledYears,
          minSelectableDay: minSelectableDay,
          maxSelectableDay: maxSelectableDay,
          onChanged: (value) {
            didChange = true;
            picked = value;
          },
        );
      },
    );
    return (value: picked, didChange: didChange);
  }

  static Future<DateTimeRange?> pickDateRange(
    BuildContext context, {
    required DateTimeRange? initialRange,
    DateTime? firstDay,
    DateTime? lastDay,
    String bottomLabel = '选择日历范围',
    String clearLabel = '清除',
    Set<int>? enabledYears,
    DateTime? minSelectableDay,
    DateTime? maxSelectableDay,
  }) async {
    final result = await pickDateRangeResult(
      context,
      initialRange: initialRange,
      firstDay: firstDay,
      lastDay: lastDay,
      bottomLabel: bottomLabel,
      clearLabel: clearLabel,
      enabledYears: enabledYears,
      minSelectableDay: minSelectableDay,
      maxSelectableDay: maxSelectableDay,
    );
    return result.didChange ? result.value : initialRange;
  }
}
