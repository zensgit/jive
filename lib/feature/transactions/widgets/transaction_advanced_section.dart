import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';

/// A collapsible section for advanced transaction fields.
///
/// When collapsed, shows "高级选项" with a count badge of filled fields.
/// When expanded, shows rows for tags, project, budget exclusion,
/// and attachment.
///
/// Uses [AnimatedCrossFade] for a smooth expand/collapse transition.
class TransactionAdvancedSection extends StatelessWidget {
  /// Whether the advanced section is currently expanded.
  final bool isExpanded;

  /// Called when the header is tapped to toggle expansion.
  final VoidCallback? onToggle;

  /// Display names of selected tags (empty list = no tags).
  final List<String> tagNames;

  /// Display name of the selected project, or null if none.
  final String? projectName;

  /// Whether this transaction is excluded from budget calculations.
  final bool isExcludedFromBudget;

  /// Whether an attachment is present.
  final bool hasAttachment;

  /// Whether the tags row should be visually called out as missing.
  final bool highlightTags;

  /// Called when the tags row is tapped.
  final VoidCallback? onTagsTap;

  /// Called when the project row is tapped.
  final VoidCallback? onProjectTap;

  /// Called when the budget-exclusion toggle is changed.
  final ValueChanged<bool>? onBudgetExclusionChanged;

  /// Called when the attachment row is tapped.
  final VoidCallback? onAttachmentTap;

  const TransactionAdvancedSection({
    super.key,
    required this.isExpanded,
    this.onToggle,
    this.tagNames = const [],
    this.projectName,
    this.isExcludedFromBudget = false,
    this.hasAttachment = false,
    this.highlightTags = false,
    this.onTagsTap,
    this.onProjectTap,
    this.onBudgetExclusionChanged,
    this.onAttachmentTap,
  });

  /// Counts how many advanced fields have been filled.
  int get _filledCount {
    int count = 0;
    if (tagNames.isNotEmpty) count++;
    if (projectName != null) count++;
    if (isExcludedFromBudget) count++;
    if (hasAttachment) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? JiveTheme.darkCard : JiveTheme.cardWhite;
    final dividerColor = isDark ? JiveTheme.darkDivider : Colors.grey.shade200;
    final filledCount = _filledCount;

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
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    '高级选项',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (filledCount > 0 && !isExpanded) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$filledCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _divider(dividerColor),
                _AdvancedRow(
                  icon: Icons.label_outline,
                  label: '标签',
                  value: tagNames.isNotEmpty ? tagNames.join(', ') : '添加标签',
                  valueColor: tagNames.isNotEmpty ? null : Colors.grey,
                  highlighted: highlightTags,
                  onTap: onTagsTap,
                ),
                _divider(dividerColor),
                _AdvancedRow(
                  icon: Icons.folder_outlined,
                  label: '项目',
                  value: projectName ?? '关联项目',
                  valueColor: projectName != null ? null : Colors.grey,
                  onTap: onProjectTap,
                ),
                _divider(dividerColor),
                _BudgetExclusionRow(
                  isExcluded: isExcludedFromBudget,
                  onChanged: onBudgetExclusionChanged,
                ),
                _divider(dividerColor),
                _AdvancedRow(
                  icon: Icons.attach_file_outlined,
                  label: '附件',
                  value: hasAttachment ? '已添加' : '添加附件',
                  valueColor: hasAttachment ? null : Colors.grey,
                  onTap: onAttachmentTap,
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 0.5, color: color),
    );
  }
}

/// A single row inside the advanced section.
class _AdvancedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlighted;
  final VoidCallback? onTap;

  const _AdvancedRow({
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

/// Row for the budget-exclusion toggle.
class _BudgetExclusionRow extends StatelessWidget {
  final bool isExcluded;
  final ValueChanged<bool>? onChanged;

  const _BudgetExclusionRow({required this.isExcluded, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isExcluded ? Colors.orange.shade700 : Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.pie_chart_outline, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            '不计入预算',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: isExcluded,
              onChanged: onChanged,
              activeTrackColor: Colors.orange.withValues(alpha: 0.4),
              activeThumbColor: Colors.orange.shade700,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
