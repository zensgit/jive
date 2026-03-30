import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/account_model.dart';
import '../../../core/database/transaction_model.dart';
import '../../../core/database/category_model.dart';
import '../../../core/database/auto_draft_model.dart';
import '../../../core/database/tag_model.dart';
import '../../../core/database/tag_rule_model.dart';
import '../../../core/service/account_service.dart';
import '../../../core/service/category_service.dart';
import '../../../core/service/transaction_service.dart';
import '../../../core/service/tag_service.dart';
import '../../../core/service/data_backup_service.dart';
import '../../../core/service/ui_pref_service.dart';
import '../../../core/service/project_service.dart';
import '../main_screen_controller.dart';

class RandomSeedResult {
  final int accounts;
  final int tags;
  final int transactions;

  const RandomSeedResult({
    required this.accounts,
    required this.tags,
    required this.transactions,
  });
}

class ProjectSeedResult {
  final String projectName;
  final int transactions;

  const ProjectSeedResult({
    required this.projectName,
    required this.transactions,
  });
}

class RandomAccountSeed {
  final String name;
  final String type;
  final String subType;

  const RandomAccountSeed(this.name, this.type, this.subType);
}

mixin DebugSeedMixin on MainScreenController {
  static const _prefKeyDemoSeedEnabled = 'demo_seed_enabled';

  bool demoSeedEnabled = true;
  final Random random = Random();

  Future<void> loadDemoSeedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final demoSeed = prefs.getBool(_prefKeyDemoSeedEnabled) ?? true;
    final showBadge = await UiPrefService.getShowSmartTagBadge();
    if (mounted) {
      setState(() {
        demoSeedEnabled = demoSeed;
        showSmartTagBadge = showBadge;
      });
    }
  }

  Future<void> setDemoSeedEnabled(bool enabled) async {
    demoSeedEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDemoSeedEnabled, enabled);
  }

  Future<bool> seedDemoDataIfNeeded() async {
    if (!kDebugMode) return false;
    if (!demoSeedEnabled) return false;
    final existingCount = await isar.jiveTransactions.count();
    if (existingCount > 0) return false;

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    if (accounts.isEmpty) return false;

    final accountByKeyMap = {for (final account in accounts) account.key: account};
    final defaultAccount =
        await accountService.getDefaultAccount() ?? accounts.first;
    final shouldSeedBalances = accounts.every(
      (account) => account.openingBalance == 0,
    );

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

    final cash = accountByKeyMap['acct_cash'] ?? defaultAccount;
    final bank = accountByKeyMap['acct_bank'] ?? defaultAccount;
    final wechat = accountByKeyMap['acct_wechat'] ?? defaultAccount;
    final alipay = accountByKeyMap['acct_alipay'] ?? defaultAccount;

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
      await isar.jiveTransactions.putAll([...demoTxs, transfer]);
    });
    return true;
  }

  Future<void> handleRandomSeed() async {
    const accountCount = 3;
    const tagCount = 12;
    const transactionCount = 80;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成随机测试数据'),
        content: const Text('将追加随机测试数据：3 个账户、12 个标签、80 笔交易。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await seedRandomTestData(
      accountCount: accountCount,
      tagCount: tagCount,
      transactionCount: transactionCount,
    );
    await loadTransactions();
    await loadAutoDraftCount();
    notifyDataChanged();
    showMessage(
      '已生成随机测试数据：账户${result.accounts}、标签${result.tags}、交易${result.transactions}',
    );
  }

  Future<void> handleProjectSeedLarge() async {
    const transactionCount = 1200;
    const daysSpan = 420;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成项目测试数据'),
        content: const Text('将创建一个测试项目，并生成 1200 笔交易（覆盖近 14 个月），全部关联到该项目。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await seedProjectTestData(
      transactionCount: transactionCount,
      daysSpan: daysSpan,
    );
    await loadTransactions();
    await loadAutoDraftCount();
    notifyDataChanged();
    showMessage('已生成项目测试数据：${result.projectName}，交易${result.transactions} 笔');
  }

  Future<RandomSeedResult> seedRandomTestData({
    required int accountCount,
    required int tagCount,
    required int transactionCount,
  }) async {
    final accountService = AccountService(isar);
    final tagService = TagService(isar);
    await accountService.initDefaultAccounts();
    await tagService.initDefaultGroups();
    await CategoryService(isar).initDefaultCategories();

    final accountTemplates = <RandomAccountSeed>[
      RandomAccountSeed('测试钱包', AccountService.typeAsset, 'wallet'),
      RandomAccountSeed('测试现金', AccountService.typeAsset, 'cash'),
      RandomAccountSeed('测试银行卡', AccountService.typeAsset, 'bank'),
      RandomAccountSeed('测试微信', AccountService.typeAsset, 'wechat'),
      RandomAccountSeed('测试支付宝', AccountService.typeAsset, 'alipay'),
      RandomAccountSeed('测试信用卡', AccountService.typeLiability, 'credit'),
      RandomAccountSeed('测试借入', AccountService.typeLiability, 'loan'),
    ];

    final createdAccounts = <JiveAccount>[];
    for (var i = 0; i < accountCount; i++) {
      final seed = accountTemplates[random.nextInt(accountTemplates.length)];
      final name = '${seed.name}${randomSuffix()}';
      final amount = 200 + random.nextInt(9800);
      final openingBalance = seed.type == AccountService.typeLiability
          ? -amount.toDouble()
          : amount.toDouble();
      final account = await accountService.createAccount(
        name: name,
        type: seed.type,
        subType: seed.subType,
        openingBalance: openingBalance,
      );
      createdAccounts.add(account);
    }

    final groups = await tagService.getGroups(includeArchived: false);
    if (groups.isEmpty) {
      await tagService.createGroup(name: '随机分组');
    }
    final refreshedGroups = await tagService.getGroups(includeArchived: false);
    final createdTags = <JiveTag>[];
    for (var i = 0; i < tagCount; i++) {
      final name = '随机标签${randomSuffix()}';
      final group = refreshedGroups.isEmpty
          ? null
          : refreshedGroups[random.nextInt(refreshedGroups.length)];
      final color = TagService
          .defaultColors[random.nextInt(TagService.defaultColors.length)];
      try {
        final tag = await tagService.createTag(
          name: name,
          groupKey: group?.key,
          colorHex: color,
        );
        createdTags.add(tag);
      } catch (_) {
        // Ignore duplicates; use a new suffix next time.
      }
    }

    final accounts = await accountService.getActiveAccounts();
    final tags = await tagService.getTags(includeArchived: false);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final expenseParents = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome && !cat.isHidden)
        .toList();
    final incomeParents = categories
        .where((cat) => cat.parentKey == null && cat.isIncome && !cat.isHidden)
        .toList();

    JiveCategory? pickParent(List<JiveCategory> parents) {
      if (parents.isEmpty) return null;
      return parents[random.nextInt(parents.length)];
    }

    JiveCategory? pickChild(String parentKey) {
      final children = categories
          .where((cat) => cat.parentKey == parentKey && !cat.isHidden)
          .toList();
      if (children.isEmpty) return null;
      return children[random.nextInt(children.length)];
    }

    List<String> pickTags() {
      if (tags.isEmpty) return [];
      final count = random.nextInt(3);
      if (count == 0) return [];
      final pool = List<JiveTag>.from(tags)..shuffle(random);
      return pool.take(count).map((tag) => tag.key).toList();
    }

    final now = DateTime.now();
    final txList = <JiveTransaction>[];
    for (var i = 0; i < transactionCount; i++) {
      final roll = random.nextInt(100);
      final type = roll < 15 ? 'income' : (roll < 25 ? 'transfer' : 'expense');
      final timestamp = now.subtract(
        Duration(days: random.nextInt(120), minutes: random.nextInt(1440)),
      );
      final account = accounts[random.nextInt(accounts.length)];
      if (type == 'transfer') {
        final others = accounts.where((a) => a.id != account.id).toList();
        if (others.isEmpty) continue;
        final toAccount = others[random.nextInt(others.length)];
        final amount = 50 + random.nextInt(3000);
        txList.add(
          JiveTransaction()
            ..amount = amount.toDouble()
            ..source = 'SeedRandom'
            ..type = 'transfer'
            ..timestamp = timestamp
            ..accountId = account.id
            ..toAccountId = toAccount.id
            ..tagKeys = pickTags(),
        );
        continue;
      }

      final parent = type == 'income'
          ? pickParent(incomeParents)
          : pickParent(expenseParents);
      final child = parent == null ? null : pickChild(parent.key);
      final amount = type == 'income'
          ? 200 + random.nextInt(12000)
          : 10 + random.nextInt(1200);
      txList.add(
        JiveTransaction()
          ..amount = amount.toDouble()
          ..source = 'SeedRandom'
          ..type = type
          ..timestamp = timestamp
          ..accountId = account.id
          ..categoryKey = parent?.key
          ..subCategoryKey = child?.key
          ..category = parent?.name ?? ''
          ..subCategory = child?.name ?? ''
          ..rawText = '随机测试数据'
          ..note = '随机测试数据'
          ..tagKeys = pickTags(),
      );
    }

    await isar.writeTxn(() async {
      if (txList.isNotEmpty) {
        await isar.jiveTransactions.putAll(txList);
      }
    });
    await tagService.refreshUsageCounts();

    return RandomSeedResult(
      accounts: createdAccounts.length,
      tags: createdTags.length,
      transactions: txList.length,
    );
  }

  Future<ProjectSeedResult> seedProjectTestData({
    required int transactionCount,
    required int daysSpan,
  }) async {
    final accountService = AccountService(isar);
    final tagService = TagService(isar);
    await accountService.initDefaultAccounts();
    await tagService.initDefaultGroups();
    await CategoryService(isar).initDefaultCategories();

    final projectService = ProjectService(isar);
    final projectName = '项目测试${randomSuffix()}';
    final startDate = DateTime.now().subtract(Duration(days: daysSpan));
    final project = await projectService.createProject(
      name: projectName,
      description: '自动生成的项目测试数据',
      budget: 50000,
      iconName: 'folder',
      colorHex: '#2E7D32',
      startDate: startDate,
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    final accounts = await accountService.getActiveAccounts();
    final tags = await tagService.getTags(includeArchived: false);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final expenseParents = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome && !cat.isHidden)
        .toList();

    JiveCategory? pickParent() {
      if (expenseParents.isEmpty) return null;
      return expenseParents[random.nextInt(expenseParents.length)];
    }

    JiveCategory? pickChild(String parentKey) {
      final children = categories
          .where((cat) => cat.parentKey == parentKey && !cat.isHidden)
          .toList();
      if (children.isEmpty) return null;
      return children[random.nextInt(children.length)];
    }

    List<String> pickTags() {
      if (tags.isEmpty) return [];
      final count = random.nextInt(3);
      if (count == 0) return [];
      final pool = List<JiveTag>.from(tags)..shuffle(random);
      return pool.take(count).map((tag) => tag.key).toList();
    }

    final now = DateTime.now();
    final txList = <JiveTransaction>[];
    for (var i = 0; i < transactionCount; i++) {
      if (accounts.isEmpty) break;
      final timestamp = now.subtract(
        Duration(
          days: random.nextInt(daysSpan),
          minutes: random.nextInt(1440),
        ),
      );
      final account = accounts[random.nextInt(accounts.length)];
      final parent = pickParent();
      final child = parent == null ? null : pickChild(parent.key);
      final amount = 10 + random.nextInt(5000);
      txList.add(
        JiveTransaction()
          ..amount = amount.toDouble()
          ..source = 'SeedProject'
          ..type = 'expense'
          ..timestamp = timestamp
          ..accountId = account.id
          ..projectId = project.id
          ..categoryKey = parent?.key
          ..subCategoryKey = child?.key
          ..category = parent?.name ?? ''
          ..subCategory = child?.name ?? ''
          ..rawText = '项目测试数据'
          ..note = '项目测试数据'
          ..tagKeys = pickTags(),
      );
    }

    await isar.writeTxn(() async {
      if (txList.isNotEmpty) {
        await isar.jiveTransactions.putAll(txList);
      }
    });
    await tagService.refreshUsageCounts();

    return ProjectSeedResult(
      projectName: project.name,
      transactions: txList.length,
    );
  }

  String randomSuffix() {
    return '${1000 + random.nextInt(9000)}';
  }

  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().clear();
      await isar.collection<JiveAccount>().clear();
      await isar.collection<JiveCategory>().clear();
      await isar.collection<JiveAutoDraft>().clear();
      await isar.collection<JiveTag>().clear();
      await isar.collection<JiveTagGroup>().clear();
      await isar.collection<JiveTagRule>().clear();
    });
    await CategoryService(isar).initDefaultCategories();
    await AccountService(isar).initDefaultAccounts();
    await TagService(isar).initDefaultGroups();
    await TransactionService(isar).migrateTransactionCategoryKeys();
    await TransactionService(isar).migrateTransactionAccountIds();
    await loadTransactions();
    await loadAutoDraftCount();
    notifyDataChanged();
  }

  Future<void> exportBackup() async {
    try {
      final file = await JiveDataBackupService.exportToFile(isar);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Jive 数据备份'),
      );
      showMessage('已导出数据');
    } catch (e) {
      showMessage('导出失败：$e');
    }
  }

  Future<void> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入将覆盖当前全部数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final summary = await JiveDataBackupService.importFromFile(
        isar,
        file,
        clearBefore: true,
      );
      await TagService(isar).refreshUsageCounts();
      await TransactionService(isar).migrateTransactionCategoryKeys();
      await TransactionService(isar).migrateTransactionAccountIds();
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
      showMessage('导入完成：交易${summary.transactions}条，标签${summary.tags}个');
    } catch (e) {
      showMessage('导入失败：$e');
    }
  }
}
