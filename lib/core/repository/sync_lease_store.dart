import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_lease.dart';

class SyncLeaseStore {
  static const _leaseKey = 'sync_lease_store_v1';

  static Future<void> save(SyncLease lease) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_leaseKey, jsonEncode(lease.toJson()));
  }

  static Future<SyncLease?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_leaseKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return SyncLease.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<bool> hasActiveLease({DateTime? now}) async {
    final lease = await load();
    if (lease == null) return false;
    return lease.isActiveAt(now ?? DateTime.now());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leaseKey);
  }
}
