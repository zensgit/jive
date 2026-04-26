import 'package:jive/core/service/import_service.dart';

class ImportCsvColumnMapping {
  const ImportCsvColumnMapping({
    this.accountBookColumnIndex,
    this.assetColumnIndex,
    this.toAssetColumnIndex,
    this.categoryPathColumnIndex,
    this.parentCategoryColumnIndex,
    this.childCategoryColumnIndex,
    this.tagColumnIndex,
    this.serviceChargeColumnIndex,
    this.dateColumnIndex,
    this.amountColumnIndex,
    this.remarkColumnIndex,
    this.typeColumnIndex,
  });

  final int? accountBookColumnIndex;
  final int? assetColumnIndex;
  final int? toAssetColumnIndex;
  final int? categoryPathColumnIndex;
  final int? parentCategoryColumnIndex;
  final int? childCategoryColumnIndex;
  final int? tagColumnIndex;
  final int? serviceChargeColumnIndex;
  final int? dateColumnIndex;
  final int? amountColumnIndex;
  final int? remarkColumnIndex;
  final int? typeColumnIndex;

  ImportCsvColumnMapping copyWith({
    int? accountBookColumnIndex,
    bool clearAccountBookColumnIndex = false,
    int? assetColumnIndex,
    bool clearAssetColumnIndex = false,
    int? toAssetColumnIndex,
    bool clearToAssetColumnIndex = false,
    int? categoryPathColumnIndex,
    bool clearCategoryPathColumnIndex = false,
    int? parentCategoryColumnIndex,
    bool clearParentCategoryColumnIndex = false,
    int? childCategoryColumnIndex,
    bool clearChildCategoryColumnIndex = false,
    int? tagColumnIndex,
    bool clearTagColumnIndex = false,
    int? serviceChargeColumnIndex,
    bool clearServiceChargeColumnIndex = false,
    int? dateColumnIndex,
    bool clearDateColumnIndex = false,
    int? amountColumnIndex,
    bool clearAmountColumnIndex = false,
    int? remarkColumnIndex,
    bool clearRemarkColumnIndex = false,
    int? typeColumnIndex,
    bool clearTypeColumnIndex = false,
  }) {
    return ImportCsvColumnMapping(
      accountBookColumnIndex: clearAccountBookColumnIndex
          ? null
          : (accountBookColumnIndex ?? this.accountBookColumnIndex),
      assetColumnIndex: clearAssetColumnIndex
          ? null
          : (assetColumnIndex ?? this.assetColumnIndex),
      toAssetColumnIndex: clearToAssetColumnIndex
          ? null
          : (toAssetColumnIndex ?? this.toAssetColumnIndex),
      categoryPathColumnIndex: clearCategoryPathColumnIndex
          ? null
          : (categoryPathColumnIndex ?? this.categoryPathColumnIndex),
      parentCategoryColumnIndex: clearParentCategoryColumnIndex
          ? null
          : (parentCategoryColumnIndex ?? this.parentCategoryColumnIndex),
      childCategoryColumnIndex: clearChildCategoryColumnIndex
          ? null
          : (childCategoryColumnIndex ?? this.childCategoryColumnIndex),
      tagColumnIndex: clearTagColumnIndex
          ? null
          : (tagColumnIndex ?? this.tagColumnIndex),
      serviceChargeColumnIndex: clearServiceChargeColumnIndex
          ? null
          : (serviceChargeColumnIndex ?? this.serviceChargeColumnIndex),
      dateColumnIndex: clearDateColumnIndex
          ? null
          : (dateColumnIndex ?? this.dateColumnIndex),
      amountColumnIndex: clearAmountColumnIndex
          ? null
          : (amountColumnIndex ?? this.amountColumnIndex),
      remarkColumnIndex: clearRemarkColumnIndex
          ? null
          : (remarkColumnIndex ?? this.remarkColumnIndex),
      typeColumnIndex: clearTypeColumnIndex
          ? null
          : (typeColumnIndex ?? this.typeColumnIndex),
    );
  }
}

class ImportCsvMappingDraft {
  const ImportCsvMappingDraft({
    required this.headers,
    required this.hasHeader,
    required this.delimiter,
    required this.mapping,
  });

  final List<String> headers;
  final bool hasHeader;
  final String delimiter;
  final ImportCsvColumnMapping mapping;
}

class ImportCsvMappingService {
  ImportCsvMappingDraft inspect(String text) {
    final lines = _normalizedLines(text);
    if (lines.isEmpty) {
      return const ImportCsvMappingDraft(
        headers: <String>[],
        hasHeader: false,
        delimiter: ',',
        mapping: ImportCsvColumnMapping(),
      );
    }

    final delimiter = _guessDelimiter(lines.first);
    final firstCells = _splitDelimitedLine(lines.first, delimiter);
    final hasHeader = _looksLikeHeader(firstCells);
    final headerMap = hasHeader ? _buildHeaderMap(firstCells) : <String, int>{};

    return ImportCsvMappingDraft(
      headers: hasHeader ? firstCells : const <String>[],
      hasHeader: hasHeader,
      delimiter: delimiter,
      mapping: hasHeader
          ? _inferMappingFromHeaderMap(headerMap)
          : const ImportCsvColumnMapping(),
    );
  }

  List<ImportParsedRecord> parseWithMapping(
    String text, {
    required ImportCsvColumnMapping mapping,
    ImportSourceType sourceType = ImportSourceType.csv,
  }) {
    final lines = _normalizedLines(text);
    if (lines.isEmpty) return const <ImportParsedRecord>[];

    final delimiter = _guessDelimiter(lines.first);
    final firstCells = _splitDelimitedLine(lines.first, delimiter);
    final hasHeader = _looksLikeHeader(firstCells);
    final start = hasHeader ? 1 : 0;
    final base = DateTime.now();
    final rows = <ImportParsedRecord>[];

    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      final cells = _splitDelimitedLine(line, delimiter);
      if (cells.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final warnings = <String>[];
      final lineNumber = i + 1;

      final amountText = _pickByIndex(cells, mapping.amountColumnIndex);
      final amount = _parseAmount(amountText ?? '');
      final normalizedAmount = amount ?? 0;
      final validAmount = amount != null && amount > 0;
      if (!validAmount) {
        warnings.add('无法识别金额');
      } else if (_isSuspiciousAmount(normalizedAmount)) {
        warnings.add('金额较大，请确认');
      }

      final dateText = _pickByIndex(cells, mapping.dateColumnIndex);
      final parsedDateCandidate = _parseDate(
        dateText ?? '',
        fallbackDate: base,
      );
      final timestamp = parsedDateCandidate ?? base.add(Duration(seconds: i));
      if (parsedDateCandidate == null) {
        warnings.add('时间未识别，已使用默认值');
      }
      if (_isSuspiciousTimestamp(timestamp)) {
        warnings.add('时间异常，请确认');
      }

      final sourceText = _pickByIndex(cells, mapping.assetColumnIndex) ?? line;
      final source = _sourceFromText(
        sourceText,
        defaultValue: _defaultSource(sourceType),
      );
      if (!_looksLikeKnownSource(sourceText)) {
        warnings.add('来源未识别，使用默认来源');
      }

      final accountBookName = _pickByIndex(
        cells,
        mapping.accountBookColumnIndex,
      );
      final accountName = _pickByIndex(cells, mapping.assetColumnIndex);
      final toAccountName = _pickByIndex(cells, mapping.toAssetColumnIndex);
      final categoryPathText = _pickByIndex(
        cells,
        mapping.categoryPathColumnIndex,
      );
      final categoryPath = _splitCategoryPath(categoryPathText);
      final rawParentCategoryName = _pickByIndex(
        cells,
        mapping.parentCategoryColumnIndex,
      );
      final rawChildCategoryName = _pickByIndex(
        cells,
        mapping.childCategoryColumnIndex,
      );
      final parentCategoryName =
          _preferExplicitCategoryName(
            rawParentCategoryName,
            categoryPathText,
          ) ??
          categoryPath.parentName;
      final childCategoryName =
          _preferExplicitCategoryName(rawChildCategoryName, categoryPathText) ??
          categoryPath.childName;
      final tagNames = _splitTagNames(
        _pickByIndex(cells, mapping.tagColumnIndex),
      );
      final serviceChargeText = _pickByIndex(
        cells,
        mapping.serviceChargeColumnIndex,
      );
      final serviceCharge = _parseAmount(serviceChargeText ?? '');
      final typeText = _pickByIndex(cells, mapping.typeColumnIndex);
      final rawText = _pickByIndex(cells, mapping.remarkColumnIndex) ?? line;
      final normalizedType = _normalizeType(typeText);
      final inferredType =
          _inferTypeFromCategoryHints(
            parentCategoryName: parentCategoryName,
            childCategoryName: childCategoryName,
          ) ??
          (((toAccountName ?? '').trim().isNotEmpty || serviceCharge != null)
              ? 'transfer'
              : null) ??
          _inferTypeFromText(rawText, sourceType);
      final resolvedType = normalizedType ?? inferredType;
      if (normalizedType == null && inferredType != null) {
        warnings.add('交易类型为推断值');
      }
      if (resolvedType == null) {
        warnings.add('交易类型未知');
      }
      if (resolvedType == 'transfer' &&
          ((toAccountName ?? '').trim().isEmpty)) {
        warnings.add('转账缺少转入账户');
      }
      if (serviceChargeText != null &&
          serviceChargeText.trim().isNotEmpty &&
          serviceCharge == null) {
        warnings.add('手续费未识别');
      }

      rows.add(
        ImportParsedRecord(
          amount: validAmount ? normalizedAmount : 0,
          source: source,
          timestamp: timestamp,
          rawText: rawText,
          type: resolvedType,
          accountBookName: accountBookName,
          accountName: accountName,
          toAccountName: toAccountName,
          parentCategoryName: parentCategoryName,
          childCategoryName: childCategoryName,
          serviceCharge: serviceCharge,
          tagNames: tagNames,
          lineNumber: lineNumber,
          confidence: _estimateConfidence(
            valid: validAmount,
            warnings: warnings,
          ),
          warnings: warnings,
        ),
      );
    }

    return rows;
  }

  ImportCsvColumnMapping _inferMappingFromHeaderMap(
    Map<String, int> headerMap,
  ) {
    return ImportCsvColumnMapping(
      accountBookColumnIndex: _pickHeaderIndex(headerMap, _accountBookAliases),
      assetColumnIndex: _pickHeaderIndex(headerMap, <String>{
        ..._assetAliases,
        ..._sourceAliases,
      }),
      toAssetColumnIndex: _pickHeaderIndex(headerMap, _toAssetAliases),
      categoryPathColumnIndex: _pickHeaderIndex(
        headerMap,
        _categoryPathAliases,
      ),
      parentCategoryColumnIndex: _pickHeaderIndex(
        headerMap,
        _parentCategoryAliases,
      ),
      childCategoryColumnIndex: _pickHeaderIndex(
        headerMap,
        _childCategoryAliases,
      ),
      tagColumnIndex: _pickHeaderIndex(headerMap, _tagAliases),
      serviceChargeColumnIndex: _pickHeaderIndex(
        headerMap,
        _serviceChargeAliases,
      ),
      dateColumnIndex: _pickHeaderIndex(headerMap, _dateAliases),
      amountColumnIndex: _pickHeaderIndex(headerMap, _amountAliases),
      remarkColumnIndex: _pickHeaderIndex(headerMap, _textAliases),
      typeColumnIndex: _pickHeaderIndex(headerMap, _typeAliases),
    );
  }

  int? _pickHeaderIndex(Map<String, int> headerMap, Set<String> aliases) {
    for (final alias in aliases) {
      final index = headerMap[alias];
      if (index != null) return index;
    }
    return null;
  }

  List<String> _normalizedLines(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim()
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _guessDelimiter(String firstLine) {
    final commaCount = ','.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;
    return tabCount > commaCount ? '\t' : ',';
  }

  List<String> _splitDelimitedLine(String line, String delimiter) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (nextIsQuote) {
          buffer.write('"');
          i += 1;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (!inQuotes && char == delimiter) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  bool _looksLikeHeader(List<String> cells) {
    if (cells.isEmpty) return false;
    final normalized = cells.map(_normalizeAlias).toList(growable: false);
    for (final cell in normalized) {
      if (_amountAliases.contains(cell) ||
          _dateAliases.contains(cell) ||
          _sourceAliases.contains(cell) ||
          _typeAliases.contains(cell) ||
          _textAliases.contains(cell) ||
          _accountBookAliases.contains(cell) ||
          _assetAliases.contains(cell) ||
          _toAssetAliases.contains(cell) ||
          _categoryPathAliases.contains(cell) ||
          _parentCategoryAliases.contains(cell) ||
          _childCategoryAliases.contains(cell) ||
          _tagAliases.contains(cell) ||
          _serviceChargeAliases.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  Map<String, int> _buildHeaderMap(List<String> headers) {
    final map = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final key = _normalizeAlias(headers[i]);
      if (key.isNotEmpty) {
        map[key] = i;
      }
    }
    return map;
  }

  String _normalizeAlias(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  String? _pickByIndex(List<String> cells, int? index) {
    if (index == null || index < 0 || index >= cells.length) {
      return null;
    }
    final value = cells[index].trim();
    return value.isEmpty ? null : value;
  }

  double? _parseAmount(String input) {
    final text = input.replaceAll(',', '');

    final withCurrency = RegExp(
      r'(?:¥|￥|rmb|cny)\s*([+-]?\d+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    if (withCurrency != null) {
      return double.tryParse(withCurrency)?.abs();
    }

    final withYuan = RegExp(
      r'([+-]?\d+(?:\.\d{1,2})?)\s*元',
    ).firstMatch(text)?.group(1);
    if (withYuan != null) {
      return double.tryParse(withYuan)?.abs();
    }

    final decimal = RegExp(r'([+-]?\d+\.\d{1,2})').firstMatch(text)?.group(1);
    if (decimal != null) {
      return double.tryParse(decimal)?.abs();
    }

    if (RegExp(r'金额|支付|付款|收款|收入|支出|转账').hasMatch(text)) {
      final integer = RegExp(r'([+-]?\d{1,8})').firstMatch(text)?.group(1);
      if (integer != null) {
        final parsed = double.tryParse(integer);
        if (parsed != null && parsed.abs() <= 1000000) {
          return parsed.abs();
        }
      }
    }

    return null;
  }

  DateTime? _parseDate(String input, {DateTime? fallbackDate}) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final unix = RegExp(r'^\d{10,13}$').firstMatch(text)?.group(0);
    if (unix != null) {
      final value = int.tryParse(unix);
      if (value != null) {
        if (unix.length == 13) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final full = RegExp(
      r'(\d{4})[\-\/.年](\d{1,2})[\-\/.月](\d{1,2})(?:日)?(?:\s+|T)?(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (full != null) {
      return DateTime(
        int.parse(full.group(1)!),
        int.parse(full.group(2)!),
        int.parse(full.group(3)!),
        int.parse(full.group(4)!),
        int.parse(full.group(5)!),
        int.tryParse(full.group(6) ?? '0') ?? 0,
      );
    }

    final monthDayTime = RegExp(
      r'(\d{1,2})[\-\/.月](\d{1,2})(?:日)?\s*(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (monthDayTime != null) {
      final ref = fallbackDate ?? DateTime.now();
      return DateTime(
        ref.year,
        int.parse(monthDayTime.group(1)!),
        int.parse(monthDayTime.group(2)!),
        int.parse(monthDayTime.group(3)!),
        int.parse(monthDayTime.group(4)!),
        int.tryParse(monthDayTime.group(5) ?? '0') ?? 0,
      );
    }

    final timeOnly = RegExp(
      r'(\d{1,2})[:：](\d{1,2})(?:[:：](\d{1,2}))?',
    ).firstMatch(text);
    if (timeOnly != null) {
      final ref = fallbackDate ?? DateTime.now();
      return DateTime(
        ref.year,
        ref.month,
        ref.day,
        int.parse(timeOnly.group(1)!),
        int.parse(timeOnly.group(2)!),
        int.tryParse(timeOnly.group(3) ?? '0') ?? 0,
      );
    }

    return null;
  }

  bool _looksLikeKnownSource(String input) {
    final lower = input.toLowerCase();
    return lower.contains('wechat') ||
        lower.contains('alipay') ||
        lower.contains('unionpay') ||
        input.contains('微信') ||
        input.contains('支付宝') ||
        input.contains('云闪付');
  }

  bool _isSuspiciousAmount(double amount) {
    return amount >= 50000;
  }

  bool _isSuspiciousTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.isAfter(now.add(const Duration(days: 1)))) return true;
    if (timestamp.year < 2000) return true;
    return false;
  }

  double _estimateConfidence({
    required bool valid,
    required List<String> warnings,
  }) {
    if (!valid) return 0;
    final value = 1 - (warnings.length * 0.18);
    if (value < 0.2) return 0.2;
    if (value > 1) return 1;
    return value;
  }

  String _sourceFromText(String input, {required String defaultValue}) {
    final lower = input.toLowerCase();
    if (lower.contains('wechat') || input.contains('微信')) return 'WeChat';
    if (lower.contains('alipay') || input.contains('支付宝')) return 'Alipay';
    if (input.contains('云闪付') || lower.contains('unionpay')) {
      return 'UnionPay';
    }
    return defaultValue;
  }

  String _defaultSource(ImportSourceType sourceType) {
    switch (sourceType) {
      case ImportSourceType.wechat:
        return 'WeChat';
      case ImportSourceType.alipay:
        return 'Alipay';
      case ImportSourceType.ocr:
        return 'OCR';
      case ImportSourceType.csv:
      case ImportSourceType.auto:
        return 'Import';
    }
  }

  String? _normalizeType(String? raw) {
    if (raw == null) return null;
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;
    if (lower == 'expense' || lower == 'income' || lower == 'transfer') {
      return lower;
    }
    if (raw.contains('收入') || raw.contains('收款') || raw.contains('到账')) {
      return 'income';
    }
    if (raw.contains('转账') || raw.contains('转入') || raw.contains('转出')) {
      return 'transfer';
    }
    if (raw.contains('支出') || raw.contains('支付') || raw.contains('付款')) {
      return 'expense';
    }
    return null;
  }

  String? _inferTypeFromText(String text, ImportSourceType sourceType) {
    final normalized = _normalizeType(text);
    if (normalized != null) return normalized;
    if (sourceType == ImportSourceType.wechat ||
        sourceType == ImportSourceType.alipay) {
      return 'expense';
    }
    return null;
  }

  static const Set<String> _accountBookAliases = {
    'ledger',
    'book',
    'accountbook',
    '账本',
    '账本名称',
    '账簿',
  };

  static const Set<String> _assetAliases = {
    'asset',
    'account',
    'wallet',
    'card',
    '账户',
    '支付方式',
    '资产',
    '钱包',
    '银行卡',
  };

  static const Set<String> _toAssetAliases = {
    'toaccount',
    'toasset',
    'targetaccount',
    'targetasset',
    '转入账户',
    '转入资产',
    '目标账户',
    '目标资产',
    '收款账户',
    '对方账户',
  };

  static const Set<String> _categoryPathAliases = {
    'categorypath',
    'fullcategory',
    '分类路径',
    '完整分类',
    '分类全路径',
    '大类/中类/小类',
    '三级分类',
  };

  static const Set<String> _parentCategoryAliases = {
    '一级分类',
    'parentcategory',
    'parentcategoryname',
    'category',
    '大类',
    '主类',
  };

  static const Set<String> _childCategoryAliases = {
    '二级分类',
    'childcategory',
    'childcategoryname',
    'subcategory',
    '子类',
    '明细分类',
  };

  static const Set<String> _tagAliases = {'tag', 'tags', '标签', '标签列'};

  static const Set<String> _serviceChargeAliases = {
    'servicecharge',
    'fee',
    '手续费',
    '服务费',
    '转账手续费',
  };

  static const Set<String> _amountAliases = {
    'amount',
    'money',
    'amt',
    '金额',
    '交易金额',
    '收支金额',
  };

  static const Set<String> _dateAliases = {
    'date',
    'time',
    'datetime',
    'timestamp',
    '交易时间',
    '时间',
    '日期',
    '入账时间',
  };

  static const Set<String> _sourceAliases = {
    'source',
    'channel',
    'from',
    '来源',
    '渠道',
  };

  static const Set<String> _typeAliases = {
    'type',
    'direction',
    '收支',
    '收支类型',
    '交易类型',
  };

  static const Set<String> _textAliases = {
    'raw',
    'text',
    'note',
    'remark',
    'desc',
    '摘要',
    '说明',
    '备注',
    '商户',
  };

  List<String> _splitTagNames(String? raw) {
    if (raw == null) return const [];
    return raw
        .split(RegExp(r'[,，;；、\s]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  _CategoryPathNames _splitCategoryPath(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return const _CategoryPathNames();
    final parts = text
        .split(RegExp(r'\s*(?:/|／|>|＞|\\|、)\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return const _CategoryPathNames();
    if (parts.length == 1) return _CategoryPathNames(parentName: parts.first);
    return _CategoryPathNames(parentName: parts.first, childName: parts.last);
  }

  String? _preferExplicitCategoryName(String? explicit, String? pathText) {
    final text = explicit?.trim();
    if (text == null || text.isEmpty) return null;
    if (pathText != null && text == pathText.trim()) return null;
    return text;
  }

  String? _inferTypeFromCategoryHints({
    required String? parentCategoryName,
    required String? childCategoryName,
  }) {
    final parent = (parentCategoryName ?? '').trim();
    final child = (childCategoryName ?? '').trim();
    if (parent == '收入' || child == '收入') {
      return 'income';
    }
    if (parent == '转账' || child == '转账') {
      return 'transfer';
    }
    if (parent.isNotEmpty || child.isNotEmpty) {
      return 'expense';
    }
    return null;
  }
}

class _CategoryPathNames {
  const _CategoryPathNames({this.parentName, this.childName});

  final String? parentName;
  final String? childName;
}
