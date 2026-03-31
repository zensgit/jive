import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/auth/auth_service.dart';
import '../accounts/accounts_screen.dart';
import '../category/category_transactions_screen.dart';
import '../stats/stats_home_screen.dart';
import '../transactions/transaction_detail_screen.dart';
import 'main_screen_controller.dart';
import 'mixins/auto_capture_mixin.dart';
import 'mixins/debug_seed_mixin.dart';
import 'mixins/home_navigation_mixin.dart';
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
    with WidgetsBindingObserver, MainScreenController, AutoCaptureMixin, DebugSeedMixin, HomeNavigationMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onOpenAutoSettings = openAutoSettings;
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
        onPressed: () => showAddTransaction('expense'),
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
      onAddTransaction: () => showAddTransaction('expense'),
      onDataChanged: () async {
        await loadTransactions();
        notifyDataChanged();
      },
    );
  }

  Widget _buildTopBar({bool compact = false}) {
    final auth = context.watch<AuthService>();
    final displayName = auth.currentUser?.displayName ?? auth.currentUser?.email?.split('@').first;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTopBar(),
        const SizedBox(height: 24),
        _buildAssetCard(),
        const SizedBox(height: 16),
        const BannerAdWidget(),
        const SizedBox(height: 16),
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
}
