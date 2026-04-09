import 'package:isar/isar.dart';

import '../database/bill_relation_model.dart';
import '../database/transaction_model.dart';
import '../sync/sync_delete_marker_service.dart';

class ReimbursementService {
  ReimbursementService(this.isar);

  final Isar isar;

  static const int maxRefundCountPerBill = 25;

  Future<JiveTransaction> createReimbursement({
    required int sourceTransactionId,
    required double amount,
    int? accountId,
    DateTime? timestamp,
    String? note,
    String? groupKey,
  }) async {
    if (amount <= 0) {
      throw StateError('报销金额必须大于 0');
    }
    final source = await _getSourceBill(sourceTransactionId);
    _assertSourceTypeSupported(source);

    final tx = JiveTransaction()
      ..amount = _round2(amount)
      ..source = 'Reimbursement'
      ..timestamp = timestamp ?? DateTime.now()
      ..rawText = '报销入账 #${source.id}'
      ..type = _reverseType(source.type)
      ..categoryKey = source.categoryKey
      ..subCategoryKey = source.subCategoryKey
      ..category = source.category
      ..subCategory = source.subCategory
      ..note = note?.trim().isNotEmpty == true ? note!.trim() : '报销入账'
      ..accountId = accountId ?? source.accountId
      ..toAccountId = null
      ..tagKeys = List<String>.from(source.tagKeys)
      ..smartTagKeys = const [];

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
      await isar.collection<JiveBillRelation>().put(
        JiveBillRelation()
          ..sourceTransactionId = source.id
          ..linkedTransactionId = tx.id
          ..relationType = BillRelationType.reimbursement.value
          ..amount = tx.amount
          ..currency = _pickCurrency(source)
          ..groupKey = groupKey
          ..note = note?.trim().isNotEmpty == true ? note!.trim() : null
          ..createdAt = DateTime.now(),
      );
    });
    return tx;
  }

  Future<JiveTransaction> createRefund({
    required int sourceTransactionId,
    required double amount,
    int? accountId,
    DateTime? timestamp,
    String? note,
    String? groupKey,
  }) async {
    if (amount <= 0) {
      throw StateError('退款金额必须大于 0');
    }
    final source = await _getSourceBill(sourceTransactionId);
    _assertSourceTypeSupported(source);

    final existingRefunds = await isar
        .collection<JiveBillRelation>()
        .filter()
        .sourceTransactionIdEqualTo(source.id)
        .and()
        .relationTypeEqualTo(BillRelationType.refund.value)
        .count();
    if (existingRefunds >= maxRefundCountPerBill) {
      throw StateError('单笔账单最多支持 $maxRefundCountPerBill 次退款');
    }

    final tx = JiveTransaction()
      ..amount = _round2(amount)
      ..source = 'Refund'
      ..timestamp = timestamp ?? DateTime.now()
      ..rawText = '退款记录 #${source.id}'
      ..type = _reverseType(source.type)
      ..categoryKey = source.categoryKey
      ..subCategoryKey = source.subCategoryKey
      ..category = source.category
      ..subCategory = source.subCategory
      ..note = note?.trim().isNotEmpty == true ? note!.trim() : '退款入账'
      ..accountId = accountId ?? source.accountId
      ..toAccountId = null
      ..tagKeys = List<String>.from(source.tagKeys)
      ..smartTagKeys = const [];

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
      await isar.collection<JiveBillRelation>().put(
        JiveBillRelation()
          ..sourceTransactionId = source.id
          ..linkedTransactionId = tx.id
          ..relationType = BillRelationType.refund.value
          ..amount = tx.amount
          ..currency = _pickCurrency(source)
          ..groupKey = groupKey
          ..note = note?.trim().isNotEmpty == true ? note!.trim() : null
          ..createdAt = DateTime.now(),
      );
    });
    return tx;
  }

  Future<BillSettlementSummary> getSettlementSummary(
    int sourceTransactionId,
  ) async {
    final relations = await isar
        .collection<JiveBillRelation>()
        .filter()
        .sourceTransactionIdEqualTo(sourceTransactionId)
        .findAll();

    var reimbursementCount = 0;
    var refundCount = 0;
    var reimbursementTotal = 0.0;
    var refundTotal = 0.0;

    for (final relation in relations) {
      final amount = _round2(relation.amount);
      if (relation.relationType == BillRelationType.reimbursement.value) {
        reimbursementCount += 1;
        reimbursementTotal += amount;
      } else if (relation.relationType == BillRelationType.refund.value) {
        refundCount += 1;
        refundTotal += amount;
      }
    }

    return BillSettlementSummary(
      sourceTransactionId: sourceTransactionId,
      reimbursementCount: reimbursementCount,
      refundCount: refundCount,
      reimbursementTotal: _round2(reimbursementTotal),
      refundTotal: _round2(refundTotal),
      netRecovered: _round2(reimbursementTotal + refundTotal),
    );
  }

  Future<List<JiveBillRelation>> getRelationsForSource(
    int sourceTransactionId,
  ) async {
    final list = await isar
        .collection<JiveBillRelation>()
        .filter()
        .sourceTransactionIdEqualTo(sourceTransactionId)
        .findAll();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> deleteRelation(
    int relationId, {
    bool deleteLinkedTransaction = false,
  }) async {
    final relation = await isar.collection<JiveBillRelation>().get(relationId);
    if (relation == null) return;

    await isar.writeTxn(() async {
      await isar.collection<JiveBillRelation>().delete(relationId);
      if (deleteLinkedTransaction) {
        final linkedTx = await isar.collection<JiveTransaction>().get(
          relation.linkedTransactionId,
        );
        if (linkedTx != null) {
          await SyncDeleteMarkerService(isar).markTransactionDeleted(linkedTx);
        }
        await isar.collection<JiveTransaction>().delete(
          relation.linkedTransactionId,
        );
      }
    });
  }

  Future<JiveTransaction> _getSourceBill(int sourceTransactionId) async {
    final source = await isar.collection<JiveTransaction>().get(
      sourceTransactionId,
    );
    if (source == null) {
      throw StateError('找不到原账单，请退出重试');
    }
    return source;
  }

  void _assertSourceTypeSupported(JiveTransaction source) {
    final type = (source.type ?? 'expense').trim();
    if (type != 'expense' && type != 'income') {
      throw StateError('仅支持对收入/支出账单进行报销或退款');
    }
  }

  String _reverseType(String? type) {
    final normalized = (type ?? 'expense').trim();
    if (normalized == 'income') return 'expense';
    return 'income';
  }

  String _pickCurrency(JiveTransaction source) {
    return 'CNY';
  }

  double _round2(double value) {
    return (value * 100).round() / 100;
  }
}
