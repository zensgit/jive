import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/category_service.dart';
import '../../core/utils/logger_util.dart';
import '../stats/stats_screen.dart';
import 'category_create_dialog.dart';
import 'category_create_screen.dart';
import 'category_edit_dialog.dart';

class _UserCategorySeed {
  final String parent;
  final List<String> children;

  const _UserCategorySeed(this.parent, this.children);
}

class CategoryManagerScreen extends StatefulWidget {
  final Isar? isar;
  final bool onlyUserCategories;

  const CategoryManagerScreen({
    super.key,
    this.isar,
    this.onlyUserCategories = false,
  });

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  late Isar _isar;
  late CategoryService _service;
  bool _isLoading = true;
  String? _loadError;
  bool _showIncome = false;
  bool _showHidden = false;
  bool _hasChanges = false;
  List<JiveCategory> _parents = [];
  Map<String, List<JiveCategory>> _childrenByParentKey = {};
  final Set<String> _collapsedParents = {};
  final Set<String> _knownParentKeys = {};
  final NumberFormat _moneyFormat = NumberFormat.compactCurrency(symbol: "¥", decimalDigits: 0);
  Map<String, double> _parentTotals = {};
  Map<String, double> _subTotals = {};
  List<_RecommendationGroup> _recommendationGroups = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Map<String, String> _searchKeyCache = {};
  bool _isAddingCommonSeeds = false;
  static const List<_UserCategorySeed> _fallbackExpenseSeeds = [
    _UserCategorySeed("餐饮", ["早餐", "午餐", "晚餐", "外卖", "饮料"]),
    _UserCategorySeed("交通", ["公交车", "地铁", "打车", "高铁", "飞机"]),
    _UserCategorySeed("购物", ["日用品", "家电", "家具", "包包", "口红"]),
    _UserCategorySeed("日常", ["话费", "快递", "日用品", "房租"]),
    _UserCategorySeed("娱乐", ["电影", "游戏", "KTV", "聚会"]),
    _UserCategorySeed("医疗", ["挂号", "药品", "医院", "检查", "住院"]),
    _UserCategorySeed("校园", ["培训", "课程", "书籍", "学费", "考试"]),
    _UserCategorySeed("人情", ["发红包", "礼金", "礼物", "送礼", "孝敬"]),
  ];
  static const List<_UserCategorySeed> _fallbackIncomeSeeds = [
    _UserCategorySeed("收入", ["工资", "奖金", "兼职收入", "外快", "收红包", "理财收入"]),
  ];

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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      JiveLogger.d("Category manager init start");
      final existing = widget.isar ?? Isar.getInstance();
      if (existing != null) {
        _isar = existing;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _isar = await Isar.open(
          [
            JiveCategorySchema,
            JiveCategoryOverrideSchema,
            JiveTransactionSchema,
            JiveAccountSchema,
            JiveAutoDraftSchema,
            JiveTagSchema,
            JiveTagGroupSchema,
          ],
          directory: dir.path,
        );
      }
      _service = CategoryService(_isar);
      await _service.initDefaultCategories();
      await _loadCategories();
    } catch (e, s) {
      _loadError = e.toString();
      JiveLogger.e("Category manager init failed", e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      _loadError = null;
      final all = await _isar.collection<JiveCategory>().where().findAll();
      final onlyUser = widget.onlyUserCategories;
      final parents = all
          .where((c) =>
              c.parentKey == null &&
              c.isIncome == _showIncome &&
              (_showHidden || !c.isHidden) &&
              (!onlyUser || !c.isSystem))
          .toList();
      final children = all
          .where((c) =>
              c.parentKey != null &&
              c.isIncome == _showIncome &&
              (_showHidden || !c.isHidden) &&
              (!onlyUser || !c.isSystem))
          .toList();

      parents.sort((a, b) => a.order.compareTo(b.order));

      for (final parent in parents) {
        if (!_knownParentKeys.contains(parent.key)) {
          _collapsedParents.add(parent.key);
        }
      }
      _knownParentKeys.addAll(parents.map((parent) => parent.key));

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

      JiveLogger.d(
        "Category manager load ok: parents=${parents.length}, children=${children.length}, income=$_showIncome, showHidden=$_showHidden, onlyUser=$onlyUser",
      );

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
    } catch (e, s) {
      JiveLogger.e("Category manager load failed", e, s);
      if (mounted) {
        setState(() {
          _loadError = e.toString();
        });
      }
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
    if (_showIncome || widget.onlyUserCategories) return [];
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
    final picks = <_RecommendationPick>[];
    for (final group in _recommendationGroups) {
      for (final item in group.items) {
        picks.add(_RecommendationPick(parent: group.parent, item: item));
      }
    }
    if (picks.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("智能推荐", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: JiveTheme.primaryGreen)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "根据当前分类缺口与消费偏好推荐补充子类",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: picks.map((pick) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () async {
                      final created = await _service.createSubCategory(
                        parent: pick.parent,
                        name: pick.item.name,
                        iconName: pick.item.iconName,
                        isSystem: !widget.onlyUserCategories,
                      );
                      if (!mounted) return;
                      if (created == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("已存在: ${pick.item.name}")),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("已添加: ${pick.item.name}")),
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
                          CategoryService.buildIcon(
                            pick.item.iconName,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${pick.parent.name}·${pick.item.name}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Future<void> _toggleCategoryHidden(JiveCategory category) async {
    await _service.setCategoryHidden(category.id, !category.isHidden);
    await _reloadAndMarkChanged();
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

  Future<void> _moveSubCategoryToParent(
    JiveCategory sub,
    JiveCategory targetParent, {
    JiveCategory? insertBefore,
  }) async {
    final sourceParentKey = sub.parentKey;
    if (sourceParentKey == null || sourceParentKey == targetParent.key) return;

    final sourceList = List<JiveCategory>.from(_childrenByParentKey[sourceParentKey] ?? []);
    final targetList = List<JiveCategory>.from(_childrenByParentKey[targetParent.key] ?? []);

    sourceList.removeWhere((c) => c.key == sub.key);

    var insertIndex = insertBefore == null
        ? targetList.length
        : targetList.indexWhere((c) => c.key == insertBefore.key);
    if (insertIndex < 0 || insertIndex > targetList.length) {
      insertIndex = targetList.length;
    }

    sub.parentKey = targetParent.key;
    targetList.insert(insertIndex, sub);

    setState(() {
      _childrenByParentKey[sourceParentKey] = sourceList;
      _childrenByParentKey[targetParent.key] = targetList;
    });

    await _service.updateCategory(sub.id, sub.name, sub.iconName, targetParent.key, sub.colorHex);
    await _service.reorderChildren(sourceParentKey, sourceList);
    await _service.reorderChildren(targetParent.key, targetList);
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

  Widget _buildHighlightedText(String text, TextStyle style, String? query, {int? maxLines}) {
    final trimmed = query?.trim() ?? "";
    if (trimmed.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = trimmed.toLowerCase();
    final index = lower.indexOf(q);
    if (index == -1) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

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
      maxLines: maxLines,
    );
  }

  Widget _buildHiddenBadge({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "已隐藏",
        style: TextStyle(fontSize: compact ? 9 : 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _editCategory(JiveCategory category) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditDialog(category: category, isar: _isar),
        fullscreenDialog: true,
      ),
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
    final addAsSystem = !widget.onlyUserCategories;
    final existingNames = (await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parent.key)
        .findAll())
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
              isSystem: addAsSystem,
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
          isSystem: addAsSystem,
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

  List<_UserCategorySeed> _commonSeedsForCurrentType() {
    final lib = _service.getSystemLibrary(isIncome: _showIncome);
    if (lib.isEmpty) {
      return _showIncome ? _fallbackIncomeSeeds : _fallbackExpenseSeeds;
    }

    final userParents = _parents;
    final userParentNames = {for (final p in userParents) p.name: p};
    final Map<String, Set<String>> userChildrenByParentName = {};
    for (final parent in userParents) {
      final children = _childrenByParentKey[parent.key] ?? const [];
      userChildrenByParentName[parent.name] = children.map((c) => c.name).toSet();
    }

    final totalsByName = <String, double>{};
    for (final parent in userParents) {
      totalsByName[parent.name] = _parentTotals[parent.key] ?? 0;
    }

    List<MapEntry<String, dynamic>> entries = lib.entries.toList();
    if (userParentNames.isNotEmpty) {
      final filtered = entries.where((entry) => userParentNames.containsKey(entry.key)).toList();
      if (filtered.isNotEmpty) {
        entries = filtered;
      }
    }

    const maxParents = 6;
    const maxChildren = 6;
    final seeds = <_UserCategorySeed>[];
    for (final entry in entries) {
      final parentName = entry.key;
      final children = (entry.value['children'] as List<dynamic>? ?? const [])
          .map((child) => (child['name'] as String? ?? "").trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (children.isEmpty) continue;
      final existingChildren = userChildrenByParentName[parentName] ?? const <String>{};
      final missing = children.where((name) => !existingChildren.contains(name)).toList();
      if (missing.isEmpty) continue;
      seeds.add(_UserCategorySeed(parentName, missing.take(maxChildren).toList()));
      if (seeds.length >= maxParents) break;
    }

    final hasTotals = totalsByName.values.any((value) => value > 0);
    if (hasTotals) {
      seeds.sort((a, b) {
        final totalA = totalsByName[a.parent] ?? 0;
        final totalB = totalsByName[b.parent] ?? 0;
        return totalB.compareTo(totalA);
      });
    }

    if (seeds.isEmpty) return const [];
    return seeds;
  }

  String _resolveSystemParentIcon(String parentName) {
    final lib = _service.getSystemLibrary(isIncome: _showIncome);
    final entry = lib[parentName];
    final icon = entry?['icon'] as String?;
    if (icon != null && icon.trim().isNotEmpty) return icon;
    return _service.suggestIconName(parentName, fallback: "category");
  }

  String _resolveSystemChildIcon(String parentName, String childName) {
    final lib = _service.getSystemLibrary(isIncome: _showIncome);
    final entry = lib[parentName];
    if (entry != null) {
      final children = entry['children'] as List<dynamic>? ?? const [];
      for (final child in children) {
        final name = (child['name'] as String? ?? "").trim();
        if (name == childName) {
          final icon = child['icon'] as String?;
          if (icon != null && icon.trim().isNotEmpty) return icon;
        }
      }
    }
    return _service.suggestIconName(childName, fallback: _resolveSystemParentIcon(parentName));
  }

  Map<String, String> _buildSystemChildParentIndex(Map<String, Map<String, dynamic>> lib) {
    final index = <String, String>{};
    for (final entry in lib.entries) {
      final parentName = entry.key;
      final children = entry.value['children'] as List<dynamic>? ?? const [];
      for (final child in children) {
        final name = (child['name'] as String? ?? "").trim();
        if (name.isEmpty) continue;
        index.putIfAbsent(name, () => parentName);
      }
    }
    return index;
  }

  bool _isSystemParentSuggestion(SystemCategorySuggestion suggestion, Map<String, Map<String, dynamic>> lib) {
    return suggestion.isParent || lib.containsKey(suggestion.name);
  }

  String? _resolveParentForSuggestion(
    SystemCategorySuggestion suggestion,
    Map<String, String> childParentIndex,
  ) {
    return suggestion.parentName ?? childParentIndex[suggestion.name];
  }

  Future<JiveCategory?> _ensureUserParent(String name, {String? colorHex}) async {
    final existing = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(_showIncome)
        .isSystemEqualTo(false)
        .nameEqualTo(name)
        .findFirst();
    if (existing != null) return existing;
    final iconName = _resolveSystemParentIcon(name);
    return await _service.createParentCategory(
      name: name,
      iconName: iconName,
      isIncome: _showIncome,
      isSystem: false,
      colorHex: colorHex,
    );
  }

  Future<bool> _addCommonSeedItem(_UserCategorySeed seed, String childName) async {
    final parent = await _ensureUserParent(seed.parent);
    if (parent == null) return false;
    final iconName = _resolveSystemChildIcon(seed.parent, childName);
    final created = await _service.createSubCategory(
      parent: parent,
      name: childName,
      iconName: iconName,
      isSystem: false,
    );
    return created != null;
  }

  Future<void> _addAllCommonSeeds() async {
    if (_isAddingCommonSeeds) return;
    if (mounted) {
      setState(() => _isAddingCommonSeeds = true);
    }
    final seeds = _commonSeedsForCurrentType();
    if (seeds.isEmpty) {
      if (mounted) {
        setState(() => _isAddingCommonSeeds = false);
      }
      return;
    }
    final lib = _service.getSystemLibrary(isIncome: _showIncome);
    final userParents = _parents;
    final existingParentNames = {for (final parent in userParents) parent.name};
    final Map<String, Set<String>> userChildrenByParentName = {};
    for (final parent in userParents) {
      final children = _childrenByParentKey[parent.key] ?? const [];
      userChildrenByParentName[parent.name] = children.map((c) => c.name).toSet();
    }

    var addedAny = false;
    try {
      for (final seed in seeds) {
        final existingChildren = userChildrenByParentName[seed.parent] ?? const <String>{};
        final targetChildren = () {
          if (lib.isEmpty) {
            return seed.children.where((name) => !existingChildren.contains(name)).toList();
          }
          final entry = lib[seed.parent];
          final children = entry?['children'] as List<dynamic>? ?? const [];
          final normalized = children
              .map((child) => (child['name'] as String? ?? "").trim())
              .where((name) => name.isNotEmpty && !existingChildren.contains(name))
              .toList();
          if (normalized.isNotEmpty) return normalized;
          return seed.children.where((name) => !existingChildren.contains(name)).toList();
        }();
        final parent = await _ensureUserParent(seed.parent);
        if (parent == null) continue;
        if (existingParentNames.add(seed.parent)) {
          addedAny = true;
        }
        if (targetChildren.isEmpty) continue;
        final trackedChildren = userChildrenByParentName.putIfAbsent(seed.parent, () => <String>{});
        for (final child in targetChildren) {
          if (trackedChildren.contains(child)) continue;
          final iconName = _resolveSystemChildIcon(seed.parent, child);
          final created = await _service.createSubCategory(
            parent: parent,
            name: child,
            iconName: iconName,
            isSystem: false,
          );
          if (created != null) {
            addedAny = true;
            trackedChildren.add(child);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingCommonSeeds = false);
      }
    }
    if (!mounted) return;
    if (addedAny) {
      _hasChanges = true;
    }
    await _loadCategories();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(addedAny ? "已添加常用分类" : "常用分类已存在")),
    );
  }

  Future<void> _promptAddParentCategory({
    String? initialText,
    bool initialBatch = false,
  }) async {
    final existingNames = (await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyIsNull()
        .isIncomeEqualTo(_showIncome)
        .isSystemEqualTo(false)
        .findAll())
        .map((parent) => parent.name)
        .toSet();
    final systemLibrary = _service.getSystemLibrary(isIncome: _showIncome);
    final childParentIndex = _buildSystemChildParentIndex(systemLibrary);
    final result = await Navigator.push<CategoryCreateResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryCreateScreen(
          title: "添加一级分类",
          parentName: null,
          typeName: _showIncome ? "收入" : "支出",
          parentOnly: true,
          initialIcon: _showIncome ? "attach_money" : "category",
          nameLabel: "一级分类名称",
          allowBatch: true,
          initialText: initialText,
          initialBatch: initialBatch,
          existingNames: existingNames,
          systemLibrary: systemLibrary,
          initialGroupName: "全部",
        ),
      ),
    );
    if (result == null) return;
    if (result.names.isEmpty && result.systemSelections.isEmpty) return;

    final skipped = <String>[];
    var createdAny = false;

    for (final selection in result.systemSelections) {
      if (_isSystemParentSuggestion(selection, systemLibrary)) {
        final parent = await _ensureUserParent(selection.name, colorHex: result.colorHex);
        if (parent != null) {
          createdAny = true;
        } else {
          skipped.add(selection.name);
        }
        continue;
      }
      final parentName = _resolveParentForSuggestion(selection, childParentIndex);
      if (parentName == null) {
        final parent = await _ensureUserParent(selection.name, colorHex: result.colorHex);
        if (parent != null) {
          createdAny = true;
        } else {
          skipped.add(selection.name);
        }
        continue;
      }
      final parent = await _ensureUserParent(parentName, colorHex: result.colorHex);
      if (parent == null) {
        skipped.add("${parentName}·${selection.name}");
        continue;
      }
      final created = await _service.createSubCategory(
        parent: parent,
        name: selection.name,
        iconName: selection.iconName,
        colorHex: result.colorHex,
        isSystem: false,
      );
      if (created == null) {
        skipped.add("${parentName}·${selection.name}");
      } else {
        createdAny = true;
      }
    }

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
        createdAny = true;
      }
    }

    if (!mounted) return;
    if (!createdAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已存在同名分类")),
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
                    color: _resolveCategoryColor(parent, fallback: JiveTheme.categoryIconInactive),
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

  Future<JiveCategory?> _pickParentTarget({
    required String title,
    required JiveCategory exclude,
  }) async {
    final parents = _parents.where((p) => p.key != exclude.key).toList();
    if (parents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("没有可选的一级分类")),
        );
      }
      return null;
    }
    return showModalBottomSheet<JiveCategory>(
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...parents.map((parent) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _resolveCategoryBackground(parent),
                  child: CategoryService.buildIcon(
                    parent.iconName,
                    size: 18,
                    color: _resolveCategoryColor(parent, fallback: JiveTheme.categoryIconInactive),
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
  }

  Future<void> _convertParentToSubCategory(JiveCategory parent) async {
    if (parent.isSystem) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("系统分类不可修改层级")),
      );
      return;
    }
    final targetParent = await _pickParentTarget(
      title: "选择要归属的一级分类",
      exclude: parent,
    );
    if (targetParent == null) return;

    final children = List<JiveCategory>.from(_childrenByParentKey[parent.key] ?? const []);
    if (children.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("包含子类"),
          content: Text("该分类包含 ${children.length} 个子类，需要将子类移到其它一级分类后才能继续。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("继续"),
            ),
          ],
        ),
      );
      if (proceed != true) return;

      final moves = <MapEntry<JiveCategory, JiveCategory>>[];
      for (final child in children) {
        final selected = await _pickParentTarget(
          title: "将「${child.name}」移动到",
          exclude: parent,
        );
        if (selected == null) return;
        moves.add(MapEntry(child, selected));
      }

      for (final move in moves) {
        await _moveSubCategoryToParent(move.key, move.value);
      }
    }

    await _service.updateCategory(parent.id, parent.name, parent.iconName, targetParent.key, parent.colorHex);
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
    final children = category.parentKey == null
        ? await _loadChildCategories(category)
        : <JiveCategory>[];
    final totalTxCount = await _countTransactionsForCategories([category, ...children]);

    if (children.isNotEmpty) {
      final cascade = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("包含子类"),
          content: Text("该分类包含 ${children.length} 个子类，是否一并删除？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("一并删除"),
            ),
          ],
        ),
      );
      if (cascade != true) return;
    }

    if (totalTxCount > 0) {
      final handling = await _askDeleteHandling(totalTxCount);
      if (handling == null) return;
      if (handling == _DeleteHandling.transfer) {
        final target = await _pickTransferTarget(category);
        if (target == null) return;
        final moved = await _confirmAndTransferTransactionsForCategories(
          [category, ...children],
          target,
        );
        if (!mounted) return;
        if (moved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(moved == 0 ? "没有可转移的账单" : "已转移 $moved 笔账单")),
          );
        }
      } else if (handling == _DeleteHandling.uncategorize) {
        final updated = await _uncategorizeTransactionsForCategories([category, ...children]);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updated == 0 ? "没有可处理的账单" : "已设为未分类 $updated 笔账单")),
        );
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(children.isEmpty ? "删除分类？" : "删除分类及子类？"),
        content: Text(children.isEmpty ? "删除后分类将无法恢复，相关账单会保留原名称。" : "删除后分类与子类将无法恢复，相关账单会保留原名称。"),
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
    for (final child in children) {
      await _service.deleteCategory(child);
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

  Future<List<JiveCategory>> _loadChildCategories(JiveCategory parent) async {
    final children = await _isar.collection<JiveCategory>()
        .filter()
        .parentKeyEqualTo(parent.key)
        .isSystemEqualTo(false)
        .findAll();
    children.sort((a, b) => a.order.compareTo(b.order));
    return children;
  }

  Future<int> _countTransactionsForCategory(JiveCategory category) async {
    final isSub = category.parentKey != null;
    final base = _isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(category.key)
        : base.categoryKeyEqualTo(category.key);
    return filtered.count();
  }

  Future<int> _countTransactionsForCategories(List<JiveCategory> categories) async {
    var total = 0;
    for (final category in categories) {
      total += await _countTransactionsForCategory(category);
    }
    return total;
  }

  Future<int> _uncategorizeTransactions(JiveCategory category) async {
    final isSub = category.parentKey != null;
    final base = _isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(category.key)
        : base.categoryKeyEqualTo(category.key);
    final txs = await filtered.findAll();
    if (txs.isEmpty) return 0;
    for (final tx in txs) {
      tx.categoryKey = null;
      tx.subCategoryKey = null;
      tx.category = "未分类";
      tx.subCategory = "";
    }
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
    });
    return txs.length;
  }

  Future<int> _uncategorizeTransactionsForCategories(List<JiveCategory> categories) async {
    var total = 0;
    for (final category in categories) {
      total += await _uncategorizeTransactions(category);
    }
    return total;
  }

  Future<int?> _confirmAndTransferTransactions(
    JiveCategory category,
    _TransferTarget target,
  ) async {
    final targetName = target.child == null
        ? target.parent.name
        : "${target.parent.name} · ${target.child!.name}";
    final sourceName = category.name;

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
    if (confirm != true) return null;
    return _applyTransactionTransfer(category, target);
  }

  Future<int?> _confirmAndTransferTransactionsForCategories(
    List<JiveCategory> categories,
    _TransferTarget target,
  ) async {
    final targetName = target.child == null
        ? target.parent.name
        : "${target.parent.name} · ${target.child!.name}";
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认转移账单"),
        content: Text("将该分类及子类的账单转移到 $targetName？"),
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
    if (confirm != true) return null;
    var total = 0;
    for (final category in categories) {
      total += await _applyTransactionTransfer(category, target);
    }
    return total;
  }

  Future<int> _applyTransactionTransfer(
    JiveCategory category,
    _TransferTarget target,
  ) async {
    final isSub = category.parentKey != null;
    final base = _isar.jiveTransactions.filter();
    final filtered = isSub
        ? base.subCategoryKeyEqualTo(category.key)
        : base.categoryKeyEqualTo(category.key);
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

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll(txs);
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
            onPressed: () => Navigator.pop(context, _DeleteHandling.uncategorize),
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

  Future<_TransferTarget?> _pickTransferTarget(JiveCategory category) async {
    final all = await _isar.collection<JiveCategory>().where().findAll();
    final parents = all
        .where((c) => c.parentKey == null && c.isIncome == category.isIncome)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final Map<String, List<JiveCategory>> childrenByParent = {};
    for (final cat in all) {
      if (cat.parentKey == null || cat.isIncome != category.isIncome) continue;
      childrenByParent.putIfAbsent(cat.parentKey!, () => []).add(cat);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }

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
              child: Text("选择目标分类", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...parents.expand((parent) {
              final tiles = <Widget>[];
              final isCurrentParent = category.parentKey == null && parent.key == category.key;
              if (!isCurrentParent) {
                tiles.add(_buildTargetTile(
                  parent: parent,
                  child: null,
                  indent: 0,
                ));
              }
              final children = childrenByParent[parent.key] ?? [];
              for (final child in children) {
                if (child.key == category.key) continue;
                tiles.add(_buildTargetTile(
                  parent: parent,
                  child: child,
                  indent: 24,
                ));
              }
              tiles.add(const Divider(height: 16));
              return tiles;
            }).toList(),
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
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: child == null ? null : Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      onTap: () => Navigator.pop(context, _TransferTarget(parent: parent, child: child)),
    );
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
                leading: const Icon(Icons.subdirectory_arrow_right),
                title: const Text("改为二级分类"),
                onTap: () async {
                  Navigator.pop(context);
                  await _convertParentToSubCategory(parent);
                },
              ),
            ListTile(
              leading: Icon(parent.isHidden ? Icons.visibility : Icons.visibility_off),
              title: Text(parent.isHidden ? "显示" : "隐藏"),
              onTap: () async {
                Navigator.pop(context);
                await _toggleCategoryHidden(parent);
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
              leading: Icon(sub.isHidden ? Icons.visibility : Icons.visibility_off),
              title: Text(sub.isHidden ? "显示" : "隐藏"),
              onTap: () async {
                Navigator.pop(context);
                await _toggleCategoryHidden(sub);
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

  Widget _buildErrorState() {
    final message = _loadError ?? "未知错误";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade200),
            const SizedBox(height: 12),
            const Text("分类加载失败", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              kDebugMode ? message : "请稍后重试",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initData,
              style: ElevatedButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
              child: const Text("重试"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTypeTab(
          label: "支出",
          selected: !_showIncome,
          onTap: () => _switchType(false),
        ),
        const SizedBox(width: 24),
        _buildTypeTab(
          label: "收入",
          selected: _showIncome,
          onTap: () => _switchType(true),
        ),
      ],
    );
  }

  Widget _buildTypeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? Colors.black87 : Colors.grey.shade500;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: color),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: selected ? JiveTheme.primaryGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderHint() {
    final hint = _isSearching
        ? "搜索结果（排序已暂停）"
        : (_showHidden ? "长按图标拖拽可排序/跨分类移动，点击可编辑 · 已显示隐藏" : "长按图标拖拽可排序/跨分类移动，点击可编辑");
    return Text(
      hint,
      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
    );
  }

  Widget _buildCommonUserSection() {
    if (!widget.onlyUserCategories) return const SizedBox.shrink();
    final seeds = _commonSeedsForCurrentType();
    if (seeds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("常用分类", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const Spacer(),
                TextButton(
                  onPressed: _isAddingCommonSeeds ? null : _addAllCommonSeeds,
                  child: Text(_isAddingCommonSeeds ? "添加中..." : "一键添加"),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final seed in seeds) ...[
              Text(seed.parent, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: seed.children.map((child) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final added = await _addCommonSeedItem(seed, child);
                      if (!mounted) return;
                      if (added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("已添加: ${seed.parent}·$child")),
                        );
                        await _reloadAndMarkChanged();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("已存在: ${seed.parent}·$child")),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        child,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("分类管理提示"),
        content: const Text(
          "长按图标拖拽可排序或跨分类移动，点击可编辑。\n"
          "点击右侧菜单可查看更多操作。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("知道了"),
          ),
        ],
      ),
    );
  }

  Widget _buildParentList(List<JiveCategory> parents, {String? highlightQuery}) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _onReorderParents,
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        return KeyedSubtree(
          key: ValueKey(parent.key),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildParentCard(
              parent,
              index,
              highlightQuery: highlightQuery,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _buildErrorState();
    }
    final searchGroups = _isSearching ? _buildSearchGroups() : const <_SearchGroup>[];
    final items = <Widget>[
      const SizedBox(height: 8),
      _buildTypeTabs(),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildHeaderHint(),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                setState(() => _showHidden = !_showHidden);
                await _loadCategories();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor: _showHidden ? Colors.grey.shade200 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                _showHidden ? "隐藏中" : "显示隐藏",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ];

    if (!_isSearching && widget.onlyUserCategories) {
      items.add(_buildCommonUserSection());
      items.add(const SizedBox(height: 12));
    }

    if (!_isSearching && _recommendationGroups.isNotEmpty) {
      items.add(_buildRecommendationSection());
      items.add(const SizedBox(height: 10));
    }

    final emptyText = widget.onlyUserCategories ? "暂无用户分类，可从常用分类添加" : "暂无分类";
    if (_isSearching && searchGroups.isEmpty) {
      items.add(SizedBox(height: 320, child: _buildEmptySearchState()));
    } else if (!_isSearching && _parents.isEmpty) {
      items.add(SizedBox(height: 320, child: _buildEmptyState(text: emptyText)));
    } else if (_isSearching) {
      items.addAll(searchGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildParentCard(
            group.parent,
            0,
            allowReorder: false,
            childrenOverride: group.children,
            allowCollapse: false,
            allowChildDrag: false,
            showAddChip: false,
            highlightQuery: _rawQuery,
          ),
        );
      }));
    } else {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildParentList(_parents),
        ),
      );
    }
    items.add(const SizedBox(height: 120));

    return ListView(
      padding: EdgeInsets.zero,
      children: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text("分类管理", style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
          leading: BackButton(
            color: Colors.black87,
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            if (!_isLoading && _loadError == null)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black54),
                onPressed: _promptAddParentCategory,
              ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.black54),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
        floatingActionButton: (_isLoading || _loadError != null)
            ? null
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildParentCard(
    JiveCategory parent,
    int index, {
    bool allowReorder = true,
    List<JiveCategory>? childrenOverride,
    bool allowCollapse = true,
    bool allowChildDrag = true,
    bool showAddChip = true,
    String? highlightQuery,
  }) {
    final children = childrenOverride ?? _childrenByParentKey[parent.key] ?? [];
    final isCollapsed = allowCollapse && _collapsedParents.contains(parent.key);
    final isHidden = parent.isHidden;
    final parentIconColor = isHidden
        ? Colors.grey.shade400
        : _resolveCategoryColor(parent, fallback: JiveTheme.categoryIconInactive);

    return DragTarget<JiveCategory>(
      onWillAccept: (incoming) => incoming != null && incoming.parentKey != parent.key,
      onAccept: (incoming) => _moveSubCategoryToParent(incoming, parent),
      builder: (context, candidateData, _) {
        final isTarget = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isTarget ? JiveTheme.primaryGreen.withOpacity(0.4) : Colors.grey.shade200),
          ),
          child: Opacity(
            opacity: isHidden ? 0.6 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (allowCollapse)
                      IconButton(
                        icon: Icon(isCollapsed ? Icons.chevron_right : Icons.expand_more),
                        color: Colors.grey.shade600,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        onPressed: () {
                          setState(() {
                            if (isCollapsed) {
                              _collapsedParents.remove(parent.key);
                            } else {
                              _collapsedParents.add(parent.key);
                            }
                          });
                        },
                      )
                    else
                      const SizedBox(width: 32),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: CategoryService.buildIcon(
                          parent.iconName,
                          size: 20,
                          color: parentIconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                      Flexible(
                        child: _buildHighlightedText(
                          parent.name,
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          highlightQuery,
                          maxLines: 1,
                        ),
                      ),
                      if (parent.isHidden) ...[
                        const SizedBox(width: 6),
                        _buildHiddenBadge(),
                      ],
                    ],
                  ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      color: Colors.grey.shade600,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      onPressed: () => _showParentActions(parent),
                    ),
                    if (allowReorder)
                      ReorderableDelayedDragStartListener(
                        index: index,
                        child: Listener(
                          onPointerDown: (_) => HapticFeedback.selectionClick(),
                          child: Icon(Icons.drag_indicator, size: 18, color: Colors.grey.shade400),
                        ),
                      )
                    else
                      const SizedBox(width: 18),
                  ],
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 8),
                  _buildSubCategoryGrid(
                    parent,
                    children,
                    allowDrag: allowChildDrag,
                    showAddChip: showAddChip,
                    highlightQuery: highlightQuery,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryGrid(
    JiveCategory parent,
    List<JiveCategory> children, {
    bool allowDrag = true,
    bool showAddChip = true,
    String? highlightQuery,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        final items = _buildSubGridItems(children, showAddChip: showAddChip);
        return DragTarget<JiveCategory>(
          onWillAccept: (incoming) => incoming != null && incoming.parentKey != parent.key,
          onAccept: (incoming) => _moveSubCategoryToParent(incoming, parent),
          builder: (context, candidateData, _) {
            final isTarget = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: isTarget ? Border.all(color: JiveTheme.primaryGreen.withOpacity(0.35)) : null,
              ),
              padding: const EdgeInsets.all(2),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.96,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isAdd) return _buildAddSubChip(parent);
                  final sub = item.category!;
                  return _buildSubCategoryChip(
                    sub,
                    parent,
                    allowDrag: allowDrag,
                    highlightQuery: highlightQuery,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  List<_SubGridItem> _buildSubGridItems(
    List<JiveCategory> children, {
    required bool showAddChip,
  }) {
    final items = <_SubGridItem>[
      ...children.map(_SubGridItem.category),
    ];
    if (showAddChip) {
      items.add(const _SubGridItem.add());
    }
    return items;
  }

  Widget _buildSubCategoryChip(
    JiveCategory sub,
    JiveCategory parent, {
    bool allowDrag = true,
    String? highlightQuery,
  }) {
    final tile = _buildSubChipBody(
      sub,
      highlightQuery: highlightQuery,
    );
    if (!allowDrag) {
      return GestureDetector(
        onTap: () => _editCategory(sub),
        onLongPress: () => _showSubCategoryActions(sub, parent),
        child: tile,
      );
    }
    return DragTarget<JiveCategory>(
      onWillAccept: (incoming) {
        return incoming != null && incoming.key != sub.key && incoming.parentKey != null;
      },
      onAccept: (incoming) {
        if (incoming.parentKey == parent.key) {
          _reorderSubCategory(parent, incoming, sub);
        } else {
          _moveSubCategoryToParent(incoming, parent, insertBefore: sub);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isTarget = candidateData.isNotEmpty;
        final decorated = _buildSubChipBody(
          sub,
          isTarget: isTarget,
          highlightQuery: highlightQuery,
        );
        return LongPressDraggable<JiveCategory>(
          data: sub,
          onDragStarted: () => HapticFeedback.mediumImpact(),
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.05,
              child: decorated,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: decorated,
          ),
          child: GestureDetector(
            onTap: () => _editCategory(sub),
            child: decorated,
          ),
        );
      },
    );
  }

  Widget _buildSubChipBody(
    JiveCategory sub, {
    bool isTarget = false,
    String? highlightQuery,
  }) {
    final isHidden = sub.isHidden;
    final iconColor = isHidden
        ? Colors.grey.shade400
        : _resolveCategoryColor(sub, fallback: Colors.grey.shade700);
    final labelColor = isHidden ? Colors.grey.shade400 : Colors.grey.shade600;
    final tile = Opacity(
      opacity: isHidden ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isTarget
              ? Border.all(color: JiveTheme.primaryGreen.withOpacity(0.35))
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryService.buildIcon(
              sub.iconName,
              size: 26,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            _buildHighlightedText(
              sub.name,
              TextStyle(fontSize: 10, height: 1.0, color: labelColor, fontWeight: FontWeight.w500),
              highlightQuery,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );

    return tile;
  }

  Widget _buildAddSubChip(JiveCategory parent) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _promptAddSubCategory(parent),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 26, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            "添加子类",
            style: TextStyle(fontSize: 10, height: 1.0, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String text = "暂无分类"}) {
    final canQuickAdd = widget.onlyUserCategories && _commonSeedsForCurrentType().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
          if (canQuickAdd) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAddingCommonSeeds ? null : _addAllCommonSeeds,
              style: ElevatedButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
              child: Text(_isAddingCommonSeeds ? "添加中..." : "一键添加常用分类"),
            ),
          ],
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

class _SubGridItem {
  final JiveCategory? category;
  final bool isAdd;

  const _SubGridItem._(this.category, {this.isAdd = false});

  const _SubGridItem.add() : this._(null, isAdd: true);
  const _SubGridItem.category(JiveCategory category) : this._(category);
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

class _RecommendationPick {
  final JiveCategory parent;
  final _RecommendationItem item;

  const _RecommendationPick({required this.parent, required this.item});
}

enum _DeleteHandling {
  transfer,
  uncategorize,
}

class _TransferTarget {
  final JiveCategory parent;
  final JiveCategory? child;

  const _TransferTarget({required this.parent, this.child});
}
