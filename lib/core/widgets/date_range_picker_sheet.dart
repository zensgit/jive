import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRangePickerSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime firstDay;
  final DateTime lastDay;
  final ValueChanged<DateTimeRange?> onChanged;
  final String bottomLabel;
  final String clearLabel;
  final Set<int>? enabledYears;

  DateRangePickerSheet({
    super.key,
    required this.initialRange,
    required this.onChanged,
    DateTime? firstDay,
    DateTime? lastDay,
    this.bottomLabel = '选择日历范围',
    this.clearLabel = '清除',
    this.enabledYears,
  })  : firstDay = firstDay ?? DateTime(2010),
        lastDay = lastDay ?? DateTime.now();

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _focusedDay;

  static const double _bottomBarHeight = 72;

  @override
  void initState() {
    super.initState();
    _rangeStart = _normalizeRangeDate(widget.initialRange?.start);
    _rangeEnd = _normalizeRangeDate(widget.initialRange?.end);
    if (_rangeStart == null) {
      _rangeEnd = null;
    }
    _focusedDay = _clampDate(
      _rangeStart ?? DateTime.now(),
      widget.firstDay,
      widget.lastDay,
    );
  }

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
        return;
      }

      if (_rangeEnd == null) {
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }
      }
    });

    if (_rangeStart != null && _rangeEnd != null) {
      widget.onChanged(DateTimeRange(start: _rangeStart!, end: _rangeEnd!));
      Navigator.pop(context);
    }
  }

  void _handleClear() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
    widget.onChanged(null);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = _two(date.month);
    final day = _two(date.day);
    return '$year-$month-$day';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }

  bool _shouldShowTodayLabel(DateTime day, Set<int>? enabledYears) {
    if (!isSameDay(day, DateTime.now())) return false;
    if (enabledYears != null && !enabledYears.contains(day.year)) return false;
    return true;
  }

  Widget _buildTodayCell({
    required DateTime day,
    required CalendarStyle style,
    required Decoration decoration,
    required TextStyle textStyle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: style.cellMargin,
      padding: style.cellPadding,
      decoration: decoration,
      alignment: style.cellAlignment,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: const Alignment(0, 0.3),
            child: Text('${day.day}', style: textStyle),
          ),
          Align(
            alignment: const Alignment(0, -0.75),
            child: Text(
              '今日',
              style: GoogleFonts.lato(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _normalizeRangeDate(DateTime? value) {
    if (value == null) return null;
    if (value.isBefore(widget.firstDay) || value.isAfter(widget.lastDay)) {
      return null;
    }
    return value;
  }

  int _closestEnabledYear(int year, List<int> enabledYears) {
    final sorted = [...enabledYears]..sort();
    for (final candidate in sorted.reversed) {
      if (candidate <= year) return candidate;
    }
    return sorted.first;
  }

  int _minMonthForYear(int year) {
    if (year == widget.firstDay.year) return widget.firstDay.month;
    return 1;
  }

  int _maxMonthForYear(int year) {
    if (year == widget.lastDay.year) return widget.lastDay.month;
    return 12;
  }

  Future<void> _openMonthYearPicker(DateTime focusedDay) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int selectedMonth = focusedDay.month;
        final startYear = widget.firstDay.year;
        final endYear = widget.lastDay.year;
        int selectedYear = focusedDay.year.clamp(startYear, endYear).toInt();
        final years = List<int>.generate(
          endYear - startYear + 1,
          (index) => startYear + index,
        );
        final enabledYears =
            widget.enabledYears?.isNotEmpty == true ? widget.enabledYears : null;
        if (enabledYears != null && !enabledYears.contains(selectedYear)) {
          selectedYear = _closestEnabledYear(selectedYear, enabledYears.toList());
        }
        final minMonth = _minMonthForYear(selectedYear);
        final maxMonth = _maxMonthForYear(selectedYear);
        if (selectedMonth < minMonth) selectedMonth = minMonth;
        if (selectedMonth > maxMonth) selectedMonth = maxMonth;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '选择月份',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedYear,
                      items: years
                          .map(
                            (year) {
                              final isEnabled =
                                  enabledYears == null || enabledYears.contains(year);
                              final color = isEnabled
                                  ? Colors.black87
                                  : Colors.grey.shade500;
                              return DropdownMenuItem<int>(
                                value: year,
                                enabled: isEnabled,
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(color: color),
                                ),
                              );
                            },
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedYear = value;
                          final minMonth = _minMonthForYear(selectedYear);
                          final maxMonth = _maxMonthForYear(selectedYear);
                          if (selectedMonth < minMonth) selectedMonth = minMonth;
                          if (selectedMonth > maxMonth) selectedMonth = maxMonth;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: '年份',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final minMonth = _minMonthForYear(selectedYear);
                        final maxMonth = _maxMonthForYear(selectedYear);
                        final isEnabled = month >= minMonth && month <= maxMonth;
                        final color = isEnabled ? Colors.black87 : Colors.grey.shade500;
                        return ChoiceChip(
                          label: Text(
                            '${_two(month)}',
                            style: TextStyle(color: color),
                          ),
                          selected: selectedMonth == month,
                          onSelected: isEnabled
                              ? (_) => setSheetState(() => selectedMonth = month)
                              : null,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final candidate = DateTime(selectedYear, selectedMonth, 1);
                          final clamped = _clampDate(
                            candidate,
                            widget.firstDay,
                            widget.lastDay,
                          );
                          Navigator.pop(context, clamped);
                        },
                        child: const Text('确定'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() => _focusedDay = picked);
    }
  }

  String _rangeLabel() {
    if (_rangeStart == null) return '不限';
    if (_rangeEnd == null) return '${_formatDate(_rangeStart!)} -';
    return '${_formatDate(_rangeStart!)} - ${_formatDate(_rangeEnd!)}';
  }

  @override
  Widget build(BuildContext context) {
    final background = Colors.white;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.62,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const headerHeight = 48.0;
                      const dowHeight = 20.0;
                      final available =
                          (constraints.maxHeight - headerHeight - dowHeight - 12)
                              .clamp(180.0, constraints.maxHeight);
                      final rowHeight =
                          (available / 6).clamp(32.0, 46.0);
                      const todayDecoration = BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      );
                      final enabledYears =
                          widget.enabledYears?.isNotEmpty == true
                              ? widget.enabledYears
                              : null;
                      final calendarStyle = CalendarStyle(
                        rangeHighlightColor: Colors.green.withOpacity(0.12),
                        rangeStartDecoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: todayDecoration,
                        todayTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                      return TableCalendar(
                        firstDay: widget.firstDay,
                        lastDay: widget.lastDay,
                        focusedDay: _focusedDay,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        rowHeight: rowHeight,
                        daysOfWeekHeight: dowHeight,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronMargin: EdgeInsets.zero,
                          rightChevronMargin: EdgeInsets.zero,
                        ),
                        enabledDayPredicate: (day) {
                          if (enabledYears == null) return true;
                          return enabledYears.contains(day.year);
                        },
                        calendarBuilders: CalendarBuilders(
                          headerTitleBuilder: (context, day) {
                            return InkWell(
                              onTap: () => _openMonthYearPicker(day),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${day.year}-${_two(day.month)}',
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            if (!_shouldShowTodayLabel(day, enabledYears)) {
                              return null;
                            }
                            return _buildTodayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.todayDecoration,
                              textStyle: calendarStyle.todayTextStyle,
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            if (!_shouldShowTodayLabel(day, enabledYears)) {
                              return null;
                            }
                            return _buildTodayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.selectedDecoration,
                              textStyle: calendarStyle.selectedTextStyle,
                            );
                          },
                          rangeStartBuilder: (context, day, focusedDay) {
                            if (!_shouldShowTodayLabel(day, enabledYears)) {
                              return null;
                            }
                            return _buildTodayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.rangeStartDecoration,
                              textStyle: calendarStyle.rangeStartTextStyle,
                            );
                          },
                          rangeEndBuilder: (context, day, focusedDay) {
                            if (!_shouldShowTodayLabel(day, enabledYears)) {
                              return null;
                            }
                            return _buildTodayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.rangeEndDecoration,
                              textStyle: calendarStyle.rangeEndTextStyle,
                            );
                          },
                          withinRangeBuilder: (context, day, focusedDay) {
                            if (!_shouldShowTodayLabel(day, enabledYears)) {
                              return null;
                            }
                            return _buildTodayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.withinRangeDecoration,
                              textStyle: calendarStyle.withinRangeTextStyle,
                            );
                          },
                        ),
                        calendarStyle: calendarStyle,
                        onDaySelected: _handleDaySelected,
                        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                      );
                    },
                  ),
                ),
              ),
              Container(
                height: _bottomBarHeight,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: background,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.bottomLabel,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _rangeLabel(),
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _handleClear,
                      child: Text(widget.clearLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
