import 'package:isar/isar.dart';

import '../database/tag_model.dart';
import 'sync_cursor.dart';
import 'sync_repository_contract.dart';

class TagSyncRepository implements SyncRepository<JiveTag> {
  TagSyncRepository(this.isar);

  final Isar isar;

  @override
  String get entityType => 'tag';

  @override
  Future<SyncPage<JiveTag>> listChangedAfter({
    SyncCursor? cursor,
    int limit = 100,
  }) async {
    _validateCursor(cursor);
    final tags = await isar.collection<JiveTag>().where().findAll();
    tags.sort(_compareTag);

    final changed = tags
        .where((tag) => _isAfterCursor(tag, cursor))
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
    final tags = await isar.collection<JiveTag>().where().findAll();
    if (tags.isEmpty) return null;
    tags.sort(_compareTag);
    return _cursorFrom(tags.last);
  }

  bool _isAfterCursor(JiveTag tag, SyncCursor? cursor) {
    if (cursor == null) return true;
    final updatedAtCompare = tag.updatedAt.compareTo(cursor.updatedAt);
    if (updatedAtCompare > 0) return true;
    if (updatedAtCompare < 0) return false;
    return tag.id > cursor.lastId;
  }

  int _compareTag(JiveTag a, JiveTag b) {
    final updatedAtCompare = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtCompare != 0) return updatedAtCompare;
    return a.id.compareTo(b.id);
  }

  SyncCursor _cursorFrom(JiveTag tag) {
    return SyncCursor(
      entityType: entityType,
      updatedAt: tag.updatedAt,
      lastId: tag.id,
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
