import 'package:flutter/material.dart';

import '../../../core/design_system/date_quick_selector.dart';
import '../../../core/design_system/theme.dart';

/// Card-style display of essential transaction fields.
///
/// Shows a vertical list of tappable rows:
/// - 分类 (category)
/// - 账户 (account)
/// - 时间 (date, with inline [DateQuickSelector])
/// - 备注 (note)
///
/// Each row shows a label, the current value, and a chevron icon.
class TransactionCoreFields extends StatelessWidget {
  /// Display name of the selected category, or null if none selected.
  final String? categoryName;

  /// Display name of the selected account, or null if none selected.
  final String? accountName;

  /// The note/memo text, or null if empty.
  final String? note;

  /// The currently selected date.
  final DateTime date;

  final bool highlightCategory;
  final bool highlightAccount;
  final bool highlightDate;
  final bool highlightNote;

  /// Called when the category row is tapped.
  final VoidCallback? onCategoryTap;

  /// Called when the account row is tapped.
  final VoidCallback? onAccountTap;

  /// Called when the note row is tapped.
  final VoidCallback? onNoteTap;

  /// Called when a date is selected via the quick selector or date row tap.
  final ValueChanged<DateTime>? onDateSelected;

  const TransactionCoreFields({
    super.key,
    this.categoryName,
    this.accountName,
    this.note,
    required this.date,
    this.highlightCategory = false,
    this.highlightAccount = false,
    this.highlightDate = false,
    this.highlightNote = false,
    this.onCategoryTap,
    this.onAccountTap,
    this.onNoteTap,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? JiveTheme.darkCard : JiveTheme.cardWhite;
    final dividerColor = isDark ? JiveTheme.darkDivider : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FieldRow(
            icon: Icons.category_outlined,
            label: '分类',
            value: categoryName ?? '未选择',
            valueColor: categoryName != null ? null : Colors.grey,
            highlighted: highlightCategory,
            onTap: onCategoryTap,
          ),
          _Divider(color: dividerColor),
          _FieldRow(
            icon: Icons.account_balance_wallet_outlined,
            label: '账户',
            value: accountName ?? '未选择',
            valueColor: accountName != null ? null : Colors.grey,
            highlighted: highlightAccount,
            onTap: onAccountTap,
          ),
          _Divider(color: dividerColor),
          _DateFieldRow(
            date: date,
            highlighted: highlightDate,
            onDateSelected: onDateSelected,
          ),
          _Divider(color: dividerColor),
          _FieldRow(
            icon: Icons.notes_outlined,
            label: '备注',
            value: (note != null && note!.isNotEmpty) ? note! : '添加备注',
            valueColor: (note != null && note!.isNotEmpty) ? null : Colors.grey,
            highlighted: highlightNote,
            onTap: onNoteTap,
          ),
        ],
      ),
    );
  }
}

/// A single tappable row in the core fields card.
class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlighted;
  final VoidCallback? onTap;

  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: highlighted
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: highlighted
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                : EdgeInsets.zero,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: highlighted
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (highlighted) ...[
                  Text(
                    '待补全',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin horizontal divider for between rows.
class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 0.5, color: color),
    );
  }
}

/// The date row with an inline [DateQuickSelector].
class _DateFieldRow extends StatelessWidget {
  final DateTime date;
  final bool highlighted;
  final ValueChanged<DateTime>? onDateSelected;

  const _DateFieldRow({
    required this.date,
    this.highlighted = false,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: highlighted
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
              : EdgeInsets.zero,
          child: Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 20,
                color: highlighted
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '时间',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DateQuickSelector(
                  selectedDate: date,
                  onDateSelected: onDateSelected ?? (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
