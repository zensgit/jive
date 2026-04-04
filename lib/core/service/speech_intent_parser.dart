class SpeechIntent {
  final String rawText;
  final String? cleanedText;
  final double? amount;
  final DateTime timestamp;
  final String? type;
  final String? accountHint;
  final String? toAccountHint;

  const SpeechIntent({
    required this.rawText,
    required this.cleanedText,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.accountHint,
    required this.toAccountHint,
  });

  bool get isValid => amount != null && amount! > 0;
}

class SpeechIntentParser {
  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '转到',
    '转给',
    '还款',
    '还给',
    '还钱',
    '还信用卡',
    '充值',
    '提现',
  ];

  static const _incomeKeywords = [
    '收入',
    '到账',
    '收款',
    '工资',
    '退款',
    '返现',
    '报销',
    '补贴',
    '奖金',
    '红包',
    '收到',
    '入账',
    '赚了',
    '卖了',
    '分红',
    '利息',
    '中奖',
    '兼职',
    '稿费',
  ];

  static const _expenseKeywords = [
    '支出',
    '消费',
    '花了',
    '用了',
    '买了',
    '付了',
    '吃了',
    '打车',
    '打的',
    '加油',
    '充了',
    '交了',
    '缴费',
    '水电',
    '房租',
    '外卖',
    '点了',
    '订了',
    '看了',
    '修了',
    '剪了',
    '洗了',
    '停车',
  ];

  static const _cleanupTokens = [
    '记账',
    '记一笔',
    '记录',
    '帮我',
    '帮忙',
    '请帮我',
    '请帮忙',
    '一下',
  ];

  SpeechIntent? parse(
    String text, {
    DateTime? now,
    List<String> accountNames = const [],
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final baseTime = now ?? DateTime.now();
    final timeMatch = _extractTimestamp(trimmed, baseTime);
    final amountMatch = _extractAmount(trimmed);
    final type = _inferType(trimmed);
    final accountHints = _extractAccountHints(
      trimmed,
      accountNames: accountNames,
      isTransfer: type == 'transfer',
    );

    final cleaned = _cleanText(
      trimmed,
      amountToken: amountMatch.token,
      timeTokens: timeMatch.tokens,
      type: type,
    );

    return SpeechIntent(
      rawText: trimmed,
      cleanedText: cleaned,
      amount: amountMatch.value,
      timestamp: timeMatch.timestamp,
      type: type,
      accountHint: accountHints.from,
      toAccountHint: accountHints.to,
    );
  }

  _AmountMatch _extractAmount(String text) {
    final decimalWithUnit = RegExp(r'(\d+)\s*(块|元)\s*(\d+)');
    final decimalMatches = decimalWithUnit.allMatches(text).toList();
    if (decimalMatches.isNotEmpty) {
      final match = decimalMatches.last;
      final integerPart = match.group(1);
      final fractionPart = match.group(3);
      if (integerPart != null && fractionPart != null) {
        final value = double.tryParse('$integerPart.$fractionPart');
        if (value != null) {
          return _AmountMatch(value.abs(), match.group(0));
        }
      }
    }

    final numericWithUnit = RegExp(r'(\d+(?:\.\d+)?)\s*(元|块|毛|角|分)');
    final unitMatches = numericWithUnit.allMatches(text).toList();
    if (unitMatches.isNotEmpty) {
      final match = unitMatches.last;
      final token = match.group(1);
      final unit = match.group(2);
      if (token != null) {
        final value = _applyUnit(double.tryParse(token), unit);
        if (value != null) {
          return _AmountMatch(value.abs(), match.group(0));
        }
      }
    }

    final numeric = RegExp(r'(\d+(?:\.\d+)?)');
    final numericMatches = numeric.allMatches(text).toList();
    if (numericMatches.isNotEmpty) {
      final match = numericMatches.last;
      final token = match.group(1);
      if (token != null) {
        final value = double.tryParse(token);
        if (value != null) {
          return _AmountMatch(value.abs(), token);
        }
      }
    }

    final normalized = _normalizeChineseAmount(text);
    final chineseDecimal = RegExp(r'([零一二两三四五六七八九十百千万]+)\s*(块|元)\s*([零一二两三四五六七八九]+)');
    final chineseDecimalMatches = chineseDecimal.allMatches(normalized).toList();
    if (chineseDecimalMatches.isNotEmpty) {
      final match = chineseDecimalMatches.last;
      final integerToken = match.group(1);
      final fractionToken = match.group(3);
      if (integerToken != null && fractionToken != null) {
        final integerValue = _chineseToInt(integerToken);
        final fractionValue = _chineseFraction(fractionToken);
        return _AmountMatch(integerValue + fractionValue, match.group(0));
      }
    }

    final chineseWithUnit = RegExp(r'([零一二两三四五六七八九十百千万点]+)\s*(元|块|毛|角|分)');
    final chineseUnitMatches = chineseWithUnit.allMatches(normalized).toList();
    if (chineseUnitMatches.isNotEmpty) {
      final match = chineseUnitMatches.last;
      final token = match.group(1);
      final unit = match.group(2);
      if (token != null) {
        final value = _applyUnit(_chineseToDouble(token), unit);
        return _AmountMatch(value, match.group(0));
      }
    }

    final chinese = RegExp(r'[零一二两三四五六七八九十百千万点]+');
    final chineseMatches = chinese.allMatches(normalized).toList();
    if (chineseMatches.isNotEmpty) {
      final match = chineseMatches.last;
      final token = match.group(0);
      if (token != null) {
        final value = _chineseToDouble(token);
        return _AmountMatch(value, token);
      }
    }

    return const _AmountMatch(null, null);
  }

  _TimeMatch _extractTimestamp(String text, DateTime now) {
    final tokens = <String>[];
    DateTime timestamp = now;

    final fullDate = RegExp(r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?');
    final fullMatch = fullDate.firstMatch(text);
    if (fullMatch != null) {
      final year = int.tryParse(fullMatch.group(1) ?? '');
      final month = int.tryParse(fullMatch.group(2) ?? '');
      final day = int.tryParse(fullMatch.group(3) ?? '');
      if (year != null && month != null && day != null) {
        timestamp = DateTime(year, month, day, now.hour, now.minute, now.second);
        tokens.add(fullMatch.group(0)!);
        return _TimeMatch(timestamp, tokens);
      }
    }

    final shortDate = RegExp(r'(\d{1,2})[-/月](\d{1,2})日?');
    final shortMatch = shortDate.firstMatch(text);
    if (shortMatch != null) {
      final month = int.tryParse(shortMatch.group(1) ?? '');
      final day = int.tryParse(shortMatch.group(2) ?? '');
      if (month != null && day != null) {
        timestamp = DateTime(now.year, month, day, now.hour, now.minute, now.second);
        tokens.add(shortMatch.group(0)!);
        return _TimeMatch(timestamp, tokens);
      }
    }

    const relativeMap = {
      '今天': 0,
      '昨日': -1,
      '昨天': -1,
      '前天': -2,
      '明天': 1,
      '后天': 2,
    };

    for (final entry in relativeMap.entries) {
      if (text.contains(entry.key)) {
        timestamp = DateTime(
          now.year,
          now.month,
          now.day + entry.value,
          now.hour,
          now.minute,
          now.second,
        );
        tokens.add(entry.key);
        break;
      }
    }

    return _TimeMatch(timestamp, tokens);
  }

  String? _inferType(String text) {
    final normalized = _normalizeText(text);
    if (_containsAny(normalized, _transferKeywords)) return 'transfer';
    if (_containsAny(normalized, _incomeKeywords)) return 'income';
    if (_containsAny(normalized, _expenseKeywords)) return 'expense';
    return null;
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  _AccountHints _extractAccountHints(
    String text, {
    required List<String> accountNames,
    required bool isTransfer,
  }) {
    final aliasMap = _buildAliasMap(accountNames);
    if (aliasMap.isEmpty) {
      return const _AccountHints(null, null);
    }

    var from = _matchAccountWithMarker(
      text,
      aliasMap: aliasMap,
      markers: const ['从', '由', '转出'],
    );
    var to = _matchAccountWithMarker(
      text,
      aliasMap: aliasMap,
      markers: const ['到', '转到', '转入', '转进'],
    );

    if (from != null || to != null) {
      if (isTransfer && (from == null || to == null)) {
        final matches = _findAccountMatches(text, aliasMap);
        for (final name in matches) {
          if (from == null && name != to) {
            from = name;
          } else if (to == null && name != from) {
            to = name;
          }
          if (from != null && to != null) break;
        }
      }
      return _AccountHints(from, to);
    }

    final matches = _findAccountMatches(text, aliasMap);
    if (matches.isEmpty) {
      return const _AccountHints(null, null);
    }

    if (isTransfer && matches.length >= 2) {
      return _AccountHints(matches.first, matches[1]);
    }

    return _AccountHints(matches.first, null);
  }

  Map<String, String> _buildAliasMap(List<String> accountNames) {
    final aliasMap = <String, String>{};
    for (final name in accountNames) {
      final aliases = _accountAliases(name);
      for (final alias in aliases) {
        if (alias.isEmpty) continue;
        aliasMap[alias] = name;
      }
    }
    if (!aliasMap.containsKey('现金')) {
      aliasMap['现金'] = '现金';
    }
    if (!aliasMap.containsKey('银行卡')) {
      aliasMap['银行卡'] = '银行卡';
    }
    if (!aliasMap.containsKey('微信')) {
      aliasMap['微信'] = '微信';
    }
    if (!aliasMap.containsKey('支付宝')) {
      aliasMap['支付宝'] = '支付宝';
    }
    if (!aliasMap.containsKey('信用卡')) {
      aliasMap['信用卡'] = '信用卡';
    }
    return aliasMap;
  }

  List<String> _accountAliases(String name) {
    final aliases = <String>{name};
    final trimmed = name.replaceAll(RegExp(r'(钱包|账户|帐户)$'), '');
    if (trimmed.length >= 2 && trimmed != name) {
      aliases.add(trimmed);
    }
    if (name.contains('微信')) aliases.add('微信');
    if (name.contains('支付宝')) aliases.add('支付宝');
    if (name.contains('现金')) aliases.add('现金');
    if (name.contains('银行卡') || name.contains('银行')) aliases.add('银行卡');
    if (name.contains('信用卡')) aliases.add('信用卡');
    return aliases.toList();
  }

  String? _matchAccountWithMarker(
    String text, {
    required Map<String, String> aliasMap,
    required List<String> markers,
  }) {
    String? bestAlias;
    for (final marker in markers) {
      for (final alias in aliasMap.keys) {
        if (text.contains('$marker$alias')) {
          if (bestAlias == null || alias.length > bestAlias.length) {
            bestAlias = alias;
          }
        }
      }
    }
    return bestAlias == null ? null : aliasMap[bestAlias];
  }

  List<String> _findAccountMatches(String text, Map<String, String> aliasMap) {
    final matches = <_AccountHit>[];
    for (final entry in aliasMap.entries) {
      final index = text.indexOf(entry.key);
      if (index >= 0) {
        matches.add(_AccountHit(entry.value, entry.key, index));
      }
    }
    matches.sort((a, b) {
      if (a.index != b.index) return a.index.compareTo(b.index);
      return b.alias.length.compareTo(a.alias.length);
    });
    final result = <String>[];
    final seen = <String>{};
    for (final match in matches) {
      if (seen.add(match.name)) {
        result.add(match.name);
      }
    }
    return result;
  }

  String? _cleanText(
    String text, {
    String? amountToken,
    List<String> timeTokens = const [],
    String? type,
  }) {
    var cleaned = text;
    if (amountToken != null && amountToken.isNotEmpty) {
      cleaned = cleaned.replaceAll(amountToken, '');
    }
    for (final token in timeTokens) {
      cleaned = cleaned.replaceAll(token, '');
    }
    for (final token in _cleanupTokens) {
      cleaned = cleaned.replaceAll(token, '');
    }
    if (type == 'income') {
      cleaned = cleaned.replaceAll('收入', '');
    } else if (type == 'expense') {
      cleaned = cleaned.replaceAll('支出', '');
    } else if (type == 'transfer') {
      cleaned = cleaned.replaceAll('转账', '');
    }
    cleaned = cleaned.replaceAll(RegExp(r'[，,。]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[\s`~!@#$%^&*()+=|{}\[\]:;,.<>/?，。！？、【】（）《》""''￥…—-]"), '');
  }

  String _normalizeChineseAmount(String text) {
    return text.replaceAllMapped(
      RegExp(r'(块|元)([一二两三四五六七八九])(?!毛|角|分)'),
      (match) => '点${match.group(2)}',
    );
  }

  double? _applyUnit(double? value, String? unit) {
    if (value == null) return null;
    switch (unit) {
      case '毛':
      case '角':
        return value / 10;
      case '分':
        return value / 100;
    }
    return value;
  }

  double _chineseToDouble(String text) {
    final parts = text.split('点');
    final integer = _chineseToInt(parts.first);
    if (parts.length == 1) return integer.toDouble();
    final fraction = _chineseFraction(parts[1]);
    return integer + fraction;
  }

  double _chineseFraction(String text) {
    final buffer = StringBuffer('0.');
    for (final char in text.split('')) {
      final digit = _chineseDigit(char);
      if (digit == null) continue;
      buffer.write(digit);
    }
    return double.tryParse(buffer.toString()) ?? 0;
  }

  int _chineseToInt(String text) {
    var result = 0;
    var section = 0;
    var number = 0;
    for (final char in text.split('')) {
      final digit = _chineseDigit(char);
      if (digit != null) {
        number = digit;
        continue;
      }
      final unit = _chineseUnit(char);
      if (unit == null) {
        continue;
      }
      if (unit == 10000) {
        section = (section + number) * unit;
        result += section;
        section = 0;
        number = 0;
      } else {
        if (number == 0) number = 1;
        section += number * unit;
        number = 0;
      }
    }
    return result + section + number;
  }

  int? _chineseDigit(String char) {
    switch (char) {
      case '零':
        return 0;
      case '一':
        return 1;
      case '二':
        return 2;
      case '两':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      case '七':
        return 7;
      case '八':
        return 8;
      case '九':
        return 9;
    }
    return null;
  }

  int? _chineseUnit(String char) {
    switch (char) {
      case '十':
        return 10;
      case '百':
        return 100;
      case '千':
        return 1000;
      case '万':
        return 10000;
    }
    return null;
  }
}

class _AmountMatch {
  final double? value;
  final String? token;

  const _AmountMatch(this.value, this.token);
}

class _TimeMatch {
  final DateTime timestamp;
  final List<String> tokens;

  const _TimeMatch(this.timestamp, this.tokens);
}

class _AccountHints {
  final String? from;
  final String? to;

  const _AccountHints(this.from, this.to);
}

class _AccountHit {
  final String name;
  final String alias;
  final int index;

  const _AccountHit(this.name, this.alias, this.index);
}
