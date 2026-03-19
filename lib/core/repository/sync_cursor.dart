class SyncCursor {
  const SyncCursor({
    required this.entityType,
    required this.updatedAt,
    required this.lastId,
  });

  final String entityType;
  final DateTime updatedAt;
  final int lastId;

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType,
      'updatedAt': updatedAt.toIso8601String(),
      'lastId': lastId,
    };
  }

  factory SyncCursor.fromJson(Map<String, dynamic> json) {
    return SyncCursor(
      entityType: json['entityType']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastId: switch (json['lastId']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
    );
  }
}

class SyncPage<T> {
  const SyncPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final SyncCursor? nextCursor;
  final bool hasMore;
}
