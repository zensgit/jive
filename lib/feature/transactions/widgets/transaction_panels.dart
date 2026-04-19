import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/budget_model.dart';
import '../../../core/database/currency_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/budget_service.dart';
import '../../../core/service/category_service.dart';

/// A single row in the budget-impact warning shown above the save action when
/// a transaction is about to push a budget into warning or exceeded state.
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class BudgetImpactRow extends StatelessWidget {
  final BudgetTransactionImpact impact;

  const BudgetImpactRow({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    final budget = impact.budget;
    final symbol = CurrencyDefaults.getSymbol(budget.currency);
    final isExceeded = impact.projectedStatus == BudgetStatus.exceeded;
    final color = isExceeded ? Colors.red.shade700 : Colors.orange.shade700;
    final icon = isExceeded ? Icons.warning_amber_rounded : Icons.info_outline;
    final message = isExceeded
        ? '将超支 $symbol ${(impact.projectedUsedAmount - impact.effectiveAmount).abs().toStringAsFixed(0)}'
        : '将达到预警 ${budget.alertThreshold?.toStringAsFixed(0) ?? '--'}%（${impact.projectedUsedPercent.toStringAsFixed(1)}%）';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: color.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary line for a credit-card account showing 额度 / 已用 / 可用.
/// Renders nothing when the account has no credit limit.
class CreditAccountSummary extends StatelessWidget {
  final JiveAccount account;
  final double balance;
  final bool isLandscape;

  const CreditAccountSummary({
    super.key,
    required this.account,
    required this.balance,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final limit = account.creditLimit ?? 0;
    if (limit <= 0) return const SizedBox.shrink();
    final used = balance < 0 ? -balance : 0.0;
    final available = (limit - used).clamp(0, double.infinity).toDouble();
    final fontSize = isLandscape ? 10.0 : 11.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isLandscape ? 10 : 12,
      runSpacing: 4,
      children: [
        _CreditMetaText(label: '额度', value: limit, color: Colors.blueGrey, fontSize: fontSize),
        _CreditMetaText(label: '已用', value: used, color: Colors.redAccent, fontSize: fontSize),
        _CreditMetaText(label: '可用', value: available, color: JiveTheme.primaryGreen, fontSize: fontSize),
      ],
    );
  }
}

class _CreditMetaText extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double fontSize;

  const _CreditMetaText({
    required this.label,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final rounded = value.roundToDouble();
    final formatted =
        value == rounded ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return Text(
      '$label ¥$formatted',
      style: GoogleFonts.lato(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Suggestion entry shown in [SystemSuggestionPanel]. Pre-computed by the
/// caller from the system category library.
class SystemSuggestion {
  final String parentName;
  final String name;
  final String parentIconName;
  final String iconName;
  final bool isSub;

  const SystemSuggestion._({
    required this.parentName,
    required this.name,
    required this.parentIconName,
    required this.iconName,
    required this.isSub,
  });

  factory SystemSuggestion.parent(String name, String iconName) {
    return SystemSuggestion._(
      parentName: name,
      name: name,
      parentIconName: iconName,
      iconName: iconName,
      isSub: false,
    );
  }

  factory SystemSuggestion.child(
    String parentName,
    String name,
    String iconName,
    String parentIconName,
  ) {
    return SystemSuggestion._(
      parentName: parentName,
      name: name,
      parentIconName: parentIconName,
      iconName: iconName,
      isSub: true,
    );
  }
}

/// Panel shown in the inline category search when no local categories match
/// the query but there are matches in the system library. Tapping a row
/// invokes [onApply] so the caller can persist the selection.
class SystemSuggestionPanel extends StatelessWidget {
  final List<SystemSuggestion> suggestions;
  final ValueChanged<SystemSuggestion> onApply;

  const SystemSuggestionPanel({
    super.key,
    required this.suggestions,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const Center(child: Text('未找到匹配分类'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: suggestions.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '系统库建议',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  '点击添加并选中',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }
        final suggestion = suggestions[index - 1];
        final title =
            suggestion.isSub ? suggestion.name : suggestion.parentName;
        final subtitle = suggestion.isSub ? suggestion.parentName : '一级分类';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: CategoryService.buildIcon(
              suggestion.iconName,
              size: 18,
              color: JiveTheme.categoryIconInactive,
              isSystemCategory: true,
            ),
          ),
          title: Text(title, style: TextStyle(color: Colors.grey.shade700)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: JiveTheme.categoryLabelInactive,
            ),
          ),
          trailing: const Icon(Icons.add, color: Colors.grey),
          onTap: () => onApply(suggestion),
        );
      },
    );
  }
}
