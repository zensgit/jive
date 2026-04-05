import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import '../database/recurring_rule_model.dart';
import '../database/savings_goal_model.dart';
import '../database/transaction_model.dart';
import 'sync_key_generator.dart';

/// Backfills stable sync keys for legacy rows that predate SaaS sync identity.
class SyncKeyMigration {
  SyncKeyMigration._();

  static Future<void> migrateAllSyncKeys(Isar isar) async {
    await migrateTransactionSyncKeys(isar);
    await migrateBudgetSyncKeys(isar);
    await migrateRecurringSyncKeys(isar);
    await migrateSavingsGoalSyncKeys(isar);
  }

  static Future<void> migrateTransactionSyncKeys(Isar isar) async {
    final items = await isar.jiveTransactions.where().findAll();
    final pending = items.where((item) => _needsSyncKey(item.syncKey)).toList();
    if (pending.isEmpty) return;

    await isar.writeTxn(() async {
      for (final item in pending) {
        item.syncKey = SyncKeyGenerator.generate('tx');
      }
      await isar.jiveTransactions.putAll(pending);
    });
  }

  static Future<void> migrateBudgetSyncKeys(Isar isar) async {
    final items = await isar.jiveBudgets.where().findAll();
    final pending = items.where((item) => _needsSyncKey(item.syncKey)).toList();
    if (pending.isEmpty) return;

    await isar.writeTxn(() async {
      for (final item in pending) {
        item.syncKey = SyncKeyGenerator.generate('budget');
      }
      await isar.jiveBudgets.putAll(pending);
    });
  }

  static Future<void> migrateRecurringSyncKeys(Isar isar) async {
    final items = await isar.jiveRecurringRules.where().findAll();
    final pending = items.where((item) => _needsSyncKey(item.syncKey)).toList();
    if (pending.isEmpty) return;

    await isar.writeTxn(() async {
      for (final item in pending) {
        item.syncKey = SyncKeyGenerator.generate('recurring');
      }
      await isar.jiveRecurringRules.putAll(pending);
    });
  }

  static Future<void> migrateSavingsGoalSyncKeys(Isar isar) async {
    final items = await isar.jiveSavingsGoals.where().findAll();
    final pending = items.where((item) => _needsSyncKey(item.syncKey)).toList();
    if (pending.isEmpty) return;

    await isar.writeTxn(() async {
      for (final item in pending) {
        item.syncKey = SyncKeyGenerator.generate('saving');
      }
      await isar.jiveSavingsGoals.putAll(pending);
    });
  }

  static bool _needsSyncKey(String value) => value.trim().isEmpty;
}
