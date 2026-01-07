import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
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
import 'core/service/account_service.dart';
import 'core/service/category_service.dart';
import 'core/service/transaction_service.dart';
import 'core/service/auto_draft_service.dart';
import 'core/service/auto_settings.dart';
import 'feature/accounts/accounts_screen.dart';
import 'feature/auto/auto_settings_screen.dart';
import 'feature/transactions/add_transaction_screen.dart';
import 'feature/stats/stats_screen.dart';
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const eventChannel = EventChannel('com.jive.app/stream');
  static const _prefKeyDemoSeedEnabled = 'demo_seed_enabled';

  late Isar _isar;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  bool _isLoading = true;
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  int? _defaultAccountId;
  int _currentIndex = 0;
  bool _demoSeedEnabled = true;
  bool _dbReady = false;
  bool _isListening = false;
  StreamSubscription<Uri>? _appLinkSub;
  final List<Map<String, dynamic>> _pendingAutoEvents = [];
  AutoSettings _autoSettings = AutoSettingsStore.defaults;
  int _pendingDraftCount = 0;

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _startListening();
    _startAppLinks();
  }

  @override
  void dispose() {
    _appLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open(
        [JiveTransactionSchema, JiveCategorySchema, JiveAccountSchema, JiveAutoDraftSchema],
        directory: dir.path,
      );
    }
    await _loadDemoSeedPrefs();
    await _loadAutoSettings();
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    _defaultAccountId = (await AccountService(_isar).getDefaultAccount())?.id;
    await _loadTransactions();
    await _loadAutoDraftCount();
    _dbReady = true;
    await _flushPendingAutoEvents();
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    });
    await CategoryService(_isar).initDefaultCategories();
    await AccountService(_isar).initDefaultAccounts();
    await TransactionService(_isar).migrateTransactionCategoryKeys();
    await TransactionService(_isar).migrateTransactionAccountIds();
    _defaultAccountId = (await AccountService(_isar).getDefaultAccount())?.id;
    await _loadTransactions();
    await _loadAutoDraftCount();
  }

  Future<void> _loadTransactions() async {
    final list = await _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};
    final accountService = AccountService(_isar);
    final accounts = await accountService.getActiveAccounts();
    final balances = await accountService.computeBalances(accounts: accounts);
    final totals = accountService.calculateTotals(accounts, balances);

    if (mounted) {
      setState(() {
        _transactions = list;
        _categoryByKey = categoryMap;
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
    if (!_autoSettings.enabled) return;
    final capture = AutoCapture.fromEvent(data);
    if (!capture.isValid) return;
    final result = await AutoDraftService(_isar).ingestCapture(
      capture,
      directCommit: _autoSettings.directCommit,
    );
    if (!mounted) return;
    if (result.duplicate) {
      _showMessage("已忽略重复自动记账");
      return;
    }
    await _loadAutoDraftCount();
    if (result.committed) {
      await _loadTransactions();
      _showMessage("已自动入账");
      return;
    }
    if (result.inserted) {
      _showMessage("已加入待确认");
    }
  }

  void _startListening() {
    if (_isListening) return;
    _isListening = true;
    eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is! Map) return;
        final payload = Map<String, dynamic>.from(event);
        if (!_dbReady) {
          _pendingAutoEvents.add(payload);
          return;
        }
        await _handleAutoEvent(payload);
      },
    );
  }

  Future<void> _startAppLinks() async {
    final appLinks = AppLinks();
    _appLinkSub = appLinks.uriLinkStream.listen(
      _handleAppLink,
      onError: (error) => debugPrint('AppLinks error: $error'),
    );
    final initial = await appLinks.getInitialLink();
    if (initial != null) {
      _handleAppLink(initial);
    }
  }

  void _handleAppLink(Uri uri) {
    if (uri.scheme != 'jive') return;
    final action = uri.host.isNotEmpty ? uri.host : uri.path.replaceFirst('/', '');
    if (action != 'auto') return;
    final params = uri.queryParameters;
    final source = params['source'] ?? params['app'] ?? 'Shortcut';
    final data = <String, dynamic>{
      'source': source,
      'raw_text': params['text'] ?? params['raw_text'] ?? '',
      'amount': params['amount'] ?? params['money'],
      'type': params['type'],
      'timestamp': params['timestamp'],
    };
    if (!_dbReady) {
      _pendingAutoEvents.add(data);
      return;
    }
    _handleAutoEvent(data);
  }

  Future<void> _openAutoSettings() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoSettingsScreen(
          isar: _isar,
          autoSettings: _autoSettings,
          pendingDraftCount: _pendingDraftCount,
          demoSeedEnabled: _demoSeedEnabled,
        ),
      ),
    );
    if (changed == true) {
      await _loadDemoSeedPrefs();
      await _loadAutoSettings();
      await _loadTransactions();
      await _loadAutoDraftCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const StatsScreen(),
          const AccountsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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
            Text("Good Evening,", style: GoogleFonts.lato(color: Colors.grey, fontSize: greetingSize)),
            Text("Huazhou", style: GoogleFonts.lato(color: Colors.black87, fontSize: nameSize, fontWeight: FontWeight.bold)),
          ],
        ),
        GestureDetector(
          onTap: _openAutoSettings,
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.settings, color: Colors.black54, size: iconSize),
          ),
        )
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
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.wallet, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text("净资产", style: GoogleFonts.lato(color: Colors.white70, fontSize: titleSize)),
            ],
          ),
          SizedBox(height: headerGap),
          Text(
            NumberFormat.currency(symbol: "¥").format(netAssets),
            style: GoogleFonts.rubik(color: Colors.white, fontSize: amountSize, fontWeight: FontWeight.w600),
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
              _buildActionBtn(Icons.arrow_downward, "Income", compact: compact, tight: tight, showLabel: showActionLabels),
              _buildActionBtn(Icons.arrow_upward, "Expense", compact: compact, tight: tight, showLabel: showActionLabels),
              _buildActionBtn(Icons.swap_horiz, "Transfer", compact: compact, tight: tight, showLabel: showActionLabels),
            ],
          )
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
          Text("Recent Transactions", style: GoogleFonts.lato(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text("View All", style: GoogleFonts.lato(color: JiveTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: actionSize)),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Expanded(child: _buildTransactionListBody());
  }

  Widget _buildTransactionListBody({bool shrinkWrap = false, ScrollPhysics? physics}) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        if (showLabel) ...[
          SizedBox(height: gap),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: labelSize)),
        ],
      ],
    );
  }

  Widget _buildBalanceMeta(String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 6),
        Text(
          NumberFormat.compactCurrency(symbol: "¥", decimalDigits: 0).format(amount),
          style: GoogleFonts.lato(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
          Text("No transactions yet", style: GoogleFonts.lato(color: Colors.grey)),
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
    final amountColor = isTransfer ? Colors.blueGrey : (isIncome ? Colors.green : Colors.redAccent);
    final parentName = _displayCategoryName(item.categoryKey, item.category);
    final subName = _displayCategoryName(item.subCategoryKey, item.subCategory);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
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
                Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("$subName • ${DateFormat('MM-dd HH:mm').format(item.timestamp)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "$amountPrefix¥${item.amount.toStringAsFixed(2)}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
          ),
        ],
      ),
    );
  }
}
