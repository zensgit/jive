import 'package:flutter/material.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/project_model.dart';
import '../../../core/database/tag_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/account_service.dart';

/// Horizontal scrollable row of pill-shaped quick action chips, mirroring
/// iCost's bar above the amount input. Each pill opens a picker / toggles a
/// flag for one transaction field.
class QuickFieldPillsBar extends StatelessWidget {
  final JiveAccount? selectedAccount;
  final List<JiveTag> selectedTags;
  final JiveProject? selectedProject;
  final bool excludeFromBudget;
  final bool excludeFromTotals;
  final bool isExpense;
  final bool isTransfer;
  final VoidCallback onTapAccount;
  final VoidCallback onTapTags;
  final VoidCallback onTapProject;
  final VoidCallback onTapBillFlag;
  final ValueChanged<bool> onToggleExcludeBudget;
  final VoidCallback? onTapPhoto;

  const QuickFieldPillsBar({
    super.key,
    required this.selectedAccount,
    required this.selectedTags,
    required this.selectedProject,
    required this.excludeFromBudget,
    required this.excludeFromTotals,
    required this.isExpense,
    required this.isTransfer,
    required this.onTapAccount,
    required this.onTapTags,
    required this.onTapProject,
    required this.onTapBillFlag,
    required this.onToggleExcludeBudget,
    this.onTapPhoto,
  });

  String _billFlagLabel() {
    if (excludeFromBudget && excludeFromTotals) return '不计收支·预算';
    if (excludeFromTotals) return '不计收支';
    if (excludeFromBudget) return '不计预算';
    return '标记';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);

    final accountColor = AccountService.parseColorHex(selectedAccount?.colorHex)
        ?? JiveTheme.primaryGreen;
    final accountLabel = selectedAccount?.name ?? '选择账户';

    final tagsLabel = selectedTags.isEmpty
        ? '标签'
        : '标签·${selectedTags.length}';

    final projectLabel = selectedProject?.name ?? '项目';

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? JiveTheme.darkCard : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? JiveTheme.darkDivider : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _Pill(
            icon: AccountService.getIcon(
              selectedAccount?.iconName ?? 'account_balance_wallet',
            ),
            label: accountLabel,
            color: accountColor,
            isActive: selectedAccount != null,
            onTap: onTapAccount,
          ),
          _Pill(
            icon: Icons.label_outline,
            label: tagsLabel,
            color: JiveTheme.primaryGreen,
            isActive: selectedTags.isNotEmpty,
            onTap: onTapTags,
          ),
          _Pill(
            icon: Icons.folder_outlined,
            label: projectLabel,
            color: Colors.purple,
            isActive: selectedProject != null,
            onTap: onTapProject,
          ),
          // 账单标记 pill — combines 不计入收支 + 不计入预算 per 钱迹 UX
          _Pill(
            icon: Icons.flag_outlined,
            label: _billFlagLabel(),
            color: Colors.redAccent,
            isActive: excludeFromBudget || excludeFromTotals,
            onTap: onTapBillFlag,
          ),
          if (onTapPhoto != null)
            _Pill(
              icon: Icons.image_outlined,
              label: '图片',
              color: Colors.blue,
              isActive: false,
              onTap: onTapPhoto!,
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = JiveTheme.isDark(context);
    final bgColor = isActive
        ? color.withValues(alpha: isDark ? 0.25 : 0.12)
        : (isDark ? Colors.white12 : Colors.white);
    final borderColor = isActive
        ? color.withValues(alpha: 0.5)
        : (isDark ? Colors.white24 : Colors.grey.shade300);
    final fgColor = isActive
        ? color
        : JiveTheme.secondaryTextColor(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: fgColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
