/// Enhanced parser for WeChat, Alipay and bank payment notifications.
///
/// Extracts structured [PaymentNotification] data from raw notification text.
library;

enum PaymentType { income, expense }

enum PaymentSource { wechat, alipay, bank, unknown }

class PaymentNotification {
  final double amount;
  final PaymentType type;
  final String? merchant;
  final PaymentSource source;
  final String rawText;
  final DateTime timestamp;

  const PaymentNotification({
    required this.amount,
    required this.type,
    this.merchant,
    required this.source,
    required this.rawText,
    required this.timestamp,
  });

  bool get isValid => amount > 0;

  String get typeLabel => type == PaymentType.income ? 'income' : 'expense';

  String get sourceLabel {
    switch (source) {
      case PaymentSource.wechat:
        return 'WeChat';
      case PaymentSource.alipay:
        return 'Alipay';
      case PaymentSource.bank:
        return 'Bank';
      case PaymentSource.unknown:
        return 'Unknown';
    }
  }
}

class PaymentNotificationParser {
  PaymentNotificationParser._();

  // ---------------------------------------------------------------------------
  // WeChat patterns
  // ---------------------------------------------------------------------------

  static final _wechatExpense = RegExp(
    r'微信支付\s*付款\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _wechatIncome = RegExp(
    r'微信支付\s*收款\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _wechatPayTo = RegExp(
    r'已付款\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)\s*给\s*(.+)',
  );

  /// Parse a WeChat payment notification.
  static PaymentNotification? parseWeChatNotification(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Income – 收款
    final incomeMatch = _wechatIncome.firstMatch(trimmed);
    if (incomeMatch != null) {
      final amount = double.tryParse(incomeMatch.group(1) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.income,
          merchant: _extractWeChatMerchant(trimmed),
          source: PaymentSource.wechat,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – 付款给xxx
    final payToMatch = _wechatPayTo.firstMatch(trimmed);
    if (payToMatch != null) {
      final amount = double.tryParse(payToMatch.group(1) ?? '');
      final merchant = payToMatch.group(2)?.trim();
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          merchant: merchant,
          source: PaymentSource.wechat,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – generic 付款
    final expenseMatch = _wechatExpense.firstMatch(trimmed);
    if (expenseMatch != null) {
      final amount = double.tryParse(expenseMatch.group(1) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          merchant: _extractWeChatMerchant(trimmed),
          source: PaymentSource.wechat,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  static final _wechatMerchantPattern = RegExp(r'(?:在|向)\s*(.+?)(?:\s*付款|\s*支付|$)');

  static String? _extractWeChatMerchant(String text) {
    final match = _wechatMerchantPattern.firstMatch(text);
    final merchant = match?.group(1)?.trim();
    if (merchant != null && merchant.isNotEmpty) return merchant;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Alipay patterns
  // ---------------------------------------------------------------------------

  static final _alipayExpense = RegExp(
    r'支付宝\s*付款成功\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _alipayTransfer = RegExp(
    r'收到\s*(.+?)\s*转账\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _alipayConsume = RegExp(
    r'(.+?)\s*消费\s*[¥￥]\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );

  /// Parse an Alipay payment notification.
  static PaymentNotification? parseAlipayNotification(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Income – transfer received
    final transferMatch = _alipayTransfer.firstMatch(trimmed);
    if (transferMatch != null) {
      final sender = transferMatch.group(1)?.trim();
      final amount = double.tryParse(transferMatch.group(2) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.income,
          merchant: sender,
          source: PaymentSource.alipay,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – 付款成功
    final expenseMatch = _alipayExpense.firstMatch(trimmed);
    if (expenseMatch != null) {
      final amount = double.tryParse(expenseMatch.group(1) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          source: PaymentSource.alipay,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – consume
    final consumeMatch = _alipayConsume.firstMatch(trimmed);
    if (consumeMatch != null) {
      final merchant = consumeMatch.group(1)?.trim();
      final amount = double.tryParse(consumeMatch.group(2) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          merchant: merchant,
          source: PaymentSource.alipay,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Bank notification patterns
  // ---------------------------------------------------------------------------

  static const _majorBanks = ['工商', '建设', '农业', '中国', '招商', '交通'];

  static final _bankCardConsume = RegExp(
    r'您尾号(\d{4})的储蓄卡.*?消费\s*[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _bankExpenseGeneric = RegExp(
    r'(?:工商|建设|农业|中国|招商|交通)银行.*?支出.*?[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );
  static final _bankIncomeGeneric = RegExp(
    r'(?:工商|建设|农业|中国|招商|交通)银行.*?(?:收入|到账|入账).*?[¥￥]?\s*([0-9]+(?:\.[0-9]{1,2})?)',
  );

  /// Parse a bank SMS notification.
  static PaymentNotification? parseBankNotification(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Check if text references a known bank
    final hasBankKeyword =
        _majorBanks.any((b) => trimmed.contains(b)) || trimmed.contains('尾号');
    if (!hasBankKeyword) return null;

    // Income
    final incomeMatch = _bankIncomeGeneric.firstMatch(trimmed);
    if (incomeMatch != null) {
      final amount = double.tryParse(incomeMatch.group(1) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.income,
          merchant: _extractBankName(trimmed),
          source: PaymentSource.bank,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – card consume
    final cardMatch = _bankCardConsume.firstMatch(trimmed);
    if (cardMatch != null) {
      final amount = double.tryParse(cardMatch.group(2) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          merchant: _extractBankName(trimmed),
          source: PaymentSource.bank,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    // Expense – generic bank
    final genericMatch = _bankExpenseGeneric.firstMatch(trimmed);
    if (genericMatch != null) {
      final amount = double.tryParse(genericMatch.group(1) ?? '');
      if (amount != null && amount > 0) {
        return PaymentNotification(
          amount: amount,
          type: PaymentType.expense,
          merchant: _extractBankName(trimmed),
          source: PaymentSource.bank,
          rawText: trimmed,
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  static String? _extractBankName(String text) {
    for (final bank in _majorBanks) {
      if (text.contains(bank)) return '$bank银行';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Unified entry point
  // ---------------------------------------------------------------------------

  /// Try all parsers in order: WeChat, Alipay, Bank.
  static PaymentNotification? parse(String text) {
    return parseWeChatNotification(text) ??
        parseAlipayNotification(text) ??
        parseBankNotification(text);
  }
}
