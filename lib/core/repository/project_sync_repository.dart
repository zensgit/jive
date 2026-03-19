import 'package:isar/isar.dart';

import '../database/project_model.dart';
import 'sync_cursor.dart';
import 'sync_repository_contract.dart';

class ProjectSyncRepository implements SyncRepository<JiveProject> {
  ProjectSyncRepository(this.isar);

  final Isar isar;

  @override
  String get entityType => 'project';

  @override
  Future<SyncPage<JiveProject>> listChangedAfter({
    SyncCursor? cursor,
    int limit = 100,
  }) async {
    _validateCursor(cursor);
    final projects = await isar.collection<JiveProject>().where().findAll();
    projects.sort(_compareProject);

    final changed = projects
        .where((project) => _isAfterCursor(project, cursor))
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
    final projects = await isar.collection<JiveProject>().where().findAll();
    if (projects.isEmpty) return null;
    projects.sort(_compareProject);
    return _cursorFrom(projects.last);
  }

  bool _isAfterCursor(JiveProject project, SyncCursor? cursor) {
    if (cursor == null) return true;
    final updatedAtCompare = project.updatedAt.compareTo(cursor.updatedAt);
    if (updatedAtCompare > 0) return true;
    if (updatedAtCompare < 0) return false;
    return project.id > cursor.lastId;
  }

  int _compareProject(JiveProject a, JiveProject b) {
    final updatedAtCompare = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtCompare != 0) return updatedAtCompare;
    return a.id.compareTo(b.id);
  }

  SyncCursor _cursorFrom(JiveProject project) {
    return SyncCursor(
      entityType: entityType,
      updatedAt: project.updatedAt,
      lastId: project.id,
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
