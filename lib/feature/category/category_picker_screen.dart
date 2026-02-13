import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../core/database/category_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import 'category_manager_screen.dart';
import 'category_search_delegate.dart';

class CategoryPickerScreen extends StatefulWidget {
  final bool isIncome;
  final bool onlyUserCategories;
  final Isar? isar;
  final String title;

  const CategoryPickerScreen({
    super.key,
    required this.isIncome,
    this.onlyUserCategories = false,
    this.isar,
    this.title = '选择分类',
  });

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  static const _searchHint = '搜索分类';

  Isar? _isar;
  bool _isLoading = true;
  String? _loadError;
  List<JiveCategory> _parents = [];
  Map<String, List<JiveCategory>> _childrenByParentKey = {};
  List<CategorySearchResult> _items = [];
  final Set<String> _expandedParents = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final Map<String, String> _searchKeyCache = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final value = _searchController.text;
      if (value == _query) return;
      setState(() => _query = value);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = widget.isar ?? await DatabaseService.getInstance();
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
      final all = await isar.collection<JiveCategory>().where().findAll();
      final filtered = all.where((cat) {
        if (cat.isHidden) return false;
        if (cat.isIncome != widget.isIncome) return false;
        if (widget.onlyUserCategories && cat.isSystem) return false;
        return true;
      }).toList();

      final parents = filtered.where((cat) => cat.parentKey == null).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final childrenByParent = <String, List<JiveCategory>>{};
      for (final child in filtered.where((cat) => cat.parentKey != null)) {
        final parentKey = child.parentKey!;
        childrenByParent.putIfAbsent(parentKey, () => []).add(child);
      }
      for (final list in childrenByParent.values) {
        list.sort((a, b) => a.order.compareTo(b.order));
      }

      final items = <CategorySearchResult>[];
      for (final parent in parents) {
        items.add(CategorySearchResult(parent: parent));
        final children = childrenByParent[parent.key] ?? const <JiveCategory>[];
        for (final child in children) {
          items.add(CategorySearchResult(parent: parent, sub: child));
        }
      }

      if (!mounted) return;
      setState(() {
        _parents = parents;
        _childrenByParentKey = childrenByParent;
        _items = items;
        _searchKeyCache.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parents = [];
        _childrenByParentKey = {};
        _items = [];
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CategorySearchResult> _filter(String query) {
    final q = _normalizeSearch(query);
    if (q.isEmpty) return _items;
    return _items.where((item) {
      if (_matches(item.parent, q)) return true;
      final sub = item.sub;
      return sub != null && _matches(sub, q);
    }).toList();
  }

  String _normalizeSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  bool _matches(JiveCategory category, String query) {
    final key = _searchKeyCache[category.key] ??= _buildSearchKey(category);
    return key.contains(query);
  }

  String _buildSearchKey(JiveCategory category) {
    final name = _normalizeSearch(category.name);
    final icon = _normalizeSearch(category.iconName);
    final pinyin = _normalizeSearch(PinyinHelper.getPinyinE(category.name));
    final short = _normalizeSearch(PinyinHelper.getShortPinyin(category.name));
    return '$name $icon $pinyin $short';
  }

  Future<void> _openManager() async {
    final isar = await _ensureIsar();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagerScreen(
          isar: isar,
          onlyUserCategories: widget.onlyUserCategories,
          initialShowIncome: widget.isIncome,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '分类管理',
            onPressed: _openManager,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildErrorState()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _searchHint,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                        filled: true,
                        isDense: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _query.trim().isEmpty
                        ? _buildHierarchicalList()
                        : _buildSearchList(_filter(_query)),
                  ),
                ],
              ),
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
              '分类加载失败',
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

  Widget _buildHierarchicalList() {
    if (_parents.isEmpty) {
      return const Center(child: Text('暂无分类'));
    }
    return ListView.separated(
      itemCount: _parents.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final parent = _parents[index];
        final children =
            _childrenByParentKey[parent.key] ?? const <JiveCategory>[];
        final isExpanded = _expandedParents.contains(parent.key);
        final parentColor =
            CategoryService.parseColorHex(parent.colorHex) ??
            JiveTheme.categoryIconInactive;
        final parentLeading = Semantics(
          button: children.isNotEmpty,
          label: children.isEmpty
              ? parent.name
              : (isExpanded ? '收起 ${parent.name}' : '展开 ${parent.name}'),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: children.isEmpty
                ? null
                : () {
                    setState(() {
                      if (isExpanded) {
                        _expandedParents.remove(parent.key);
                      } else {
                        _expandedParents.add(parent.key);
                      }
                    });
                  },
            child: CircleAvatar(
              backgroundColor: parentColor.withValues(alpha: 0.12),
              child: CategoryService.buildIcon(
                parent.iconName,
                size: 18,
                color: parentColor,
                isSystemCategory: parent.isSystem,
                forceTinted: parent.iconForceTinted,
              ),
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: parentLeading,
              title: Text(parent.name),
              subtitle: children.isEmpty
                  ? const Text('一级分类')
                  : Text('${children.length} 个子类'),
              trailing: const Icon(Icons.chevron_right, color: Colors.black38),
              onTap: () =>
                  Navigator.pop(context, CategorySearchResult(parent: parent)),
            ),
            if (children.isNotEmpty && isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: children
                      .map((child) => _buildChildItem(parent, child))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChildItem(JiveCategory parent, JiveCategory child) {
    final childColor =
        CategoryService.parseColorHex(child.colorHex) ??
        JiveTheme.categoryIconInactive;
    return SizedBox(
      width: 74,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(
          context,
          CategorySearchResult(parent: parent, sub: child),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: childColor.withValues(alpha: 0.12),
                child: CategoryService.buildIcon(
                  child.iconName,
                  size: 18,
                  color: childColor,
                  isSystemCategory: child.isSystem,
                  forceTinted: child.iconForceTinted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                child.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchList(List<CategorySearchResult> results) {
    if (results.isEmpty) {
      return const Center(child: Text('未找到匹配分类'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = results[index];
        final iconName = item.sub?.iconName ?? item.parent.iconName;
        final iconColor = CategoryService.parseColorHex(
          item.sub?.colorHex ?? item.parent.colorHex,
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                iconColor?.withValues(alpha: 0.12) ?? Colors.grey.shade100,
            child: CategoryService.buildIcon(
              iconName,
              size: 18,
              color: iconColor ?? JiveTheme.categoryIconInactive,
              isSystemCategory: item.sub?.isSystem ?? item.parent.isSystem,
              forceTinted:
                  item.sub?.iconForceTinted ?? item.parent.iconForceTinted,
            ),
          ),
          title: Text(item.primaryName),
          subtitle: Text(item.secondaryName),
          trailing: const Icon(Icons.chevron_right, color: Colors.black38),
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }
}
