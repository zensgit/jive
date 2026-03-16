import 'package:isar/isar.dart';

import '../database/category_model.dart';
import 'sync_cursor.dart';
import 'sync_repository_contract.dart';

class CategorySyncRepository implements SyncRepository<JiveCategory> {
  CategorySyncRepository(this.isar);

  final Isar isar;

  @override
  String get entityType => 'category';

  @override
  Future<SyncPage<JiveCategory>> listChangedAfter({
    SyncCursor? cursor,
    int limit = 100,
  }) async {
    _validateCursor(cursor);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    categories.sort(_compareCategory);

    final changed = categories
        .where((category) => _isAfterCursor(category, cursor))
        .toList(growable: false);
    final items = changed.take(limit).toList(growable: false);

    return SyncPage(
      items: items,
      nextCursor: items.isEmpty ? cursor : _cursorFrom(items.last),
      hasMore: changed.length > items.length,
    );
  }

  @override
  Future<SyncCursor?> latestCursor() async {
    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return null;
    categories.sort(_compareCategory);
    return _cursorFrom(categories.last);
  }

  bool _isAfterCursor(JiveCategory category, SyncCursor? cursor) {
    if (cursor == null) return true;
    final updatedAtCompare = category.updatedAt.compareTo(cursor.updatedAt);
    if (updatedAtCompare > 0) return true;
    if (updatedAtCompare < 0) return false;
    return category.id > cursor.lastId;
  }

  int _compareCategory(JiveCategory a, JiveCategory b) {
    final updatedAtCompare = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtCompare != 0) return updatedAtCompare;
    return a.id.compareTo(b.id);
  }

  SyncCursor _cursorFrom(JiveCategory category) {
    return SyncCursor(
      entityType: entityType,
      updatedAt: category.updatedAt,
      lastId: category.id,
    );
  }

  void _validateCursor(SyncCursor? cursor) {
    if (cursor != null && cursor.entityType != entityType) {
      throw StateError(
        'sync cursor entityType=${cursor.entityType} 不能用于 $entityType repository',
      );
    }
  }
}
