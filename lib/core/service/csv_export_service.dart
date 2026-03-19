import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../database/transaction_model.dart';

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

  final Isar _isar;

  const CsvExportService(this._isar);

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
    final directory = await _resolveExportDirectory();
    final file = File(
      '${directory.path}/${_buildFileName(start, end, categoryKey: categoryKey, type: type)}',
    );
    await file.writeAsString(_buildCsv(transactions), flush: true);
    return file;
  }

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

  String _buildCsv(List<JiveTransaction> transactions) {
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

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _sanitizeFileSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final normalized = sanitized.replaceAll(RegExp(r'_+'), '_').replaceAll(
      RegExp(r'^_|_$'),
      '',
    );
    return normalized.isEmpty ? 'category' : normalized;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
