class SyncBookScope {
  final Map<int, String> bookKeyById;
  final Map<String, int> bookIdByKey;
  final int? defaultBookId;
  final String defaultBookKey;

  const SyncBookScope({
    required this.bookKeyById,
    required this.bookIdByKey,
    required this.defaultBookId,
    required this.defaultBookKey,
  });

  String transactionBookKey(int? bookId) {
    if (bookId == null) return defaultBookKey;
    return bookKeyById[bookId] ?? defaultBookKey;
  }

  String accountBookKey(int? bookId) {
    if (bookId == null) return defaultBookKey;
    return bookKeyById[bookId] ?? defaultBookKey;
  }

  String? budgetBookKey(int? bookId) {
    if (bookId == null) return null;
    return bookKeyById[bookId];
  }

  int? transactionBookId(String? bookKey, {int? fallbackBookId}) {
    final normalized = _normalize(bookKey);
    if (normalized == null) {
      return fallbackBookId ?? defaultBookId;
    }
    return bookIdByKey[normalized] ?? fallbackBookId ?? defaultBookId;
  }

  int? accountBookId(String? bookKey, {int? fallbackBookId}) {
    final normalized = _normalize(bookKey);
    if (normalized == null) {
      return fallbackBookId ?? defaultBookId;
    }
    return bookIdByKey[normalized] ?? fallbackBookId ?? defaultBookId;
  }

  int? budgetBookId(String? bookKey, {int? fallbackBookId}) {
    final normalized = _normalize(bookKey);
    if (normalized == null) return fallbackBookId;
    return bookIdByKey[normalized] ?? fallbackBookId;
  }

  String sharedLedgerWorkspaceKey(String? workspaceKey) {
    return _normalize(workspaceKey) ?? defaultBookKey;
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
