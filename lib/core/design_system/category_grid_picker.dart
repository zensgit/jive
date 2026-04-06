import 'package:flutter/material.dart';

import '../database/category_model.dart';
import '../service/category_service.dart';
import 'theme.dart';

/// Alternative category picker that shows categories in a 3-column grid layout.
///
/// Top: horizontally scrollable parent category tabs.
/// Body: subcategories as grid items under the selected parent.
/// Each item shows a circular icon background + category name below.
/// Selected item is highlighted with a green border.
class CategoryGridPicker extends StatefulWidget {
  final List<JiveCategory> categories;
  final void Function(String categoryKey, String? subCategoryKey) onCategorySelected;

  /// Currently selected category key (for highlighting).
  final String? selectedCategoryKey;

  /// Currently selected subcategory key (for highlighting).
  final String? selectedSubCategoryKey;

  /// Whether to start in grid mode (true) or list mode (false).
  final bool initialGridMode;

  const CategoryGridPicker({
    super.key,
    required this.categories,
    required this.onCategorySelected,
    this.selectedCategoryKey,
    this.selectedSubCategoryKey,
    this.initialGridMode = true,
  });

  @override
  State<CategoryGridPicker> createState() => _CategoryGridPickerState();
}

class _CategoryGridPickerState extends State<CategoryGridPicker> {
  late bool _isGridMode;
  String? _selectedParentKey;

  List<JiveCategory> get _parents =>
      widget.categories.where((c) => c.parentKey == null && !c.isHidden).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<JiveCategory> _childrenOf(String parentKey) =>
      widget.categories.where((c) => c.parentKey == parentKey && !c.isHidden).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  void initState() {
    super.initState();
    _isGridMode = widget.initialGridMode;
    // Default to first parent, or the currently selected one.
    final parents = _parents;
    if (widget.selectedCategoryKey != null) {
      final match = parents.where((p) => p.key == widget.selectedCategoryKey);
      if (match.isNotEmpty) {
        _selectedParentKey = match.first.key;
      } else {
        // The selected category might be a child; find its parent.
        final selectedCat = widget.categories
            .where((c) => c.key == widget.selectedCategoryKey)
            .firstOrNull;
        if (selectedCat?.parentKey != null) {
          _selectedParentKey = selectedCat!.parentKey;
        }
      }
    }
    _selectedParentKey ??= parents.firstOrNull?.key;
  }

  bool _isSelected(JiveCategory category) {
    if (category.parentKey == null) {
      return category.key == widget.selectedCategoryKey &&
          widget.selectedSubCategoryKey == null;
    }
    return category.key == widget.selectedSubCategoryKey;
  }

  @override
  Widget build(BuildContext context) {
    final parents = _parents;
    if (parents.isEmpty) {
      return const Center(child: Text('暂无分类'));
    }

    return Column(
      children: [
        _buildHeader(parents),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader(List<JiveCategory> parents) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: parents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final parent = parents[i];
                final isActive = parent.key == _selectedParentKey;
                return ChoiceChip(
                  label: Text(parent.name),
                  selected: isActive,
                  onSelected: (_) {
                    setState(() => _selectedParentKey = parent.key);
                  },
                  selectedColor: JiveTheme.primaryGreen.withAlpha(30),
                  labelStyle: TextStyle(
                    color: isActive ? JiveTheme.primaryGreen : null,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: isActive
                      ? const BorderSide(color: JiveTheme.primaryGreen)
                      : BorderSide.none,
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
        // Grid / List toggle
        IconButton(
          icon: Icon(
            _isGridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
            size: 20,
          ),
          tooltip: _isGridMode ? '列表视图' : '网格视图',
          onPressed: () => setState(() => _isGridMode = !_isGridMode),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedParentKey == null) return const SizedBox.shrink();

    final selectedParent =
        _parents.where((p) => p.key == _selectedParentKey).firstOrNull;
    if (selectedParent == null) return const SizedBox.shrink();

    final children = _childrenOf(_selectedParentKey!);

    // Include parent as first selectable item
    final items = <JiveCategory>[selectedParent, ...children];

    if (_isGridMode) {
      return _buildGrid(items);
    }
    return _buildList(items);
  }

  Widget _buildGrid(List<JiveCategory> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildGridItem(items[i]),
    );
  }

  Widget _buildGridItem(JiveCategory category) {
    final selected = _isSelected(category);
    final color = CategoryService.parseColorHex(category.colorHex) ??
        JiveTheme.categoryIconInactive;
    final isParent = category.parentKey == null;

    return GestureDetector(
      onTap: () {
        if (isParent) {
          widget.onCategorySelected(category.key, null);
        } else {
          widget.onCategorySelected(category.parentKey!, category.key);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: JiveTheme.primaryGreen, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          color: selected
              ? JiveTheme.primaryGreen.withAlpha(15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(30),
              ),
              child: Center(
                child: CategoryService.buildIcon(
                  category.iconName,
                  size: 24,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isParent ? '全部${category.name}' : category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? JiveTheme.primaryGreen : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<JiveCategory> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final category = items[i];
        final selected = _isSelected(category);
        final color = CategoryService.parseColorHex(category.colorHex) ??
            JiveTheme.categoryIconInactive;
        final isParent = category.parentKey == null;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: CategoryService.buildIcon(
              category.iconName,
              size: 20,
              color: color,
            ),
          ),
          title: Text(
            isParent ? '全部${category.name}' : category.name,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? JiveTheme.primaryGreen : null,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle, color: JiveTheme.primaryGreen)
              : null,
          onTap: () {
            if (isParent) {
              widget.onCategorySelected(category.key, null);
            } else {
              widget.onCategorySelected(category.parentKey!, category.key);
            }
          },
        );
      },
    );
  }
}
