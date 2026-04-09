import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_tombstone_entry.dart';

class SyncTombstoneStore {
  static const _prefKey = 'sync_tombstone_store_v1';

  static Future<void> upsert(SyncTombstoneEntry entry) async {
    await upsertAll([entry]);
  }

  static Future<void> upsertAll(Iterable<SyncTombstoneEntry> entries) async {
    final incoming = entries.toList(growable: false);
    if (incoming.isEmpty) return;

    final all = await loadAll();
    final nextByKey = <String, SyncTombstoneEntry>{
      for (final current in all) _entryStoreKey(current): current,
    };

    for (final entry in incoming) {
      nextByKey[_entryStoreKey(entry)] = entry;
    }

    await _saveAll(nextByKey.values.toList(growable: false));
  }

  static Future<List<SyncTombstoneEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                SyncTombstoneEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<List<SyncTombstoneEntry>> listForTable(String table) async {
    final all = await loadAll();
    return all.where((entry) => entry.table == table).toList(growable: false);
  }

  static Future<Map<String, SyncTombstoneEntry>> mapForTable(
    String table,
  ) async {
    final entries = await listForTable(table);
    return {for (final entry in entries) entry.entityKey: entry};
  }

  static Future<void> removeEntries(
    String table,
    Iterable<String> entityKeys,
  ) async {
    final keys = entityKeys.toSet();
    if (keys.isEmpty) return;

    final all = await loadAll();
    final next = all
        .where(
          (entry) => !(entry.table == table && keys.contains(entry.entityKey)),
        )
        .toList(growable: false);
    await _saveAll(next);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  static Future<void> _saveAll(List<SyncTombstoneEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    await prefs.setString(_prefKey, encoded);
  }

  static String _entryStoreKey(SyncTombstoneEntry entry) {
    return '${entry.table}::${entry.entityKey}';
  }
}
