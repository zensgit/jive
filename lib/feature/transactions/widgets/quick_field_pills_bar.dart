import 'package:flutter/material.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/project_model.dart';
import '../../../core/database/tag_model.dart';
import '../../../core/design_system/theme.dart';

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
  final double? discountAmount;
  final double? feeAmount;
  final bool isSplitMode;
  final int splitCount;
  final VoidCallback onTapAccount;
  final VoidCallback onTapTags;
  final VoidCallback onTapProject;
  final VoidCallback onTapBillFlag;
  final VoidCallback onTapDiscount;
  final VoidCallback onTapFee;
  final VoidCallback onTapSplit;
  final int photoCount;
  final ValueChanged<bool> onToggleExcludeBudget;
  final VoidCallback? onTapPhoto;
  final String? bookName;
  final String? bookEmoji;
  final VoidCallback? onTapBook;
  final String? reimbursementStatus;
  final VoidCallback? onTapReimbursement;

  const QuickFieldPillsBar({
    super.key,
    required this.selectedAccount,
    required this.selectedTags,
    required this.selectedProject,
    required this.excludeFromBudget,
    required this.excludeFromTotals,
    required this.isExpense,
    required this.isTransfer,
    required this.discountAmount,
    required this.feeAmount,
    required this.isSplitMode,
    required this.splitCount,
    required this.onTapAccount,
    required this.onTapTags,
    required this.onTapProject,
    required this.onTapBillFlag,
    required this.onTapDiscount,
    required this.onTapFee,
    required this.onTapSplit,
    this.photoCount = 0,
    required this.onToggleExcludeBudget,
    this.onTapPhoto,
    this.bookName,
    this.bookEmoji,
    this.onTapBook,
    this.reimbursementStatus,
    this.onTapReimbursement,
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
          // 账本 pill (first)
          if (onTapBook != null)
            _Pill(
              icon: Icons.book_outlined,
              label: bookName ?? '账本',
              color: Colors.teal,
              isActive: bookName != null,
              onTap: onTapBook!,
              emojiPrefix: bookEmoji,
            ),
          // 账户已移到金额栏左侧，pills 中不再显示
          // 组合（multi-account split）
          if (!isTransfer)
            _Pill(
              icon: Icons.call_split,
              label: isSplitMode ? '组合·$splitCount' : '组合',
              color: Colors.deepPurple,
              isActive: isSplitMode,
              onTap: onTapSplit,
            ),
          _Pill(
            icon: Icons.label_outline,
            label: tagsLabel,
            color: JiveTheme.primaryGreen,
            isActive: selectedTags.isNotEmpty,
            onTap: onTapTags,
          ),
          // 报销 pill
          if (onTapReimbursement != null)
            _Pill(
              icon: Icons.receipt_outlined,
              label: reimbursementStatus == 'pending' ? '报销·待处理' : '报销',
              color: Colors.orange,
              isActive: reimbursementStatus != null,
              onTap: onTapReimbursement!,
            ),
          _Pill(
            icon: Icons.folder_outlined,
            label: projectLabel,
            color: Colors.purple,
            isActive: selectedProject != null,
            onTap: onTapProject,
          ),
          // 优惠 pill
          _Pill(
            icon: Icons.local_offer_outlined,
            label: discountAmount != null && discountAmount! > 0
                ? '优惠 -${discountAmount!.toStringAsFixed(discountAmount! % 1 == 0 ? 0 : 2)}'
                : '优惠',
            color: Colors.pink,
            isActive: discountAmount != null && discountAmount! > 0,
            onTap: onTapDiscount,
          ),
          // 手续费 pill
          _Pill(
            icon: Icons.receipt_long_outlined,
            label: feeAmount != null && feeAmount! > 0
                ? '手续费 +${feeAmount!.toStringAsFixed(feeAmount! % 1 == 0 ? 0 : 2)}'
                : '手续费',
            color: Colors.amber.shade700,
            isActive: feeAmount != null && feeAmount! > 0,
            onTap: onTapFee,
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
              label: photoCount > 0 ? '图片·$photoCount' : '图片',
              color: Colors.blue,
              isActive: photoCount > 0,
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
  final String? emojiPrefix;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.emojiPrefix,
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
              if (emojiPrefix != null) ...[
                Text(emojiPrefix!, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
              ] else ...[
                Icon(icon, size: 14, color: fgColor),
              ],
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
