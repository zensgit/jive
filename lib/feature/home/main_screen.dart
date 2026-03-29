import 'dart:async';

import 'package:flutter/material.dart';
import '../accounts/accounts_screen.dart';
import '../auto/auto_drafts_screen.dart';
import '../auto/auto_rule_tester_screen.dart';
import '../auto/auto_supported_apps_screen.dart';
import '../auto/auto_settings_screen.dart';
import '../import/import_center_screen.dart';
import '../search/global_search_screen.dart';
import '../calendar/calendar_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import '../stats/stats_home_screen.dart';
import '../category/category_manager_screen.dart';
import '../category/category_transactions_screen.dart';
import '../currency/currency_converter_screen.dart';
import 'main_screen_controller.dart';
import 'widgets/home_asset_card.dart';
import 'widgets/home_menu_sheet.dart';
import 'widgets/home_recent_transactions_section.dart';
import 'widgets/home_top_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, MainScreenController {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onOpenAutoSettings = _openAutoSettings;
    initDatabase();
    startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    dataReloadSignal.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAutoPermissions();
      unawaited(processRecurringRules());
    }
  }

  Future<void> _openAutoSettings() async {
    if (!dbReady) {
      showMessage("数据库尚未就绪");
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoSettingsScreen(isar: isar)),
    );
    await loadAutoSettings();
    await loadAutoDraftCount();
  }

  Future<void> _openGlobalSearch() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      notifyDataChanged();
    }
  }

  Future<void> _openCalendarView() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      notifyDataChanged();
    }
  }

  Future<void> _openAutoDrafts() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoDraftsScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }

  Future<void> _openImportCenter() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportCenterScreen()),
    );
    if (changed == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }

  Future<void> _openAutoRuleTester() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoRuleTesterScreen(isar: isar),
      ),
    );
  }

  Future<void> _openAutoSupportedApps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSupportedAppsScreen()),
    );
    await loadAutoAppSettings();
  }

  Future<void> _openCategoryManager() async {
    if (!dbReady) {
      showMessage("数据库尚未就绪");
      return;
    }
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryManagerScreen(isar: isar, onlyUserCategories: true),
      ),
    );
    if (changed == true) {
      await loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          StatsHomeScreen(reloadSignal: dataReloadSignal, bookId: currentBookId),
          AccountsScreen(
            reloadSignal: dataReloadSignal,
            onDataChanged: notifyDataChanged,
            bookId: currentBookId,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(bookId: currentBookId),
            ),
          );
          if (result == true) {
            await loadTransactions();
            await loadAutoDraftCount();
            notifyDataChanged();
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
      onAddTransaction: () => _showAddTransaction('expense'),
      onDataChanged: () async {
        await loadTransactions();
        notifyDataChanged();
      },
    );
  }

  Widget _buildTopBar({bool compact = false}) {
    return HomeTopBar(
      compact: compact,
      books: books,
      currentBookId: currentBookId,
      pendingDraftCount: pendingDraftCount,
      onSearch: _openGlobalSearch,
      onCalendar: _openCalendarView,
      onGearMenu: () {
        showHomeMenuSheet(
          context: context,
          demoSeedEnabled: demoSeedEnabled,
          autoSettings: autoSettings,
          autoAppEnabledCount: autoAppEnabledCount,
          pendingDraftCount: pendingDraftCount,
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
            openCategoryManager: _openCategoryManager,
            openImportCenter: _openImportCenter,
            openAutoDrafts: _openAutoDrafts,
            openAutoRuleTester: _openAutoRuleTester,
            openAutoSupportedApps: _openAutoSupportedApps,
            openAutoSettings: _openAutoSettings,
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
      onAddExpense: () => _showAddTransaction('expense'),
      onAddIncome: () => _showAddTransaction('income'),
      onAddTransfer: () => _showAddTransaction('transfer'),
      onCurrencyConverter: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CurrencyConverterScreen(),
        ),
      ),
    );
  }

  Widget _buildHomeColumnContent() {
    final section = _recentSection();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTopBar(),
        const SizedBox(height: 24),
        _buildAssetCard(),
        const SizedBox(height: 32),
        section.buildTitle(),
        const SizedBox(height: 16),
        section.buildTransactionList(),
      ],
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
        builder: (context) => AddTransactionScreen(initialType: txType, bookId: currentBookId),
      ),
    );
    if (result == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
    }
  }
}
