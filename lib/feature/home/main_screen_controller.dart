import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/account_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/book_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/transaction_service.dart';
import '../../core/service/auto_permission_prompt_policy.dart';
import '../../core/service/tag_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/database_service.dart';
import '../../core/service/project_service.dart';
import '../../core/service/recurring_service.dart';
import '../../core/service/book_service.dart';
import '../../core/service/reminder_service.dart';
import '../../core/service/daily_reminder_service.dart';
import '../../core/service/notification_service.dart';
import 'main_screen.dart';

class CreditSummary {
  final double limit;
  final double used;
  final double available;

  const CreditSummary({
    required this.limit,
    required this.used,
    required this.available,
  });
}

mixin MainScreenController on State<MainScreen> {
  late Isar isar;
  List<JiveTransaction> transactions = [];
  Map<String, JiveCategory> categoryByKey = {};
  Map<String, JiveTag> tagByKey = {};
  Map<int, JiveAccount> accountById = {};
  bool isLoading = true;
  bool hasMoreTransactions = false;
  static const int _transactionPageSize = 50;
  double totalAssets = 0;
  double totalLiabilities = 0;
  double totalCreditLimit = 0;
  double totalCreditUsed = 0;
  double totalCreditAvailable = 0;
  bool showSmartTagBadge = true;
  bool dbReady = false;
  bool isProcessingRecurringRules = false;
  final ValueNotifier<int> dataReloadSignal = ValueNotifier(0);

  // 多币种支持
  String baseCurrency = 'CNY';
  CurrencyService? currencyService;

  // 多账本支持
  List<JiveBook> books = [];
  int? currentBookId; // null = 全部账本

  // Abstract - provided by AutoCaptureMixin
  AutoPermissionPromptPolicy? get autoPermissionPromptPolicy;
  set autoPermissionPromptPolicy(AutoPermissionPromptPolicy? value);
  Future<void> loadAutoSettings();
  Future<void> loadAutoAppSettings();
  Future<void> flushPendingAutoEvents();
  Future<void> checkAutoPermissions();
  Future<void> loadAutoDraftCount();

  // Abstract - provided by DebugSeedMixin
  Future<void> loadDemoSeedPrefs();

  /// Called after any data change. Override to add sync scheduling.
  VoidCallback? onDataChanged;

  void notifyDataChanged() {
    dataReloadSignal.value += 1;
    DataReloadBus.notify();
    onDataChanged?.call();
  }

  Future<void> initDatabase() async {
    isar = await DatabaseService.getInstance();
    autoPermissionPromptPolicy = AutoPermissionPromptPolicy(
      await SharedPreferences.getInstance(),
    );
    await loadDemoSeedPrefs();
    await loadAutoSettings();
    await loadAutoAppSettings();
    await CategoryService(isar).initDefaultCategories();
    await AccountService(isar).initDefaultAccounts();
    await TagService(isar).initDefaultGroups();
    final cs = CurrencyService(isar);
    await cs.initCurrencies();
    // 检查是否需要自动更新汇率
    await checkAutoUpdateRates(cs);
    await ProjectService(isar).initTestProjectIfNeeded();
    await BookService(isar).initDefaultBook();
    await loadBooks();
    await TransactionService(isar).migrateTransactionCategoryKeys();
    await TransactionService(isar).migrateTransactionAccountIds();
    await loadTransactions();
    await loadAutoDraftCount();
    dbReady = true;
    await flushPendingAutoEvents();
    await processRecurringRules();

    // Defer non-critical initialization so the home screen renders faster
    Future.delayed(const Duration(seconds: 2), () async {
      await checkReminders();
      await _checkDailyReminder();
      await _showPendingNotifications();
      await checkAutoPermissions();
    });
  }

  Future<void> processRecurringRules() async {
    if (!dbReady || isProcessingRecurringRules) return;
    isProcessingRecurringRules = true;
    try {
      final result = await RecurringService(isar).processDueRules();
      if (result.generatedDrafts > 0) {
        await loadAutoDraftCount();
      }
      if (result.committedTransactions > 0) {
        await loadTransactions();
        notifyDataChanged();
      }
    } catch (e) {
      debugPrint('Recurring processing failed: $e');
    } finally {
      isProcessingRecurringRules = false;
    }
  }

  Future<void> checkReminders() async {
    if (!dbReady) return;
    try {
      await ReminderService(isar).checkReminders();
    } catch (e) {
      debugPrint('Reminder check failed: $e');
    }
  }

  Future<void> _checkDailyReminder() async {
    try {
      final shouldShow = await DailyReminderService.shouldShowReminder();
      if (shouldShow) {
        InAppNotificationService().addNotification(InAppNotification(
          id: 'daily_reminder_${DateTime.now().toIso8601String().substring(0, 10)}',
          title: '记账提醒',
          body: '今天还没记账哦，花一分钟记一笔吧 📝',
          type: NotificationType.info,
        ));
      }
    } catch (e) {
      debugPrint('Daily reminder check failed: $e');
    }
  }

  Future<void> _showPendingNotifications() async {
    if (!mounted) return;
    final service = InAppNotificationService();
    if (!service.hasPendingNotifications) return;
    final notifications = service.consumePendingNotifications();
    // Show as overlay notifications with delay between each
    for (var i = 0; i < notifications.length; i++) {
      if (!mounted) return;
      if (i > 0) await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return;
      final n = notifications[i];
      final color = n.type == NotificationType.alert
          ? Colors.orange
          : const Color(0xFF2E7D32);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(n.body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> checkAutoUpdateRates(CurrencyService cs) async {
    try {
      final pref = await cs.getPreference();
      if (pref == null || !pref.autoUpdateRates) return;

      // 检查是否需要更新（每天最多更新一次）
      final lastUpdate = pref.lastRateUpdate;
      if (lastUpdate != null) {
        final now = DateTime.now();
        final diff = now.difference(lastUpdate);
        if (diff.inHours < 24) return; // 24小时内不重复更新
      }

      // 后台静默更新汇率
      await cs.fetchAndUpdateRates(
        pref.baseCurrency,
        pref.enabledCurrencies,
      );
    } catch (e) {
      // 静默失败，不影响应用启动
      debugPrint('Auto rate update failed: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> loadMoreTransactions(int offset) async {
    List<JiveTransaction> moreList;
    if (currentBookId != null) {
      moreList = await isar.jiveTransactions
          .where()
          .filter()
          .bookIdEqualTo(currentBookId)
          .sortByTimestampDesc()
          .offset(offset)
          .limit(_transactionPageSize)
          .findAll();
    } else {
      moreList = await isar.jiveTransactions
          .where()
          .sortByTimestampDesc()
          .offset(offset)
          .limit(_transactionPageSize)
          .findAll();
    }
    if (mounted) {
      setState(() {
        transactions = [...transactions, ...moreList];
        hasMoreTransactions = moreList.length >= _transactionPageSize;
      });
    }
  }

  Future<void> loadTransactions() async {
    List<JiveTransaction> list;
    if (currentBookId != null) {
      list = await isar.jiveTransactions
          .where()
          .filter()
          .bookIdEqualTo(currentBookId)
          .sortByTimestampDesc()
          .limit(_transactionPageSize)
          .findAll();
    } else {
      list = await isar.jiveTransactions
          .where()
          .sortByTimestampDesc()
          .limit(_transactionPageSize)
          .findAll();
    }
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};
    final tags = await isar.collection<JiveTag>().where().findAll();
    final tagMap = {for (final t in tags) t.key: t};
    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts(bookId: currentBookId);
    final accountMap = {for (final a in accounts) a.id: a};
    final balances = await accountService.computeBalances(accounts: accounts);
    final totals = accountService.calculateTotals(accounts, balances);
    final credit = computeCreditSummary(accounts, balances);

    // 加载基础货币
    currencyService ??= CurrencyService(isar);
    final base = await currencyService!.getBaseCurrency();

    if (mounted) {
      setState(() {
        transactions = list;
        hasMoreTransactions = list.length >= _transactionPageSize;
        categoryByKey = categoryMap;
        tagByKey = tagMap;
        accountById = accountMap;
        totalAssets = totals.assets;
        totalLiabilities = totals.liabilities;
        totalCreditLimit = credit.limit;
        totalCreditUsed = credit.used;
        totalCreditAvailable = credit.available;
        baseCurrency = base;
        isLoading = false;
      });
    }
  }

  Future<void> loadBooks() async {
    final bookList = await BookService(isar).getActiveBooks();
    final defaultBook = await BookService(isar).getDefaultBook();
    if (mounted) {
      setState(() {
        books = bookList;
        // 默认选中默认账本
        currentBookId ??= defaultBook?.id;
      });
    }
  }

  CreditSummary computeCreditSummary(
    List<JiveAccount> accounts,
    Map<int, double> balances,
  ) {
    double limit = 0;
    double used = 0;
    double available = 0;

    for (final account in accounts) {
      if (!AccountService.isCreditAccount(account)) continue;
      final accountLimit = account.creditLimit;
      if (accountLimit == null || accountLimit <= 0) continue;
      final balance = balances[account.id] ?? account.openingBalance;
      final usedForAccount = balance < 0 ? -balance : 0;
      limit += accountLimit;
      used += usedForAccount;
      final availableForAccount = accountLimit - usedForAccount;
      if (availableForAccount > 0) {
        available += availableForAccount;
      }
    }

    return CreditSummary(limit: limit, used: used, available: available);
  }
}
