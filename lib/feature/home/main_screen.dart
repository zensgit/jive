import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/auth/auth_service.dart';
import '../../core/database/book_model.dart';
import '../../core/service/book_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/quick_action_service.dart';
import '../../core/sync/sync_engine.dart';
import '../accounts/accounts_screen.dart';
import '../category/category_transactions_screen.dart';
import '../quick_entry/quick_action_deep_link_service.dart';
import '../quick_entry/quick_action_executor.dart';
import '../stats/stats_home_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/transaction_form_screen.dart';
import 'main_screen_controller.dart';
import 'mixins/auto_capture_mixin.dart';
import 'mixins/debug_seed_mixin.dart';
import 'mixins/home_navigation_mixin.dart';
import 'widgets/home_asset_card.dart';
import 'widgets/home_menu_sheet.dart';
import 'widgets/home_recent_transactions_section.dart';
import 'widgets/daily_budget_widget.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/template_quick_bar.dart';
import '../quick_entry/quick_entry_hub_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with
        WidgetsBindingObserver,
        MainScreenController,
        AutoCaptureMixin,
        DebugSeedMixin,
        HomeNavigationMixin {
  int _currentIndex = 0;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onOpenAutoSettings = openAutoSettings;
    onDataChanged = () => context.read<SyncEngine>().scheduleSync();
    initDatabase();
    startListening();
    unawaited(_initDeepLinks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    dataReloadSignal.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAutoPermissions();
      unawaited(processRecurringRules());
      context.read<SyncEngine>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          StatsHomeScreen(
            reloadSignal: dataReloadSignal,
            bookId: currentBookId,
          ),
          AccountsScreen(
            reloadSignal: dataReloadSignal,
            onDataChanged: notifyDataChanged,
            bookId: currentBookId,
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: '新增记账，长按打开快记中心',
        button: true,
        onTap: () => showAddTransaction('expense'),
        onLongPress: _showQuickEntryHub,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showAddTransaction('expense'),
          onLongPress: () => _showQuickEntryHub(),
          child: AbsorbPointer(
            child: FloatingActionButton(
              tooltip: '新增记账，长按打开快记中心',
              onPressed: () {},
              child: const Icon(Icons.add, size: 32),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1 || idx == 2) {
            notifyDataChanged();
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

  void _showQuickEntryHub() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickEntryHubSheet(
        bookId: currentBookId,
        onTransactionCreated: () async {
          await loadTransactions();
          notifyDataChanged();
        },
      ),
    );
  }

  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
      _deepLinkSubscription = appLinks.uriLinkStream.listen((uri) {
        unawaited(_handleDeepLink(uri));
      });
    } catch (error) {
      debugPrint('Deep link initialization skipped: $error');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final request = QuickActionDeepLinkService.parse(uri);
    if (request == null || !mounted) return;

    if (request.isQuickAction) {
      await _executeQuickActionLink(request.quickActionId!);
      return;
    }

    if (request.isSceneSwitch) {
      await _switchSceneLink(request);
      return;
    }

    final params = request.transactionParams;
    if (params == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransactionFormScreen(params: params)),
    );
    if (saved == true) {
      await loadTransactions();
      notifyDataChanged();
    }
  }

  Future<void> _executeQuickActionLink(String quickActionId) async {
    final isar = await DatabaseService.getInstance();
    final action = await QuickActionService(isar).findActionById(quickActionId);
    if (action == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('快速动作不存在或已删除')));
      return;
    }

    if (!mounted) return;
    await QuickActionExecutor.execute(
      context,
      action,
      onCompleted: () {
        unawaited(loadTransactions().then((_) => notifyDataChanged()));
      },
    );
  }

  Future<void> _switchSceneLink(QuickActionDeepLinkRequest request) async {
    if (request.switchToAllScenes) {
      setState(() {
        currentBookId = null;
        _currentIndex = 0;
      });
      await loadTransactions();
      notifyDataChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已切换到全部场景')));
      return;
    }

    final isar = await DatabaseService.getInstance();
    final bookService = BookService(isar);
    var activeBooks = books;
    if (activeBooks.isEmpty) {
      activeBooks = await bookService.getActiveBooks();
    }

    var target = _findSceneBook(activeBooks, request);
    if (target == null) {
      activeBooks = await bookService.getActiveBooks();
      target = _findSceneBook(activeBooks, request);
    }

    final targetBook = target;
    if (targetBook == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('场景不存在或已归档')));
      return;
    }

    if (!mounted) return;
    setState(() {
      books = activeBooks;
      currentBookId = targetBook.id;
      _currentIndex = 0;
    });
    await loadTransactions();
    notifyDataChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已切换到场景「${targetBook.name}」')));
  }

  JiveBook? _findSceneBook(
    List<JiveBook> activeBooks,
    QuickActionDeepLinkRequest request,
  ) {
    for (final book in activeBooks) {
      if (request.sceneBookId != null && book.id == request.sceneBookId) {
        return book;
      }
      if (_sameSceneText(book.key, request.sceneBookKey)) {
        return book;
      }
      if (_sameSceneText(book.name, request.sceneName)) {
        return book;
      }
    }
    return null;
  }

  bool _sameSceneText(String value, String? candidate) {
    final text = candidate?.trim();
    if (text == null || text.isEmpty) return false;
    return value.trim().toLowerCase() == text.toLowerCase();
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

  HomeRecentTransactionsSection _recentSection({bool compact = false}) {
    return HomeRecentTransactionsSection(
      compact: compact,
      transactions: transactions,
      categoryByKey: categoryByKey,
      tagByKey: tagByKey,
      accountById: accountById,
      isLoading: isLoading,
      showSmartTagBadge: showSmartTagBadge,
      currentBookId: currentBookId,
      baseCurrency: baseCurrency,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CategoryTransactionsScreen(title: "全部账单"),
          ),
        );
      },
      onTransactionDetail: showTransactionDetailSheet,
      onAddTransaction: () => showAddTransaction('expense'),
      onDataChanged: () async {
        await loadTransactions();
        notifyDataChanged();
      },
    );
  }

  Widget _buildTopBar({bool compact = false}) {
    final auth = context.watch<AuthService>();
    final displayName =
        auth.currentUser?.displayName ??
        auth.currentUser?.email?.split('@').first;
    return HomeTopBar(
      compact: compact,
      displayName: displayName,
      books: books,
      currentBookId: currentBookId,
      pendingDraftCount: pendingDraftCount,
      onSearch: openGlobalSearch,
      onCalendar: openCalendarView,
      onGearMenu: () {
        showHomeMenuSheet(
          context: context,
          demoSeedEnabled: demoSeedEnabled,
          autoSettings: autoSettings,
          autoAppEnabledCount: autoAppEnabledCount,
          pendingDraftCount: pendingDraftCount,
          currentBookId: currentBookId,
          isar: isar,
          actions: HomeMenuActions(
            setDemoSeedEnabled: setDemoSeedEnabled,
            seedDemoData: seedDemoDataIfNeeded,
            randomSeed: handleRandomSeed,
            projectSeedLarge: handleProjectSeedLarge,
            simulateAutoEvent: handleAutoEvent,
            setAutoSettings: setAutoSettings,
            clearAllData: clearAllData,
            exportBackup: exportBackup,
            importBackup: importBackup,
            loadTransactions: loadTransactions,
            loadAutoDraftCount: loadAutoDraftCount,
            notifyDataChanged: notifyDataChanged,
            showMessage: showMessage,
            openCategoryManager: openCategoryManager,
            openImportCenter: openImportCenter,
            openAutoDrafts: openAutoDrafts,
            openAutoRuleTester: openAutoRuleTester,
            openAutoSupportedApps: openAutoSupportedApps,
            openAutoSettings: openAutoSettings,
          ),
        );
      },
      onBookSwitch: (bookId) {
        setState(() => currentBookId = bookId);
        loadTransactions();
      },
    );
  }

  Widget _buildAssetCard({bool compact = false, bool tight = false}) {
    return HomeAssetCard(
      compact: compact,
      tight: tight,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalCreditLimit: totalCreditLimit,
      totalCreditUsed: totalCreditUsed,
      totalCreditAvailable: totalCreditAvailable,
      baseCurrency: baseCurrency,
      onAddExpense: () => showAddTransaction('expense'),
      onAddIncome: () => showAddTransaction('income'),
      onAddTransfer: () => showAddTransaction('transfer'),
      onCurrencyConverter: openCurrencyConverter,
    );
  }

  Widget _buildHomeColumnContent() {
    final section = _recentSection();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildTopBar(),
          const SizedBox(height: 24),
          _buildAssetCard(),
          const SizedBox(height: 16),
          const BannerAdWidget(),
          const SizedBox(height: 16),
          DailyBudgetWidget(bookId: currentBookId),
          const SizedBox(height: 16),
          TemplateQuickBar(
            onTransactionCreated: () async {
              await loadTransactions();
              notifyDataChanged();
            },
          ),
          const SizedBox(height: 16),
          section.buildTitle(),
          const SizedBox(height: 16),
          section.buildTransactionListBody(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeLandscapeContent({bool tight = false}) {
    final topGap = tight ? 4.0 : 8.0;
    final sectionGap = tight ? 8.0 : 12.0;
    final listGap = tight ? 6.0 : 8.0;
    final section = _recentSection(compact: tight);
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
              section.buildTitle(),
              SizedBox(height: listGap),
              Expanded(child: section.buildTransactionListBody()),
            ],
          ),
        ),
      ],
    );
  }
}
