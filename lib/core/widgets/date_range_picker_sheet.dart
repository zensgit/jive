import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lunar/lunar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'jive_calendar/jive_calendar_day_cell.dart';

class DateRangePickerSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime firstDay;
  final DateTime lastDay;
  final ValueChanged<DateTimeRange?> onChanged;
  final String bottomLabel;
  final String clearLabel;
  final Set<int>? enabledYears;
  final DateTime? minSelectableDay;
  final DateTime? maxSelectableDay;

  DateRangePickerSheet({
    super.key,
    required this.initialRange,
    required this.onChanged,
    DateTime? firstDay,
    DateTime? lastDay,
    this.bottomLabel = '选择日历范围',
    this.clearLabel = '清除',
    this.enabledYears,
    this.minSelectableDay,
    this.maxSelectableDay,
  }) : firstDay = firstDay ?? DateTime(2010),
       lastDay = lastDay ?? DateTime.now();

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _focusedDay;
  bool _showLunar = true;
  bool _showJieQi = false;
  bool _showFestival = false;
  bool _showHoliday = false;

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
    _loadLunarPrefs();
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

  Future<void> _loadLunarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showLunar = prefs.getBool('calendar_show_lunar') ?? true;
      _showJieQi = prefs.getBool('calendar_show_jieqi') ?? false;
      _showFestival = prefs.getBool('calendar_show_festival') ?? false;
      _showHoliday = prefs.getBool('calendar_show_holiday') ?? false;
    });
  }

  Future<void> _saveLunarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_show_lunar', _showLunar);
    await prefs.setBool('calendar_show_jieqi', _showJieQi);
    await prefs.setBool('calendar_show_festival', _showFestival);
    await prefs.setBool('calendar_show_holiday', _showHoliday);
  }

  bool _isChineseLocale(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null && locale.languageCode.toLowerCase().startsWith('zh')) {
      return true;
    }
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode.toLowerCase().startsWith('zh');
  }

  bool _hasChineseText(String value) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(value);
  }

  String _calendarLocaleTag(BuildContext context) {
    final locale =
        Localizations.maybeLocaleOf(context) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    if (locale.languageCode.toLowerCase().startsWith('zh')) {
      final country = locale.countryCode;
      if (country == null || country.isEmpty) return 'zh_CN';
      return 'zh_${country.toUpperCase()}';
    }
    return locale.toLanguageTag();
  }

  String? _lunarLabelFor(DateTime day, bool isChinese) {
    if (!isChinese) return null;
    if (!_showLunar && !_showJieQi && !_showFestival) return null;
    final lunar = Lunar.fromDate(DateTime(day.year, day.month, day.day));
    if (_showFestival) {
      final holiday = HolidayUtil.getHolidayByYmd(day.year, day.month, day.day);
      if (holiday != null) {
        final target = holiday.getTarget();
        if (target == _formatDate(day)) {
          return holiday.getName();
        }
      }
      final month = lunar.getMonth().abs();
      final key = '$month-${lunar.getDay()}';
      final festival = LunarUtil.FESTIVAL[key];
      if (festival != null && festival.isNotEmpty) return festival;
      final others = LunarUtil.OTHER_FESTIVAL[key];
      if (others != null && others.isNotEmpty) return others.first;
    }
    if (_showJieQi) {
      final jie = lunar.getJie();
      if (jie.isNotEmpty) return jie;
      final qi = lunar.getQi();
      if (qi.isNotEmpty) return qi;
    }
    if (_showLunar) return lunar.getDayInChinese();
    return null;
  }

  JiveHolidayCornerMark? _holidayCornerMarkFor(DateTime day, bool isChinese) {
    if (!isChinese || !_showHoliday) return null;
    final holiday = HolidayUtil.getHolidayByYmd(day.year, day.month, day.day);
    if (holiday == null) return null;
    return JiveHolidayCornerMark(
      holiday.isWork()
          ? JiveHolidayCornerType.work
          : JiveHolidayCornerType.rest,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = _two(date.month);
    final day = _two(date.day);
    return '$year-$month-$day';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  DateTime _selectableMin() => widget.minSelectableDay ?? widget.firstDay;

  DateTime _selectableMax() => widget.maxSelectableDay ?? widget.lastDay;

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

  DateTime? _normalizeRangeDate(DateTime? value) {
    if (value == null) return null;
    final minSelectable = _selectableMin();
    final maxSelectable = _selectableMax();
    if (value.isBefore(minSelectable) || value.isAfter(maxSelectable)) {
      return null;
    }
    return value;
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
        final minMonth = _minMonthForYear(selectedYear);
        final maxMonth = _maxMonthForYear(selectedYear);
        if (selectedMonth < minMonth) selectedMonth = minMonth;
        if (selectedMonth > maxMonth) selectedMonth = maxMonth;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                      initialValue: selectedYear,
                      items: years
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedYear = value;
                          final minMonth = _minMonthForYear(selectedYear);
                          final maxMonth = _maxMonthForYear(selectedYear);
                          if (selectedMonth < minMonth) {
                            selectedMonth = minMonth;
                          }
                          if (selectedMonth > maxMonth) {
                            selectedMonth = maxMonth;
                          }
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
                        final isEnabled =
                            month >= minMonth && month <= maxMonth;
                        final color = isEnabled
                            ? Colors.black87
                            : Colors.grey.shade500;
                        return ChoiceChip(
                          label: Text(
                            _two(month),
                            style: TextStyle(color: color),
                          ),
                          selected: selectedMonth == month,
                          onSelected: isEnabled
                              ? (_) =>
                                    setSheetState(() => selectedMonth = month)
                              : null,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final candidate = DateTime(
                            selectedYear,
                            selectedMonth,
                            1,
                          );
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
    final orientation = MediaQuery.of(context).orientation;
    final isChinese =
        _isChineseLocale(context) || _hasChineseText(widget.bottomLabel);
    final calendarLocale = isChinese ? 'zh_CN' : _calendarLocaleTag(context);
    final heightFactor = orientation == Orientation.landscape ? 0.94 : 0.62;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
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
                      final headerHeight = orientation == Orientation.landscape
                          ? 52.0
                          : 48.0;
                      const dowHeight = 20.0;
                      final extraPadding = orientation == Orientation.landscape
                          ? 20.0
                          : 12.0;
                      final maxHeight = constraints.maxHeight;
                      final available =
                          maxHeight - headerHeight - dowHeight - extraPadding;
                      var rowHeight = available / 6;
                      final maxRowHeight = orientation == Orientation.landscape
                          ? 42.0
                          : 46.0;
                      if (rowHeight > maxRowHeight) {
                        rowHeight = maxRowHeight;
                      }
                      const todayDecoration = BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      );
                      final enabledYears =
                          widget.enabledYears?.isNotEmpty == true
                          ? widget.enabledYears
                          : null;
                      final calendarStyle = CalendarStyle(
                        rangeHighlightColor: Colors.green.withValues(
                          alpha: 0.12,
                        ),
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
                        locale: calendarLocale,
                        firstDay: widget.firstDay,
                        lastDay: widget.lastDay,
                        focusedDay: _focusedDay,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        shouldFillViewport: true,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        rowHeight: rowHeight,
                        daysOfWeekHeight: dowHeight,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronMargin: EdgeInsets.zero,
                          rightChevronMargin: EdgeInsets.zero,
                          headerPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        enabledDayPredicate: (day) {
                          final minSelectable = _selectableMin();
                          final maxSelectable = _selectableMax();
                          if (day.isBefore(minSelectable) ||
                              day.isAfter(maxSelectable)) {
                            return false;
                          }
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
                          defaultBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.defaultDecoration,
                              textStyle: calendarStyle.defaultTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          outsideBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.outsideDecoration,
                              textStyle: calendarStyle.outsideTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: false,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          disabledBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.disabledDecoration,
                              textStyle: calendarStyle.disabledTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: false,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.todayDecoration,
                              textStyle: calendarStyle.todayTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.selectedDecoration,
                              textStyle: calendarStyle.selectedTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          rangeStartBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.rangeStartDecoration,
                              textStyle: calendarStyle.rangeStartTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          rangeEndBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.rangeEndDecoration,
                              textStyle: calendarStyle.rangeEndTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
                            );
                          },
                          withinRangeBuilder: (context, day, focusedDay) {
                            final lunarLabel = _lunarLabelFor(day, isChinese);
                            final holidayMark = _holidayCornerMarkFor(
                              day,
                              isChinese,
                            );
                            final showTodayLabel = _shouldShowTodayLabel(
                              day,
                              enabledYears,
                            );
                            return JiveCalendarDayCell(
                              day: day,
                              style: calendarStyle,
                              decoration: calendarStyle.withinRangeDecoration,
                              textStyle: calendarStyle.withinRangeTextStyle,
                              lunarLabel: lunarLabel,
                              showTodayLabel: showTodayLabel,
                              holidayCornerMark: holidayMark,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: background,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChinese)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('农历'),
                              selected: _showLunar,
                              onSelected: (value) {
                                setState(() => _showLunar = value);
                                _saveLunarPrefs();
                              },
                              selectedColor: Colors.green.withValues(
                                alpha: 0.12,
                              ),
                              checkmarkColor: Colors.green.shade700,
                            ),
                            FilterChip(
                              label: const Text('节气'),
                              selected: _showJieQi,
                              onSelected: (value) {
                                setState(() => _showJieQi = value);
                                _saveLunarPrefs();
                              },
                              selectedColor: Colors.green.withValues(
                                alpha: 0.12,
                              ),
                              checkmarkColor: Colors.green.shade700,
                            ),
                            FilterChip(
                              label: const Text('节日'),
                              selected: _showFestival,
                              onSelected: (value) {
                                setState(() => _showFestival = value);
                                _saveLunarPrefs();
                              },
                              selectedColor: Colors.green.withValues(
                                alpha: 0.12,
                              ),
                              checkmarkColor: Colors.green.shade700,
                            ),
                            FilterChip(
                              label: const Text('节假日'),
                              selected: _showHoliday,
                              onSelected: (value) {
                                setState(() => _showHoliday = value);
                                _saveLunarPrefs();
                              },
                              selectedColor: Colors.green.withValues(
                                alpha: 0.12,
                              ),
                              checkmarkColor: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    Row(
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
