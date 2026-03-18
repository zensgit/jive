import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'core/design_system/theme.dart';
import 'core/database/account_model.dart';
import 'core/database/transaction_model.dart';
import 'core/database/category_model.dart';
import 'core/database/auto_draft_model.dart';
import 'core/database/tag_model.dart';
import 'core/database/tag_rule_model.dart';
import 'core/database/currency_model.dart';
import 'core/service/account_service.dart';
import 'core/service/category_service.dart';
import 'core/service/category_icon_style.dart';
import 'core/service/currency_service.dart';
import 'core/service/transaction_service.dart';
import 'core/service/auto_draft_service.dart';
import 'core/service/auto_app_registry.dart';
import 'core/service/auto_app_settings.dart';
import 'core/service/auto_permission_service.dart';
import 'core/service/auto_permission_prompt_policy.dart';
import 'core/service/auto_settings.dart';
import 'core/service/tag_service.dart';
import 'core/service/data_reload_bus.dart';
import 'core/service/data_backup_service.dart';
import 'core/service/ui_pref_service.dart';
import 'core/service/database_service.dart';
import 'core/service/project_service.dart';
import 'core/service/recurring_service.dart';
import 'feature/accounts/accounts_screen.dart';
import 'feature/auto/auto_drafts_screen.dart';
import 'feature/auto/auto_rule_tester_screen.dart';
import 'feature/auto/auto_supported_apps_screen.dart';
import 'feature/auto/auto_settings_screen.dart';
import 'feature/import/import_center_screen.dart';
import 'feature/transactions/add_transaction_screen.dart';
import 'feature/transactions/transaction_detail_screen.dart';
import 'feature/stats/stats_home_screen.dart';
import 'feature/category/category_manager_screen.dart';
import 'feature/category/category_transactions_screen.dart';
import 'feature/tag/tag_management_screen.dart';
import 'feature/tag/tag_icon_catalog.dart';
import 'feature/project/project_list_screen.dart';
import 'feature/recurring/recurring_rule_list_screen.dart';
import 'feature/currency/currency_settings_screen.dart';
import 'feature/currency/currency_converter_screen.dart';
import 'feature/budget/budget_manager_screen.dart';
import 'feature/settings/settings_screen.dart';
import 'core/utils/logger_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await JiveLogger.init();
  final iconStyle = await CategoryIconStyleStore.load();
  CategoryIconStyleConfig.current = iconStyle;
  runApp(const JiveApp());
}

class JiveApp extends StatelessWidget {
  const JiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CategoryIconStyle>(
      valueListenable: CategoryIconStyleConfig.notifier,
      builder: (context, _, __) {
        return MaterialApp(
          title: 'Jive 积叶',
          debugShowCheckedModeBanner: false,
          theme: JiveTheme.lightTheme,
          darkTheme: JiveTheme.darkTheme,
          themeMode: ThemeMode.system, // 跟随系统主题
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
            return supportedLocales.first;
          },
          home: const MainScreen(),
        );
      },
    );
  }
}

class _RandomSeedResult {
  final int accounts;
  final int tags;
  final int transactions;

  const _RandomSeedResult({
    required this.accounts,
    required this.tags,
    required this.transactions,
  });
}

class _ProjectSeedResult {
  final String projectName;
  final int transactions;

  const _ProjectSeedResult({
    required this.projectName,
    required this.transactions,
  });
}

class _RandomAccountSeed {
  final String name;
  final String type;
  final String subType;

  const _RandomAccountSeed(this.name, this.type, this.subType);
}

enum _AutoPermissionDialogAction { later, settings }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const eventChannel = EventChannel('com.jive.app/stream');
  static const _prefKeyDemoSeedEnabled = 'demo_seed_enabled';
  static const _kE2eMode = bool.fromEnvironment(
    'JIVE_E2E',
    defaultValue: false,
  );

  late Isar _isar;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  Map<String, JiveTag> _tagByKey = {};
  Map<int, JiveAccount> _accountById = {};
  bool _isLoading = true;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  double _totalCreditLimit = 0;
  double _totalCreditUsed = 0;
  double _totalCreditAvailable = 0;
  int _currentIndex = 0;
  bool _demoSeedEnabled = true;
  bool _showSmartTagBadge = true;
  bool _dbReady = false;
  bool _isListening = false;
  final List<Map<String, dynamic>> _pendingAutoEvents = [];
  AutoSettings _autoSettings = AutoSettingsStore.defaults;
  int _pendingDraftCount = 0;
  Map<String, bool> _autoAppEnabled = {};
  int _autoAppEnabledCount = AutoAppRegistry.apps.length;
  bool _permissionDialogVisible = false;
  AutoPermissionPromptPolicy? _autoPermissionPromptPolicy;
  final ValueNotifier<int> _dataReloadSignal = ValueNotifier(0);
  final Random _random = Random();
  bool _isProcessingRecurringRules = false;

  // 多币种支持
  String _baseCurrency = 'CNY';
  CurrencyService? _currencyService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDatabase();
    _startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataReloadSignal.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    _dataReloadSignal.value += 1;
    DataReloadBus.notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoPermissions();
      unawaited(_processRecurringRules());
    }
  }

  Future<void> _initDatabase() async {
    _isar = await DatabaseService.getInstance();
    _autoPermissionPromptPolicy = AutoPermissionPromptPolicy(
      await SharedPreferences.getInstance(),
    );
    await _loadDemoSeedPrefs();
    await _loadAutoSettings();
    await _loadAutoAppSettings();
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TagService(_isar).initDefaultGroups();
    final currencyService = CurrencyService(_isar);
    await currencyService.initCurrencies();
    // 检查是否需要自动更新汇率
    await _checkAutoUpdateRates(currencyService);
    await ProjectService(_isar).initTestProjectIfNeeded();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    await _loadTransactions();
    await _loadAutoDraftCount();
    _dbReady = true;
    await _flushPendingAutoEvents();
    await _processRecurringRules();
    await _checkAutoPermissions();
  }

  Future<void> _processRecurringRules() async {
    if (!_dbReady || _isProcessingRecurringRules) return;
    _isProcessingRecurringRules = true;
    try {
      final result = await RecurringService(_isar).processDueRules();
      if (result.generatedDrafts > 0) {
        await _loadAutoDraftCount();
      }
      if (result.committedTransactions > 0) {
        await _loadTransactions();
        _notifyDataChanged();
      }
    } catch (e) {
      debugPrint('Recurring processing failed: $e');
    } finally {
      _isProcessingRecurringRules = false;
    }
  }

  Future<void> _checkAutoUpdateRates(CurrencyService currencyService) async {
    try {
      final pref = await currencyService.getPreference();
      if (pref == null || !pref.autoUpdateRates) return;

      // 检查是否需要更新（每天最多更新一次）
      final lastUpdate = pref.lastRateUpdate;
      if (lastUpdate != null) {
        final now = DateTime.now();
        final diff = now.difference(lastUpdate);
        if (diff.inHours < 24) return; // 24小时内不重复更新
      }

      // 后台静默更新汇率
      await currencyService.fetchAndUpdateRates(
        pref.baseCurrency,
        pref.enabledCurrencies,
      );
    } catch (e) {
      // 静默失败，不影响应用启动
      debugPrint('Auto rate update failed: $e');
    }
  }

  Future<void> _loadDemoSeedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _demoSeedEnabled = prefs.getBool(_prefKeyDemoSeedEnabled) ?? true;
    _showSmartTagBadge = await UiPrefService.getShowSmartTagBadge();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAutoSettings() async {
    final settings = await AutoSettingsStore.load();
    if (!mounted) return;
    setState(() {
      _autoSettings = settings;
    });
  }

  Future<void> _loadAutoAppSettings() async {
    final map = await AutoAppSettingsStore.loadEnabledMap();
    if (!mounted) return;
    setState(() {
      _autoAppEnabled = map;
      _autoAppEnabledCount = AutoAppSettingsStore.enabledCount(map);
    });
  }

  Future<void> _setAutoSettings(AutoSettings settings) async {
    if (!mounted) return;
    final wasEnabled = _autoSettings.enabled;
    setState(() {
      _autoSettings = settings;
    });
    await AutoSettingsStore.save(settings);
    if (!wasEnabled && settings.enabled) {
      await _autoPermissionPromptPolicy?.clearSnooze();
    }
    await _checkAutoPermissions();
  }

  Future<void> _checkAutoPermissions() async {
    if (_kE2eMode) return;
    if (!_dbReady) return;
    final promptPolicy = _autoPermissionPromptPolicy;
    if (promptPolicy == null) return;
    if (!_autoSettings.enabled) return;
    final status = await AutoPermissionService.getStatus();
    if (!mounted) return;
    final shouldPrompt = await promptPolicy.shouldPrompt(
      autoEnabled: _autoSettings.enabled,
      allRequiredPermissionsGranted: status.allRequired,
      dialogVisible: _permissionDialogVisible,
    );
    if (!shouldPrompt) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _permissionDialogVisible) return;
      _permissionDialogVisible = true;
      try {
        final missing = status.missingRequiredLabels();
        final action = await showDialog<_AutoPermissionDialogAction>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('自动记账权限未开启'),
            content: Text('未开启：${missing.join('、')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _AutoPermissionDialogAction.later,
                ),
                child: const Text('稍后'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _AutoPermissionDialogAction.settings,
                ),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        // Any close path should enter cooldown to avoid repeated interruptions.
        await promptPolicy.snoozePrompt();
        if (action == _AutoPermissionDialogAction.settings && mounted) {
          _openAutoSettings();
        }
      } finally {
        _permissionDialogVisible = false;
      }
    });
  }

  Future<void> _setDemoSeedEnabled(bool enabled) async {
    _demoSeedEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDemoSeedEnabled, enabled);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _seedDemoDataIfNeeded() async {
    if (!kDebugMode) return false;
    if (!_demoSeedEnabled) return false;
    final existingCount = await _isar.jiveTransactions.count();
    if (existingCount > 0) return false;

    final accountService = AccountService(_isar);
    final accounts = await accountService.getActiveAccounts();
    if (accounts.isEmpty) return false;

    final accountByKey = {for (final account in accounts) account.key: account};
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
      await _isar.writeTxn(() async {
        for (final account in accounts) {
          final opening = openingBalances[account.key];
          if (opening == null) continue;
          account.openingBalance = opening;
          await _isar.collection<JiveAccount>().put(account);
        }
      });
    }

    final categories = await _isar.collection<JiveCategory>().where().findAll();
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

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.putAll([...demoTxs, transfer]);
    });
    return true;
  }

  Future<void> _handleRandomSeed() async {
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
    final result = await _seedRandomTestData(
      accountCount: accountCount,
      tagCount: tagCount,
      transactionCount: transactionCount,
    );
    await _loadTransactions();
    await _loadAutoDraftCount();
    _notifyDataChanged();
    _showMessage(
      '已生成随机测试数据：账户${result.accounts}、标签${result.tags}、交易${result.transactions}',
    );
  }

  Future<void> _handleProjectSeedLarge() async {
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
    final result = await _seedProjectTestData(
      transactionCount: transactionCount,
      daysSpan: daysSpan,
    );
    await _loadTransactions();
    await _loadAutoDraftCount();
    _notifyDataChanged();
    _showMessage('已生成项目测试数据：${result.projectName}，交易${result.transactions} 笔');
  }

  Future<_RandomSeedResult> _seedRandomTestData({
    required int accountCount,
    required int tagCount,
    required int transactionCount,
  }) async {
    final accountService = AccountService(_isar);
    final tagService = TagService(_isar);
    await accountService.initDefaultAccounts();
    await tagService.initDefaultGroups();
    await CategoryService(_isar).initDefaultCategories();

    final accountTemplates = <_RandomAccountSeed>[
      _RandomAccountSeed('测试钱包', AccountService.typeAsset, 'wallet'),
      _RandomAccountSeed('测试现金', AccountService.typeAsset, 'cash'),
      _RandomAccountSeed('测试银行卡', AccountService.typeAsset, 'bank'),
      _RandomAccountSeed('测试微信', AccountService.typeAsset, 'wechat'),
      _RandomAccountSeed('测试支付宝', AccountService.typeAsset, 'alipay'),
      _RandomAccountSeed('测试信用卡', AccountService.typeLiability, 'credit'),
      _RandomAccountSeed('测试借入', AccountService.typeLiability, 'loan'),
    ];

    final createdAccounts = <JiveAccount>[];
    for (var i = 0; i < accountCount; i++) {
      final seed = accountTemplates[_random.nextInt(accountTemplates.length)];
      final name = '${seed.name}${_randomSuffix()}';
      final amount = 200 + _random.nextInt(9800);
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
      final name = '随机标签${_randomSuffix()}';
      final group = refreshedGroups.isEmpty
          ? null
          : refreshedGroups[_random.nextInt(refreshedGroups.length)];
      final color = TagService
          .defaultColors[_random.nextInt(TagService.defaultColors.length)];
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
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final expenseParents = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome && !cat.isHidden)
        .toList();
    final incomeParents = categories
        .where((cat) => cat.parentKey == null && cat.isIncome && !cat.isHidden)
        .toList();

    JiveCategory? pickParent(List<JiveCategory> parents) {
      if (parents.isEmpty) return null;
      return parents[_random.nextInt(parents.length)];
    }

    JiveCategory? pickChild(String parentKey) {
      final children = categories
          .where((cat) => cat.parentKey == parentKey && !cat.isHidden)
          .toList();
      if (children.isEmpty) return null;
      return children[_random.nextInt(children.length)];
    }

    List<String> pickTags() {
      if (tags.isEmpty) return [];
      final count = _random.nextInt(3);
      if (count == 0) return [];
      final pool = List<JiveTag>.from(tags)..shuffle(_random);
      return pool.take(count).map((tag) => tag.key).toList();
    }

    final now = DateTime.now();
    final transactions = <JiveTransaction>[];
    for (var i = 0; i < transactionCount; i++) {
      final roll = _random.nextInt(100);
      final type = roll < 15 ? 'income' : (roll < 25 ? 'transfer' : 'expense');
      final timestamp = now.subtract(
        Duration(days: _random.nextInt(120), minutes: _random.nextInt(1440)),
      );
      final account = accounts[_random.nextInt(accounts.length)];
      if (type == 'transfer') {
        final others = accounts.where((a) => a.id != account.id).toList();
        if (others.isEmpty) continue;
        final toAccount = others[_random.nextInt(others.length)];
        final amount = 50 + _random.nextInt(3000);
        transactions.add(
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
          ? 200 + _random.nextInt(12000)
          : 10 + _random.nextInt(1200);
      transactions.add(
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

    await _isar.writeTxn(() async {
      if (transactions.isNotEmpty) {
        await _isar.jiveTransactions.putAll(transactions);
      }
    });
    await tagService.refreshUsageCounts();

    return _RandomSeedResult(
      accounts: createdAccounts.length,
      tags: createdTags.length,
      transactions: transactions.length,
    );
  }

  Future<_ProjectSeedResult> _seedProjectTestData({
    required int transactionCount,
    required int daysSpan,
  }) async {
    final accountService = AccountService(_isar);
    final tagService = TagService(_isar);
    await accountService.initDefaultAccounts();
    await tagService.initDefaultGroups();
    await CategoryService(_isar).initDefaultCategories();

    final projectService = ProjectService(_isar);
    final projectName = '项目测试${_randomSuffix()}';
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
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final expenseParents = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome && !cat.isHidden)
        .toList();

    JiveCategory? pickParent() {
      if (expenseParents.isEmpty) return null;
      return expenseParents[_random.nextInt(expenseParents.length)];
    }

    JiveCategory? pickChild(String parentKey) {
      final children = categories
          .where((cat) => cat.parentKey == parentKey && !cat.isHidden)
          .toList();
      if (children.isEmpty) return null;
      return children[_random.nextInt(children.length)];
    }

    List<String> pickTags() {
      if (tags.isEmpty) return [];
      final count = _random.nextInt(3);
      if (count == 0) return [];
      final pool = List<JiveTag>.from(tags)..shuffle(_random);
      return pool.take(count).map((tag) => tag.key).toList();
    }

    final now = DateTime.now();
    final transactions = <JiveTransaction>[];
    for (var i = 0; i < transactionCount; i++) {
      if (accounts.isEmpty) break;
      final timestamp = now.subtract(
        Duration(
          days: _random.nextInt(daysSpan),
          minutes: _random.nextInt(1440),
        ),
      );
      final account = accounts[_random.nextInt(accounts.length)];
      final parent = pickParent();
      final child = parent == null ? null : pickChild(parent.key);
      final amount = 10 + _random.nextInt(5000);
      transactions.add(
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

    await _isar.writeTxn(() async {
      if (transactions.isNotEmpty) {
        await _isar.jiveTransactions.putAll(transactions);
      }
    });
    await tagService.refreshUsageCounts();

    return _ProjectSeedResult(
      projectName: project.name,
      transactions: transactions.length,
    );
  }

  String _randomSuffix() {
    return '${1000 + _random.nextInt(9000)}';
  }

  Future<void> _clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.collection<JiveTransaction>().clear();
      await _isar.collection<JiveAccount>().clear();
      await _isar.collection<JiveCategory>().clear();
      await _isar.collection<JiveAutoDraft>().clear();
      await _isar.collection<JiveTag>().clear();
      await _isar.collection<JiveTagGroup>().clear();
      await _isar.collection<JiveTagRule>().clear();
    });
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TagService(_isar).initDefaultGroups();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    await _loadTransactions();
    await _loadAutoDraftCount();
    _notifyDataChanged();
  }

  Future<void> _exportBackup() async {
    try {
      final file = await JiveDataBackupService.exportToFile(_isar);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Jive 数据备份'),
      );
      _showMessage('已导出数据');
    } catch (e) {
      _showMessage('导出失败：$e');
    }
  }

  Future<void> _importBackup() async {
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
        _isar,
        file,
        clearBefore: true,
      );
      await TagService(_isar).refreshUsageCounts();
      await TransactionService(_isar).migrateTransactionCategoryKeys();
      await TransactionService(_isar).migrateTransactionAccountIds();
      await _loadTransactions();
      await _loadAutoDraftCount();
      _notifyDataChanged();
      _showMessage('导入完成：交易${summary.transactions}条，标签${summary.tags}个');
    } catch (e) {
      _showMessage('导入失败：$e');
    }
  }

  Future<void> _loadTransactions() async {
    final list = await _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .findAll();
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};
    final tags = await _isar.collection<JiveTag>().where().findAll();
    final tagMap = {for (final t in tags) t.key: t};
    final accountService = AccountService(_isar);
    final accounts = await accountService.getActiveAccounts();
    final accountMap = {for (final a in accounts) a.id: a};
    final balances = await accountService.computeBalances(accounts: accounts);
    final totals = accountService.calculateTotals(accounts, balances);
    final creditSummary = _computeCreditSummary(accounts, balances);

    // 加载基础货币
    _currencyService ??= CurrencyService(_isar);
    final baseCurrency = await _currencyService!.getBaseCurrency();

    if (mounted) {
      setState(() {
        _transactions = list;
        _categoryByKey = categoryMap;
        _tagByKey = tagMap;
        _accountById = accountMap;
        _totalAssets = totals.assets;
        _totalLiabilities = totals.liabilities;
        _totalCreditLimit = creditSummary.limit;
        _totalCreditUsed = creditSummary.used;
        _totalCreditAvailable = creditSummary.available;
        _baseCurrency = baseCurrency;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAutoDraftCount() async {
    final count = await _isar.collection<JiveAutoDraft>().count();
    if (!mounted) return;
    setState(() {
      _pendingDraftCount = count;
    });
  }

  Future<void> _flushPendingAutoEvents() async {
    if (_pendingAutoEvents.isEmpty) return;
    final events = List<Map<String, dynamic>>.from(_pendingAutoEvents);
    _pendingAutoEvents.clear();
    for (final event in events) {
      await _handleAutoEvent(event);
    }
  }

  Future<void> _handleAutoEvent(Map<String, dynamic> data) async {
    if (!_autoSettings.enabled) {
      JiveLogger.w("AutoCapture ignored: auto disabled");
      return;
    }
    final packageName = _resolveAutoPackageName(data);
    if (!_isAutoAppEnabled(packageName)) {
      JiveLogger.w("AutoCapture ignored: app disabled package=$packageName");
      return;
    }
    if (_autoSettings.keywordFilterEnabled) {
      final rawText = data['raw_text']?.toString() ?? '';
      if (rawText.isNotEmpty &&
          !_containsAnyKeyword(rawText, _autoSettings.keywordFilters)) {
        JiveLogger.w("AutoCapture ignored: keyword filter raw=$rawText");
        return;
      }
    }
    final capture = AutoCapture.fromEvent(data);
    if (!capture.isValid) {
      JiveLogger.w(
        "AutoCapture invalid: source=${capture.source} amount=${capture.amount}",
      );
      return;
    }
    JiveLogger.i(
      "AutoCapture received: source=${capture.source} amount=${capture.amount} type=${capture.type} raw=${capture.rawText}",
    );
    final result = await AutoDraftService(_isar).ingestCapture(
      capture,
      directCommit: _autoSettings.directCommit,
      settings: _autoSettings,
    );
    if (!mounted) return;
    JiveLogger.i(
      "AutoCapture result: inserted=${result.inserted} committed=${result.committed} duplicate=${result.duplicate}",
    );
    if (result.duplicate) {
      _showMessage("已忽略重复自动记账");
      return;
    }
    if (result.merged) {
      _showMessage("已合并转账记录");
      await _loadAutoDraftCount();
      return;
    }
    await _loadAutoDraftCount();
    if (result.committed) {
      await _loadTransactions();
      _notifyDataChanged();
      _showMessage("已自动入账");
      return;
    }
    if (result.inserted) {
      _showMessage("已加入待确认");
    }
  }

  bool _containsAnyKeyword(String text, List<String> keywords) {
    if (keywords.isEmpty) return true;
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  String? _resolveAutoPackageName(Map<String, dynamic> data) {
    final pkg = data['package_name']?.toString();
    if (pkg != null && pkg.isNotEmpty) return pkg;
    final source = data['source']?.toString();
    return AutoAppRegistry.resolvePackage(source);
  }

  bool _isAutoAppEnabled(String? packageName) {
    if (packageName == null) return true;
    if (!AutoAppRegistry.isSupported(packageName)) return true;
    return AutoAppSettingsStore.isEnabled(_autoAppEnabled, packageName);
  }

  void _startListening() {
    if (_isListening) return;
    _isListening = true;
    eventChannel.receiveBroadcastStream().listen((dynamic event) async {
      if (event is! Map) return;
      final payload = Map<String, dynamic>.from(event);
      if (!_dbReady) {
        _pendingAutoEvents.add(payload);
        return;
      }
      await _handleAutoEvent(payload);
    });
  }

  Future<void> _openAutoSettings() async {
    if (!_dbReady) {
      _showMessage("数据库尚未就绪");
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoSettingsScreen(isar: _isar)),
    );
    await _loadAutoSettings();
    await _loadAutoDraftCount();
  }

  Future<void> _openAutoDrafts() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoDraftsScreen()),
    );
    if (changed == true) {
      await _loadTransactions();
      await _loadAutoDraftCount();
      _notifyDataChanged();
    }
  }

  Future<void> _openImportCenter() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportCenterScreen()),
    );
    if (changed == true) {
      await _loadTransactions();
      await _loadAutoDraftCount();
      _notifyDataChanged();
    }
  }

  Future<void> _openAutoRuleTester() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoRuleTesterScreen(isar: _isar),
      ),
    );
  }

  Future<void> _openAutoSupportedApps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSupportedAppsScreen()),
    );
    await _loadAutoAppSettings();
  }

  Future<void> _openCategoryManager() async {
    if (!_dbReady) {
      _showMessage("数据库尚未就绪");
      return;
    }
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryManagerScreen(isar: _isar, onlyUserCategories: true),
      ),
    );
    if (changed == true) {
      await _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          StatsHomeScreen(reloadSignal: _dataReloadSignal),
          AccountsScreen(
            reloadSignal: _dataReloadSignal,
            onDataChanged: _notifyDataChanged,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true) {
            await _loadTransactions();
            await _loadAutoDraftCount();
            _notifyDataChanged();
          }
        },
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1 || idx == 2) {
            _notifyDataChanged();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: "Home"),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: "Stats"),
          NavigationDestination(icon: Icon(Icons.wallet), label: "Assets"),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTightLandscape = isLandscape;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: isLandscape
            ? _buildHomeLandscapeContent(tight: isTightLandscape)
            : _buildHomeColumnContent(),
      ),
    );
  }

  Widget _buildHomeColumnContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTopBar(),
        const SizedBox(height: 24),
        _buildAssetCard(),
        const SizedBox(height: 32),
        _buildRecentTitle(),
        const SizedBox(height: 16),
        _buildTransactionList(),
      ],
    );
  }

  Widget _buildHomeLandscapeContent({bool tight = false}) {
    final topGap = tight ? 4.0 : 8.0;
    final sectionGap = tight ? 8.0 : 12.0;
    final listGap = tight ? 6.0 : 8.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topGap),
                        _buildTopBar(compact: true),
                        SizedBox(height: sectionGap),
                        _buildAssetCard(compact: true, tight: tight),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topGap),
              _buildRecentTitle(compact: tight),
              SizedBox(height: listGap),
              Expanded(child: _buildTransactionListBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({bool compact = false}) {
    final greetingSize = compact ? 12.0 : 14.0;
    final nameSize = compact ? 20.0 : 24.0;
    final avatarRadius = compact ? 18.0 : 20.0;
    final iconSize = compact ? 18.0 : 20.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Evening,",
              style: GoogleFonts.lato(
                color: Colors.grey,
                fontSize: greetingSize,
              ),
            ),
            Text(
              "Huazhou",
              style: GoogleFonts.lato(
                color: Colors.black87,
                fontSize: nameSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              builder: (context) => SafeArea(
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.75,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return StatefulBuilder(
                      builder: (context, setSheetState) {
                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 12),
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.science_outlined),
                              title: const Text("测试数据开关"),
                              subtitle: const Text("仅用于调试展示"),
                              value: _demoSeedEnabled,
                              onChanged: (value) async {
                                setSheetState(() {
                                  _demoSeedEnabled = value;
                                });
                                await _setDemoSeedEnabled(value);
                                _showMessage(value ? "已开启测试数据" : "已关闭测试数据");
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.auto_awesome),
                              title: const Text("注入测试数据"),
                              subtitle: Text(
                                _demoSeedEnabled ? "写入一批示例数据" : "请先开启测试数据开关",
                              ),
                              onTap: () async {
                                if (!_demoSeedEnabled) {
                                  _showMessage("请先开启测试数据开关");
                                  return;
                                }
                                Navigator.pop(context);
                                final inserted = await _seedDemoDataIfNeeded();
                                await _loadTransactions();
                                if (inserted) {
                                  _notifyDataChanged();
                                }
                                _showMessage(
                                  inserted ? "已注入测试数据" : "已有数据，未注入测试数据",
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.auto_awesome_motion),
                              title: const Text("生成随机测试数据"),
                              subtitle: Text(
                                _demoSeedEnabled
                                    ? "随机生成账户/标签/交易"
                                    : "请先开启测试数据开关",
                              ),
                              onTap: () async {
                                if (!_demoSeedEnabled) {
                                  _showMessage("请先开启测试数据开关");
                                  return;
                                }
                                Navigator.pop(context);
                                await _handleRandomSeed();
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.folder_special_outlined,
                              ),
                              title: const Text("生成项目测试数据（大量）"),
                              subtitle: Text(
                                _demoSeedEnabled
                                    ? "生成一年以上交易并关联到项目"
                                    : "请先开启测试数据开关",
                              ),
                              onTap: () async {
                                if (!_demoSeedEnabled) {
                                  _showMessage("请先开启测试数据开关");
                                  return;
                                }
                                Navigator.pop(context);
                                await _handleProjectSeedLarge();
                              },
                            ),
                            if (kDebugMode)
                              ListTile(
                                leading: const Icon(Icons.bolt_outlined),
                                title: const Text("模拟自动记账"),
                                subtitle: const Text("写入一条自动记账事件"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final now = DateTime.now();
                                  await _handleAutoEvent({
                                    "source": "WeChat",
                                    "amount": "12.34",
                                    "raw_text": "微信 支付成功 测试 12.34",
                                    "type": "expense",
                                    "timestamp": now.millisecondsSinceEpoch,
                                    "package_name": "com.tencent.mm",
                                  });
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.category_outlined),
                              title: const Text("分类管理"),
                              subtitle: const Text("管理自定义分类"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openCategoryManager();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings_outlined),
                              title: const Text("设置"),
                              subtitle: const Text("外观与偏好"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.folder_outlined),
                              title: const Text("项目追踪"),
                              subtitle: const Text("追踪旅行、装修等专项支出"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProjectListScreen(),
                                  ),
                                );
                                await _loadTransactions();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.currency_exchange),
                              title: const Text("货币与汇率"),
                              subtitle: const Text("管理多币种和汇率"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CurrencySettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              title: const Text("预算管理"),
                              subtitle: const Text("设置和追踪预算"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BudgetManagerScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.repeat),
                              title: const Text("周期记账"),
                              subtitle: const Text("自动生成草稿或入账"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RecurringRuleListScreen(),
                                  ),
                                );
                                await _loadTransactions();
                                await _loadAutoDraftCount();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.label_outline),
                              title: const Text("标签管理"),
                              subtitle: const Text("管理交易标签"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TagManagementScreen(isar: _isar),
                                  ),
                                );
                                await _loadTransactions();
                              },
                            ),
                            if (kDebugMode)
                              ListTile(
                                leading: const Icon(
                                  Icons.restart_alt,
                                  color: Colors.orangeAccent,
                                ),
                                title: const Text(
                                  "重置系统分类",
                                  style: TextStyle(color: Colors.orangeAccent),
                                ),
                                subtitle: const Text("清空分类并重新载入系统分类"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text("重置系统分类"),
                                      content: const Text(
                                        "将清空所有分类并重新载入系统分类，是否继续？",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text("取消"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text("重置"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await CategoryService(
                                    _isar,
                                  ).resetCategories();
                                  await TransactionService(
                                    _isar,
                                  ).migrateTransactionCategoryKeys();
                                  await _loadTransactions();
                                  _showMessage("已重置系统分类");
                                },
                              ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                "清空数据",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text("清空数据"),
                                    content: const Text(
                                      "将删除全部交易、账户和分类数据，是否继续？",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text("取消"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text("清空"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                await _clearAllData();
                                _showMessage("已清空数据");
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.file_download_outlined),
                              title: const Text("导出数据"),
                              subtitle: const Text("导出为备份文件"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _exportBackup();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.file_upload_outlined),
                              title: const Text("导入数据"),
                              subtitle: const Text("导入将覆盖当前数据"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _importBackup();
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.playlist_add_check_circle_outlined,
                              ),
                              title: const Text("导入中心"),
                              subtitle: const Text("文本/CSV/OCR 导入到待确认草稿"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openImportCenter();
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const Icon(Icons.auto_awesome),
                              title: const Text("自动记账"),
                              subtitle: Text(
                                _autoSettings.enabled ? "已开启" : "已关闭",
                              ),
                              value: _autoSettings.enabled,
                              onChanged: (value) async {
                                final updated = _autoSettings.copyWith(
                                  enabled: value,
                                );
                                setSheetState(() {
                                  _autoSettings = updated;
                                });
                                await _setAutoSettings(updated);
                              },
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.playlist_add_check),
                              title: const Text("自动入账"),
                              subtitle: const Text("关闭则进入待确认"),
                              value: _autoSettings.directCommit,
                              onChanged: (value) async {
                                final updated = _autoSettings.copyWith(
                                  directCommit: value,
                                );
                                setSheetState(() {
                                  _autoSettings = updated;
                                });
                                await _setAutoSettings(updated);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.apps),
                              title: const Text("自动记账支持的应用"),
                              subtitle: Text(
                                "已启用 $_autoAppEnabledCount / ${AutoAppRegistry.apps.length}",
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openAutoSupportedApps();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.inbox_outlined),
                              title: const Text("待确认自动记账"),
                              subtitle: Text("当前 $_pendingDraftCount 条"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openAutoDrafts();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.rule),
                              title: const Text("自动规则测试"),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openAutoRuleTester();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text("自动记账设置"),
                              onTap: () {
                                Navigator.pop(context);
                                _openAutoSettings();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.bug_report),
                              title: const Text("导出调试日志"),
                              onTap: () {
                                Navigator.pop(context);
                                JiveLogger.exportLogs();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.settings, color: Colors.black54, size: iconSize),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard({bool compact = false, bool tight = false}) {
    final padding = tight ? 16.0 : (compact ? 20.0 : 28.0);
    final amountSize = tight ? 28.0 : (compact ? 32.0 : 40.0);
    final headerGap = tight ? 10.0 : (compact ? 14.0 : 20.0);
    final actionGap = tight ? 12.0 : (compact ? 18.0 : 32.0);
    final titleSize = tight ? 11.0 : (compact ? 12.0 : 14.0);
    final showActionLabels = !tight;
    final netAssets = _totalAssets - _totalLiabilities;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wallet, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "净资产",
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: titleSize,
                ),
              ),
            ],
          ),
          SizedBox(height: headerGap),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                NumberFormat.currency(symbol: "¥").format(netAssets),
                maxLines: 1,
                style: GoogleFonts.rubik(
                  color: Colors.white,
                  fontSize: amountSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!tight) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBalanceMeta("资产", _totalAssets),
                const SizedBox(width: 16),
                _buildBalanceMeta("负债", _totalLiabilities),
              ],
            ),
            if (_totalCreditLimit > 0) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _buildBalanceMeta("信用额度", _totalCreditLimit),
                  _buildBalanceMeta("已用", _totalCreditUsed),
                  _buildBalanceMeta("可用", _totalCreditAvailable),
                ],
              ),
            ],
          ],
          SizedBox(height: actionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionBtn(
                Icons.arrow_downward,
                "收入",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: () => _showAddTransaction('income'),
              ),
              _buildActionBtn(
                Icons.arrow_upward,
                "支出",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: () => _showAddTransaction('expense'),
              ),
              _buildActionBtn(
                Icons.swap_horiz,
                "转账",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: () => _showAddTransaction('transfer'),
              ),
              _buildActionBtn(
                Icons.currency_exchange,
                "汇率",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrencyConverterScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTitle({bool compact = false}) {
    final titleSize = compact ? 18.0 : 20.0;
    final actionSize = compact ? 12.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Recent Transactions",
            style: GoogleFonts.lato(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            key: const Key('home_view_all_transactions_button'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CategoryTransactionsScreen(title: "全部账单"),
                ),
              );
            },
            child: Text(
              "View All",
              style: GoogleFonts.lato(
                color: JiveTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: actionSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Expanded(child: _buildTransactionListBody());
  }

  Widget _buildTransactionListBody({
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(_transactions[index]);
      },
    );
  }

  /// 显示添加交易页面
  Future<void> _showAddTransaction(String type) async {
    TransactionType txType;
    switch (type) {
      case 'income':
        txType = TransactionType.income;
        break;
      case 'transfer':
        txType = TransactionType.transfer;
        break;
      default:
        txType = TransactionType.expense;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: txType),
      ),
    );
    if (result == true) {
      await _loadTransactions();
      await _loadAutoDraftCount();
      _notifyDataChanged();
    }
  }

  Widget _buildActionBtn(
    IconData icon,
    String label, {
    bool compact = false,
    bool tight = false,
    bool showLabel = true,
    VoidCallback? onTap,
  }) {
    final padding = tight ? 8.0 : (compact ? 10.0 : 12.0);
    final iconSize = tight ? 18.0 : (compact ? 20.0 : 24.0);
    final labelSize = tight ? 10.0 : (compact ? 11.0 : 12.0);
    final gap = tight ? 4.0 : (compact ? 6.0 : 8.0);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          if (showLabel) ...[
            SizedBox(height: gap),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: labelSize),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceMeta(String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Text(
          NumberFormat.compactCurrency(
            symbol: "¥",
            decimalDigits: 0,
          ).format(amount),
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No transactions yet",
            style: GoogleFonts.lato(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  _CreditSummary _computeCreditSummary(
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

    return _CreditSummary(limit: limit, used: used, available: available);
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return "未分类";
  }

  Widget _buildTransactionItem(JiveTransaction item) {
    final type = item.type ?? "expense";
    final isIncome = type == "income";
    final isTransfer = type == "transfer";
    final isWeChat = item.source == 'WeChat';
    IconData leadingIcon;
    Color leadingColor;
    Color leadingBg;
    if (isTransfer) {
      leadingIcon = Icons.swap_horiz;
      leadingColor = Colors.blueGrey;
      leadingBg = Colors.blueGrey.shade50;
    } else if (isWeChat) {
      leadingIcon = Icons.wechat;
      leadingColor = Colors.green;
      leadingBg = const Color(0xFFE8F5E9);
    } else {
      leadingIcon = Icons.payment;
      leadingColor = Colors.blue;
      leadingBg = const Color(0xFFE3F2FD);
    }
    final amountPrefix = isTransfer ? "" : (isIncome ? "+ " : "- ");
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (isIncome ? Colors.green : Colors.redAccent);
    final parentName = _displayCategoryName(item.categoryKey, item.category);
    final subName = _displayCategoryName(item.subCategoryKey, item.subCategory);
    final note = (item.note ?? '').trim();
    final hasNote = note.isNotEmpty;
    final showSmartBadge = _showSmartTagBadge && item.smartTagKeys.isNotEmpty;
    final tags = item.tagKeys
        .map((key) => _tagByKey[key])
        .whereType<JiveTag>()
        .toList();

    // 获取交易账户的货币信息
    final account = item.accountId != null
        ? _accountById[item.accountId]
        : null;
    final txCurrency = account?.currency ?? 'CNY';
    final txSymbol = CurrencyDefaults.getSymbol(txCurrency);
    final txDecimals = CurrencyDefaults.getDecimalPlaces(txCurrency);
    final isMultiCurrency = txCurrency != _baseCurrency;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await showTransactionDetailSheet(context, item.id);
        if (updated == true) {
          await _loadTransactions();
          _notifyDataChanged();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: leadingBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leadingIcon, color: leadingColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$subName • ${DateFormat('MM-dd HH:mm').format(item.timestamp)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (showSmartBadge) ...[
                        const SizedBox(width: 6),
                        _buildSmartTagBadge(),
                      ],
                    ],
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(3).map((tag) {
                        final color =
                            AccountService.parseColorHex(tag.colorHex) ??
                            Colors.blueGrey;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            tagDisplayName(tag),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$amountPrefix$txSymbol${item.amount.toStringAsFixed(txDecimals)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amountColor,
                  ),
                ),
                if (isMultiCurrency)
                  Text(
                    txCurrency,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTagBadge() {
    final badge = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: JiveTheme.primaryGreen.withValues(alpha: 0.4),
        ),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 12,
        color: JiveTheme.primaryGreen,
      ),
    );
    return Tooltip(
      message: '该交易由智能标签自动打标',
      triggerMode: TooltipTriggerMode.longPress,
      child: badge,
    );
  }
}

class _CreditSummary {
  final double limit;
  final double used;
  final double available;

  const _CreditSummary({
    required this.limit,
    required this.used,
    required this.available,
  });
}
