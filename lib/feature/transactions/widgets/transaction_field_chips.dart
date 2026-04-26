import 'package:flutter/material.dart';

import '../../../core/database/category_model.dart';
import '../../../core/database/project_model.dart';
import '../../../core/design_system/theme.dart';
import '../../../core/service/category_icon_style.dart';
import '../../../core/service/category_service.dart';
import '../../tag/tag_icon_catalog.dart';

/// Subcategory grid shown below the parent category tabs in the transaction
/// editor. Tapping a sub-category selects it; long-press triggers actions.
/// The trailing "+ 自定义" tile lets the user add a new sub-category.
///
/// Extracted from `add_transaction_screen.dart` to reduce monolith size.
class SubCategoryGrid extends StatelessWidget {
  final List<JiveCategory> subCategories;
  final JiveCategory? selectedSub;
  final Key Function(JiveCategory category)? categoryKeyBuilder;
  final String Function(JiveCategory category)? labelBuilder;
  final String? Function(JiveCategory category)? subtitleBuilder;
  final double aspectRatio;
  final double mainAxisSpacing;
  final ValueChanged<JiveCategory> onSelect;
  final ValueChanged<JiveCategory> onLongPress;
  final VoidCallback onAddCustom;

  const SubCategoryGrid({
    super.key,
    required this.subCategories,
    required this.selectedSub,
    this.categoryKeyBuilder,
    this.labelBuilder,
    this.subtitleBuilder,
    required this.aspectRatio,
    required this.mainAxisSpacing,
    required this.onSelect,
    required this.onLongPress,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: aspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: 8,
      ),
      itemCount: subCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == subCategories.length) {
          return GestureDetector(
            onTap: onAddCustom,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey, size: 20),
                ),
                const SizedBox(height: 3),
                const Text(
                  '自定义',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final cat = subCategories[index];
        final isSelected = cat.key == selectedSub?.key;
        final label = labelBuilder?.call(cat) ?? cat.name;
        final subtitle = subtitleBuilder?.call(cat);
        final customColor = CategoryService.parseColorHex(cat.colorHex);
        final activeColor = customColor ?? JiveTheme.primaryGreen;
        final inactiveColor = JiveTheme.categoryIconInactive;
        final isCategoryAssetIcon =
            (cat.iconName.endsWith('.png') || cat.iconName.endsWith('.svg')) &&
            (!cat.iconName.startsWith('assets/') ||
                cat.iconName.startsWith('assets/category_icons/'));
        final shouldTintIcon = isCategoryAssetIcon
            ? (cat.iconForceTinted ||
                  CategoryIconStyleConfig.current.shouldTintForCategory(
                    isSystemCategory: cat.isSystem,
                  ))
            : true;
        final coloredIcons = !shouldTintIcon;

        return GestureDetector(
          key: categoryKeyBuilder?.call(cat),
          onTap: () => onSelect(cat),
          onLongPress: () => onLongPress(cat),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (coloredIcons
                            ? activeColor.withValues(alpha: 0.14)
                            : activeColor)
                      : (coloredIcons
                            ? Colors.white
                            : JiveTheme.categoryIconInactiveBackground),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : JiveTheme.categoryIconInactiveBorder,
                  ),
                ),
                child: CategoryService.buildIcon(
                  cat.iconName,
                  size: 18,
                  color: coloredIcons
                      ? (isSelected ? null : inactiveColor)
                      : (isSelected ? Colors.white : inactiveColor),
                  isSystemCategory: cat.isSystem,
                  forceTinted: cat.iconForceTinted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.black87
                      : JiveTheme.categoryLabelInactive,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 7,
                    color: isSelected
                        ? Colors.black54
                        : JiveTheme.categoryLabelInactive,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Filter chip that toggles "exclude from budget" for an expense transaction.
class BudgetExclusionChip extends StatelessWidget {
  final bool excludeFromBudget;
  final bool isLandscape;
  final ValueChanged<bool> onChanged;

  const BudgetExclusionChip({
    super.key,
    required this.excludeFromBudget,
    required this.isLandscape,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = isLandscape ? 10.0 : 12.0;
    final color = excludeFromBudget
        ? Colors.orange.shade700
        : Colors.grey.shade700;
    return Align(
      alignment: Alignment.center,
      child: FilterChip(
        label: Text(
          '不计入预算',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        avatar: Icon(Icons.pie_chart_outline, size: 14, color: color),
        selected: excludeFromBudget,
        onSelected: onChanged,
        showCheckmark: true,
        selectedColor: Colors.orange.withValues(alpha: 0.12),
        checkmarkColor: Colors.orange.shade700,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }
}

/// Project association chip — shows the selected project as an InputChip with
/// a clear button, or an "添加项目" action chip if none is selected.
class ProjectSelectorChip extends StatelessWidget {
  final JiveProject? selectedProject;
  final bool isLandscape;
  final VoidCallback onPickProject;
  final VoidCallback onClearProject;

  const ProjectSelectorChip({
    super.key,
    required this.selectedProject,
    required this.isLandscape,
    required this.onPickProject,
    required this.onClearProject,
  });

  @override
  Widget build(BuildContext context) {
    final textSize = isLandscape ? 10.0 : 12.0;

    if (selectedProject != null) {
      final color = selectedProject!.colorHex != null
          ? Color(
              int.parse(selectedProject!.colorHex!.replaceFirst('#', '0xFF')),
            )
          : JiveTheme.primaryGreen;
      return Align(
        alignment: Alignment.center,
        child: InputChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidgetForName(
                selectedProject!.iconName,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                selectedProject!.name,
                style: TextStyle(
                  fontSize: textSize,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: color.withValues(alpha: 0.12),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          onDeleted: onClearProject,
          onPressed: onPickProject,
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: ActionChip(
        label: Text('关联项目', style: TextStyle(fontSize: textSize)),
        avatar: const Icon(
          Icons.folder_outlined,
          size: 14,
          color: Colors.black54,
        ),
        onPressed: onPickProject,
      ),
    );
  }
}
