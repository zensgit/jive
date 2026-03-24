import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';

class CsvExportService {
  CsvExportService(this._isar);

  final Isar _isar;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<String> exportTransactionsCsv(
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
      ['日期', '类型(收入/支出/转账)', '金额', '分类', '子分类', '备注', '账户', '标签'],
    ];

    for (final transaction in transactions) {
      rows.add([
        _dateFormat.format(transaction.timestamp),
        _typeLabel(transaction.type),
        transaction.amount.toStringAsFixed(2),
        _categoryLabel(transaction, categoryByKey),
        _subCategoryLabel(transaction, categoryByKey),
        transaction.note?.trim() ?? '',
        _accountLabel(transaction, accountById),
        _tagLabel(transaction, tagByKey),
      ]);
    }

    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
    return '\uFEFF$csv';
  }

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

  String _typeLabel(String? rawType) {
    switch (rawType) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      case 'expense':
      default:
        return '支出';
    }
  }

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

  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String? _normalizeCategoryKey(String? categoryKey) {
    final normalized = categoryKey?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
