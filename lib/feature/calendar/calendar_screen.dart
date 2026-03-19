import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import 'calendar_day_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static final DateTime _firstDay = DateTime(2000, 1, 1);
  static final DateTime _lastDay = DateTime(2100, 12, 31);

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );
  final DateFormat _monthFormat = DateFormat('yyyy年M月', 'zh_CN');

  Isar? _isar;
  DateTime _focusedMonth = DateUtils.dateOnly(DateTime.now());
  DateTime? _selectedDay = DateUtils.dateOnly(DateTime.now());
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasDataChanges = false;
  int _loadRevision = 0;

  List<JiveTransaction> _monthTransactions = const [];
  Map<DateTime, _DayTotals> _dailyTotals = const {};
  _MonthSummary _monthSummary = const _MonthSummary();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    _loadMonthData(_focusedMonth);
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _loadMonthData(DateTime month, {bool showLoading = true}) async {
    final revision = ++_loadRevision;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final isar = await _ensureIsar();
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 1);

      final txFuture = isar.jiveTransactions
          .filter()
          .timestampBetween(monthStart, monthEnd, includeUpper: false)
          .findAll();

      final transactions = await txFuture;
      transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final dailyTotals = <DateTime, _DayTotals>{};
      var income = 0.0;
      var expense = 0.0;

      for (final tx in transactions) {
        final dayKey = DateUtils.dateOnly(tx.timestamp);
        final current = dailyTotals[dayKey] ?? const _DayTotals();
        final type = tx.type ?? 'expense';
        final amount = tx.amount.abs();
        if (type == 'income') {
          dailyTotals[dayKey] = current.copyWith(income: current.income + amount);
          income += amount;
        } else if (type == 'expense') {
          dailyTotals[dayKey] = current.copyWith(expense: current.expense + amount);
          expense += amount;
        }
      }

      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _focusedMonth = monthStart;
        _monthTransactions = transactions;
        _dailyTotals = dailyTotals;
        _monthSummary = _MonthSummary(
          income: income,
          expense: expense,
        );
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stack) {
      debugPrint('CalendarScreen load error: $e\n$stack');
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载日历失败：$e';
      });
    }
  }

  Future<void> _handleMonthChanged(DateTime month) async {
    final nextMonth = DateTime(month.year, month.month, 1);
    setState(() {
      _focusedMonth = nextMonth;
      if (_selectedDay != null &&
          (_selectedDay!.year != nextMonth.year ||
              _selectedDay!.month != nextMonth.month)) {
        _selectedDay = null;
      }
    });
    await _loadMonthData(nextMonth, showLoading: false);
  }

  Future<void> _openDayDetail(DateTime day) async {
    setState(() {
      _selectedDay = DateUtils.dateOnly(day);
    });
    final changed = await CalendarDayDetailSheet.show(context, day: day);
    if (changed == true) {
      _hasDataChanges = true;
      await _loadMonthData(_focusedMonth, showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasDataChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasDataChanges),
          ),
          title: Text(
            '日历视图',
            style: GoogleFonts.lato(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: '回到本月',
              onPressed: _goToCurrentMonth,
              icon: const Icon(Icons.today_outlined),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  void _goToCurrentMonth() {
    final now = DateUtils.dateOnly(DateTime.now());
    _selectedDay = now;
    _handleMonthChanged(now);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadMonthData(_focusedMonth),
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMonthData(_focusedMonth, showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildCalendarCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final cardColor = JiveTheme.cardColor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final balanceColor = _monthSummary.balance >= 0
        ? JiveTheme.primaryGreen
        : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: JiveTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月汇总',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_monthFormat.format(_focusedMonth)} · ${_monthTransactions.length} 笔记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: '收入',
                  value: _currency.format(_monthSummary.income),
                  valueColor: JiveTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: '支出',
                  value: _currency.format(_monthSummary.expense),
                  valueColor: colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: '结余',
                  value: _currency.format(_monthSummary.balance),
                  valueColor: balanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: JiveTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: TableCalendar<dynamic>(
        locale: 'zh_CN',
        firstDay: _firstDay,
        lastDay: _lastDay,
        focusedDay: _focusedMonth,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        availableGestures: AvailableGestures.horizontalSwipe,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 86,
        daysOfWeekHeight: 24,
        sixWeekMonthsEnforced: true,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: const EdgeInsets.symmetric(vertical: 6),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: colorScheme.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: colorScheme.primary,
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          isTodayHighlighted: false,
          cellMargin: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          _openDayDetail(selectedDay);
        },
        onPageChanged: _handleMonthChanged,
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) {
            return Text(
              _monthFormat.format(day),
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            );
          },
          dowBuilder: (context, day) {
            const labels = <int, String>{
              DateTime.monday: '一',
              DateTime.tuesday: '二',
              DateTime.wednesday: '三',
              DateTime.thursday: '四',
              DateTime.friday: '五',
              DateTime.saturday: '六',
              DateTime.sunday: '日',
            };
            final isWeekend = day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday;
            return Center(
              child: Text(
                labels[day.weekday] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? colorScheme.error.withValues(alpha: 0.85)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              day,
              isSelected: isSameDay(_selectedDay, day),
              isToday: isSameDay(DateTime.now(), day),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              day,
              isSelected: true,
              isToday: isSameDay(DateTime.now(), day),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              day,
              isSelected: isSameDay(_selectedDay, day),
              isToday: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isSelected,
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayKey = DateUtils.dateOnly(day);
    final totals = _dailyTotals[dayKey] ?? const _DayTotals();
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : (isToday
              ? JiveTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent);
    final borderColor = isSelected
        ? colorScheme.primary
        : (isToday
              ? JiveTheme.primaryGreen.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3));
    final dayColor = isSelected ? colorScheme.primary : colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${day.day}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dayColor,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: JiveTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAmountLine(
                  label: '收',
                  amount: totals.income,
                  color: JiveTheme.primaryGreen,
                ),
                const SizedBox(height: 2),
                _buildAmountLine(
                  label: '支',
                  amount: totals.expense,
                  color: colorScheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountLine({
    required String label,
    required double amount,
    required Color color,
  }) {
    final hasValue = amount > 0;
    final text = hasValue ? '$label ${_formatCellAmount(amount)}' : '$label -';
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontSize: 9,
            fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
            color: hasValue ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatCellAmount(double amount) {
    if (amount >= 10000) {
      final text = (amount / 10000).toStringAsFixed(amount >= 100000 ? 0 : 1);
      return '${text.replaceAll('.0', '')}万';
    }
    if (amount >= 1000) {
      return amount.toStringAsFixed(0);
    }
    if (amount >= 100) {
      return amount.toStringAsFixed(0);
    }
    if (amount >= 10) {
      return amount.toStringAsFixed(1).replaceAll('.0', '');
    }
    return amount.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSummary {
  final double income;
  final double expense;

  const _MonthSummary({
    this.income = 0,
    this.expense = 0,
  });

  double get balance => income - expense;
}

class _DayTotals {
  final double income;
  final double expense;

  const _DayTotals({
    this.income = 0,
    this.expense = 0,
  });

  _DayTotals copyWith({
    double? income,
    double? expense,
  }) {
    return _DayTotals(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
