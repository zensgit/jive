import 'package:flutter/material.dart';

import '../../core/service/billing_reminder_service.dart';

/// 账单/还款日提醒卡片 — 用于首页或设置页展示
class BillingReminderWidget extends StatelessWidget {
  final List<BillingReminder> reminders;

  const BillingReminderWidget({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '账单提醒',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...reminders.map((r) => _buildReminderRow(context, r)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderRow(BuildContext context, BillingReminder reminder) {
    final theme = Theme.of(context);
    final color = _urgencyColor(reminder.daysUntil);
    final label = reminder.type == 'billing' ? '账单日' : '还款日';
    final daysText = reminder.daysUntil == 0
        ? '今天'
        : reminder.daysUntil == 1
            ? '明天'
            : '${reminder.daysUntil}天后';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reminder.accountName,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$label还有$daysText',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 绿色 >5天, 橙色 2-5天, 红色 <=1天
  Color _urgencyColor(int daysUntil) {
    if (daysUntil <= 1) return Colors.red;
    if (daysUntil <= 5) return Colors.orange;
    return Colors.green;
  }
}
