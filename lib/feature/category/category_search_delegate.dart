import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import '../../core/database/category_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';

class CategorySearchResult {
  final JiveCategory parent;
  final JiveCategory? sub;
  final List<JiveCategory> path;

  const CategorySearchResult({
    required this.parent,
    this.sub,
    List<JiveCategory>? path,
  }) : path = path ?? const [];

  String get primaryName => sub?.name ?? parent.name;
  String get secondaryName {
    final segments = path.isEmpty ? [parent, if (sub != null) sub!] : path;
    if (segments.length <= 1) return "一级分类";
    return segments.map((category) => category.name).join(" / ");
  }

  Iterable<JiveCategory> get searchableCategories sync* {
    if (path.isNotEmpty) {
      yield* path;
      return;
    }
    yield parent;
    if (sub != null) yield sub!;
  }
}

class CategorySearchDelegate extends SearchDelegate<CategorySearchResult?> {
  final List<CategorySearchResult> items;
  final String hintText;
  final Map<String, String> _searchKeyCache = {};

  CategorySearchDelegate({required this.items, this.hintText = "搜索分类"});

  @override
  String get searchFieldLabel => hintText;

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return [];
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
    ];
  }

  List<CategorySearchResult> _filter(String query) {
    final q = _normalizeSearch(query);
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.searchableCategories.any((category) {
        return _matches(category, q);
      });
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
    return "$name $icon $pinyin $short";
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(_filter(query));
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(_filter(query));
  }

  Widget _buildList(List<CategorySearchResult> results) {
    if (results.isEmpty) {
      return const Center(child: Text("未找到匹配分类"));
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
          onTap: () => close(context, item),
        );
      },
    );
  }
}
