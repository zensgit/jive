class AutoDraftTypeHints {
  const AutoDraftTypeHints._();

  static const incomeKeywords = ['已收款', '已收到', '到账', '退款', '赔付'];

  static const transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  static String? normalizeType(String? rawType) {
    if (rawType == null) return null;
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'expense' ||
        normalized == 'income' ||
        normalized == 'transfer') {
      return normalized;
    }
    return null;
  }

  static String? inferFromText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return null;
    for (final keyword in incomeKeywords) {
      if (rawText.contains(keyword)) return 'income';
    }
    for (final keyword in transferKeywords) {
      if (rawText.contains(keyword)) return 'transfer';
    }
    return null;
  }

  static String? preferType(String? normalizedType, String? inferredType) {
    if (inferredType == 'transfer' && normalizedType != 'transfer') {
      return 'transfer';
    }
    return normalizedType ?? inferredType;
  }

  static bool looksLikeTransferText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    for (final keyword in transferKeywords) {
      if (rawText.contains(keyword)) return true;
    }
    return false;
  }
}
