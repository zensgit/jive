class SyncRuntimeIdentity {
  const SyncRuntimeIdentity({
    required this.deviceId,
    required this.appInstanceId,
    required this.createdAt,
  });

  final String deviceId;
  final String appInstanceId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'appInstanceId': appInstanceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncRuntimeIdentity.fromJson(Map<String, dynamic> json) {
    return SyncRuntimeIdentity(
      deviceId: json['deviceId']?.toString() ?? '',
      appInstanceId: json['appInstanceId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
