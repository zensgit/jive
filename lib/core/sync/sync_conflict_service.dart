import 'dart:convert';

import 'package:isar/isar.dart';

import '../database/sync_conflict_model.dart';

/// Service for managing sync conflicts.
class SyncConflictService {
  final Isar _isar;

  SyncConflictService(this._isar);

  /// Record a new conflict.
  Future<void> recordConflict({
    required String table,
    required int localId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) async {
    // Check if there's already a pending conflict for this record
    final existing = await _isar.jiveSyncConflicts
        .filter()
        .tableEqualTo(table)
        .and()
        .localIdEqualTo(localId)
        .and()
        .statusEqualTo('pending')
        .findFirst();

    if (existing != null) {
      // Update existing conflict with new data
      await _isar.writeTxn(() async {
        existing.localJson = jsonEncode(localData);
        existing.remoteJson = jsonEncode(remoteData);
        existing.localUpdatedAt = localUpdatedAt;
        existing.remoteUpdatedAt = remoteUpdatedAt;
        existing.detectedAt = DateTime.now();
        await _isar.jiveSyncConflicts.put(existing);
      });
      return;
    }

    final conflict = JiveSyncConflict()
      ..table = table
      ..localId = localId
      ..localJson = jsonEncode(localData)
      ..remoteJson = jsonEncode(remoteData)
      ..localUpdatedAt = localUpdatedAt
      ..remoteUpdatedAt = remoteUpdatedAt
      ..status = 'pending'
      ..detectedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveSyncConflicts.put(conflict);
    });
  }

  /// Get all pending conflicts.
  Future<List<JiveSyncConflict>> getPendingConflicts() async {
    return _isar.jiveSyncConflicts
        .filter()
        .statusEqualTo('pending')
        .sortByDetectedAtDesc()
        .findAll();
  }

  /// Get pending conflict count.
  Future<int> getPendingCount() async {
    return _isar.jiveSyncConflicts
        .filter()
        .statusEqualTo('pending')
        .count();
  }

  /// Resolve a conflict by keeping local version.
  Future<void> resolveKeepLocal(int conflictId) async {
    await _isar.writeTxn(() async {
      final conflict = await _isar.jiveSyncConflicts.get(conflictId);
      if (conflict == null) return;
      conflict.status = 'keepLocal';
      conflict.resolvedAt = DateTime.now();
      await _isar.jiveSyncConflicts.put(conflict);
    });
  }

  /// Resolve a conflict by keeping remote version.
  Future<void> resolveKeepRemote(int conflictId) async {
    await _isar.writeTxn(() async {
      final conflict = await _isar.jiveSyncConflicts.get(conflictId);
      if (conflict == null) return;
      conflict.status = 'keepRemote';
      conflict.resolvedAt = DateTime.now();
      await _isar.jiveSyncConflicts.put(conflict);
    });
  }

  /// Resolve all pending conflicts with one strategy.
  Future<int> resolveAll(String strategy) async {
    final pending = await getPendingConflicts();
    await _isar.writeTxn(() async {
      for (final conflict in pending) {
        conflict.status = strategy;
        conflict.resolvedAt = DateTime.now();
        await _isar.jiveSyncConflicts.put(conflict);
      }
    });
    return pending.length;
  }

  /// Clean up old resolved conflicts (older than 30 days).
  Future<void> cleanupOldConflicts() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final old = await _isar.jiveSyncConflicts
        .filter()
        .not()
        .statusEqualTo('pending')
        .resolvedAtIsNotNull()
        .resolvedAtLessThan(cutoff)
        .findAll();

    if (old.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.jiveSyncConflicts.deleteAll(old.map((c) => c.id).toList());
    });
  }

  /// Parse a conflict's local or remote JSON data.
  Map<String, dynamic> parseConflictData(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
