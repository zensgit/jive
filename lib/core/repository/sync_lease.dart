class SyncLease {
  const SyncLease({
    required this.leaseId,
    required this.scope,
    required this.ownerId,
    required this.deviceId,
    required this.version,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String leaseId;
  final String scope;
  final String ownerId;
  final String deviceId;
  final int version;
  final DateTime issuedAt;
  final DateTime expiresAt;

  bool isActiveAt(DateTime now) => expiresAt.isAfter(now);

  Map<String, dynamic> toJson() {
    return {
      'leaseId': leaseId,
      'scope': scope,
      'ownerId': ownerId,
      'deviceId': deviceId,
      'version': version,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory SyncLease.fromJson(Map<String, dynamic> json) {
    return SyncLease(
      leaseId: json['leaseId']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      version: switch (json['version']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      issuedAt:
          DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
