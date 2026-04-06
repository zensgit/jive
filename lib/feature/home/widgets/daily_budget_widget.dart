import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/service/daily_budget_service.dart';

/// 每日可用预算小卡片 —— 用于首页展示
class DailyBudgetWidget extends StatefulWidget {
  final int? bookId;

  const DailyBudgetWidget({super.key, this.bookId});

  @override
  State<DailyBudgetWidget> createState() => _DailyBudgetWidgetState();
}

class _DailyBudgetWidgetState extends State<DailyBudgetWidget> {
  DailyBudgetInfo? _info;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = await DailyBudgetService.create();
      final info = await service.getDailyBudget(bookId: widget.bookId);
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(DailyBudgetStatus status) {
    switch (status) {
      case DailyBudgetStatus.safe:
        return const Color(0xFF43A047); // green
      case DailyBudgetStatus.tight:
        return const Color(0xFFFB8C00); // orange
      case DailyBudgetStatus.exceeded:
        return const Color(0xFFE53935); // red
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_info == null) return const SizedBox.shrink();

    final info = _info!;
    final color = _statusColor(info.status);
    final fmt = NumberFormat('#,##0.00');

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.today, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  '今日可用',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '\u00a5${fmt.format(info.dailyAvailable)}',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _expandedRow('月预算', '\u00a5${fmt.format(info.monthlyBudget)}'),
              const SizedBox(height: 4),
              _expandedRow('已支出', '\u00a5${fmt.format(info.spent)}'),
              const SizedBox(height: 4),
              _expandedRow('剩余', '\u00a5${fmt.format(info.remaining)}'),
              const SizedBox(height: 4),
              _expandedRow('剩余天数', '${info.daysLeft} 天'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _expandedRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.notoSansSc(
                fontSize: 12, color: Colors.grey[600])),
        Text(value,
            style: GoogleFonts.notoSansSc(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
