import 'dart:convert';

import '../../core/database/auto_draft_model.dart';
import '../transactions/transaction_entry_params.dart';

/// Converts an automatic capture draft into the unified transaction editor
/// contract without changing the existing AutoDraftService confirm path.
class AutoDraftEntryParamsBuilder {
  const AutoDraftEntryParamsBuilder();

  static const _transferServiceChargeMetadataKey = 'transferServiceCharge';
  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  TransactionEntryParams build(JiveAutoDraft draft) {
    final type = _normalizedType(draft);
    final fee = type == 'transfer' ? transferServiceCharge(draft) : null;
    return TransactionEntryParams(
      source: TransactionEntrySource.autoDraft,
      sourceLabel: '来自自动识别「${draft.source}」',
      prefillAmount: draft.amount > 0 ? draft.amount : null,
      prefillType: type,
      prefillCategoryKey: type == 'transfer'
          ? null
          : _firstNonEmpty(draft.categoryKey, draft.category),
      prefillSubCategoryKey: type == 'transfer'
          ? null
          : _firstNonEmpty(draft.subCategoryKey, draft.subCategory),
      prefillAccountId: draft.accountId,
      prefillToAccountId: type == 'transfer' ? draft.toAccountId : null,
      prefillDate: draft.timestamp,
      prefillTagKeys: draft.tagKeys.isEmpty ? null : List.of(draft.tagKeys),
      prefillRawText: draft.rawText,
      prefillExchangeFee: fee,
      prefillExchangeFeeType: fee == null ? null : 'fixed',
      highlightFields: _highlightFields(draft, type),
    );
  }

  double? transferServiceCharge(JiveAutoDraft draft) {
    final json = draft.metadataJson;
    if (json == null || json.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      final rawFee = decoded[_transferServiceChargeMetadataKey];
      final fee = rawFee is num
          ? rawFee.toDouble()
          : double.tryParse(rawFee?.toString() ?? '');
      return fee != null && fee > 0 ? fee : null;
    } catch (_) {
      return null;
    }
  }

  String _normalizedType(JiveAutoDraft draft) {
    final explicit = draft.type?.trim().toLowerCase();
    if (explicit == 'income' ||
        explicit == 'expense' ||
        explicit == 'transfer') {
      return explicit!;
    }
    final rawText = draft.rawText ?? '';
    if (_transferKeywords.any(rawText.contains)) return 'transfer';
    return 'expense';
  }

  List<String> _highlightFields(JiveAutoDraft draft, String type) {
    final fields = <String>{};
    if (draft.amount <= 0) fields.add(TransactionHighlightField.amount);
    if (draft.accountId == null) fields.add(TransactionHighlightField.account);
    if (type == 'transfer') {
      if (draft.toAccountId == null) {
        fields.add(TransactionHighlightField.transferAccount);
      }
    } else if (_firstNonEmpty(
          draft.categoryKey,
          draft.subCategoryKey,
          draft.category,
          draft.subCategory,
        ) ==
        null) {
      fields.add(TransactionHighlightField.category);
    }
    return fields.toList(growable: false);
  }

  String? _firstNonEmpty(
    String? first, [
    String? second,
    String? third,
    String? fourth,
  ]) {
    for (final value in [first, second, third, fourth]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
