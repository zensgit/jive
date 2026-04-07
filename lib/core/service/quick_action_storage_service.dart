import 'package:isar/isar.dart';

import '../database/quick_action_model.dart';
import '../database/template_model.dart';
import '../database/transaction_model.dart';

/// Persistent storage service for [JiveQuickAction] (Stage 2).
///
/// Provides CRUD operations, migration from legacy [JiveTemplate], and usage
/// tracking.
class QuickActionStorageService {
  final Isar _isar;

  QuickActionStorageService(this._isar);

  // ---------------------------------------------------------------------------
  // Migration
  // ---------------------------------------------------------------------------

  /// One-time migration: copies all [JiveTemplate] records into
  /// [JiveQuickAction]. Existing actions whose [legacyTemplateId] already
  /// matches a template are skipped.
  Future<int> migrateFromTemplates() async {
    final templates = await _isar.jiveTemplates.where().findAll();
    if (templates.isEmpty) return 0;

    // Collect already-migrated template ids.
    final existing = await _isar.jiveQuickActions.where().findAll();
    final migratedIds = <int>{};
    for (final a in existing) {
      if (a.legacyTemplateId != null) {
        migratedIds.add(a.legacyTemplateId!);
      }
    }

    final toInsert = <JiveQuickAction>[];
    for (final t in templates) {
      if (migratedIds.contains(t.id)) continue;

      final mode = _inferMode(t);
      final action = JiveQuickAction()
        ..name = t.name
        ..transactionType = t.type
        ..accountId = t.accountId
        ..toAccountId = t.toAccountId
        ..categoryKey = t.categoryKey
        ..subCategoryKey = t.subCategoryKey
        ..defaultAmount = t.amount != 0 ? t.amount : null
        ..defaultNote = t.note
        ..mode = mode
        ..showOnHome = t.isPinned
        ..showInHub = true
        ..usageCount = t.usageCount
        ..lastUsedAt = t.lastUsedAt
        ..legacyTemplateId = t.id
        ..createdAt = t.createdAt;
      toInsert.add(action);
    }

    if (toInsert.isEmpty) return 0;

    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.putAll(toInsert);
    });
    return toInsert.length;
  }

  String _inferMode(JiveTemplate t) {
    final hasAmount = t.amount != 0;
    final hasCategory =
        t.categoryKey != null && t.categoryKey!.isNotEmpty;
    final hasAccount = t.accountId != null;

    if (hasAmount && hasCategory && hasAccount) return 'direct';
    if (hasCategory) return 'confirm';
    return 'edit';
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns all quick actions ordered by usage count descending.
  Future<List<JiveQuickAction>> getAll() async {
    return _isar.jiveQuickActions
        .where()
        .sortByUsageCountDesc()
        .findAll();
  }

  /// Returns actions that should appear on the home screen.
  Future<List<JiveQuickAction>> getForHome() async {
    return _isar.jiveQuickActions
        .filter()
        .showOnHomeEqualTo(true)
        .sortByUsageCountDesc()
        .findAll();
  }

  /// Returns actions that should appear in the quick-action hub.
  Future<List<JiveQuickAction>> getForHub() async {
    return _isar.jiveQuickActions
        .filter()
        .showInHubEqualTo(true)
        .sortByUsageCountDesc()
        .findAll();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Creates a new quick action and returns its id.
  Future<int> create(JiveQuickAction action) async {
    action.createdAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.put(action);
    });
    return action.id;
  }

  /// Updates an existing quick action.
  Future<void> update(JiveQuickAction action) async {
    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.put(action);
    });
  }

  /// Deletes a quick action by id.
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.delete(id);
    });
  }

  // ---------------------------------------------------------------------------
  // Usage tracking
  // ---------------------------------------------------------------------------

  /// Increments usage counter and updates [lastUsedAt].
  Future<void> incrementUsage(int id) async {
    await _isar.writeTxn(() async {
      final action = await _isar.jiveQuickActions.get(id);
      if (action == null) return;
      action
        ..usageCount = action.usageCount + 1
        ..lastUsedAt = DateTime.now();
      await _isar.jiveQuickActions.put(action);
    });
  }

  // ---------------------------------------------------------------------------
  // Reverse-create from transaction
  // ---------------------------------------------------------------------------

  /// Creates a [JiveQuickAction] pre-filled from an existing transaction.
  Future<JiveQuickAction> createFromTransaction(
    JiveTransaction tx, {
    required String name,
  }) async {
    final hasAmount = tx.amount != 0;
    final hasCategory =
        tx.categoryKey != null && tx.categoryKey!.isNotEmpty;
    final hasAccount = tx.accountId != null;

    String mode;
    if (hasAmount && hasCategory && hasAccount) {
      mode = 'direct';
    } else if (hasCategory) {
      mode = 'confirm';
    } else {
      mode = 'edit';
    }

    final action = JiveQuickAction()
      ..name = name
      ..transactionType = tx.type ?? 'expense'
      ..accountId = tx.accountId
      ..toAccountId = tx.toAccountId
      ..categoryKey = tx.categoryKey
      ..subCategoryKey = tx.subCategoryKey
      ..tagKeys = List<String>.from(tx.tagKeys)
      ..defaultAmount = tx.amount
      ..defaultNote = tx.note
      ..mode = mode
      ..showOnHome = true
      ..showInHub = true
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveQuickActions.put(action);
    });
    return action;
  }
}
