import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../category/category_edit_dialog.dart';
import '../category/category_picker_screen.dart';
import '../category/category_search_delegate.dart';

class BudgetExcludeScreen extends StatefulWidget {
  const BudgetExcludeScreen({super.key});

  @override
  State<BudgetExcludeScreen> createState() => _BudgetExcludeScreenState();
}

class _BudgetExcludeScreenState extends State<BudgetExcludeScreen> {
  Isar? _isar;
  bool _isLoading = true;
  String? _loadError;
  List<JiveCategory> _excluded = [];
  Map<String, JiveCategory> _categoryByKey = {};
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final isar = await _ensureIsar();
      final all = await isar.collection<JiveCategory>()
          .filter()
          .isIncomeEqualTo(false)
          .findAll();
      final byKey = {for (final cat in all) cat.key: cat};
      final excluded = all.where((cat) => cat.excludeFromBudget).toList();

      excluded.sort((a, b) {
        final parentA = a.parentKey == null ? a : byKey[a.parentKey!];
        final parentB = b.parentKey == null ? b : byKey[b.parentKey!];
        final orderA = parentA?.order ?? a.order;
        final orderB = parentB?.order ?? b.order;
        if (orderA != orderB) return orderA.compareTo(orderB);
        final parentNameA = parentA?.name ?? '';
        final parentNameB = parentB?.name ?? '';
        final parentNameCmp = parentNameA.compareTo(parentNameB);
        if (parentNameCmp != 0) return parentNameCmp;
        final depthA = a.parentKey == null ? 0 : 1;
        final depthB = b.parentKey == null ? 0 : 1;
        if (depthA != depthB) return depthA.compareTo(depthB);
        if (a.order != b.order) return a.order.compareTo(b.order);
        return a.name.compareTo(b.name);
      });

      if (!mounted) return;
      setState(() {
        _categoryByKey = byKey;
        _excluded = excluded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryByKey = {};
        _excluded = [];
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addExcludedCategory() async {
    final isar = await _ensureIsar();
    // Prefer user categories if they exist; otherwise show system categories.
    final hasUserExpense = await isar.collection<JiveCategory>()
            .filter()
            .isIncomeEqualTo(false)
            .and()
            .isSystemEqualTo(false)
            .findFirst() !=
        null;

    if (!mounted) return;
    final picked = await Navigator.push<CategorySearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(
          isIncome: false,
          onlyUserCategories: hasUserExpense,
          isar: isar,
          title: '选择要排除的分类',
        ),
      ),
    );
    if (picked == null) return;
    final target = picked.sub ?? picked.parent;
    await CategoryService(isar).setCategoryExcludeFromBudget(target.id, true);
    _hasChanged = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已排除：${picked.primaryName}')),
    );
    await _load();
  }

  Future<void> _removeExcludedCategory(JiveCategory category) async {
    final isar = await _ensureIsar();
    await CategoryService(isar).setCategoryExcludeFromBudget(category.id, false);
    _hasChanged = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已恢复计入预算：${_displayName(category)}')),
    );
    await _load();
  }

  String _displayName(JiveCategory category) {
    final parent = category.parentKey == null ? null : _categoryByKey[category.parentKey!];
    if (parent == null) return category.name;
    return '${parent.name} · ${category.name}';
  }

  Future<void> _openCategoryEdit(JiveCategory category) async {
    final isar = await _ensureIsar();
    if (!mounted) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditDialog(category: category, isar: isar),
      ),
    );
    if (updated == true) {
      _hasChanged = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          title: const Text('预算排除'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _addExcludedCategory,
              child: const Text('新增'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildErrorState()
            : _excluded.isEmpty
            ? _buildEmptyState()
            : _buildList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              '加载失败',
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '暂无排除分类',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加后，这些分类的支出将不计入总预算。\n也可在「编辑分类」中单独设置。',
              textAlign: TextAlign.center,
              style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addExcludedCategory,
              icon: const Icon(Icons.add),
              label: const Text('新增排除分类'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _excluded.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildIntroCard();
        }
        final category = _excluded[index - 1];
        final parent = category.parentKey == null ? null : _categoryByKey[category.parentKey!];
        final color = CategoryService.parseColorHex(category.colorHex) ?? JiveTheme.categoryIconInactive;
        final subtitle = parent == null ? '一级分类（含子类）' : parent.name;
        final badges = <Widget>[];
        if (category.isHidden) {
          badges.add(_buildBadge('已隐藏'));
        }
        if (category.isSystem) {
          badges.add(_buildBadge('系统'));
        }

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openCategoryEdit(category),
            onLongPress: () => _showItemActions(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: CategoryService.buildIcon(
                      category.iconName,
                      size: 18,
                      color: color,
                      isSystemCategory: category.isSystem,
                      forceTinted: category.iconForceTinted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                parent == null ? category.name : '${parent.name} · ${category.name}',
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badges.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...badges,
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: JiveTheme.secondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '取消排除',
                    onPressed: () => _removeExcludedCategory(category),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade700,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '这里设置的分类将不计入总预算统计；\n仍可在「编辑分类」中单独调整。',
              style: TextStyle(color: Colors.grey.shade700, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
      ),
    );
  }

  Future<void> _showItemActions(JiveCategory category) async {
    final action = await showModalBottomSheet<_ExcludeAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('编辑分类'),
                onTap: () => Navigator.pop(context, _ExcludeAction.edit),
              ),
              ListTile(
                title: const Text('取消不计入预算'),
                onTap: () => Navigator.pop(context, _ExcludeAction.remove),
              ),
            ],
          ),
        );
      },
    );
    if (action == null) return;
    if (action == _ExcludeAction.edit) {
      await _openCategoryEdit(category);
    } else if (action == _ExcludeAction.remove) {
      await _removeExcludedCategory(category);
    }
  }
}

enum _ExcludeAction { edit, remove }
