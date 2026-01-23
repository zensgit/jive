import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design_system/theme.dart';
import 'core/database/account_model.dart';
import 'core/database/transaction_model.dart';
import 'core/database/category_model.dart';
import 'core/database/auto_draft_model.dart';
import 'core/database/tag_model.dart';
import 'core/database/tag_conversion_log.dart';
import 'core/service/account_service.dart';
import 'core/service/category_service.dart';
import 'core/service/transaction_service.dart';
import 'core/service/auto_draft_service.dart';
import 'core/service/auto_app_registry.dart';
import 'core/service/auto_app_settings.dart';
import 'core/service/auto_permission_service.dart';
import 'core/service/auto_settings.dart';
import 'core/service/tag_service.dart';
import 'feature/accounts/accounts_screen.dart';
import 'feature/auto/auto_drafts_screen.dart';
import 'feature/auto/auto_rule_tester_screen.dart';
import 'feature/auto/auto_supported_apps_screen.dart';
import 'feature/auto/auto_settings_screen.dart';
import 'feature/transactions/add_transaction_screen.dart';
import 'feature/transactions/transaction_detail_screen.dart';
import 'feature/stats/stats_screen.dart';
import 'feature/category/category_manager_screen.dart';
import 'feature/tag/tag_management_screen.dart';
import 'feature/tag/tag_icon_catalog.dart';
import 'feature/category/category_transactions_screen.dart';
import 'core/utils/logger_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await JiveLogger.init();
  runApp(const JiveApp());
}

class JiveApp extends StatelessWidget {
  const JiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jive 积叶',
      debugShowCheckedModeBanner: false,
      theme: JiveTheme.lightTheme,
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
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const eventChannel = EventChannel('com.jive.app/stream');
  static const _prefKeyDemoSeedEnabled = 'demo_seed_enabled';

  late Isar _isar;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  Map<String, JiveTag> _tagByKey = {};
  bool _isLoading = true;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  int? _defaultAccountId;
  int _currentIndex = 0;
  bool _demoSeedEnabled = true;
  bool _dbReady = false;
  bool _isListening = false;
  final List<Map<String, dynamic>> _pendingAutoEvents = [];
  AutoSettings _autoSettings = AutoSettingsStore.defaults;
  int _pendingDraftCount = 0;
  Map<String, bool> _autoAppEnabled = {};
  int _autoAppEnabledCount = AutoAppRegistry.apps.length;
  bool _permissionDialogVisible = false;
  final ValueNotifier<int> _dataReloadSignal = ValueNotifier(0);

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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoPermissions();
    }
  }

  Future<void> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open([
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
        JiveTagSchema,
        JiveTagGroupSchema,
        JiveTagConversionLogSchema,
      ], directory: dir.path);
    }
    await _loadDemoSeedPrefs();
    await _loadAutoSettings();
    await _loadAutoAppSettings();
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TagService(_isar).initDefaultGroups();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    _defaultAccountId = (await AccountService(_isar).getDefaultAccount())?.id;
    await _loadTransactions();
    await _loadAutoDraftCount();
    _dbReady = true;
    await _flushPendingAutoEvents();
    await _checkAutoPermissions();
  }

  Future<void> _loadDemoSeedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _demoSeedEnabled = prefs.getBool(_prefKeyDemoSeedEnabled) ?? true;
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
    setState(() {
      _autoSettings = settings;
    });
    await AutoSettingsStore.save(settings);
    await _checkAutoPermissions();
  }

  Future<void> _checkAutoPermissions() async {
    if (!_dbReady) return;
    if (!_autoSettings.enabled) return;
    final status = await AutoPermissionService.getStatus();
    if (!mounted) return;
    if (status.allRequired) return;
    if (_permissionDialogVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _permissionDialogVisible) return;
      _permissionDialogVisible = true;
      final missing = status.missingRequiredLabels();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('自动记账权限未开启'),
          content: Text('未开启：${missing.join('、')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openAutoSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        ),
      );
      _permissionDialogVisible = false;
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

  Future<void> _clearAllData() async {
    await _isar.writeTxn(() async {
      await _isar.collection<JiveTransaction>().clear();
      await _isar.collection<JiveAccount>().clear();
      await _isar.collection<JiveCategory>().clear();
      await _isar.collection<JiveAutoDraft>().clear();
      await _isar.collection<JiveTag>().clear();
      await _isar.collection<JiveTagGroup>().clear();
    });
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TagService(_isar).initDefaultGroups();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    _defaultAccountId = (await AccountService(_isar).getDefaultAccount())?.id;
    await _loadTransactions();
    await _loadAutoDraftCount();
    _notifyDataChanged();
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
    final balances = await accountService.computeBalances(accounts: accounts);
    final totals = accountService.calculateTotals(accounts, balances);

    if (mounted) {
      setState(() {
        _transactions = list;
        _categoryByKey = categoryMap;
        _tagByKey = tagMap;
        _totalAssets = totals.assets;
        _totalLiabilities = totals.liabilities;
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
          StatsScreen(reloadSignal: _dataReloadSignal),
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
            _loadTransactions();
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
            color: const Color(0xFF2E7D32).withOpacity(0.4),
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
          Text(
            NumberFormat.currency(symbol: "¥").format(netAssets),
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: amountSize,
              fontWeight: FontWeight.w600,
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
          ],
          SizedBox(height: actionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionBtn(
                Icons.arrow_downward,
                "Income",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
              ),
              _buildActionBtn(
                Icons.arrow_upward,
                "Expense",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
              ),
              _buildActionBtn(
                Icons.swap_horiz,
                "Transfer",
                compact: compact,
                tight: tight,
                showLabel: showActionLabels,
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

  Widget _buildActionBtn(
    IconData icon,
    String label, {
    bool compact = false,
    bool tight = false,
    bool showLabel = true,
  }) {
    final padding = tight ? 8.0 : (compact ? 10.0 : 12.0);
    final iconSize = tight ? 18.0 : (compact ? 20.0 : 24.0);
    final labelSize = tight ? 10.0 : (compact ? 11.0 : 12.0);
    final gap = tight ? 4.0 : (compact ? 6.0 : 8.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
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
    final tags = item.tagKeys
        .map((key) => _tagByKey[key])
        .whereType<JiveTag>()
        .toList();
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
                  Text(
                    "$subName • ${DateFormat('MM-dd HH:mm').format(item.timestamp)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.4)),
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
            Text(
              "$amountPrefix¥${item.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
