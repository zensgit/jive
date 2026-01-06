import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/category_service.dart';
import '../stats/stats_screen.dart';
import 'category_create_dialog.dart';
import 'category_create_screen.dart';
import 'category_edit_dialog.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  late Isar _isar;
  late CategoryService _service;
  bool _isLoading = true;
  bool _showIncome = false;
  bool _hasChanges = false;
  List<JiveCategory> _parents = [];
  Map<String, List<JiveCategory>> _childrenByParentKey = {};
  final Set<String> _collapsedParents = {};
  final NumberFormat _moneyFormat = NumberFormat.compactCurrency(symbol: "¥", decimalDigits: 0);
  Map<String, double> _parentTotals = {};
  Map<String, double> _subTotals = {};
  List<_RecommendationGroup> _recommendationGroups = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Map<String, String> _searchKeyCache = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (Isar.getInstance() != null) {
        _isar = Isar.getInstance()!;
      } else {
        _isar = await Isar.open(
          [JiveCategorySchema, JiveTransactionSchema, JiveAccountSchema],
          directory: dir.path,
        );
      }
      _service = CategoryService(_isar);
      await _service.initDefaultCategories();
      await _loadCategories();
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    final all = await _isar.collection<JiveCategory>().where().findAll();
    final parents = all
        .where((c) => c.parentKey == null && c.isIncome == _showIncome && !c.isHidden)
        .toList();
    final children = all
        .where((c) => c.parentKey != null && c.isIncome == _showIncome && !c.isHidden)
        .toList();

    parents.sort((a, b) => a.order.compareTo(b.order));

    final Map<String, List<JiveCategory>> byParent = {};
    for (final child in children) {
      final key = child.parentKey!;
      byParent.putIfAbsent(key, () => []).add(child);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final txs = await _isar.jiveTransactions
        .filter()
        .timestampBetween(monthStart, monthEnd, includeUpper: false)
        .findAll();

    final Map<String, double> parentTotals = {};
    final Map<String, double> subTotals = {};
    for (final tx in txs) {
      if (!_includeTxForTotals(tx)) continue;
      if (tx.amount <= 0) continue;
      final parentKey = tx.categoryKey;
      if (parentKey != null && parentKey.isNotEmpty) {
        parentTotals[parentKey] = (parentTotals[parentKey] ?? 0) + tx.amount;
      }
      final subKey = tx.subCategoryKey;
      if (subKey != null && subKey.isNotEmpty) {
        subTotals[subKey] = (subTotals[subKey] ?? 0) + tx.amount;
      }
    }

    final recommendations = _buildRecommendations(parents, byParent, parentTotals);

    if (mounted) {
      setState(() {
        _parents = parents;
        _childrenByParentKey = byParent;
        _parentTotals = parentTotals;
        _subTotals = subTotals;
        _recommendationGroups = recommendations;
        _searchKeyCache.clear();
      });
    }
  }

  bool _includeTxForTotals(JiveTransaction tx) {
    final type = tx.type ?? "expense";
    if (type == "transfer") return false;
    if (_showIncome) return type == "income";
    return type == "expense";
  }

  List<_RecommendationGroup> _buildRecommendations(
    List<JiveCategory> parents,
    Map<String, List<JiveCategory>> childrenByParent,
    Map<String, double> parentTotals,
  ) {
    if (_showIncome) return [];
    final lib = _service.getSystemLibrary(isIncome: _showIncome);
    if (lib.isEmpty) return [];

    final parentByName = {for (final p in parents) p.name: p};
    final groups = <_RecommendationGroup>[];
    for (final entry in lib.entries) {
      final parent = parentByName[entry.key];
      if (parent == null) continue;
      final existingNames = (childrenByParent[parent.key] ?? [])
          .map((c) => c.name)
          .toSet();
      final children = entry.value['children'] as List<dynamic>;
      final items = <_RecommendationItem>[];
      for (final child in children) {
        final name = child['name'] as String;
        if (existingNames.contains(name)) continue;
        items.add(_RecommendationItem(
          name: name,
          iconName: child['icon'] as String,
        ));
      }
      if (items.isNotEmpty) {
        groups.add(_RecommendationGroup(parent: parent, items: items));
      }
    }

    groups.sort((a, b) {
      final totalA = parentTotals[a.parent.key] ?? 0;
      final totalB = parentTotals[b.parent.key] ?? 0;
      return totalB.compareTo(totalA);
    });
    return groups;
  }

  Widget _buildRecommendationSection() {
    if (_recommendationGroups.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("智能推荐", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: JiveTheme.primaryGreen)),
          const SizedBox(height: 4),
          Text("根据当前分类缺口与消费偏好推荐补充子类", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          ..._recommendationGroups.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(group.parent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        "本月 ${_formatAmount(_parentTotals[group.parent.key] ?? 0)}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.items.map((item) {
                    return InkWell(
                      onTap: () async {
                        final created = await _service.createSubCategory(
                          parent: group.parent,
                          name: item.name,
                          iconName: item.iconName,
                          isSystem: true,
                        );
                        if (!mounted) return;
                        if (created == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("已存在: ${item.name}")),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("已添加: ${item.name}")),
                        );
                        await _reloadAndMarkChanged();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryService.buildIcon(item.iconName, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text(item.name, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "搜索分类",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
              ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _reloadAndMarkChanged() async {
    _hasChanges = true;
    await _loadCategories();
  }

  Future<void> _onReorderParents(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _parents.length || newIndex >= _parents.length) {
      return;
    }
    final updated = List<JiveCategory>.from(_parents);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    setState(() => _parents = updated);
    await _service.reorderParents(updated);
    _hasChanges = true;
  }

  Future<void> _reorderSubCategory(JiveCategory parent, JiveCategory from, JiveCategory to) async {
    final list = List<JiveCategory>.from(_childrenByParentKey[parent.key] ?? []);
    final oldIndex = list.indexWhere((c) => c.key == from.key);
    final newIndex = list.indexWhere((c) => c.key == to.key);
    if (oldIndex == -1 || newIndex == -1 || oldIndex == newIndex) return;

    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    setState(() => _childrenByParentKey[parent.key] = list);
    await _service.reorderChildren(parent.key, list);
    _hasChanges = true;
  }

  String _formatAmount(double value) {
    return _moneyFormat.format(value);
  }

  Color _resolveCategoryColor(JiveCategory category, {required Color fallback}) {
    return CategoryService.parseColorHex(category.colorHex) ?? fallback;
  }

  Color _resolveCategoryBackground(JiveCategory category) {
    final color = CategoryService.parseColorHex(category.colorHex);
    return color?.withOpacity(0.12) ?? Colors.grey.shade100;
  }

  Widget _buildSubStatsRow(JiveCategory parent, List<JiveCategory> children) {
    final entries = children
        .map((child) => MapEntry(child, _subTotals[child.key] ?? 0))
        .where((entry) => entry.value > 0)
        .toList();
    if (entries.isEmpty) {
      return Text("本月暂无子类支出", style: TextStyle(fontSize: 11, color: Colors.grey.shade500));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(3).toList();
    final total = _parentTotals[parent.key] ?? 0;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: top.map((entry) {
        final percent = total > 0 ? (entry.value / total * 100).round() : 0;
        return Text(
          "${entry.key.name} ${_formatAmount(entry.value)} ${percent}%",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        );
      }).toList(),
    );
  }

  Widget _dragProxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.scale(
          scale: 1.02,
          child: Material(
            color: Colors.transparent,
            elevation: 6,
            child: child,
          ),
        );
      },
    );
  }

  void _switchType(bool showIncome) {
    if (_showIncome == showIncome) return;
    setState(() => _showIncome = showIncome);
    _loadCategories();
  }

  String _normalizedQuery() => _normalizeSearch(_searchQuery);

  bool get _isSearching => _normalizedQuery().isNotEmpty;
  String get _rawQuery => _searchQuery.trim();

  List<_SearchGroup> _buildSearchGroups() {
    final query = _normalizedQuery();
    if (query.isEmpty) return [];
    final groups = <_SearchGroup>[];
    for (final parent in _parents) {
      final parentMatch = _matchesCategory(parent, query);
      final children = _childrenByParentKey[parent.key] ?? [];
      final matchedChildren = parentMatch
          ? children
          : children.where((c) => _matchesCategory(c, query)).toList();
      if (parentMatch || matchedChildren.isNotEmpty) {
        groups.add(_SearchGroup(parent: parent, children: matchedChildren));
      }
    }
    return groups;
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  bool _matchesCategory(JiveCategory category, String query) {
    final key = _searchKeyCache[category.key] ??= _buildSearchKey(category);
    return key.contains(query);
  }

  String _buildSearchKey(JiveCategory category) {
    final name = _normalizeSearch(category.name);
    final icon = _normalizeSearch(category.iconName);
    final pinyin = _normalizeSearch(PinyinHelper.getPinyinE(category.name));
    final short = _normalizeSearch(PinyinHelper.getShortPinyin(category.name));
    return "$name $icon $pinyin $short";
  }

  Widget _buildHighlightedText(String text, TextStyle style, String? query) {
    final trimmed = query?.trim() ?? "";
    if (trimmed.isEmpty) return Text(text, style: style);
    final lower = text.toLowerCase();
    final q = trimmed.toLowerCase();
    final index = lower.indexOf(q);
    if (index == -1) return Text(text, style: style);

    final before = text.substring(0, index);
    final match = text.substring(index, index + q.length);
    final after = text.substring(index + q.length);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: style.copyWith(color: JiveTheme.primaryGreen, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: after),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSourceBadge(bool isSystem, {bool compact = false}) {
    final label = isSystem ? "系统" : "自定义";
    final color = isSystem ? Colors.grey.shade600 : JiveTheme.primaryGreen;
    final background = isSystem ? Colors.grey.shade200 : JiveTheme.primaryGreen.withOpacity(0.12);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: compact ? 9 : 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _editCategory(JiveCategory category) async {
    final updated = await showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(category: category, isar: _isar),
    );
    if (updated == true) {
      await _reloadAndMarkChanged();
    }
  }

  Future<void> _promptAddSubCategory(
    JiveCategory parent, {
    String? initialText,
    bool initialBatch = false,
  }) async {
    final existingNames = (_childrenByParentKey[parent.key] ?? [])
        .map((child) => child.name)
        .toSet();
    final systemLibrary = _service.getSystemLibrary(isIncome: parent.isIncome, includeIncome: true);
    final result = await Navigator.push<CategoryCreateResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryCreateScreen(
          title: "添加子类 · ${parent.name}",
          parentName: parent.name,
          initialIcon: parent.iconName,
          nameLabel: "子类名称",
          allowBatch: true,
          initialText: initialText,
          initialBatch: initialBatch,
          systemLibrary: systemLibrary,
          existingNames: existingNames,
          initialGroupName: parent.name,
          autoBatchAdd: true,
          onBatchAdd: (suggestion, colorHex) async {
            final created = await _service.createSubCategory(
              parent: parent,
              name: suggestion.name,
              iconName: suggestion.iconName,
              colorHex: colorHex,
              isSystem: true,
            );
            return created != null;
          },
        ),
      ),
    );
    if (result == null) return;
    if (result.hasChanges) {
      await _reloadAndMarkChanged();
      return;
    }
    if (result.systemSelections.isEmpty && result.names.isEmpty) return;

    final skipped = <String>[];
    JiveCategory? lastCreated;
    if (result.systemSelections.isNotEmpty) {
      for (final item in result.systemSelections) {
        final created = await _service.createSubCategory(
          parent: parent,
          name: item.name,
          iconName: item.iconName,
          colorHex: result.colorHex,
          isSystem: true,
        );
        if (created == null) {
          skipped.add(item.name);
        } else {
          lastCreated = created;
        }
      }
    } else {
      for (final name in result.names) {
        final iconName = result.autoMatchIcon
            ? _service.suggestIconName(name, fallback: result.iconName)
            : result.iconName;
        final created = await _service.createSubCategory(
          parent: parent,
          name: name,
          iconName: iconName,
          colorHex: result.colorHex,
        );
        if (created == null) {
          skipped.add(name);
        } else {
          lastCreated = created;
        }
      }
    }

    if (!mounted) return;
    if (lastCreated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已存在同名子类")),
      );
      return;
    }
    await _reloadAndMarkChanged();
    if (skipped.isNotEmpty) {
      final preview = skipped.take(3).join("、");
      final suffix = skipped.length > 3 ? "等" : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已忽略重复: $preview$suffix")),
      );
    }
  }

  Future<void> _promptAddParentCategory({
    String? initialText,
    bool initialBatch = false,
  }) async {
    final result = await Navigator.push<CategoryCreateResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryCreateScreen(
          title: "添加一级分类",
          parentName: _showIncome ? "收入" : "支出",
          initialIcon: _showIncome ? "attach_money" : "category",
          nameLabel: "分类名称",
          allowBatch: true,
          initialText: initialText,
          initialBatch: initialBatch,
        ),
      ),
    );
    if (result == null) return;
    if (result.names.isEmpty) return;

    final skipped = <String>[];
    JiveCategory? lastCreated;
    for (final name in result.names) {
      final iconName = result.autoMatchIcon
          ? _service.suggestIconName(name, fallback: result.iconName)
          : result.iconName;
      final created = await _service.createParentCategory(
        name: name,
        iconName: iconName,
        isIncome: _showIncome,
        colorHex: result.colorHex,
      );
      if (created == null) {
        skipped.add(name);
      } else {
        lastCreated = created;
      }
    }

    if (!mounted) return;
    if (lastCreated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已存在同名一级分类")),
      );
      return;
    }
    await _reloadAndMarkChanged();
    if (skipped.isNotEmpty) {
      final preview = skipped.take(3).join("、");
      final suffix = skipped.length > 3 ? "等" : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已忽略重复: $preview$suffix")),
      );
    }
  }

  Future<void> _openStats({
    required JiveCategory parent,
    JiveCategory? sub,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(
          filterCategoryKey: parent.key,
          filterSubCategoryKey: sub?.key,
        ),
      ),
    );
  }

  Future<void> _moveSubCategory(JiveCategory sub) async {
    final parents = _parents.where((p) => p.key != sub.parentKey).toList();
    if (parents.isEmpty) return;

    final target = await showModalBottomSheet<JiveCategory>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text("移动到其他一级分类", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...parents.map((parent) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _resolveCategoryBackground(parent),
                  child: CategoryService.buildIcon(
                    parent.iconName,
                    size: 18,
                    color: _resolveCategoryColor(parent, fallback: Colors.grey.shade700),
                  ),
                ),
                title: Text(parent.name),
                onTap: () => Navigator.pop(context, parent),
              );
            }),
          ],
        ),
      ),
    );
    if (target == null) return;

    await _service.updateCategory(sub.id, sub.name, sub.iconName, target.key, sub.colorHex);
    await _reloadAndMarkChanged();
  }

  Future<void> _deleteCategory(JiveCategory category) async {
    if (category.isSystem) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("系统分类不可删除")),
      );
      return;
    }
    final deleted = await _service.deleteCategory(category);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请先处理子类后再删除")),
      );
      return;
    }
    await _reloadAndMarkChanged();
  }

  void _showParentActions(JiveCategory parent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("修改"),
              onTap: () async {
                Navigator.pop(context);
                await _editCategory(parent);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("添加子类"),
              onTap: () async {
                Navigator.pop(context);
                await _promptAddSubCategory(parent);
              },
            ),
            if (!parent.isSystem)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("删除", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteCategory(parent);
                },
              ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text("查看统计数据"),
              onTap: () async {
                Navigator.pop(context);
                await _openStats(parent: parent);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryActions(JiveCategory sub, JiveCategory parent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("修改"),
              onTap: () async {
                Navigator.pop(context);
                await _editCategory(sub);
              },
            ),
            if (!sub.isSystem)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("删除", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteCategory(sub);
                },
              ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text("改为一级分类"),
              onTap: () async {
                Navigator.pop(context);
                await _service.updateCategory(sub.id, sub.name, sub.iconName, null, sub.colorHex);
                await _reloadAndMarkChanged();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text("移动到其它一级分类"),
              onTap: () async {
                Navigator.pop(context);
                await _moveSubCategory(sub);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text("查看统计数据"),
              onTap: () async {
                Navigator.pop(context);
                await _openStats(parent: parent, sub: sub);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final searchGroups = _isSearching ? _buildSearchGroups() : const <_SearchGroup>[];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("分类管理", style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            color: Colors.black87,
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _promptAddParentCategory,
          child: const Icon(Icons.add),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text("支出"),
                      selected: !_showIncome,
                      onSelected: (_) => _switchType(false),
                      selectedColor: JiveTheme.primaryGreen.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("收入"),
                      selected: _showIncome,
                      onSelected: (_) => _switchType(true),
                      selectedColor: JiveTheme.primaryGreen.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _buildSearchField(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  _isSearching ? "搜索结果（排序已暂时关闭）" : "长按拖动可排序，点击可编辑，长按子类更多操作",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ),
            if (_isSearching && searchGroups.isEmpty)
              SliverFillRemaining(child: _buildEmptySearchState())
            else if (!_isSearching && _parents.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else if (_isSearching)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = searchGroups[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildParentCard(
                        group.parent,
                        index,
                        childrenOverride: group.children,
                        allowReorder: false,
                        allowCollapse: true,
                        allowChildDrag: false,
                        showAddChip: false,
                        highlightQuery: _rawQuery,
                      ),
                    );
                  },
                  childCount: searchGroups.length,
                ),
              )
            else
              SliverReorderableList(
                itemCount: _parents.length,
                onReorder: _onReorderParents,
                proxyDecorator: _dragProxyDecorator,
                itemBuilder: (context, index) {
                  final parent = _parents[index];
                  return Padding(
                    key: ValueKey("parent_${parent.key}"),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildParentCard(parent, index),
                  );
                },
              ),
            if (!_isSearching && _recommendationGroups.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRecommendationSection(),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard(
    JiveCategory parent,
    int index, {
    List<JiveCategory>? childrenOverride,
    bool allowReorder = true,
    bool allowCollapse = true,
    bool allowChildDrag = true,
    bool showAddChip = true,
    String? highlightQuery,
  }) {
    final children = childrenOverride ?? _childrenByParentKey[parent.key] ?? [];
    final isCollapsed = allowCollapse && _collapsedParents.contains(parent.key);
    final parentTotal = _parentTotals[parent.key] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (allowReorder)
                ReorderableDelayedDragStartListener(
                  index: index,
                  child: Listener(
                    onPointerDown: (_) => HapticFeedback.selectionClick(),
                    child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
                  ),
                )
              else
                const SizedBox(width: 24),
              const SizedBox(width: 6),
              CircleAvatar(
                backgroundColor: _resolveCategoryBackground(parent),
                child: CategoryService.buildIcon(
                  parent.iconName,
                  size: 20,
                  color: _resolveCategoryColor(parent, fallback: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _buildHighlightedText(
                            parent.name,
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            highlightQuery,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceBadge(parent.isSystem),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "本月 ${_formatAmount(parentTotal)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showParentActions(parent),
              ),
              if (allowCollapse)
                IconButton(
                  icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                  onPressed: () {
                    setState(() {
                      if (isCollapsed) {
                        _collapsedParents.remove(parent.key);
                      } else {
                        _collapsedParents.add(parent.key);
                      }
                    });
                  },
                ),
            ],
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: 8),
            if (children.isNotEmpty) ...[
              _buildSubStatsRow(parent, children),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...children.map((child) => _buildSubCategoryChip(
                  child,
                  parent,
                  parentTotal,
                  allowDrag: allowChildDrag,
                  highlightQuery: highlightQuery,
                )),
                if (showAddChip) _buildAddSubChip(parent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubCategoryChip(
    JiveCategory sub,
    JiveCategory parent,
    double parentTotal, {
    bool allowDrag = true,
    String? highlightQuery,
  }) {
    final amount = _subTotals[sub.key] ?? 0;
    if (!allowDrag) {
      return GestureDetector(
        onTap: () => _editCategory(sub),
        onLongPress: () => _showSubCategoryActions(sub, parent),
        child: _buildSubChipBody(
          sub,
          parent,
          amount,
          parentTotal: parentTotal,
          showHandle: false,
          highlightQuery: highlightQuery,
        ),
      );
    }
    return DragTarget<JiveCategory>(
      onWillAccept: (incoming) {
        return incoming != null && incoming.key != sub.key && incoming.parentKey == parent.key;
      },
      onAccept: (incoming) => _reorderSubCategory(parent, incoming, sub),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _editCategory(sub),
          onLongPress: () => _showSubCategoryActions(sub, parent),
          child: _buildSubChipBody(
            sub,
            parent,
            amount,
            parentTotal: parentTotal,
            isTarget: candidateData.isNotEmpty,
            highlightQuery: highlightQuery,
          ),
        );
      },
    );
  }

  Widget _buildSubChipBody(
    JiveCategory sub,
    JiveCategory parent,
    double amount, {
    double parentTotal = 0,
    bool isTarget = false,
    bool showHandle = true,
    String? highlightQuery,
  }) {
    final percent = parentTotal > 0 ? (amount / parentTotal).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTarget ? JiveTheme.primaryGreen.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryService.buildIcon(
            sub.iconName,
            size: 16,
            color: _resolveCategoryColor(sub, fallback: Colors.grey.shade700),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: _buildHighlightedText(
                      sub.name,
                      const TextStyle(fontSize: 12),
                      highlightQuery,
                    ),
                  ),
                  if (!sub.isSystem) ...[
                    const SizedBox(width: 4),
                    _buildSourceBadge(false, compact: true),
                  ],
                ],
              ),
              Text(
                _formatAmount(amount),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              if (parentTotal > 0) ...[
                const SizedBox(height: 3),
                SizedBox(
                  width: 48,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey.shade300,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
              ],
            ],
          ),
          if (showHandle) ...[
            const SizedBox(width: 6),
            LongPressDraggable<JiveCategory>(
              data: sub,
              onDragStarted: () => HapticFeedback.mediumImpact(),
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.03,
                  child: _buildSubChipBody(
                    sub,
                    parent,
                    amount,
                    parentTotal: parentTotal,
                    showHandle: false,
                  ),
                ),
              ),
              child: Icon(Icons.drag_indicator, size: 14, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddSubChip(JiveCategory parent) {
    return GestureDetector(
      onTap: () => _promptAddSubCategory(parent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 16, color: Colors.grey),
            SizedBox(width: 6),
            Text("添加子类", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String text = "暂无分类"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    final query = _rawQuery;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("未找到 \"$query\"", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _promptAddParentCategory(initialText: query),
            style: ElevatedButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
            child: const Text("创建一级分类"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _promptAddParentCategory(initialText: query, initialBatch: true),
            child: const Text("批量创建一级分类"),
          ),
        ],
      ),
    );
  }
}

class _SearchGroup {
  final JiveCategory parent;
  final List<JiveCategory> children;

  const _SearchGroup({required this.parent, required this.children});
}

class _RecommendationGroup {
  final JiveCategory parent;
  final List<_RecommendationItem> items;

  const _RecommendationGroup({required this.parent, required this.items});
}

class _RecommendationItem {
  final String name;
  final String iconName;

  const _RecommendationItem({required this.name, required this.iconName});
}
