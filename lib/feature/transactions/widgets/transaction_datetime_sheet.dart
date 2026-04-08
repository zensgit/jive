import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/theme.dart';

/// 钱迹风格的日期时间选择 sheet：
///
/// - 顶部 iOS 风格的三列滚轮（年/月/日）
/// - 下方快捷按钮：今 / 昨 / 前 / 时间 HH:mm
/// - 底部 取消 / 确定
///
/// 返回选择的 DateTime（含时间），取消返回 null。
Future<DateTime?> showTransactionDateTimeSheet(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: JiveTheme.cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) => _Sheet(
      initial: initial,
      firstDate: firstDate ?? DateTime(DateTime.now().year - 5),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 1),
    ),
  );
}

class _Sheet extends StatefulWidget {
  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  const _Sheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late DateTime _value;
  late DateTime _todayMidnight;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    final now = DateTime.now();
    _todayMidnight = DateTime(now.year, now.month, now.day);
  }

  void _jumpToOffset(int daysBack) {
    final target = _todayMidnight.subtract(Duration(days: daysBack));
    setState(() {
      _value = DateTime(
        target.year,
        target.month,
        target.day,
        _value.hour,
        _value.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_value),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null && mounted) {
      setState(() {
        _value = DateTime(
          _value.year,
          _value.month,
          _value.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final valueDay = DateTime(_value.year, _value.month, _value.day);
    final isToday = _isSameDay(valueDay, _todayMidnight);
    final isYesterday =
        _isSameDay(valueDay, _todayMidnight.subtract(const Duration(days: 1)));
    final isDayBeforeYesterday =
        _isSameDay(valueDay, _todayMidnight.subtract(const Duration(days: 2)));
    final timeText = DateFormat('HH:mm').format(_value);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Wheel picker
            SizedBox(
              height: 180,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness:
                      JiveTheme.isDark(context) ? Brightness.dark : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 20,
                      color: JiveTheme.textColor(context),
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  key: ValueKey(
                    '${_value.year}-${_value.month}-${_value.day}',
                  ),
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _value,
                  minimumDate: widget.firstDate,
                  maximumDate: widget.lastDate,
                  onDateTimeChanged: (d) {
                    setState(() {
                      _value = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        _value.hour,
                        _value.minute,
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Preset row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _PresetChip(
                  label: '今',
                  isActive: isToday,
                  onTap: () => _jumpToOffset(0),
                ),
                _PresetChip(
                  label: '昨',
                  isActive: isYesterday,
                  onTap: () => _jumpToOffset(1),
                ),
                _PresetChip(
                  label: '前',
                  isActive: isDayBeforeYesterday,
                  onTap: () => _jumpToOffset(2),
                ),
                _PresetChip(
                  label: '时间 $timeText',
                  isActive: false,
                  icon: Icons.access_time,
                  onTap: _pickTime,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _value),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final activeColor = JiveTheme.primaryGreen;
    final bg = isActive
        ? activeColor.withValues(alpha: 0.18)
        : (isDark ? Colors.white12 : Colors.grey.shade100);
    final fg = isActive
        ? activeColor
        : JiveTheme.secondaryTextColor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: fg,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
