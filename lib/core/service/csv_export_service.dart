import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';
import 'category_path_service.dart';

enum CsvExportTransactionType {
  all('all', '全部'),
  income('income', '收入'),
  expense('expense', '支出'),
  transfer('transfer', '转账');

  final String rawValue;
  final String label;

  const CsvExportTransactionType(this.rawValue, this.label);

  static CsvExportTransactionType fromRaw(String? raw) {
    return CsvExportTransactionType.values.firstWhere(
      (value) => value.rawValue == raw,
      orElse: () => CsvExportTransactionType.all,
    );
  }
}

class CsvExportService {
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd');
  static final DateFormat _fileTimestampFormat = DateFormat('yyyyMMdd_HHmmss');
  static final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final Isar _isar;

  const CsvExportService(this._isar);

  /// Count transactions matching the given filters (from main).
  Future<int> countTransactions({
    required DateTime start,
    required DateTime end,
    String? categoryKey,
    String? type,
  }) async {
    final transactions = await _loadTransactions(
      start: start,
      end: end,
      categoryKey: categoryKey,
      type: type,
    );
    return transactions.length;
  }

  /// Preview transaction count with bookId filtering (from HEAD).
  Future<int> previewTransactionCount(
    DateTime start,
    DateTime end, {
    String? categoryKey,
    int? bookId,
  }) async {
    final transactions = await _loadFilteredTransactions(
      start,
      end,
      categoryKey: categoryKey,
      bookId: bookId,
    );
    return transactions.length;
  }

  /// Export transactions to a CSV string with bookId filtering (from HEAD).
  Future<String> exportTransactionsCsvString(
    DateTime start,
    DateTime end, {
    String? categoryKey,
    int? bookId,
  }) async {
    final accountsFuture = _isar.collection<JiveAccount>().where().findAll();
    final categoriesFuture = _isar.collection<JiveCategory>().where().findAll();
    final tagsFuture = _isar.collection<JiveTag>().where().findAll();
    final transactions = await _loadFilteredTransactions(
      start,
      end,
      categoryKey: categoryKey,
      bookId: bookId,
    );
    final accounts = await accountsFuture;
    final categories = await categoriesFuture;
    final tags = await tagsFuture;

    final accountById = {for (final account in accounts) account.id: account};
    final categoryByKey = {
      for (final category in categories) category.key: category,
    };
    final tagByKey = {for (final tag in tags) tag.key: tag};

    final rows = <List<String>>[
      ['日期', '类型(收入/支出/转账)', '金额', '分类', '子分类', '分类路径', '备注', '账户', '标签'],
    ];

    for (final transaction in transactions) {
      rows.add([
        _dateFormat.format(transaction.timestamp),
        _typeLabel(transaction.type),
        transaction.amount.toStringAsFixed(2),
        _categoryLabel(transaction, categoryByKey),
        _subCategoryLabel(transaction, categoryByKey),
        _categoryPathLabel(transaction, categories),
        transaction.note?.trim() ?? '',
        _accountLabel(transaction, accountById),
        _tagLabel(transaction, tagByKey),
      ]);
    }

    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
    return '\uFEFF$csv';
  }

  /// Export transactions to a CSV file with type filtering (from main).
  Future<File> exportTransactionsCsv(
    DateTime start,
    DateTime end, {
    String? categoryKey,
    String? type,
  }) async {
    final transactions = await _loadTransactions(
      start: start,
      end: end,
      categoryKey: categoryKey,
      type: type,
    );
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final directory = await _resolveExportDirectory();
    final file = File(
      '${directory.path}/${_buildFileName(start, end, categoryKey: categoryKey, type: type)}',
    );
    await file.writeAsString(_buildCsv(transactions, categories), flush: true);
    return file;
  }

  // ---------------------------------------------------------------------------
  // Transaction loading (main branch version with type filtering)
  // ---------------------------------------------------------------------------

  Future<List<JiveTransaction>> _loadTransactions({
    required DateTime start,
    required DateTime end,
    String? categoryKey,
    String? type,
  }) async {
    final normalizedType = CsvExportTransactionType.fromRaw(type);
    final normalizedCategoryKey = _normalizeOptional(categoryKey);
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final transactions = await _isar.jiveTransactions
        .where()
        .timestampBetween(rangeStart, rangeEnd)
        .findAll();

    final filtered = transactions.where((tx) {
      return _matchesCategory(tx, normalizedCategoryKey) &&
          _matchesType(tx, normalizedType);
    }).toList();

    filtered.sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return filtered;
  }

  // ---------------------------------------------------------------------------
  // Transaction loading (HEAD branch version with bookId filtering)
  // ---------------------------------------------------------------------------

  Future<List<JiveTransaction>> _loadFilteredTransactions(
    DateTime start,
    DateTime end, {
    String? categoryKey,
    int? bookId,
  }) async {
    if (end.isBefore(start)) {
      throw ArgumentError('结束时间不能早于开始时间');
    }

    final normalizedCategoryKey = _normalizeCategoryKey(categoryKey);
    final startAt = _startOfDay(start);
    final endExclusive = _startOfDay(end).add(const Duration(days: 1));

    var baseQuery = _isar
        .collection<JiveTransaction>()
        .filter()
        .timestampBetween(startAt, endExclusive, includeUpper: false);
    if (bookId != null) {
      baseQuery = baseQuery.bookIdEqualTo(bookId);
    }

    late final List<JiveTransaction> transactions;
    if (normalizedCategoryKey != null) {
      transactions = await baseQuery
          .categoryKeyEqualTo(normalizedCategoryKey)
          .findAll();
    } else {
      transactions = await baseQuery.findAll();
    }

    transactions.sort((left, right) {
      final byTimestamp = left.timestamp.compareTo(right.timestamp);
      if (byTimestamp != 0) {
        return byTimestamp;
      }
      return left.id.compareTo(right.id);
    });
    return transactions;
  }

  // ---------------------------------------------------------------------------
  // Matching helpers (from main)
  // ---------------------------------------------------------------------------

  bool _matchesCategory(JiveTransaction tx, String? categoryKey) {
    if (categoryKey == null) return true;
    return tx.categoryKey == categoryKey || tx.subCategoryKey == categoryKey;
  }

  bool _matchesType(
    JiveTransaction tx,
    CsvExportTransactionType transactionType,
  ) {
    if (transactionType == CsvExportTransactionType.all) {
      return true;
    }
    return _normalizeTransactionType(tx.type) == transactionType.rawValue;
  }

  String _normalizeTransactionType(String? rawType) {
    final normalized = rawType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return CsvExportTransactionType.expense.rawValue;
    }
    return normalized;
  }

  // ---------------------------------------------------------------------------
  // File export helpers (from main)
  // ---------------------------------------------------------------------------

  Future<Directory> _resolveExportDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory('${documentsDirectory.path}/exports');
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }
    return exportDirectory;
  }

  String _buildFileName(
    DateTime start,
    DateTime end, {
    String? categoryKey,
    String? type,
  }) {
    final segments = <String>[
      'jive_transactions',
      _fileDateFormat.format(start),
      _fileDateFormat.format(end),
    ];
    final transactionType = CsvExportTransactionType.fromRaw(type);
    final normalizedCategoryKey = _normalizeOptional(categoryKey);
    if (transactionType != CsvExportTransactionType.all) {
      segments.add(transactionType.rawValue);
    }
    if (normalizedCategoryKey != null) {
      segments.add(_sanitizeFileSegment(normalizedCategoryKey));
    }
    segments.add(_fileTimestampFormat.format(DateTime.now()));
    return '${segments.join('_')}.csv';
  }

  String _buildCsv(
    List<JiveTransaction> transactions,
    List<JiveCategory> categories,
  ) {
    final buffer = StringBuffer()..write('\uFEFF');
    buffer.writeln(
      [
        'ID',
        '交易时间',
        '类型',
        '金额',
        '来源',
        '一级分类',
        '二级分类',
        '分类路径',
        '一级分类Key',
        '二级分类Key',
        '账户ID',
        '转入账户ID',
        '转入金额',
        '汇率',
        '手续费',
        '手续费类型',
        '项目ID',
        '标签Key',
        '智能标签Key',
        '停用智能标签Key',
        '全部停用智能标签',
        '备注',
        '原始文本',
        '不计入预算',
        '周期规则ID',
        '周期去重Key',
        '更新时间',
      ].map(_csvCell).join(','),
    );

    for (final tx in transactions) {
      buffer.writeln(
        [
          tx.id,
          _timestampFormat.format(tx.timestamp),
          _typeLabel(tx.type),
          tx.amount,
          tx.source,
          tx.category,
          tx.subCategory,
          _categoryPathLabel(tx, categories),
          tx.categoryKey,
          tx.subCategoryKey,
          tx.accountId,
          tx.toAccountId,
          tx.toAmount,
          tx.exchangeRate,
          tx.exchangeFee,
          tx.exchangeFeeType,
          tx.projectId,
          tx.tagKeys.join('|'),
          tx.smartTagKeys.join('|'),
          tx.smartTagOptOutKeys.join('|'),
          tx.smartTagOptOutAll ? '是' : '否',
          tx.note,
          tx.rawText,
          tx.excludeFromBudget ? '是' : '否',
          tx.recurringRuleId,
          tx.recurringKey,
          _timestampFormat.format(tx.updatedAt),
        ].map(_csvCell).join(','),
      );
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Type / label helpers
  // ---------------------------------------------------------------------------

  String _typeLabel(String? rawType) {
    switch (_normalizeTransactionType(rawType)) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }

  // ---------------------------------------------------------------------------
  // Label helpers for string-based CSV export (from HEAD)
  // ---------------------------------------------------------------------------

  String _categoryLabel(
    JiveTransaction transaction,
    Map<String, JiveCategory> categoryByKey,
  ) {
    if (transaction.type == 'transfer') {
      return '';
    }
    final category = transaction.categoryKey == null
        ? null
        : categoryByKey[transaction.categoryKey!];
    return category?.name ?? transaction.category ?? '未分类';
  }

  String _subCategoryLabel(
    JiveTransaction transaction,
    Map<String, JiveCategory> categoryByKey,
  ) {
    if (transaction.type == 'transfer') {
      return '';
    }
    final subCategory = transaction.subCategoryKey == null
        ? null
        : categoryByKey[transaction.subCategoryKey!];
    return subCategory?.name ?? transaction.subCategory ?? '';
  }

  String _categoryPathLabel(
    JiveTransaction transaction,
    Iterable<JiveCategory> categories,
  ) {
    if (transaction.type == 'transfer') {
      return '';
    }
    final path = const CategoryPathService().resolve(
      categories,
      categoryKey: transaction.categoryKey,
      subCategoryKey: transaction.subCategoryKey,
    );
    if (!path.isEmpty) return path.displayName;
    final fallback = [transaction.category, transaction.subCategory]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return fallback.join(' / ');
  }

  String _accountLabel(
    JiveTransaction transaction,
    Map<int, JiveAccount> accountById,
  ) {
    final sourceAccount = transaction.accountId == null
        ? null
        : accountById[transaction.accountId!];
    final targetAccount = transaction.toAccountId == null
        ? null
        : accountById[transaction.toAccountId!];

    if (transaction.type == 'transfer') {
      final sourceName = sourceAccount?.name ?? '';
      final targetName = targetAccount?.name ?? '';
      if (sourceName.isNotEmpty && targetName.isNotEmpty) {
        return '$sourceName -> $targetName';
      }
      if (sourceName.isNotEmpty) {
        return sourceName;
      }
      return targetName;
    }

    return sourceAccount?.name ?? '';
  }

  String _tagLabel(JiveTransaction transaction, Map<String, JiveTag> tagByKey) {
    if (transaction.tagKeys.isEmpty) {
      return '';
    }
    return transaction.tagKeys
        .map((key) => tagByKey[key]?.name ?? key)
        .join('、');
  }

  // ---------------------------------------------------------------------------
  // CSV cell helpers
  // ---------------------------------------------------------------------------

  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _sanitizeFileSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final normalized = sanitized
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'category' : normalized;
  }

  // ---------------------------------------------------------------------------
  // Normalization helpers
  // ---------------------------------------------------------------------------

  String? _normalizeCategoryKey(String? categoryKey) {
    final normalized = categoryKey?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
