import 'speech_intent_parser.dart';

/// A single parsed transaction extracted from natural language.
class ParsedTransaction {
  double amount;
  String type; // expense | income | transfer
  String? category;
  String? subCategory;
  DateTime date;
  String? note;
  String? accountHint;
  int? splitCount;
  List<String> participants;

  ParsedTransaction({
    required this.amount,
    required this.type,
    this.category,
    this.subCategory,
    required this.date,
    this.note,
    this.accountHint,
    this.splitCount,
    this.participants = const [],
  });

  ParsedTransaction copyWith({
    double? amount,
    String? type,
    String? category,
    String? subCategory,
    DateTime? date,
    String? note,
    String? accountHint,
    int? splitCount,
    List<String>? participants,
  }) {
    return ParsedTransaction(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      note: note ?? this.note,
      accountHint: accountHint ?? this.accountHint,
      splitCount: splitCount ?? this.splitCount,
      participants: participants ?? this.participants,
    );
  }
}

/// Result from parsing a conversational input.
class ConversationResult {
  final List<ParsedTransaction> transactions;
  final String rawText;

  const ConversationResult({
    required this.transactions,
    required this.rawText,
  });

  bool get isEmpty => transactions.isEmpty;
  bool get isNotEmpty => transactions.isNotEmpty;
}

/// Enhanced NLP parser that converts natural language into structured
/// transactions. Handles AA splitting, multiple items, relative dates,
/// account hints, and category inference from keywords.
class ConversationalParser {
  final SpeechIntentParser _intentParser = SpeechIntentParser();

  // ----- Category inference keyword map -----
  static const Map<String, _CategoryInfo> _categoryKeywords = {
    // 餐饮
    '吃饭': _CategoryInfo('餐饮'),
    '餐厅': _CategoryInfo('餐饮'),
    '饭店': _CategoryInfo('餐饮'),
    '火锅': _CategoryInfo('餐饮', '聚餐'),
    '烧烤': _CategoryInfo('餐饮', '聚餐'),
    '外卖': _CategoryInfo('餐饮', '外卖'),
    '点餐': _CategoryInfo('餐饮', '外卖'),
    '早餐': _CategoryInfo('餐饮', '早餐'),
    '午餐': _CategoryInfo('餐饮', '午餐'),
    '晚餐': _CategoryInfo('餐饮', '晚餐'),
    '宵夜': _CategoryInfo('餐饮', '夜宵'),
    '夜宵': _CategoryInfo('餐饮', '夜宵'),
    '奶茶': _CategoryInfo('餐饮', '饮品'),
    '咖啡': _CategoryInfo('餐饮', '饮品'),
    '饮料': _CategoryInfo('餐饮', '饮品'),
    '水果': _CategoryInfo('餐饮', '水果'),
    '零食': _CategoryInfo('餐饮', '零食'),
    '面包': _CategoryInfo('餐饮', '零食'),
    '蛋糕': _CategoryInfo('餐饮', '零食'),
    '快餐': _CategoryInfo('餐饮', '快餐'),
    '食堂': _CategoryInfo('餐饮', '食堂'),
    '聚餐': _CategoryInfo('餐饮', '聚餐'),
    // 交通
    '打车': _CategoryInfo('交通', '打车'),
    '出租车': _CategoryInfo('交通', '打车'),
    '网约车': _CategoryInfo('交通', '打车'),
    '地铁': _CategoryInfo('交通', '公共交通'),
    '公交': _CategoryInfo('交通', '公共交通'),
    '高铁': _CategoryInfo('交通', '火车'),
    '火车': _CategoryInfo('交通', '火车'),
    '飞机': _CategoryInfo('交通', '机票'),
    '机票': _CategoryInfo('交通', '机票'),
    '加油': _CategoryInfo('交通', '加油'),
    '停车': _CategoryInfo('交通', '停车'),
    '过路费': _CategoryInfo('交通', '过路费'),
    // 娱乐
    '电影': _CategoryInfo('娱乐', '电影'),
    '游戏': _CategoryInfo('娱乐', '游戏'),
    'KTV': _CategoryInfo('娱乐', 'KTV'),
    '唱歌': _CategoryInfo('娱乐', 'KTV'),
    '演唱会': _CategoryInfo('娱乐', '演出'),
    '演出': _CategoryInfo('娱乐', '演出'),
    '旅游': _CategoryInfo('娱乐', '旅游'),
    '门票': _CategoryInfo('娱乐', '门票'),
    '景点': _CategoryInfo('娱乐', '门票'),
    // 购物
    '超市': _CategoryInfo('购物', '超市'),
    '商场': _CategoryInfo('购物'),
    '网购': _CategoryInfo('购物', '网购'),
    '淘宝': _CategoryInfo('购物', '网购'),
    '京东': _CategoryInfo('购物', '网购'),
    '拼多多': _CategoryInfo('购物', '网购'),
    '衣服': _CategoryInfo('购物', '服饰'),
    '鞋子': _CategoryInfo('购物', '服饰'),
    '化妆品': _CategoryInfo('购物', '美妆'),
    '护肤品': _CategoryInfo('购物', '美妆'),
    '日用品': _CategoryInfo('购物', '日用'),
    // 居住
    '房租': _CategoryInfo('居住', '房租'),
    '水电': _CategoryInfo('居住', '水电'),
    '物业': _CategoryInfo('居住', '物业'),
    '燃气': _CategoryInfo('居住', '燃气'),
    '宽带': _CategoryInfo('居住', '通讯'),
    '话费': _CategoryInfo('居住', '通讯'),
    // 医疗
    '看病': _CategoryInfo('医疗'),
    '医院': _CategoryInfo('医疗'),
    '买药': _CategoryInfo('医疗', '药品'),
    '药店': _CategoryInfo('医疗', '药品'),
    '体检': _CategoryInfo('医疗', '体检'),
    // 教育
    '学费': _CategoryInfo('教育', '学费'),
    '培训': _CategoryInfo('教育', '培训'),
    '书': _CategoryInfo('教育', '书籍'),
    '课程': _CategoryInfo('教育', '课程'),
    // 人情
    '红包': _CategoryInfo('人情', '红包'),
    '礼物': _CategoryInfo('人情', '礼物'),
    '份子钱': _CategoryInfo('人情', '份子钱'),
    '请客': _CategoryInfo('人情', '请客'),
    // 运动
    '健身': _CategoryInfo('运动', '健身'),
    '瑜伽': _CategoryInfo('运动', '瑜伽'),
    '游泳': _CategoryInfo('运动', '游泳'),
  };

  // ----- Account hint keywords -----
  static const Map<String, String> _accountKeywords = {
    '信用卡': '信用卡',
    '花呗': '花呗',
    '微信': '微信',
    '支付宝': '支付宝',
    '现金': '现金',
    '银行卡': '银行卡',
    '储蓄卡': '银行卡',
    '借记卡': '银行卡',
  };

  // ----- Relative date patterns (extended) -----
  static const Map<String, int> _relativeDays = {
    '今天': 0,
    '昨天': -1,
    '昨日': -1,
    '前天': -2,
    '大前天': -3,
  };

  static const Map<String, int> _weekdayMap = {
    '一': 1,
    '二': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '日': 7,
    '天': 7,
  };

  /// Parse a natural language sentence into one or more transactions.
  ConversationResult parseConversation(String text, {DateTime? now}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const ConversationResult(transactions: [], rawText: '');
    }

    final baseTime = now ?? DateTime.now();

    // Try splitting into multiple items first.
    final segments = _splitMultipleItems(trimmed);
    if (segments.length > 1) {
      final transactions = <ParsedTransaction>[];
      for (final segment in segments) {
        final result = _parseSingle(segment, baseTime);
        if (result != null) {
          transactions.add(result);
        }
      }
      if (transactions.isNotEmpty) {
        return ConversationResult(
          transactions: transactions,
          rawText: trimmed,
        );
      }
    }

    // Parse as a single sentence (may still produce split via AA).
    final result = _parseSingle(trimmed, baseTime);
    if (result != null) {
      return ConversationResult(
        transactions: [result],
        rawText: trimmed,
      );
    }

    return ConversationResult(transactions: [], rawText: trimmed);
  }

  /// Attempt to split text like "买了咖啡30和面包15" into multiple segments.
  List<String> _splitMultipleItems(String text) {
    // Pattern: text+amount 和/、/， text+amount
    final multiPattern = RegExp(
      r'(.+?\d+(?:\.\d+)?(?:元|块)?)\s*[和与、，,]\s*(.+?\d+(?:\.\d+)?(?:元|块)?)',
    );
    final match = multiPattern.firstMatch(text);
    if (match != null) {
      final part1 = match.group(1)!.trim();
      final part2 = match.group(2)!.trim();
      // Propagate shared context (date, account) to second segment.
      final dateContext = _extractDateString(text);
      final accountContext = _extractAccountString(text);
      final prefix =
          '${dateContext ?? ''}${accountContext ?? ''}';
      return [
        part1,
        if (prefix.isNotEmpty) '$prefix$part2' else part2,
      ];
    }
    return [text];
  }

  String? _extractDateString(String text) {
    for (final key in _relativeDays.keys) {
      if (text.contains(key)) return key;
    }
    final weekPattern = RegExp(r'上*周[一二三四五六日天]');
    final weekMatch = weekPattern.firstMatch(text);
    if (weekMatch != null) return weekMatch.group(0);
    return null;
  }

  String? _extractAccountString(String text) {
    final accountPattern = RegExp(r'用(信用卡|花呗|微信|支付宝|现金|银行卡|储蓄卡|借记卡)');
    final match = accountPattern.firstMatch(text);
    if (match != null) return match.group(0);
    return null;
  }

  ParsedTransaction? _parseSingle(String text, DateTime baseTime) {
    // 1. Extract date.
    final date = _parseDate(text, baseTime);

    // 2. Detect AA splitting.
    final aaSplit = _parseAA(text);

    // 3. Extract amount using the existing SpeechIntentParser.
    final intent = _intentParser.parse(text, now: baseTime);
    double? rawAmount = intent?.amount;

    // Fallback: try simple number extraction if intent parser missed.
    if (rawAmount == null || rawAmount <= 0) {
      rawAmount = _extractSimpleAmount(text);
    }

    if (rawAmount == null || rawAmount <= 0) return null;

    // 4. Calculate final amount after AA split.
    double finalAmount = rawAmount;
    int? splitCount;
    if (aaSplit != null) {
      splitCount = aaSplit.count;
      finalAmount = rawAmount / splitCount;
      // Round to 2 decimal places.
      finalAmount = (finalAmount * 100).roundToDouble() / 100;
    }

    // 5. Infer type.
    final type = intent?.type ?? 'expense';

    // 6. Infer category from keywords.
    final categoryInfo = _inferCategory(text);

    // 7. Extract account hint.
    final accountHint = _extractAccountHint(text) ?? intent?.accountHint;

    // 8. Build note — use the cleaned text or derive from input.
    final note = _buildNote(text, intent?.cleanedText);

    // 9. Extract participants for AA.
    final participants = aaSplit?.participants ?? const <String>[];

    return ParsedTransaction(
      amount: finalAmount,
      type: type,
      category: categoryInfo?.parent,
      subCategory: categoryInfo?.sub,
      date: date,
      note: note,
      accountHint: accountHint,
      splitCount: splitCount,
      participants: participants,
    );
  }

  // ----- Date parsing with relative week support -----
  DateTime _parseDate(String text, DateTime now) {
    // Check relative days.
    for (final entry in _relativeDays.entries) {
      if (text.contains(entry.key)) {
        return DateTime(
          now.year,
          now.month,
          now.day + entry.value,
          now.hour,
          now.minute,
          now.second,
        );
      }
    }

    // Check "上周X" or "上上周X".
    final lastWeekPattern = RegExp(r'(上上?)周([一二三四五六日天])');
    final lastWeekMatch = lastWeekPattern.firstMatch(text);
    if (lastWeekMatch != null) {
      final prefix = lastWeekMatch.group(1)!;
      final dayChar = lastWeekMatch.group(2)!;
      final targetWeekday = _weekdayMap[dayChar] ?? 1;
      final weeksBack = prefix == '上上' ? 2 : 1;
      final currentWeekday = now.weekday;
      final daysBack =
          (currentWeekday - targetWeekday) + (weeksBack * 7);
      return DateTime(
        now.year,
        now.month,
        now.day - daysBack,
        now.hour,
        now.minute,
        now.second,
      );
    }

    // Check "周X" (this week).
    final thisWeekPattern = RegExp(r'(?<!上)周([一二三四五六日天])');
    final thisWeekMatch = thisWeekPattern.firstMatch(text);
    if (thisWeekMatch != null) {
      final dayChar = thisWeekMatch.group(1)!;
      final targetWeekday = _weekdayMap[dayChar] ?? 1;
      final currentWeekday = now.weekday;
      final diff = targetWeekday - currentWeekday;
      return DateTime(
        now.year,
        now.month,
        now.day + diff,
        now.hour,
        now.minute,
        now.second,
      );
    }

    // Fall back to SpeechIntentParser date handling.
    final intent = _intentParser.parse(text, now: now);
    return intent?.timestamp ?? now;
  }

  // ----- AA split detection -----
  _AASplit? _parseAA(String text) {
    // Pattern: "AA了200" or "AA 200" or "AA制"
    if (!text.contains('AA') && !text.contains('aa') && !text.contains('Aa')) {
      return null;
    }

    // Count participants.
    int count = 2; // Default: 2 people.

    // "三个人AA" or "3个人AA"
    final countPattern = RegExp(r'([二三四五六七八九十]|[2-9]\d*)\s*个人?\s*[Aa]{2}');
    final countMatch = countPattern.firstMatch(text);
    if (countMatch != null) {
      final numStr = countMatch.group(1)!;
      final parsed = _parseChineseOrDigit(numStr);
      if (parsed != null && parsed > 1) count = parsed;
    }

    // "和两个朋友" → 2 friends + me = 3 people.
    final friendPattern = RegExp(r'和\s*([两二三四五六七八九十]|\d+)\s*个?\s*(朋友|同事|同学|人|好友|室友)');
    final friendMatch = friendPattern.firstMatch(text);
    if (friendMatch != null && countMatch == null) {
      final numStr = friendMatch.group(1)!;
      final parsed = _parseChineseOrDigit(numStr);
      if (parsed != null && parsed >= 1) count = parsed + 1; // +1 for self.
    }

    // "和朋友AA" → default 2.
    final simplePattern = RegExp(r'和\s*(朋友|同事|同学|好友|室友)\s*.*[Aa]{2}');
    if (simplePattern.hasMatch(text) && countMatch == null && friendMatch == null) {
      count = 2;
    }

    // Extract participant names if present.
    final participants = <String>[];
    final namePattern = RegExp(r'和\s*([^\d\s,，、]{1,4}(?:[,，、][^\d\s,，、]{1,4})*)');
    final nameMatch = namePattern.firstMatch(text);
    if (nameMatch != null) {
      final names = nameMatch.group(1)!.split(RegExp(r'[,，、]'));
      for (final name in names) {
        final trimmed = name.trim();
        // Filter out common non-name words.
        if (trimmed.isNotEmpty &&
            !_isCommonWord(trimmed) &&
            trimmed.length <= 4) {
          participants.add(trimmed);
        }
      }
    }

    return _AASplit(count: count, participants: participants);
  }

  bool _isCommonWord(String word) {
    const common = {
      '朋友', '同事', '同学', '好友', '室友', '个人', '个',
      '一起', '一块', '人', '大家',
    };
    return common.contains(word);
  }

  int? _parseChineseOrDigit(String s) {
    final digit = int.tryParse(s);
    if (digit != null) return digit;
    const map = {
      '两': 2, '二': 2, '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
    };
    return map[s];
  }

  // ----- Simple amount extraction fallback -----
  double? _extractSimpleAmount(String text) {
    final pattern = RegExp(r'(\d+(?:\.\d+)?)\s*(元|块)?');
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return null;
    final match = matches.last;
    return double.tryParse(match.group(1) ?? '');
  }

  // ----- Category inference -----
  _CategoryInfo? _inferCategory(String text) {
    _CategoryInfo? best;
    int bestIndex = text.length;
    for (final entry in _categoryKeywords.entries) {
      final idx = text.indexOf(entry.key);
      if (idx >= 0 && idx < bestIndex) {
        bestIndex = idx;
        best = entry.value;
      }
    }
    return best;
  }

  // ----- Account hint extraction -----
  String? _extractAccountHint(String text) {
    // "用信用卡" pattern.
    final usePattern = RegExp(r'用(信用卡|花呗|微信|支付宝|现金|银行卡|储蓄卡|借记卡)');
    final useMatch = usePattern.firstMatch(text);
    if (useMatch != null) {
      final keyword = useMatch.group(1)!;
      return _accountKeywords[keyword] ?? keyword;
    }

    // Direct mention without "用".
    for (final entry in _accountKeywords.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // ----- Note construction -----
  String? _buildNote(String text, String? cleanedText) {
    // Remove common filler words and amounts to build a clean note.
    var note = text;
    // Remove date tokens.
    for (final key in _relativeDays.keys) {
      note = note.replaceAll(key, '');
    }
    note = note.replaceAll(RegExp(r'上*周[一二三四五六日天]'), '');
    // Remove AA tokens.
    note = note.replaceAll(RegExp(r'[Aa]{2}了?制?'), '');
    // Remove amount tokens.
    note = note.replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(元|块)?'), '');
    // Remove account hints.
    note = note.replaceAll(RegExp(r'用(信用卡|花呗|微信|支付宝|现金|银行卡|储蓄卡|借记卡)'), '');
    // Remove filler words.
    const fillers = ['记账', '记一笔', '记录', '帮我', '帮忙', '请帮我', '请帮忙', '一下', '花了', '买了', '付了', '了'];
    for (final f in fillers) {
      note = note.replaceAll(f, '');
    }
    note = note.replaceAll(RegExp(r'[，,。、\s]+'), ' ').trim();

    if (note.isNotEmpty) return note;
    return cleanedText;
  }
}

class _CategoryInfo {
  final String parent;
  final String? sub;

  const _CategoryInfo(this.parent, [this.sub]);
}

class _AASplit {
  final int count;
  final List<String> participants;

  const _AASplit({required this.count, this.participants = const []});
}
