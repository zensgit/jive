import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/theme.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/transaction_service.dart';
import '../../core/service/auto_app_registry.dart';
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
import '../tag/tag_management_screen.dart';
import '../tag/tag_icon_catalog.dart';
import '../project/project_list_screen.dart';
import '../recurring/recurring_rule_list_screen.dart';
import '../currency/currency_settings_screen.dart';
import '../currency/currency_converter_screen.dart';
import '../budget/budget_manager_screen.dart';
import '../settings/csv_export_screen.dart';
import '../settings/settings_screen.dart';
import '../assistant/assistant_screen.dart';
import '../books/book_manager_screen.dart';
import '../installment/installment_list_screen.dart';
import '../split/bill_split_screen.dart';
import '../savings/savings_goal_screen.dart';
import '../bill_relation/bill_relation_screen.dart';
import '../merchant/merchant_memory_screen.dart';
import '../security/pin_setup_screen.dart';
import '../debt/debt_list_screen.dart';
import '../investment/investment_screen.dart';
import '../../core/utils/logger_util.dart';
import 'main_screen_controller.dart';

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

  Widget _buildBookSwitcher({bool compact = false}) {
    final currentBook = books.where((b) => b.id == currentBookId).firstOrNull;
    final label = currentBook?.name ?? '全部账本';
    final fontSize = compact ? 11.0 : 12.0;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('切换账本',
                      style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, size: 20),
                  title: const Text('全部账本'),
                  trailing: currentBookId == null
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => currentBookId = null);
                    loadTransactions();
                  },
                ),
                ...books.map((book) => ListTile(
                      leading: Icon(
                        book.isDefault ? Icons.book : Icons.book_outlined,
                        size: 20,
                        color: book.isDefault
                            ? const Color(0xFF2E7D32)
                            : null,
                      ),
                      title: Text(book.name),
                      subtitle: book.isDefault
                          ? const Text('默认',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF2E7D32)))
                          : null,
                      trailing: currentBookId == book.id
                          ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => currentBookId = book.id);
                        loadTransactions();
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined,
                size: fontSize + 2, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: fontSize,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                size: fontSize + 2, color: const Color(0xFF2E7D32)),
          ],
        ),
      ),
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
            if (books.length > 1) ...[
              const SizedBox(height: 4),
              _buildBookSwitcher(compact: compact),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '搜索交易',
              onPressed: _openGlobalSearch,
              icon: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.search,
                  color: Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '日历视图',
              onPressed: _openCalendarView,
              icon: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                                  value: demoSeedEnabled,
                                  onChanged: (value) async {
                                    setSheetState(() {
                                      demoSeedEnabled = value;
                                    });
                                    await setDemoSeedEnabled(value);
                                    showMessage(value ? "已开启测试数据" : "已关闭测试数据");
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.auto_awesome),
                                  title: const Text("注入测试数据"),
                                  subtitle: Text(
                                    demoSeedEnabled
                                        ? "写入一批示例数据"
                                        : "请先开启测试数据开关",
                                  ),
                                  onTap: () async {
                                    if (!demoSeedEnabled) {
                                      showMessage("请先开启测试数据开关");
                                      return;
                                    }
                                    Navigator.pop(context);
                                    final inserted =
                                        await seedDemoDataIfNeeded();
                                    await loadTransactions();
                                    if (inserted) {
                                      notifyDataChanged();
                                    }
                                    showMessage(
                                      inserted ? "已注入测试数据" : "已有数据，未注入测试数据",
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.auto_awesome_motion,
                                  ),
                                  title: const Text("生成随机测试数据"),
                                  subtitle: Text(
                                    demoSeedEnabled
                                        ? "随机生成账户/标签/交易"
                                        : "请先开启测试数据开关",
                                  ),
                                  onTap: () async {
                                    if (!demoSeedEnabled) {
                                      showMessage("请先开启测试数据开关");
                                      return;
                                    }
                                    Navigator.pop(context);
                                    await handleRandomSeed();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.folder_special_outlined,
                                  ),
                                  title: const Text("生成项目测试数据（大量）"),
                                  subtitle: Text(
                                    demoSeedEnabled
                                        ? "生成一年以上交易并关联到项目"
                                        : "请先开启测试数据开关",
                                  ),
                                  onTap: () async {
                                    if (!demoSeedEnabled) {
                                      showMessage("请先开启测试数据开关");
                                      return;
                                    }
                                    Navigator.pop(context);
                                    await handleProjectSeedLarge();
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
                                      await handleAutoEvent({
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
                                  leading: const Icon(
                                    Icons.table_view_outlined,
                                  ),
                                  title: const Text("导出 CSV"),
                                  subtitle: const Text("按时间范围和分类导出交易"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CsvExportScreen(),
                                      ),
                                    );
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
                                    await loadTransactions();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.currency_exchange),
                                  title: const Text("货币与汇���"),
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
                                    await loadTransactions();
                                    await loadAutoDraftCount();
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
                                            TagManagementScreen(isar: isar),
                                      ),
                                    );
                                    await loadTransactions();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.auto_awesome),
                                  title: const Text("AI 助手"),
                                  subtitle: const Text("语音记账、智能分类"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AssistantScreen(isar: isar),
                                      ),
                                    );
                                    await loadTransactions();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.store_outlined),
                                  title: const Text("商户记忆"),
                                  subtitle: const Text("管理商户名称与分类偏好"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MerchantMemoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.book_outlined),
                                  title: const Text("账本管理"),
                                  subtitle: const Text("多账本切换与管理"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BookManagerScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.credit_card_outlined),
                                  title: const Text("分期管理"),
                                  subtitle: const Text("贷款与分期付款追踪"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const InstallmentListScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.group_outlined),
                                  title: const Text("AA 分账"),
                                  subtitle: const Text("多人分账与结算"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BillSplitScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.savings_outlined),
                                  title: const Text("储蓄目标"),
                                  subtitle: const Text("设置并追踪储蓄计划"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SavingsGoalScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.receipt_long_outlined),
                                  title: const Text("账单关联"),
                                  subtitle: const Text("报销与退款追踪"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BillRelationScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.handshake_outlined),
                                  title: const Text("借贷管理"),
                                  subtitle: const Text("借入借出与还款追踪"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DebtListScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.trending_up),
                                  title: const Text("投资组合"),
                                  subtitle: const Text("股票、基金与加密货币追踪"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const InvestmentScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.lock_outline),
                                  title: const Text("应用锁"),
                                  subtitle: const Text("PIN 码与生物识别设置"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PinSetupScreen(),
                                      ),
                                    );
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
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                      ),
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
                                        isar,
                                      ).resetCategories();
                                      await TransactionService(
                                        isar,
                                      ).migrateTransactionCategoryKeys();
                                      await loadTransactions();
                                      showMessage("已重置系统分类");
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
                                            child: const Text("清空"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    await clearAllData();
                                    showMessage("已清空数据");
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.file_download_outlined,
                                  ),
                                  title: const Text("导出数据"),
                                  subtitle: const Text("导出为备份文件"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await exportBackup();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.file_upload_outlined,
                                  ),
                                  title: const Text("导入数据"),
                                  subtitle: const Text("导入将覆盖当前数据"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await importBackup();
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
                                    autoSettings.enabled ? "已开启" : "已关闭",
                                  ),
                                  value: autoSettings.enabled,
                                  onChanged: (value) async {
                                    final updated = autoSettings.copyWith(
                                      enabled: value,
                                    );
                                    setSheetState(() {
                                      autoSettings = updated;
                                    });
                                    await setAutoSettings(updated);
                                  },
                                ),
                                SwitchListTile(
                                  secondary: const Icon(
                                    Icons.playlist_add_check,
                                  ),
                                  title: const Text("自动入账"),
                                  subtitle: const Text("关闭则进入待确认"),
                                  value: autoSettings.directCommit,
                                  onChanged: (value) async {
                                    final updated = autoSettings.copyWith(
                                      directCommit: value,
                                    );
                                    setSheetState(() {
                                      autoSettings = updated;
                                    });
                                    await setAutoSettings(updated);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.apps),
                                  title: const Text("自动记账支持的应用"),
                                  subtitle: Text(
                                    "已启用 $autoAppEnabledCount / ${AutoAppRegistry.apps.length}",
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _openAutoSupportedApps();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.inbox_outlined),
                                  title: const Text("待确认自动记账"),
                                  subtitle: Text("当前 $pendingDraftCount 条"),
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
                child: Icon(
                  Icons.settings,
                  color: Colors.black54,
                  size: iconSize,
                ),
              ),
            ),
          ],
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
    final netAssets = totalAssets - totalLiabilities;
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
                _buildBalanceMeta("资产", totalAssets),
                const SizedBox(width: 16),
                _buildBalanceMeta("负债", totalLiabilities),
              ],
            ),
            if (totalCreditLimit > 0) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _buildBalanceMeta("信用额度", totalCreditLimit),
                  _buildBalanceMeta("已用", totalCreditUsed),
                  _buildBalanceMeta("可用", totalCreditAvailable),
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
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(transactions[index]);
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
        builder: (context) => AddTransactionScreen(initialType: txType, bookId: currentBookId),
      ),
    );
    if (result == true) {
      await loadTransactions();
      await loadAutoDraftCount();
      notifyDataChanged();
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

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && categoryByKey.containsKey(key)) {
      return categoryByKey[key]!.name;
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
    final showSmartBadge = showSmartTagBadge && item.smartTagKeys.isNotEmpty;
    final tags = item.tagKeys
        .map((key) => tagByKey[key])
        .whereType<JiveTag>()
        .toList();

    // 获取交易账户的货币信息
    final account = item.accountId != null
        ? accountById[item.accountId]
        : null;
    final txCurrency = account?.currency ?? 'CNY';
    final txSymbol = CurrencyDefaults.getSymbol(txCurrency);
    final txDecimals = CurrencyDefaults.getDecimalPlaces(txCurrency);
    final isMultiCurrency = txCurrency != baseCurrency;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await showTransactionDetailSheet(context, item.id);
        if (updated == true) {
          await loadTransactions();
          notifyDataChanged();
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
