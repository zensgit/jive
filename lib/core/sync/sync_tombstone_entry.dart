class SyncTombstoneEntry {
  final String table;
  final String entityKey;
  final DateTime deletedAt;
  final Map<String, dynamic> payload;

  const SyncTombstoneEntry({
    required this.table,
    required this.entityKey,
    required this.deletedAt,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
    'table': table,
    'entity_key': entityKey,
    'deleted_at': deletedAt.toIso8601String(),
    'payload': payload,
  };

  factory SyncTombstoneEntry.fromJson(Map<String, dynamic> json) {
    return SyncTombstoneEntry(
      table: json['table'] as String? ?? '',
      entityKey: json['entity_key'] as String? ?? '',
      deletedAt: DateTime.parse(json['deleted_at'] as String),
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
