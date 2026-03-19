import 'package:isar/isar.dart';
import '../database/transaction_model.dart';
import '../database/category_model.dart';
import '../database/account_model.dart';

class TransactionService {
  final Isar isar;

  TransactionService(this.isar);

  static void touchSyncMetadata(JiveTransaction tx, {DateTime? now}) {
    tx.updatedAt = now ?? DateTime.now();
  }

  static void touchSyncMetadataForAll(
    Iterable<JiveTransaction> txs, {
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    for (final tx in txs) {
      tx.updatedAt = stamp;
    }
  }

  Future<int> migrateTransactionCategoryKeys() async {
    final txs = await isar.jiveTransactions.where().findAll();
    if (txs.isEmpty) return 0;

    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return 0;

    final Map<String, JiveCategory> parentByName = {};
    final Map<String, JiveCategory> childByParentAndName = {};

    for (final cat in categories) {
      if (cat.parentKey == null) {
        parentByName[cat.name] = cat;
      } else {
        childByParentAndName["${cat.parentKey}|${cat.name}"] = cat;
      }
    }

    final List<JiveTransaction> toUpdate = [];
    for (final tx in txs) {
      var changed = false;

      String? parentKey = tx.categoryKey;
      final parentName = tx.category;
      final subName = tx.subCategory;

      if ((parentKey == null || parentKey.isEmpty) &&
          parentName != null &&
          parentName.isNotEmpty) {
        final parent = parentByName[parentName];
        if (parent != null) {
          parentKey = parent.key;
          tx.categoryKey = parent.key;
          changed = true;
        }
      }

      if ((tx.subCategoryKey == null || tx.subCategoryKey!.isEmpty) &&
          subName != null &&
          subName.isNotEmpty &&
          parentKey != null &&
          parentKey.isNotEmpty) {
        final child = childByParentAndName["$parentKey|$subName"];
        if (child != null) {
          tx.subCategoryKey = child.key;
          changed = true;
        }
      }

      if (tx.type == null || tx.type!.isEmpty) {
        tx.type = "expense";
        changed = true;
      }

      if (changed) {
        toUpdate.add(tx);
      }
    }

    if (toUpdate.isEmpty) return 0;

    touchSyncMetadataForAll(toUpdate);
    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(toUpdate);
    });

    return toUpdate.length;
  }

  Future<int> migrateTransactionAccountIds() async {
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    if (accounts.isEmpty) return 0;

    JiveAccount? defaultAccount;
    for (final account in accounts) {
      if (account.type == 'asset' &&
          account.includeInBalance &&
          !account.isHidden &&
          !account.isArchived) {
        defaultAccount = account;
        break;
      }
    }
    defaultAccount ??= accounts.first;

    final txs = await isar.jiveTransactions.where().findAll();
    if (txs.isEmpty) return 0;

    final List<JiveTransaction> toUpdate = [];
    for (final tx in txs) {
      if (tx.accountId != null) continue;
      if ((tx.type ?? 'expense') == 'transfer') continue;
      tx.accountId = defaultAccount.id;
      toUpdate.add(tx);
    }

    if (toUpdate.isEmpty) return 0;

    touchSyncMetadataForAll(toUpdate);
    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(toUpdate);
    });

    return toUpdate.length;
  }
}
