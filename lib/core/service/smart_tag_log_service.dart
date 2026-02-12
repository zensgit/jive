import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SmartTagLogEntry {
  final String tagKey;
  final String tagName;
  final int scannedCount;
  final int matchedCount;
  final int updatedCount;
  final int skippedCount;
  final bool cancelled;
  final bool success;
  final String? message;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final DateTime createdAt;

  const SmartTagLogEntry({
    required this.tagKey,
    required this.tagName,
    required this.scannedCount,
    required this.matchedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.cancelled,
    required this.success,
    required this.createdAt,
    this.message,
    this.rangeStart,
    this.rangeEnd,
  });

  Map<String, dynamic> toJson() => {
        'tagKey': tagKey,
        'tagName': tagName,
        'scannedCount': scannedCount,
        'matchedCount': matchedCount,
        'updatedCount': updatedCount,
        'skippedCount': skippedCount,
        'cancelled': cancelled,
        'success': success,
        'message': message,
        'rangeStart': rangeStart?.toIso8601String(),
        'rangeEnd': rangeEnd?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SmartTagLogEntry.fromJson(Map<String, dynamic> json) {
    return SmartTagLogEntry(
      tagKey: json['tagKey'] as String? ?? '',
      tagName: json['tagName'] as String? ?? '',
      scannedCount: json['scannedCount'] as int? ?? 0,
      matchedCount: json['matchedCount'] as int? ?? 0,
      updatedCount: json['updatedCount'] as int? ?? 0,
      skippedCount: json['skippedCount'] as int? ?? 0,
      cancelled: json['cancelled'] as bool? ?? false,
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      rangeStart: json['rangeStart'] == null
          ? null
          : DateTime.tryParse(json['rangeStart'] as String),
      rangeEnd: json['rangeEnd'] == null
          ? null
          : DateTime.tryParse(json['rangeEnd'] as String),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SmartTagLogService {
  static const _storageKey = 'smart_tag_backfill_logs_v1';
  static const _maxLogs = 200;

  Future<List<SmartTagLogEntry>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => SmartTagLogEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> addLog(SmartTagLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadLogs();
    final updated = [entry, ...list];
    if (updated.length > _maxLogs) {
      updated.removeRange(_maxLogs, updated.length);
    }
    final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
