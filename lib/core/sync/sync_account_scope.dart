class SyncAccountScope {
  final Map<int, String> accountKeyById;
  final Map<String, int> accountIdByKey;

  const SyncAccountScope({
    required this.accountKeyById,
    required this.accountIdByKey,
  });

  String? accountKey(int? accountId) {
    if (accountId == null) return null;
    return accountKeyById[accountId];
  }

  int? accountId(
    String? accountKey, {
    int? fallbackAccountId,
  }) {
    final normalized = _normalize(accountKey);
    if (normalized == null) return fallbackAccountId;
    return accountIdByKey[normalized] ?? fallbackAccountId;
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
