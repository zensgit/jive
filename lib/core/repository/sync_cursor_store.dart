import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_checkpoint_snapshot.dart';
import 'sync_cursor.dart';

class SyncCursorStore {
  static const _entityIndexKey = 'sync_cursor_store_entities_v1';
  static const _cursorKeyPrefix = 'sync_cursor_store_v1_';
  static const _snapshotMetaKey = 'sync_cursor_store_snapshot_meta_v1';

  static Future<void> save(SyncCursor cursor) async {
    await saveAll([cursor]);
  }

  static Future<void> saveAll(Iterable<SyncCursor> cursors) async {
    final items = cursors.toList(growable: false);
    if (items.isEmpty) return;

    final current = await loadSnapshot();
    final merged = Map<String, SyncCursor>.from(current.cursors);
    for (final cursor in items) {
      merged[cursor.entityType] = cursor;
    }
    await saveSnapshot(SyncCheckpointSnapshot(cursors: merged));
  }

  static Future<void> saveSnapshot(SyncCheckpointSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await _persistSnapshot(prefs, snapshot);
  }

  static Future<SyncCursor?> load(String entityType) async {
    final snapshot = await loadSnapshot();
    if (!snapshot.isRestorable) return null;
    return snapshot.cursors[entityType];
  }

  static Future<SyncCheckpointSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final metaRaw = prefs.getString(_snapshotMetaKey);
    Map<String, dynamic> meta = const {};
    if (metaRaw != null && metaRaw.isNotEmpty) {
      final decoded = jsonDecode(metaRaw);
      if (decoded is Map) {
        meta = Map<String, dynamic>.from(decoded);
      }
    }

    final entities = _loadEntityIndex(prefs).toList()..sort();
    final payload = <String, dynamic>{...meta};
    for (final entityType in entities) {
      final raw = prefs.getString(_cursorKey(entityType));
      if (raw == null || raw.isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      payload[entityType] = Map<String, dynamic>.from(decoded);
    }

    final snapshot = SyncCheckpointSnapshot.fromJson(payload);
    if (!snapshot.isRestorable && payload.isNotEmpty) {
      await clearAll();
      return SyncCheckpointSnapshot();
    }
    return snapshot;
  }

  static Future<void> clear(String entityType) async {
    final snapshot = await loadSnapshot();
    final next = Map<String, SyncCursor>.from(snapshot.cursors)
      ..remove(entityType);
    await saveSnapshot(SyncCheckpointSnapshot(cursors: next));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final entities = _loadEntityIndex(prefs);
    for (final entityType in entities) {
      await prefs.remove(_cursorKey(entityType));
    }
    await prefs.remove(_entityIndexKey);
    await prefs.remove(_snapshotMetaKey);
  }

  static String _cursorKey(String entityType) => '$_cursorKeyPrefix$entityType';

  static Set<String> _loadEntityIndex(SharedPreferences prefs) {
    return Set<String>.from(prefs.getStringList(_entityIndexKey) ?? const []);
  }

  static Future<void> _persistSnapshot(
    SharedPreferences prefs,
    SyncCheckpointSnapshot snapshot,
  ) async {
    final previousEntities = _loadEntityIndex(prefs);
    final nextEntities = snapshot.cursors.keys.toSet();
    for (final entityType in previousEntities.difference(nextEntities)) {
      await prefs.remove(_cursorKey(entityType));
    }
    for (final entry in snapshot.cursors.entries) {
      await prefs.setString(
        _cursorKey(entry.key),
        jsonEncode(entry.value.toJson()),
      );
    }
    await prefs.setStringList(_entityIndexKey, nextEntities.toList()..sort());
    await prefs.setString(
      _snapshotMetaKey,
      jsonEncode({
        'version': snapshot.version,
        'capturedAt': snapshot.capturedAt.toIso8601String(),
        'checksum': snapshot.checksum,
      }),
    );
  }
}
