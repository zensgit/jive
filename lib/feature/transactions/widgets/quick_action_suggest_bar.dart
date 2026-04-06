import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/model/quick_action.dart';

/// A horizontal bar of suggested quick actions relevant to the current
/// transaction editor state.
///
/// Shows a scrollable list of quick-action chips and a trailing
/// "保存为快速动作" button. Only renders when there are relevant suggestions.
class QuickActionSuggestBar extends StatelessWidget {
  /// The currently selected category key, used to filter suggestions.
  final String? currentCategoryKey;

  /// The list of quick actions to suggest.
  final List<QuickAction> suggestions;

  /// Called when the user taps a suggested quick action.
  final ValueChanged<QuickAction>? onActionSelected;

  /// Called when the user taps "保存为快速动作".
  final VoidCallback? onSaveAsAction;

  const QuickActionSuggestBar({
    super.key,
    this.currentCategoryKey,
    this.suggestions = const [],
    this.onActionSelected,
    this.onSaveAsAction,
  });

  @override
  Widget build(BuildContext context) {
    // Don't render if there are no suggestions and no save option.
    if (suggestions.isEmpty && onSaveAsAction == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Suggestion chips
          for (final action in suggestions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SuggestionChip(
                action: action,
                isDark: isDark,
                onTap: () => onActionSelected?.call(action),
              ),
            ),

          // "Save as quick action" button
          if (onSaveAsAction != null)
            _SaveAsActionButton(
              isDark: isDark,
              onTap: onSaveAsAction!,
            ),
        ],
      ),
    );
  }
}

/// A single quick-action suggestion chip.
class _SuggestionChip extends StatelessWidget {
  final QuickAction action;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.action,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = action.colorHex != null
        ? Color(int.parse(action.colorHex!.replaceFirst('#', '0xFF')))
        : JiveTheme.primaryGreen;

    return ActionChip(
      label: Text(
        action.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
      avatar: Icon(Icons.flash_on, size: 14, color: chipColor),
      backgroundColor: chipColor.withValues(alpha: isDark ? 0.2 : 0.08),
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

/// The trailing "保存为快速动作" button.
class _SaveAsActionButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SaveAsActionButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text(
        '保存为快速动作',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: const Icon(Icons.add, size: 14),
      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
      side: BorderSide(
        color: isDark ? Colors.white24 : Colors.grey.shade300,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
