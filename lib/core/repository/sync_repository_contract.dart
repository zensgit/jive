import 'sync_cursor.dart';

abstract class SyncRepository<T> {
  String get entityType;

  Future<SyncPage<T>> listChangedAfter({SyncCursor? cursor, int limit = 100});

  Future<SyncCursor?> latestCursor();
}
