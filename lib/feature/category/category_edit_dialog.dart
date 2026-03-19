import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/category_icon_style.dart';
import '../../core/service/category_service.dart';
import '../../core/service/transaction_service.dart';
import '../../core/design_system/theme.dart';
import '../stats/stats_screen.dart';
import 'category_icon_source_picker.dart';
import 'category_transactions_screen.dart';

class CategoryEditDialog extends StatefulWidget {
  final JiveCategory category;
  final Isar isar;

  const CategoryEditDialog({
    super.key,
    required this.category,
    required this.isar,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  static const String _noParentKey = "__no_parent__";
  late TextEditingController _nameController;
  late String _selectedIcon;
  String? _selectedColorHex;
  String? _selectedParentKey;
  late bool _isHidden;
  late bool _iconForceTinted;
  late bool _excludeFromBudget;
  bool _isSaving = false;
  List<JiveCategory> _parents = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.iconName;
    _selectedColorHex = widget.category.colorHex;
    _selectedParentKey = widget.category.parentKey;
    _isHidden = widget.category.isHidden;
    _iconForceTinted = widget.category.iconForceTinted;
    _excludeFromBudget = widget.category.excludeFromBudget;
    _loadParents();
  }

  Future<void> _loadParents() async {
    final parents = await CategoryService(widget.isar).getAllParents();
    parents.removeWhere(
      (p) =>
          p.id == widget.category.id || p.isIncome != widget.category.isIncome,
    );
    parents.sort((a, b) => a.order.compareTo(b.order));
    if (mounted) setState(() => _parents = parents);
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final isSubCategory = _selectedParentKey != null;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "编辑分类",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text("保存"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _showIconPicker,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: highlightColor.withValues(alpha: 0.12),
                        child: CategoryService.buildIcon(
                          _selectedIcon,
                          size: 28,
                          color: highlightColor,
                          isSystemCategory: widget.category.isSystem,
                          forceTinted: _iconForceTinted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "分类名称",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildColorPicker(),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _iconForceTinted,
                  title: const Text("图标强制单色"),
                  subtitle: const Text("即使在彩色模式下也显示为单色（跟随分类颜色）"),
                  onChanged: (value) =>
                      setState(() => _iconForceTinted = value),
                ),
                if (!widget.category.isIncome) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _excludeFromBudget,
                    title: const Text("不计入预算"),
                    subtitle: Text(
                      isSubCategory
                          ? "该二级分类相关支出将不计入总预算"
                          : "该一级分类及其子类相关支出将不计入总预算",
                    ),
                    onChanged: (value) =>
                        setState(() => _excludeFromBudget = value),
                  ),
                ],
                _buildForceTintedPreview(),
                const SizedBox(height: 12),
                _buildParentSelector(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(_buildActionList()),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildParentSelector() {
    final selectedParent = _parents.firstWhere(
      (p) => p.key == _selectedParentKey,
      orElse: () => _parents.isNotEmpty ? _parents.first : widget.category,
    );
    final hasParent = _selectedParentKey != null;
    final label = hasParent ? selectedParent.name : "无 (作为一级分类)";
    final iconName = hasParent ? selectedParent.iconName : "category";
    final iconColor = hasParent
        ? (CategoryService.parseColorHex(selectedParent.colorHex) ??
              Colors.grey.shade600)
        : Colors.grey.shade500;
    final iconIsSystem = hasParent ? selectedParent.isSystem : null;
    final iconForceTinted = hasParent ? selectedParent.iconForceTinted : false;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showParentPicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "所属父级 (层级)",
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Row(
          children: [
            CategoryService.buildIcon(
              iconName,
              size: 16,
              color: iconColor,
              isSystemCategory: iconIsSystem,
              forceTinted: iconForceTinted,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Future<void> _showParentPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        var tempKey = _selectedParentKey ?? _noParentKey;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "分类选择",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: GridView.builder(
                        itemCount: _parents.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = tempKey == _noParentKey;
                            return _buildParentPickerTile(
                              iconName: "category",
                              label: "无",
                              isSelected: isSelected,
                              onTap: () =>
                                  setStateDialog(() => tempKey = _noParentKey),
                            );
                          }
                          final parent = _parents[index - 1];
                          final isSelected = tempKey == parent.key;
                          return _buildParentPickerTile(
                            iconName: parent.iconName,
                            label: parent.name,
                            iconColor:
                                CategoryService.parseColorHex(
                                  parent.colorHex,
                                ) ??
                                Colors.grey.shade600,
                            isSelected: isSelected,
                            onTap: () =>
                                setStateDialog(() => tempKey = parent.key),
                            isSystemCategory: parent.isSystem,
                            forceTinted: parent.iconForceTinted,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("取消"),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, tempKey),
                            child: const Text("确定"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    setState(() => _selectedParentKey = result == _noParentKey ? null : result);
  }

  Widget _buildParentPickerTile({
    required String iconName,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
    bool? isSystemCategory,
    bool forceTinted = false,
  }) {
    final color = iconColor ?? Colors.grey.shade600;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? JiveTheme.primaryGreen.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? JiveTheme.primaryGreen : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryService.buildIcon(
              iconName,
              size: 20,
              color: isSelected ? JiveTheme.primaryGreen : color,
              isSystemCategory: isSystemCategory,
              forceTinted: forceTinted,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? JiveTheme.primaryGreen
                    : Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList() {
    final isSubCategory = widget.category.parentKey != null;
    final canDelete = !widget.category.isSystem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("分类操作", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        _buildActionTile(
          icon: Icons.pie_chart,
          label: "查看统计数据",
          onTap: _openStats,
        ),
        _buildActionTile(
          icon: Icons.receipt_long,
          label: "查看账单",
          onTap: _openTransactions,
        ),
        _buildActionTile(
          icon: Icons.swap_horiz,
          label: "将账单转移至其它分类",
          onTap: _transferTransactions,
        ),
        if (isSubCategory)
          _buildActionTile(
            icon: Icons.arrow_upward,
            label: "改为一级分类",
            onTap: _promoteToParent,
          ),
        _buildActionTile(
          icon: _isHidden ? Icons.visibility : Icons.visibility_off,
          label: _isHidden ? "显示分类" : "隐藏分类",
          onTap: _toggleHidden,
        ),
        if (canDelete)
          _buildActionTile(
            icon: Icons.delete_outline,
            label: "删除分类",
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _confirmDelete,
          ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: textColor ?? Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showIconPicker() async {
    final selected = await pickCategoryIcon(
      context,
      initialIcon: _selectedIcon,
      forSystemCategory: widget.category.isSystem,
      forceTinted: _iconForceTinted,
    );
    if (selected != null) {
      setState(() => _selectedIcon = selected);
    }
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    await CategoryService(widget.isar).updateCategory(
      widget.category.id,
      newName,
      _selectedIcon,
      _selectedParentKey,
      _selectedColorHex,
      iconForceTinted: _iconForceTinted,
      excludeFromBudget: _excludeFromBudget,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _openStats() async {
    final isSub = widget.category.parentKey != null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(
          filterCategoryKey: isSub ? null : widget.category.key,
          filterSubCategoryKey: isSub ? widget.category.key : null,
        ),
      ),
    );
  }

  Future<void> _openTransactions() async {
    final isSub = widget.category.parentKey != null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          title: "账单 · ${widget.category.name}",
          filterCategoryKey: isSub ? null : widget.category.key,
          filterSubCategoryKey: isSub ? widget.category.key : null,
          includeSubCategories: false,
        ),
      ),
    );
  }

  Future<void> _transferTransactions() async {
    final target = await _pickTransferTarget();
    if (target == null) return;

    final targetName = target.child == null
        ? target.parent.name
        : "${target.parent.name} · ${target.child!.name}";
    final sourceName = widget.category.name;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认转移账单"),
        content: Text("将 $sourceName 的账单转移到 $targetName？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("转移"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final moved = await _applyTransactionTransfer(target);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(moved == 0 ? "没有可转移的账单" : "已转移 $moved 笔账单")),
    );
  }

  Future<int> _applyTransactionTransfer(_TransferTarget target) async {
    final isSub = widget.category.parentKey != null;
    final base = widget.isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(widget.category.key)
        : base.categoryKeyEqualTo(widget.category.key);
    final txs = await filtered.findAll();
    if (txs.isEmpty) return 0;

    for (final tx in txs) {
      tx.categoryKey = target.parent.key;
      tx.category = target.parent.name;
      if (target.child != null) {
        tx.subCategoryKey = target.child!.key;
        tx.subCategory = target.child!.name;
      } else {
        tx.subCategoryKey = null;
        tx.subCategory = "";
      }
    }

    TransactionService.touchSyncMetadataForAll(txs);
    await widget.isar.writeTxn(() async {
      await widget.isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  Future<_TransferTarget?> _pickTransferTarget() async {
    final all = await widget.isar.collection<JiveCategory>().where().findAll();
    final parents = all
        .where(
          (c) => c.parentKey == null && c.isIncome == widget.category.isIncome,
        )
        .toList();
    parents.sort((a, b) => a.order.compareTo(b.order));

    final Map<String, List<JiveCategory>> childrenByParent = {};
    for (final cat in all) {
      if (cat.parentKey == null || cat.isIncome != widget.category.isIncome) {
        continue;
      }
      childrenByParent.putIfAbsent(cat.parentKey!, () => []).add(cat);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }

    if (!mounted) return null;
    return showModalBottomSheet<_TransferTarget>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                "选择目标分类",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...parents.expand((parent) {
              final tiles = <Widget>[];
              final isCurrentParent =
                  widget.category.parentKey == null &&
                  parent.key == widget.category.key;
              if (!isCurrentParent) {
                tiles.add(
                  _buildTargetTile(parent: parent, child: null, indent: 0),
                );
              }
              final children = childrenByParent[parent.key] ?? [];
              for (final child in children) {
                if (child.key == widget.category.key) continue;
                tiles.add(
                  _buildTargetTile(parent: parent, child: child, indent: 24),
                );
              }
              tiles.add(const Divider(height: 16));
              return tiles;
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTile({
    required JiveCategory parent,
    required JiveCategory? child,
    required double indent,
  }) {
    final title = child == null ? parent.name : child.name;
    final subtitle = child == null ? "仅一级" : parent.name;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 12 + indent, right: 12),
      leading: CategoryService.buildIcon(
        child?.iconName ?? parent.iconName,
        size: 18,
        color: Colors.grey.shade700,
        isSystemCategory: child?.isSystem ?? parent.isSystem,
        forceTinted: child?.iconForceTinted ?? parent.iconForceTinted,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: child == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
      onTap: () =>
          Navigator.pop(context, _TransferTarget(parent: parent, child: child)),
    );
  }

  Future<void> _promoteToParent() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    await CategoryService(widget.isar).updateCategory(
      widget.category.id,
      newName,
      _selectedIcon,
      null,
      _selectedColorHex,
      iconForceTinted: _iconForceTinted,
      excludeFromBudget: _excludeFromBudget,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleHidden() async {
    await CategoryService(
      widget.isar,
    ).setCategoryHidden(widget.category.id, !_isHidden);
    if (!mounted) return;
    setState(() => _isHidden = !_isHidden);
  }

  Future<int> _countTransactionsForCategory() async {
    final isSub = widget.category.parentKey != null;
    final base = widget.isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(widget.category.key)
        : base.categoryKeyEqualTo(widget.category.key);
    return filtered.count();
  }

  Future<int> _uncategorizeTransactions() async {
    final isSub = widget.category.parentKey != null;
    final base = widget.isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(widget.category.key)
        : base.categoryKeyEqualTo(widget.category.key);
    final txs = await filtered.findAll();
    if (txs.isEmpty) return 0;
    for (final tx in txs) {
      tx.categoryKey = null;
      tx.subCategoryKey = null;
      tx.category = "未分类";
      tx.subCategory = "";
    }
    TransactionService.touchSyncMetadataForAll(txs);
    await widget.isar.writeTxn(() async {
      await widget.isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  Future<_DeleteHandling?> _askDeleteHandling(int txCount) async {
    return showDialog<_DeleteHandling>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("该分类有账单"),
        content: Text("检测到 $txCount 笔账单，请选择处理方式。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _DeleteHandling.uncategorize),
            child: const Text("设为未分类"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DeleteHandling.transfer),
            child: const Text("转移到其它分类"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final txCount = await _countTransactionsForCategory();
    if (txCount > 0) {
      final handling = await _askDeleteHandling(txCount);
      if (handling == null) return;
      if (handling == _DeleteHandling.transfer) {
        final target = await _pickTransferTarget();
        if (target == null) return;
        await _applyTransactionTransfer(target);
      } else if (handling == _DeleteHandling.uncategorize) {
        await _uncategorizeTransactions();
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("删除分类？"),
        content: const Text("删除后分类将无法恢复，相关账单会保留原名称。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("删除"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await CategoryService(
      widget.isar,
    ).deleteCategory(widget.category);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请先处理子类后再删除")));
      return;
    }
    Navigator.pop(context, true);
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        const Text("颜色", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColorDot(null),
                const SizedBox(width: 8),
                ..._categoryColorOptions.map((color) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildColorDot(color),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForceTintedPreview() {
    final highlightColor = _resolveSelectedColor() ?? JiveTheme.primaryGreen;
    final globalStyleLabel = CategoryIconStyleConfig.current.label;
    return Semantics(
      container: true,
      label: "效果预览",
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "效果预览（当前全局：$globalStyleLabel）",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildForceTintedPreviewTile(
                    title: "跟随全局",
                    subtitle: "保持当前风格",
                    active: !_iconForceTinted,
                    forceTinted: false,
                    color: highlightColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildForceTintedPreviewTile(
                    title: "强制单色",
                    subtitle: "始终跟随分类色",
                    active: _iconForceTinted,
                    forceTinted: true,
                    color: highlightColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForceTintedPreviewTile({
    required String title,
    required String subtitle,
    required bool active,
    required bool forceTinted,
    required Color color,
  }) {
    final borderColor = active
        ? JiveTheme.primaryGreen.withValues(alpha: 0.45)
        : Colors.grey.shade300;
    final backgroundColor = active
        ? JiveTheme.primaryGreen.withValues(alpha: 0.08)
        : Colors.white;
    return Semantics(
      container: true,
      label: title,
      selected: active,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CategoryService.buildIcon(
                  _selectedIcon,
                  size: 14,
                  color: color,
                  isSystemCategory: widget.category.isSystem,
                  forceTinted: forceTinted,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? JiveTheme.primaryGreen
                          : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color? color) {
    final hex = color == null ? null : _colorHexFromColor(color);
    final isSelected = _selectedColorHex == hex;
    final borderColor = isSelected
        ? (color ?? Colors.grey.shade600)
        : Colors.grey.shade300;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedColorHex = hex),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: color == null
            ? Icon(Icons.close, size: 12, color: Colors.grey.shade500)
            : (isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null),
      ),
    );
  }

  Color? _resolveSelectedColor() {
    return CategoryService.parseColorHex(_selectedColorHex);
  }

  String _colorHexFromColor(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return "#${value.substring(2).toUpperCase()}";
  }
}

class _TransferTarget {
  final JiveCategory parent;
  final JiveCategory? child;

  const _TransferTarget({required this.parent, this.child});
}

enum _DeleteHandling { transfer, uncategorize }

const List<Color> _categoryColorOptions = [
  Color(0xFFF44336),
  Color(0xFFFF9800),
  Color(0xFFFFC107),
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFF795548),
  Color(0xFF607D8B),
];
