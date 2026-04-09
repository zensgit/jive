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
    return _bookKeyOrDefault(bookId);
  }

  String accountBookKey(int? bookId) {
    return _bookKeyOrDefault(bookId);
  }

  String? budgetBookKey(int? bookId) {
    if (bookId == null) return null;
    return bookKeyById[bookId];
  }

  int? transactionBookId(String? bookKey, {int? fallbackBookId}) {
    return _bookIdOrDefault(bookKey, fallbackBookId: fallbackBookId);
  }

  int? accountBookId(String? bookKey, {int? fallbackBookId}) {
    return _bookIdOrDefault(bookKey, fallbackBookId: fallbackBookId);
  }

  int? budgetBookId(String? bookKey, {int? fallbackBookId}) {
    final normalized = _normalize(bookKey);
    if (normalized == null) return fallbackBookId;
    return bookIdByKey[normalized] ?? fallbackBookId;
  }

  String sharedLedgerWorkspaceKey(String? workspaceKey) {
    return _normalize(workspaceKey) ?? defaultBookKey;
  }

  String _bookKeyOrDefault(int? bookId) {
    if (bookId == null) return defaultBookKey;
    return bookKeyById[bookId] ?? defaultBookKey;
  }

  int? _bookIdOrDefault(String? bookKey, {int? fallbackBookId}) {
    final normalized = _normalize(bookKey);
    if (normalized == null) {
      return fallbackBookId ?? defaultBookId;
    }
    return bookIdByKey[normalized] ?? fallbackBookId ?? defaultBookId;
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
