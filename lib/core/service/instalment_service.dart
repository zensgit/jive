import 'package:isar/isar.dart';

import '../database/category_model.dart';
import '../database/instalment_model.dart';
import '../database/transaction_model.dart';
import 'transaction_service.dart';

class InstalmentService {
  InstalmentService(this.isar);

  final Isar isar;

  Future<List<JiveInstalment>> getAll() async {
    final list = await isar.collection<JiveInstalment>().where().findAll();
    list.sort(_compareInstalments);
    return list;
  }

  Future<List<JiveInstalment>> getActiveInstalments() async {
    final list = await getAll();
    return list.where((item) => item.status == 'active').toList();
  }

  Future<JiveInstalment> create(JiveInstalment instalment) async {
    _normalizeForCreate(instalment);
    await isar.writeTxn(() async {
      await isar.collection<JiveInstalment>().put(instalment);
    });
    return instalment;
  }

  Future<JiveInstalment> update(JiveInstalment instalment) async {
    final existing = await isar.collection<JiveInstalment>().get(instalment.id);
    if (existing == null) {
      throw StateError('Instalment ${instalment.id} not found');
    }
    _normalizeForUpdate(instalment, existing: existing);
    await isar.writeTxn(() async {
      await isar.collection<JiveInstalment>().put(instalment);
    });
    return instalment;
  }

  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveInstalment>().delete(id);
    });
  }

  Future<JiveInstalment?> markPaid(int id) async {
    final instalment = await isar.collection<JiveInstalment>().get(id);
    if (instalment == null) return null;

    _normalizeForUpdate(instalment, existing: instalment);
    if (instalment.status != 'active') {
      return instalment;
    }

    final categories = instalment.categoryKey == null || instalment.categoryKey!.isEmpty
        ? const <JiveCategory>[]
        : await isar.collection<JiveCategory>().where().findAll();
    final paymentCategory = _resolveTransactionCategory(
      categories,
      instalment.categoryKey,
    );
    final paymentDate = instalment.nextPaymentDate;
    final nextPaidCount = instalment.paidCount + 1;
    final safeCount = instalment.instalmentCount <= 0
        ? 1
        : instalment.instalmentCount;

    instalment
      ..paidCount = nextPaidCount > safeCount ? safeCount : nextPaidCount
      ..nextPaymentDate = _addOneMonth(paymentDate)
      ..status = nextPaidCount >= safeCount ? 'completed' : 'active';

    final transaction = JiveTransaction()
      ..amount = instalment.monthlyAmount
      ..source = 'Instalment'
      ..timestamp = paymentDate
      ..rawText = instalment.name
      ..category = paymentCategory.parentName
      ..subCategory = paymentCategory.subName
      ..categoryKey = paymentCategory.parentKey
      ..subCategoryKey = paymentCategory.subKey
      ..type = 'expense'
      ..note = _buildPaymentNote(instalment, paidCount: instalment.paidCount)
      ..accountId = instalment.accountId
      ..toAccountId = null;
    TransactionService.touchSyncMetadata(transaction, now: paymentDate);

    await isar.writeTxn(() async {
      await isar.collection<JiveInstalment>().put(instalment);
      await isar.collection<JiveTransaction>().put(transaction);
    });

    return instalment;
  }

  Future<List<JiveInstalment>> getUpcomingPayments(int daysAhead) async {
    final reference = DateTime.now();
    final start = _startOfDay(reference);
    final end = _endOfDay(
      start.add(Duration(days: daysAhead < 0 ? 0 : daysAhead)),
    );
    final active = await getActiveInstalments();
    return active
        .where(
          (item) =>
              !item.nextPaymentDate.isBefore(start) &&
              !item.nextPaymentDate.isAfter(end),
        )
        .toList()
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
  }

  void _normalizeForCreate(JiveInstalment instalment) {
    _normalizeCommon(instalment);
    instalment.createdAt = DateTime.now();
  }

  void _normalizeForUpdate(
    JiveInstalment instalment, {
    required JiveInstalment existing,
  }) {
    _normalizeCommon(instalment);
    instalment.createdAt = existing.createdAt;
  }

  void _normalizeCommon(JiveInstalment instalment) {
    final trimmedName = instalment.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('name cannot be empty');
    }
    if (instalment.totalAmount <= 0) {
      throw ArgumentError('totalAmount must be greater than 0');
    }
    final safeCount = instalment.instalmentCount <= 0 ? 1 : instalment.instalmentCount;
    final safePaid = instalment.paidCount < 0
        ? 0
        : instalment.paidCount > safeCount
        ? safeCount
        : instalment.paidCount;
    final normalizedStatus = _normalizeStatus(instalment.status);
    instalment
      ..name = trimmedName
      ..instalmentCount = safeCount
      ..paidCount = safePaid
      ..monthlyAmount = instalment.totalAmount / safeCount
      ..note = _normalizeOptionalText(instalment.note)
      ..categoryKey = _normalizeOptionalText(instalment.categoryKey)
      ..status = normalizedStatus == 'cancelled'
          ? 'cancelled'
          : safePaid >= safeCount
          ? 'completed'
          : 'active';
  }

  String _normalizeStatus(String value) {
    switch (value.trim()) {
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'active':
      default:
        return 'active';
    }
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  int _compareInstalments(JiveInstalment a, JiveInstalment b) {
    final statusCompare = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (statusCompare != 0) return statusCompare;
    final nextCompare = a.nextPaymentDate.compareTo(b.nextPaymentDate);
    if (nextCompare != 0) return nextCompare;
    return b.createdAt.compareTo(a.createdAt);
  }

  int _statusRank(String status) {
    switch (status) {
      case 'active':
        return 0;
      case 'completed':
        return 1;
      case 'cancelled':
        return 2;
      default:
        return 3;
    }
  }

  DateTime _addOneMonth(DateTime from) {
    final targetMonth = from.month + 1;
    final targetYear = from.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final day = _clampDay(targetYear, month, from.day);
    return DateTime(
      targetYear,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  int _clampDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    if (day < 1) return 1;
    if (day > lastDay) return lastDay;
    return day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      23,
      59,
      59,
      999,
      999,
    );
  }

  _TransactionCategoryResolution _resolveTransactionCategory(
    List<JiveCategory> categories,
    String? selectedKey,
  ) {
    if (selectedKey == null || selectedKey.isEmpty || categories.isEmpty) {
      return const _TransactionCategoryResolution();
    }

    JiveCategory? selected;
    JiveCategory? parent;
    for (final category in categories) {
      if (category.key == selectedKey) {
        selected = category;
        break;
      }
    }
    if (selected == null) {
      return const _TransactionCategoryResolution();
    }
    if (selected.parentKey == null) {
      parent = selected;
    } else {
      for (final category in categories) {
        if (category.key == selected.parentKey) {
          parent = category;
          break;
        }
      }
    }

    return _TransactionCategoryResolution(
      parentKey: parent?.key,
      parentName: parent?.name,
      subKey: selected.parentKey == null ? null : selected.key,
      subName: selected.parentKey == null ? null : selected.name,
    );
  }

  String _buildPaymentNote(JiveInstalment instalment, {required int paidCount}) {
    final base = '分期第$paidCount/${instalment.instalmentCount}期';
    if (instalment.note == null || instalment.note!.trim().isEmpty) {
      return base;
    }
    return '$base · ${instalment.note!.trim()}';
  }
}

class _TransactionCategoryResolution {
  const _TransactionCategoryResolution({
    this.parentKey,
    this.parentName,
    this.subKey,
    this.subName,
  });

  final String? parentKey;
  final String? parentName;
  final String? subKey;
  final String? subName;
}
