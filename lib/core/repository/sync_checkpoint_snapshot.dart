import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';

import 'account_sync_repository.dart';
import 'category_sync_repository.dart';
import 'project_sync_repository.dart';
import 'sync_cursor.dart';
import 'tag_sync_repository.dart';
import 'transaction_sync_repository.dart';

class SyncCheckpointSnapshot {
  static const int currentVersion = 1;

  SyncCheckpointSnapshot({
    Map<String, SyncCursor>? cursors,
    DateTime? capturedAt,
    int version = currentVersion,
  }) : this._(
         cursors: Map.unmodifiable(cursors ?? const <String, SyncCursor>{}),
         capturedAt: (capturedAt ?? DateTime.now()).toUtc(),
         version: version,
         checksumValid: true,
       );

  SyncCheckpointSnapshot._({
    required this.cursors,
    required this.capturedAt,
    required this.version,
    required this.checksumValid,
    String? checksum,
  }) : checksum = checksum ?? _computeChecksum(cursors, capturedAt, version);

  final Map<String, SyncCursor> cursors;
  final DateTime capturedAt;
  final int version;
  final String checksum;
  final bool checksumValid;

  int get count => cursors.length;
  bool get isRestorable => checksumValid && version <= currentVersion;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'capturedAt': capturedAt.toIso8601String(),
      'checksum': checksum,
      for (final entry in cursors.entries) entry.key: entry.value.toJson(),
    };
  }

  factory SyncCheckpointSnapshot.fromJson(Object? json) {
    if (json is! Map) {
      return SyncCheckpointSnapshot();
    }
    final map = Map<String, dynamic>.from(json);
    final cursors = <String, SyncCursor>{};
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (key == 'version' ||
          key == 'capturedAt' ||
          key == 'checksum' ||
          value is! Map) {
        continue;
      }
      cursors[key] = SyncCursor.fromJson(Map<String, dynamic>.from(value));
    }

    final version = switch (map['version']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? currentVersion,
      _ => currentVersion,
    };
    final capturedAt =
        DateTime.tryParse(map['capturedAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final storedChecksum = map['checksum']?.toString();
    final expectedChecksum = _computeChecksum(cursors, capturedAt, version);
    final checksumValid =
        storedChecksum == null || storedChecksum == expectedChecksum;

    return SyncCheckpointSnapshot._(
      cursors: Map.unmodifiable(cursors),
      capturedAt: capturedAt,
      version: version,
      checksum: storedChecksum ?? expectedChecksum,
      checksumValid: checksumValid,
    );
  }

  static Future<SyncCheckpointSnapshot> collect(Isar isar) async {
    final latest = await Future.wait<SyncCursor?>([
      AccountSyncRepository(isar).latestCursor(),
      CategorySyncRepository(isar).latestCursor(),
      TransactionSyncRepository(isar).latestCursor(),
      TagSyncRepository(isar).latestCursor(),
      ProjectSyncRepository(isar).latestCursor(),
    ]);
    final cursors = <String, SyncCursor>{};
    for (final cursor in latest) {
      if (cursor == null) continue;
      cursors[cursor.entityType] = cursor;
    }
    return SyncCheckpointSnapshot(cursors: cursors);
  }

  static String _computeChecksum(
    Map<String, SyncCursor> cursors,
    DateTime capturedAt,
    int version,
  ) {
    final orderedKeys = cursors.keys.toList()..sort();
    final normalized = <String, dynamic>{
      'version': version,
      'capturedAt': capturedAt.toIso8601String(),
      'cursors': {for (final key in orderedKeys) key: cursors[key]!.toJson()},
    };
    return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
  }
}
