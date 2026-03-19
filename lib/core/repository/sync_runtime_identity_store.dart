import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SyncRuntimeDeviceIdentity {
  const SyncRuntimeDeviceIdentity({
    required this.deviceId,
    required this.createdAt,
  });

  final String deviceId;
  final DateTime createdAt;
}

class SyncRuntimeIdentityStore {
  static const _deviceIdKey = 'sync_runtime_device_id_v1';
  static const _deviceCreatedAtKey = 'sync_runtime_device_created_at_v1';

  Future<SyncRuntimeDeviceIdentity?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString(_deviceIdKey)?.trim() ?? '';
    final createdAtRaw = prefs.getString(_deviceCreatedAtKey)?.trim() ?? '';
    if (deviceId.isEmpty || createdAtRaw.isEmpty) {
      return null;
    }
    final createdAt =
        DateTime.tryParse(createdAtRaw)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return SyncRuntimeDeviceIdentity(deviceId: deviceId, createdAt: createdAt);
  }

  Future<SyncRuntimeDeviceIdentity> ensure({
    DateTime? now,
    String? deviceId,
  }) async {
    final existing = await load();
    if (existing != null) {
      return existing;
    }

    final createdAt = (now ?? DateTime.now()).toUtc();
    final nextDeviceId = (deviceId?.trim().isNotEmpty ?? false)
        ? deviceId!.trim()
        : _buildDeviceId(createdAt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, nextDeviceId);
    await prefs.setString(_deviceCreatedAtKey, createdAt.toIso8601String());
    return SyncRuntimeDeviceIdentity(
      deviceId: nextDeviceId,
      createdAt: createdAt,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceCreatedAtKey);
  }

  String _buildDeviceId(DateTime createdAt) {
    final random = Random(
      createdAt.microsecondsSinceEpoch ^ createdAt.millisecondsSinceEpoch,
    );
    final token = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'device_${createdAt.microsecondsSinceEpoch}_$token';
  }
}
