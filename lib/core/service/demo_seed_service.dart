import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/auto_draft_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'account_service.dart';
import 'category_service.dart';
import 'transaction_service.dart';

class DemoSeedService {
  static Future<bool> seedIfNeeded(
    Isar isar, {
    required bool enabled,
  }) async {
    if (!kDebugMode || !enabled) return false;
    final existingCount = await isar.collection<JiveTransaction>().count();
    if (existingCount > 0) return false;

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    if (accounts.isEmpty) return false;

    final accountByKey = {for (final account in accounts) account.key: account};
    final defaultAccount = await accountService.getDefaultAccount() ?? accounts.first;
    final shouldSeedBalances = accounts.every((account) => account.openingBalance == 0);

    if (shouldSeedBalances) {
      final openingBalances = <String, double>{
        'acct_cash': 1200,
        'acct_bank': 15000,
        'acct_wechat': 800,
        'acct_alipay': 600,
        'acct_credit': -3200,
        'acct_loan': -8000,
      };
      await isar.writeTxn(() async {
        for (final account in accounts) {
          final opening = openingBalances[account.key];
          if (opening == null) continue;
          account.openingBalance = opening;
          await isar.collection<JiveAccount>().put(account);
        }
      });
    }

    final categories = await isar.collection<JiveCategory>().where().findAll();
    final expenseParents = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome && !cat.isHidden)
        .toList();
    final incomeParents = categories
        .where((cat) => cat.parentKey == null && cat.isIncome && !cat.isHidden)
        .toList();

    JiveCategory? pickParent(List<JiveCategory> parents, List<String> names) {
      for (final name in names) {
        final match = parents.where((cat) => cat.name == name).toList();
        if (match.isNotEmpty) return match.first;
      }
      return parents.isNotEmpty ? parents.first : null;
    }

    JiveCategory? pickChild(String parentKey, List<String> names) {
      final children = categories
          .where((cat) => cat.parentKey == parentKey && !cat.isHidden)
          .toList();
      for (final name in names) {
        final match = children.where((cat) => cat.name == name).toList();
        if (match.isNotEmpty) return match.first;
      }
      return children.isNotEmpty ? children.first : null;
    }

    JiveTransaction buildTx({
      required String type,
      required double amount,
      required JiveAccount account,
      required int daysAgo,
      List<String>? parentNames,
      List<String>? childNames,
    }) {
      final now = DateTime.now().subtract(Duration(days: daysAgo));
      final parent = parentNames == null
          ? null
          : pickParent(
              type == 'income' ? incomeParents : expenseParents,
              parentNames,
            );
      final child = (parent == null || childNames == null)
          ? null
          : pickChild(parent.key, childNames);
      return JiveTransaction()
        ..amount = amount
        ..source = 'Seed'
        ..type = type
        ..timestamp = now
        ..accountId = account.id
        ..categoryKey = parent?.key
        ..subCategoryKey = child?.key
        ..category = parent?.name ?? (parentNames?.first ?? '')
        ..subCategory = child?.name ?? (childNames?.first ?? '');
    }

    final cash = accountByKey['acct_cash'] ?? defaultAccount;
    final bank = accountByKey['acct_bank'] ?? defaultAccount;
    final wechat = accountByKey['acct_wechat'] ?? defaultAccount;
    final alipay = accountByKey['acct_alipay'] ?? defaultAccount;

    final demoTxs = <JiveTransaction>[
      buildTx(
        type: 'expense',
        amount: 28,
        account: cash,
        daysAgo: 0,
        parentNames: ['餐饮', '吃喝'],
        childNames: ['早餐', '咖啡'],
      ),
      buildTx(
        type: 'expense',
        amount: 56,
        account: wechat,
        daysAgo: 1,
        parentNames: ['交通', '出行'],
        childNames: ['地铁', '公交'],
      ),
      buildTx(
        type: 'expense',
        amount: 198,
        account: alipay,
        daysAgo: 2,
        parentNames: ['购物', '日常'],
        childNames: ['衣服', '日用品'],
      ),
      buildTx(
        type: 'expense',
        amount: 76,
        account: cash,
        daysAgo: 3,
        parentNames: ['娱乐', '运动'],
        childNames: ['电影', '游戏'],
      ),
      buildTx(
        type: 'expense',
        amount: 123,
        account: bank,
        daysAgo: 4,
        parentNames: ['医疗', '健康'],
        childNames: ['药品', '门诊'],
      ),
      buildTx(
        type: 'expense',
        amount: 42,
        account: wechat,
        daysAgo: 5,
        parentNames: ['日常', '生活'],
        childNames: ['话费', '网费'],
      ),
      buildTx(
        type: 'income',
        amount: 8000,
        account: bank,
        daysAgo: 2,
        parentNames: ['收入', '工资', '薪水'],
        childNames: ['工资', '薪水'],
      ),
      buildTx(
        type: 'income',
        amount: 1200,
        account: bank,
        daysAgo: 6,
        parentNames: ['收入', '奖金', '理财'],
        childNames: ['奖金', '理财收益'],
      ),
      buildTx(
        type: 'income',
        amount: 300,
        account: alipay,
        daysAgo: 8,
        parentNames: ['收入', '投资', '利息'],
        childNames: ['投资收益', '利息'],
      ),
    ];

    final transfer = JiveTransaction()
      ..amount = 500
      ..source = 'Seed'
      ..type = 'transfer'
      ..timestamp = DateTime.now().subtract(const Duration(days: 1))
      ..accountId = bank.id
      ..toAccountId = wechat.id;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().putAll([...demoTxs, transfer]);
    });
    return true;
  }

  static Future<void> resetCategories(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveCategory>().clear();
    });
    await CategoryService(isar).initDefaultCategories();
    await TransactionService(isar).migrateTransactionCategoryKeys();
  }

  static Future<void> clearAllData(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().clear();
      await isar.collection<JiveAccount>().clear();
      await isar.collection<JiveCategory>().clear();
      await isar.collection<JiveAutoDraft>().clear();
    });
    await CategoryService(isar).initDefaultCategories();
    await AccountService(isar).initDefaultAccounts();
    await TransactionService(isar).migrateTransactionCategoryKeys();
    await TransactionService(isar).migrateTransactionAccountIds();
  }
}
