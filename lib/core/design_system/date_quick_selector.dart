import 'package:flutter/material.dart';

/// Horizontal row of quick-date chips: 今天 | 昨天 | 前天 | 选择日期...
///
/// Compact (32 px height) and fits in a single row. Tapping a relative
/// chip immediately fires [onDateSelected]; tapping "选择日期..." opens a
/// full date-picker dialog.
class DateQuickSelector extends StatelessWidget {
  /// Currently selected date (determines which chip is highlighted).
  final DateTime selectedDate;

  /// Called whenever the user picks a date.
  final ValueChanged<DateTime> onDateSelected;

  const DateQuickSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  // ── helpers ──

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = _today();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = today.subtract(const Duration(days: 2));

    final chips = <_ChipData>[
      _ChipData('今天', today),
      _ChipData('昨天', yesterday),
      _ChipData('前天', dayBefore),
    ];

    final isCustom =
        !chips.any((c) => _isSameDay(c.date, selectedDate));

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (final chip in chips) ...[
            _buildChip(
              context,
              label: chip.label,
              selected: _isSameDay(chip.date, selectedDate),
              onTap: () => onDateSelected(chip.date),
            ),
            const SizedBox(width: 8),
          ],
          _buildChip(
            context,
            label: '选择日期...',
            selected: isCustom,
            onTap: () => _pickDate(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const greenColor = Color(0xFF43A047);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? greenColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? greenColor : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final DateTime date;
  const _ChipData(this.label, this.date);
}
