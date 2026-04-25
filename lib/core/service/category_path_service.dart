import '../database/category_model.dart';

class CategoryPath {
  final List<JiveCategory> segments;

  const CategoryPath(this.segments);

  bool get isEmpty => segments.isEmpty;
  JiveCategory? get primary => segments.isEmpty ? null : segments.first;
  JiveCategory? get leaf => segments.isEmpty ? null : segments.last;
  String? get primaryKey => primary?.key;
  String? get leafKey => leaf?.key;
  String? get primaryName => primary?.name;
  String? get leafName => leaf?.name;

  String get displayName {
    if (segments.isEmpty) return '未选择';
    return segments.map((c) => c.name).join(' / ');
  }

  List<String> get keys => segments.map((c) => c.key).toList();
}

/// Resolves arbitrary-depth category trees while keeping the transaction model
/// compatible: transactions store the top-level key plus the selected leaf key.
class CategoryPathService {
  const CategoryPathService();

  CategoryPath resolve(
    Iterable<JiveCategory> categories, {
    String? categoryKey,
    String? subCategoryKey,
  }) {
    final byKey = {for (final category in categories) category.key: category};
    final leafKey = _firstNonEmpty(subCategoryKey, categoryKey);
    if (leafKey == null || !byKey.containsKey(leafKey)) {
      return const CategoryPath([]);
    }

    final reversed = <JiveCategory>[];
    final seen = <String>{};
    var current = byKey[leafKey];
    while (current != null && seen.add(current.key)) {
      reversed.add(current);
      final parentKey = current.parentKey;
      current = parentKey == null || parentKey.isEmpty
          ? null
          : byKey[parentKey];
    }

    return CategoryPath(reversed.reversed.toList(growable: false));
  }

  CategoryPath resolveFromSelection(
    Iterable<JiveCategory> categories,
    JiveCategory? selected,
  ) {
    return resolve(categories, categoryKey: selected?.key);
  }

  TransactionCategoryKeys toTransactionKeys(
    Iterable<JiveCategory> categories,
    JiveCategory? selected,
  ) {
    final path = resolveFromSelection(categories, selected);
    final primaryKey = path.primaryKey;
    final leafKey = path.leafKey;
    return TransactionCategoryKeys(
      categoryKey: primaryKey,
      subCategoryKey: leafKey == null || leafKey == primaryKey ? null : leafKey,
      categoryName: path.primaryName,
      subCategoryName: leafKey == null || leafKey == primaryKey
          ? null
          : path.leafName,
      displayName: path.displayName,
    );
  }

  List<CategoryPath> visiblePaths(
    Iterable<JiveCategory> categories, {
    required bool isIncome,
  }) {
    final visible = categories
        .where((c) => c.isIncome == isIncome && !c.isHidden)
        .toList();
    final paths = visible
        .map((c) => resolve(visible, categoryKey: c.key))
        .where((p) => !p.isEmpty)
        .toList();
    paths.sort((a, b) {
      final orderCompare = (a.primary?.order ?? 0).compareTo(
        b.primary?.order ?? 0,
      );
      if (orderCompare != 0) return orderCompare;
      return a.displayName.compareTo(b.displayName);
    });
    return paths;
  }

  static String? _firstNonEmpty(String? first, String? second) {
    if (first != null && first.trim().isNotEmpty) return first;
    if (second != null && second.trim().isNotEmpty) return second;
    return null;
  }
}

class TransactionCategoryKeys {
  final String? categoryKey;
  final String? subCategoryKey;
  final String? categoryName;
  final String? subCategoryName;
  final String displayName;

  const TransactionCategoryKeys({
    this.categoryKey,
    this.subCategoryKey,
    this.categoryName,
    this.subCategoryName,
    required this.displayName,
  });
}
