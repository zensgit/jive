import 'package:isar/isar.dart';

import '../database/template_model.dart';
import '../database/transaction_model.dart';
import '../model/quick_action.dart';
import 'quick_action_store_service.dart';
import 'template_service.dart';
import 'transaction_service.dart';

/// Compatibility-layer service for the MoneyThings-style quick action system.
///
/// Stage 1 deliberately keeps [JiveTemplate] as the persisted store and exposes
/// a stable [QuickAction] protocol on top. That lets app entry points, widgets,
/// and future URL/AppIntent bridges share one execution contract without adding
/// a destructive schema migration.
class QuickActionService {
  static const fieldAmount = 'amount';
  static const fieldCategory = 'category';
  static const fieldAccount = 'account';
  static const fieldTransferAccount = 'transferAccount';

  final Isar _isar;
  late final TemplateService _templateService = TemplateService(_isar);
  late final QuickActionStoreService _storeService = QuickActionStoreService(
    _isar,
  );

  QuickActionService(this._isar);

  Future<List<QuickAction>> getActions({int limit = 0}) async {
    final actions = await _storeService.getActions(limit: limit);
    if (actions.isNotEmpty) return actions;

    final templates = await _templateService.getTemplates();
    final fallbackActions = templates.map(toQuickAction).toList();
    if (limit <= 0 || fallbackActions.length <= limit) return fallbackActions;
    return fallbackActions.take(limit).toList();
  }

  Future<QuickAction?> findActionById(String id) async {
    final action = await _storeService.findAction(id);
    if (action != null) return action;

    final legacyId = _legacyTemplateId(id);
    if (legacyId == null) return null;
    final template = await _isar.jiveTemplates.get(legacyId);
    return template == null ? null : toQuickAction(template);
  }

  Future<List<QuickAction>> getTemplateFallbackActions({int limit = 0}) async {
    final templates = await _templateService.getTemplates();
    final actions = templates.map(toQuickAction).toList();
    if (limit <= 0 || actions.length <= limit) return actions;
    return actions.take(limit).toList();
  }

  static QuickAction toQuickAction(JiveTemplate template) {
    return QuickAction(
      id: 'template:${template.id}',
      name: template.name,
      transactionType: template.type,
      accountId: template.accountId,
      toAccountId: template.toAccountId,
      categoryKey: template.categoryKey,
      subCategoryKey: template.subCategoryKey,
      categoryName: template.category,
      subCategoryName: template.subCategory,
      defaultAmount: template.amount > 0 ? template.amount : null,
      defaultNote: template.note,
      mode: inferMode(template),
      usageCount: template.usageCount,
      lastUsedAt: template.lastUsedAt,
      legacyTemplateId: template.id,
    );
  }

  static QuickActionMode inferMode(JiveTemplate template) {
    final type = template.type;
    final hasAmount = template.amount > 0;
    final hasAccount = template.accountId != null;
    final hasCategory =
        (template.categoryKey != null && template.categoryKey!.isNotEmpty) ||
        (template.subCategoryKey != null &&
            template.subCategoryKey!.isNotEmpty);

    // Transfers may need the full editor for target account, currency, fee, or
    // repayment semantics. Keep them safe until the transfer editor is unified.
    if (type == 'transfer') return QuickActionMode.edit;

    if (hasAccount && hasCategory && hasAmount) return QuickActionMode.direct;
    if (hasAccount && hasCategory) return QuickActionMode.confirm;
    return QuickActionMode.edit;
  }

  static List<String> missingFields(QuickAction action) {
    final missing = <String>[];
    if ((action.defaultAmount ?? 0) <= 0) missing.add(fieldAmount);
    if (action.accountId == null) missing.add(fieldAccount);
    if (action.transactionType == 'transfer') {
      if (action.toAccountId == null) missing.add(fieldTransferAccount);
    } else if ((action.categoryKey == null || action.categoryKey!.isEmpty) &&
        (action.subCategoryKey == null || action.subCategoryKey!.isEmpty)) {
      missing.add(fieldCategory);
    }
    return missing;
  }

  static bool canSaveDirectly(QuickAction action) {
    return action.mode == QuickActionMode.direct &&
        missingFields(action).isEmpty &&
        action.transactionType != 'transfer';
  }

  JiveTransaction buildTransaction(
    QuickAction action, {
    double? amount,
    String? note,
  }) {
    final effectiveAmount = amount ?? action.defaultAmount ?? 0;
    if (effectiveAmount <= 0) {
      throw StateError('Quick action amount is required before saving.');
    }
    if (action.accountId == null) {
      throw StateError('Quick action account is required before saving.');
    }
    if (action.transactionType != 'transfer' &&
        (action.categoryKey == null || action.categoryKey!.isEmpty) &&
        (action.subCategoryKey == null || action.subCategoryKey!.isEmpty)) {
      throw StateError('Quick action category is required before saving.');
    }

    final tx = JiveTransaction()
      ..amount = effectiveAmount
      ..source = 'quick_action'
      ..timestamp = DateTime.now()
      ..type = action.transactionType
      ..accountId = action.accountId
      ..toAccountId = action.toAccountId
      ..categoryKey = action.categoryKey
      ..subCategoryKey = action.subCategoryKey
      ..category = action.categoryName
      ..subCategory = action.subCategoryName
      ..note = _effectiveNote(action.defaultNote, note)
      ..tagKeys = List<String>.from(action.tagKeys)
      ..bookId = action.bookId
      ..quickActionId = action.legacyTemplateId;
    TransactionService.touchSyncMetadata(tx);
    return tx;
  }

  Future<JiveTransaction> saveTransaction(
    QuickAction action, {
    double? amount,
    String? note,
  }) async {
    final tx = buildTransaction(action, amount: amount, note: note);
    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });
    await markUsed(action);
    return tx;
  }

  Future<void> markUsed(QuickAction action) async {
    await _storeService.markUsed(action);
    final templateId = action.legacyTemplateId;
    if (templateId == null) return;
    final template = await _isar.jiveTemplates.get(templateId);
    if (template == null) return;
    await _templateService.incrementUsage(template);
  }

  static String? _effectiveNote(String? defaultNote, String? overrideNote) {
    final override = overrideNote?.trim();
    if (override != null && override.isNotEmpty) return override;
    final fallback = defaultNote?.trim();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }

  static int? _legacyTemplateId(String quickActionId) {
    if (quickActionId.startsWith('template:')) {
      return int.tryParse(quickActionId.substring('template:'.length));
    }
    return int.tryParse(quickActionId);
  }
}
