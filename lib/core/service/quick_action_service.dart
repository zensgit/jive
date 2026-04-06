import 'package:isar/isar.dart';

import '../database/template_model.dart';
import '../database/transaction_model.dart';
import '../model/quick_action.dart';
import '../sync/sync_key_generator.dart';
import '../../feature/transactions/transaction_entry_params.dart';

/// Converts legacy [JiveTemplate] objects into [QuickAction] view-models and
/// provides execution helpers.
///
/// Stage 1: all data is read from [JiveTemplate]; no separate persistence.
class QuickActionService {
  final Isar _isar;

  QuickActionService(this._isar);

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  /// Returns quick actions that should appear on the home screen, sorted by
  /// pinned-first then by descending usage count.
  Future<List<QuickAction>> listForHome() async {
    final templates = await _isar.jiveTemplates
        .where()
        .sortByIsPinnedDesc()
        .thenByUsageCountDesc()
        .findAll();

    return templates.map(toQuickAction).toList();
  }

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  /// Converts a [JiveTemplate] into a [QuickAction], inferring the execution
  /// [QuickActionMode] from the completeness of the template fields:
  ///
  /// - **direct** — amount, category, and account are all set.
  /// - **confirm** — category is set but amount or account is missing.
  /// - **edit** — category is not set.
  QuickAction toQuickAction(JiveTemplate template) {
    final hasAmount = template.amount != 0;
    final hasCategory = template.categoryKey != null &&
        template.categoryKey!.isNotEmpty;
    final hasAccount = template.accountId != null;

    final QuickActionMode mode;
    if (hasAmount && hasCategory && hasAccount) {
      mode = QuickActionMode.direct;
    } else if (hasCategory) {
      mode = QuickActionMode.confirm;
    } else {
      mode = QuickActionMode.edit;
    }

    return QuickAction(
      id: 'tpl_${template.id}',
      name: template.name,
      transactionType: template.type,
      bookId: null, // JiveTemplate does not carry bookId
      accountId: template.accountId,
      categoryKey: template.categoryKey,
      subCategoryKey: template.subCategoryKey,
      tagKeys: const [],
      defaultAmount: hasAmount ? template.amount : null,
      defaultNote: template.note,
      mode: mode,
      showOnHome: template.isPinned,
      usageCount: template.usageCount,
      lastUsedAt: template.lastUsedAt,
      legacyTemplateId: template.id,
    );
  }

  // ---------------------------------------------------------------------------
  // Execution
  // ---------------------------------------------------------------------------

  /// Creates and persists a [JiveTransaction] directly from a **direct-mode**
  /// [QuickAction]. Returns the saved transaction.
  ///
  /// Also bumps the usage count on the underlying template.
  Future<JiveTransaction> executeDirect(QuickAction action) async {
    final tx = JiveTransaction()
      ..amount = action.defaultAmount ?? 0
      ..source = 'quick_action'
      ..timestamp = DateTime.now()
      ..type = action.transactionType
      ..categoryKey = action.categoryKey
      ..subCategoryKey = action.subCategoryKey
      ..accountId = action.accountId
      ..bookId = action.bookId
      ..note = action.defaultNote
      ..tagKeys = List<String>.from(action.tagKeys)
      ..syncKey = SyncKeyGenerator.generate('tx')
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);

      // Bump template usage stats.
      if (action.legacyTemplateId != null) {
        final tpl = await _isar.jiveTemplates.get(action.legacyTemplateId!);
        if (tpl != null) {
          tpl.usageCount += 1;
          tpl.lastUsedAt = DateTime.now();
          await _isar.jiveTemplates.put(tpl);
        }
      }
    });

    return tx;
  }

  /// Builds a [TransactionEntryParams] suitable for **confirm** or **edit**
  /// mode quick actions.
  TransactionEntryParams buildEntryParams(QuickAction action) {
    return TransactionEntryParams(
      source: TransactionEntrySource.quickAction,
      sourceLabel: '来自快速动作「${action.name}」',
      canDirectSubmit: action.mode == QuickActionMode.confirm,
      quickActionId: action.id,
      prefillAmount: action.defaultAmount,
      prefillType: action.transactionType,
      prefillCategoryKey: action.categoryKey,
      prefillAccountId: action.accountId,
      prefillNote: action.defaultNote,
      prefillTagKeys:
          action.tagKeys.isNotEmpty ? List<String>.from(action.tagKeys) : null,
    );
  }
}
