import 'package:isar/isar.dart';

import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/transaction_service.dart';

class RefundService {
  RefundService({Isar? isar}) : _isar = isar;

  final Isar? _isar;

  Future<JiveTransaction> createRefund(
    int originalTransactionId, {
    double? partialAmount,
    String? note,
  }) async {
    final isar = _isar ?? await DatabaseService.getInstance();
    final original = await isar.jiveTransactions.get(originalTransactionId);
    if (original == null) {
      throw StateError('original_transaction_missing');
    }

    final reversedType = _reverseType(original.type);
    final refundAmount = partialAmount ?? original.amount;
    if (refundAmount <= 0) {
      throw ArgumentError.value(
        partialAmount,
        'partialAmount',
        'refund_amount_must_be_positive',
      );
    }
    if (refundAmount > original.amount) {
      throw ArgumentError.value(
        partialAmount,
        'partialAmount',
        'refund_amount_exceeds_original',
      );
    }

    final refund = JiveTransaction()
      ..amount = refundAmount
      ..source = 'Refund'
      ..timestamp = DateTime.now()
      ..category = original.category
      ..categoryKey = original.categoryKey
      ..subCategory = original.subCategory
      ..subCategoryKey = original.subCategoryKey
      ..type = reversedType
      ..note = _buildRefundNote(
        originalTransactionId: originalTransactionId,
        originalNote: original.note,
        overrideNote: note,
      )
      ..accountId = original.accountId
      ..toAccountId = null
      ..toAmount = null
      ..exchangeRate = null
      ..exchangeFee = null
      ..exchangeFeeType = null
      ..projectId = original.projectId
      ..tagKeys = List<String>.from(original.tagKeys)
      ..excludeFromBudget =
          reversedType == 'expense' && original.excludeFromBudget
      ..smartTagKeys = []
      ..smartTagOptOutKeys = []
      ..smartTagOptOutAll = false
      ..rawText = null
      ..recurringRuleId = null
      ..recurringKey = null;

    TransactionService.touchSyncMetadata(refund);
    await isar.writeTxn(() async {
      await isar.jiveTransactions.put(refund);
    });
    return refund;
  }

  String _reverseType(String? originalType) {
    switch (originalType) {
      case 'expense':
        return 'income';
      case 'income':
        return 'expense';
      default:
        throw ArgumentError.value(
          originalType,
          'originalType',
          'refund_only_supports_expense_or_income',
        );
    }
  }

  String _buildRefundNote({
    required int originalTransactionId,
    required String? originalNote,
    required String? overrideNote,
  }) {
    final trimmedOverride = overrideNote?.trim();
    final trimmedOriginal = originalNote?.trim();
    final baseNote =
        (trimmedOverride != null && trimmedOverride.isNotEmpty)
        ? trimmedOverride
        : (trimmedOriginal != null && trimmedOriginal.isNotEmpty)
        ? trimmedOriginal
        : null;
    final prefix = baseNote == null ? '退款:' : '退款: $baseNote';
    return '$prefix [原交易ID:$originalTransactionId]';
  }
}
