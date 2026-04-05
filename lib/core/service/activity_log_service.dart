import 'package:isar/isar.dart';

import '../database/activity_log_model.dart';

/// Service for recording and querying activity audit logs.
class ActivityLogService {
  final Isar _isar;

  ActivityLogService(this._isar);

  /// Create a new audit log entry.
  Future<void> log({
    required String action,
    required String entityType,
    required int entityId,
    required String entityName,
    required String userId,
    required String userName,
    String? details,
    String? bookKey,
  }) async {
    final entry = JiveActivityLog()
      ..action = action
      ..entityType = entityType
      ..entityId = entityId
      ..entityName = entityName
      ..userId = userId
      ..userName = userName
      ..details = details
      ..bookKey = bookKey
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveActivityLogs.put(entry);
    });
  }

  /// Get recent log entries sorted by createdAt descending.
  Future<List<JiveActivityLog>> getRecentLogs({int limit = 50}) async {
    return _isar.jiveActivityLogs
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Get logs for a specific entity.
  Future<List<JiveActivityLog>> getLogsByEntity(
    String entityType,
    int entityId,
  ) async {
    return _isar.jiveActivityLogs
        .where()
        .entityTypeEqualTo(entityType)
        .filter()
        .entityIdEqualTo(entityId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get logs for a specific book/ledger.
  Future<List<JiveActivityLog>> getLogsByBook(
    String bookKey, {
    int limit = 50,
  }) async {
    return _isar.jiveActivityLogs
        .where()
        .bookKeyEqualTo(bookKey)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// Remove logs older than [keepDays] days.
  Future<int> cleanupOldLogs({int keepDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    int deleted = 0;
    await _isar.writeTxn(() async {
      deleted = await _isar.jiveActivityLogs
          .where()
          .createdAtLessThan(cutoff)
          .deleteAll();
    });
    return deleted;
  }
}
