import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../core/entitlement/feature_id.dart';
import '../../../core/service/app_lock_service.dart';
import '../../../core/entitlement/gated_list_tile.dart';
import '../../../core/service/auto_app_registry.dart';
import '../../../core/service/auto_settings.dart';
import '../../../core/service/category_service.dart';
import '../../../core/service/transaction_service.dart';
import '../../../core/utils/logger_util.dart';
import '../../assistant/assistant_screen.dart';
import '../../insights/spending_insights_screen.dart';
import '../../settings/activity_log_screen.dart';
import '../../settings/auto_rule_editor_screen.dart';
import '../../bill_relation/bill_relation_screen.dart';
import '../../report/annual_report_screen.dart';
import '../../shared/shared_ledger_screen.dart';
import '../../books/book_manager_screen.dart';
import '../../budget/budget_manager_screen.dart';
import '../../currency/currency_settings_screen.dart';
import '../../debt/debt_list_screen.dart';
import '../../installment/installment_list_screen.dart';
import '../../investment/investment_screen.dart';
import '../../merchant/merchant_analytics_screen.dart';
import '../../project/project_list_screen.dart';
import '../../recurring/recurring_rule_list_screen.dart';
import '../../savings/savings_goal_screen.dart';
import '../../travel/travel_screen.dart';
import '../../security/pin_setup_screen.dart';
import '../../plan/plan_hub_screen.dart';
import '../../settings/csv_export_screen.dart';
import '../../settings/settings_screen.dart';
import '../../settings/widget_gallery_screen.dart';
import '../../split/bill_split_screen.dart';
import '../../settings/screenshot_capture_settings.dart';
import '../../smart_list/smart_list_screen.dart';
import '../../tag/tag_management_screen.dart';

/// Callbacks that the menu sheet needs from the parent screen.
class HomeMenuActions {
  final Future<void> Function(bool enabled) setDemoSeedEnabled;
  final Future<bool> Function() seedDemoData;
  final Future<void> Function() randomSeed;
  final Future<void> Function() projectSeedLarge;
  final Future<void> Function(Map<String, dynamic>) simulateAutoEvent;
  final Future<void> Function(AutoSettings) setAutoSettings;
  final Future<void> Function() clearAllData;
  final Future<void> Function() exportBackup;
  final Future<void> Function() importBackup;
  final Future<void> Function() loadTransactions;
  final Future<void> Function() loadAutoDraftCount;
  final VoidCallback notifyDataChanged;
  final void Function(String) showMessage;
  final Future<void> Function() openCategoryManager;
  final Future<void> Function() openImportCenter;
  final Future<void> Function() openAutoDrafts;
  final Future<void> Function() openAutoRuleTester;
  final Future<void> Function() openAutoSupportedApps;
  final VoidCallback openAutoSettings;

  const HomeMenuActions({
    required this.setDemoSeedEnabled,
    required this.seedDemoData,
    required this.randomSeed,
    required this.projectSeedLarge,
    required this.simulateAutoEvent,
    required this.setAutoSettings,
    required this.clearAllData,
    required this.exportBackup,
    required this.importBackup,
    required this.loadTransactions,
    required this.loadAutoDraftCount,
    required this.notifyDataChanged,
    required this.showMessage,
    required this.openCategoryManager,
    required this.openImportCenter,
    required this.openAutoDrafts,
    required this.openAutoRuleTester,
    required this.openAutoSupportedApps,
    required this.openAutoSettings,
  });
}

/// Shows the home menu bottom sheet (settings gear menu).
void showHomeMenuSheet({
  required BuildContext context,
  required bool demoSeedEnabled,
  required AutoSettings autoSettings,
  required int autoAppEnabledCount,
  required int pendingDraftCount,
  required Isar isar,
  required HomeMenuActions actions,
}) {
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
                  // ── 拖拽指示器 ──
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ════════════════════════════════════════
                  // 快捷功能网格
                  // ════════════════════════════════════════
                  _buildQuickGrid(context, actions, isar),

                  const SizedBox(height: 8),

                  // ════════════════════════════════════════
                  // 📊 财务管理
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.account_balance_wallet_outlined,
                    title: '财务管理',
                    initiallyExpanded: true,
                    children: [
                      _MenuTile(
                        icon: Icons.pie_chart_outline,
                        title: '预算管理',
                        subtitle: '设置和追踪预算',
                        onTap: () => _nav(context, const BudgetManagerScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.event_note,
                        title: '计划中心',
                        subtitle: '预算、目标、定期、旅行一览',
                        onTap: () => _nav(context, const PlanHubScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.savingsGoals,
                        icon: Icons.savings_outlined,
                        title: '储蓄目标',
                        subtitle: '设置并追踪储蓄计划',
                        onTap: () => _nav(context, const SavingsGoalScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.recurringRules,
                        icon: Icons.repeat,
                        title: '周期记账',
                        subtitle: '自动生成草稿或入账',
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RecurringRuleListScreen()));
                          await actions.loadTransactions();
                          await actions.loadAutoDraftCount();
                        },
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.multiCurrency,
                        icon: Icons.currency_exchange,
                        title: '货币与汇率',
                        subtitle: '管理多币种和汇率',
                        onTap: () => _nav(context, const CurrencySettingsScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 📈 投资与资产
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.trending_up,
                    title: '投资与资产',
                    children: [
                      _GatedMenuTile(
                        feature: FeatureId.investmentTracking,
                        icon: Icons.show_chart,
                        title: '投资组合',
                        subtitle: '股票、基金与加密货币追踪',
                        onTap: () => _nav(context, const InvestmentScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.debtManagement,
                        icon: Icons.credit_card_outlined,
                        title: '分期管理',
                        subtitle: '贷款与分期付款追踪',
                        onTap: () => _nav(context, const InstallmentListScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.debtManagement,
                        icon: Icons.handshake_outlined,
                        title: '借贷管理',
                        subtitle: '借入借出与还款追踪',
                        onTap: () => _nav(context, const DebtListScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.debtManagement,
                        icon: Icons.receipt_long_outlined,
                        title: '账单关联',
                        subtitle: '报销与退款追踪',
                        onTap: () => _nav(context, const BillRelationScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 🤖 智能与分析
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.auto_awesome,
                    title: '智能与分析',
                    children: [
                      _GatedMenuTile(
                        feature: FeatureId.voiceBookkeeping,
                        icon: Icons.assistant,
                        title: 'AI 助手',
                        subtitle: '语音记账、智能分类',
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AssistantScreen(isar: isar)));
                          await actions.loadTransactions();
                        },
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.advancedAnalytics,
                        icon: Icons.lightbulb_outline,
                        title: '财务洞察',
                        subtitle: '智能分析支出模式',
                        onTap: () => _nav(context, const SpendingInsightsScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.merchantMemory,
                        icon: Icons.store_outlined,
                        title: '商户记忆',
                        subtitle: '商户消费分析与别名管理',
                        onTap: () => _nav(context, const MerchantAnalyticsScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.pdfReport,
                        icon: Icons.picture_as_pdf,
                        title: '年度报告',
                        subtitle: '生成 PDF 年度财务报告',
                        onTap: () => _nav(context, const AnnualReportScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 👥 协作与场景
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.people_outline,
                    title: '协作与场景',
                    children: [
                      _MenuTile(
                        icon: Icons.book_outlined,
                        title: '账本管理',
                        subtitle: '多账本切换与管理',
                        onTap: () => _nav(context, const BookManagerScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.family_restroom,
                        title: '家庭共享账本',
                        subtitle: '多人协同记账',
                        onTap: () => _nav(context, const SharedLedgerScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.billSplit,
                        icon: Icons.group_outlined,
                        title: 'AA 分账',
                        subtitle: '多人分账与结算',
                        onTap: () => _nav(context, const BillSplitScreen(), actions),
                      ),
                      _GatedMenuTile(
                        feature: FeatureId.projectTracking,
                        icon: Icons.folder_outlined,
                        title: '项目追踪',
                        subtitle: '追踪旅行、装修等专项支出',
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProjectListScreen()));
                          await actions.loadTransactions();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.flight_takeoff,
                        title: '旅行模式',
                        subtitle: '旅行消费追踪与预算',
                        onTap: () => _nav(context, const TravelScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 📁 数据管理
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.folder_open_outlined,
                    title: '数据管理',
                    children: [
                      _GatedMenuTile(
                        feature: FeatureId.csvExport,
                        icon: Icons.table_view_outlined,
                        title: '导出 CSV',
                        subtitle: '按时间范围和分类导出交易',
                        onTap: () => _nav(context, const CsvExportScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.file_download_outlined,
                        title: '导出备份',
                        subtitle: '导出为备份文件',
                        onTap: () {
                          Navigator.pop(context);
                          actions.exportBackup();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.file_upload_outlined,
                        title: '导入备份',
                        subtitle: '导入将覆盖当前数据',
                        onTap: () {
                          Navigator.pop(context);
                          actions.importBackup();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.playlist_add_check_circle_outlined,
                        title: '导入中心',
                        subtitle: '文本/CSV/OCR 导入到待确认草稿',
                        onTap: () {
                          Navigator.pop(context);
                          actions.openImportCenter();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.history,
                        title: '操作日志',
                        subtitle: '查看数据变更记录',
                        onTap: () => _nav(context, const ActivityLogScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 🔄 自动记账
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.auto_fix_high,
                    title: '自动记账',
                    trailing: Text(
                      autoSettings.enabled ? '已开启' : '已关闭',
                      style: TextStyle(
                        fontSize: 12,
                        color: autoSettings.enabled ? Colors.green : Colors.grey,
                      ),
                    ),
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.auto_awesome, size: 20),
                        title: const Text('启用自动记账', style: TextStyle(fontSize: 14)),
                        value: autoSettings.enabled,
                        onChanged: (value) async {
                          final updated = autoSettings.copyWith(enabled: value);
                          setSheetState(() => autoSettings = updated);
                          await actions.setAutoSettings(updated);
                        },
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.playlist_add_check, size: 20),
                        title: const Text('自动入账', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('关闭则进入待确认', style: TextStyle(fontSize: 12)),
                        value: autoSettings.directCommit,
                        onChanged: (value) async {
                          final updated = autoSettings.copyWith(directCommit: value);
                          setSheetState(() => autoSettings = updated);
                          await actions.setAutoSettings(updated);
                        },
                      ),
                      _MenuTile(
                        icon: Icons.apps,
                        title: '支持的应用',
                        subtitle: '已启用 $autoAppEnabledCount / ${AutoAppRegistry.apps.length}',
                        onTap: () {
                          Navigator.pop(context);
                          actions.openAutoSupportedApps();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.inbox_outlined,
                        title: '待确认',
                        subtitle: '当前 $pendingDraftCount 条',
                        onTap: () {
                          Navigator.pop(context);
                          actions.openAutoDrafts();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.auto_fix_high,
                        title: '分类规则',
                        subtitle: '自动分类规则管理',
                        onTap: () => _nav(context, const AutoRuleEditorScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.screenshot_monitor,
                        title: '截图监控',
                        subtitle: '监控截图文件夹自动识别账单',
                        onTap: () => _nav(context, const ScreenshotCaptureSettingsScreen(), actions),
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // ⚙️ 设置与工具
                  // ════════════════════════════════════════
                  _MenuSection(
                    icon: Icons.settings_outlined,
                    title: '设置与工具',
                    children: [
                      _MenuTile(
                        icon: Icons.palette_outlined,
                        title: '设置',
                        subtitle: '外观、语言与偏好',
                        onTap: () => _nav(context, const SettingsScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.category_outlined,
                        title: '分类管理',
                        subtitle: '管理自定义分类',
                        onTap: () {
                          Navigator.pop(context);
                          actions.openCategoryManager();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.label_outline,
                        title: '标签管理',
                        subtitle: '管理交易标签',
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => TagManagementScreen(isar: isar)));
                          await actions.loadTransactions();
                        },
                      ),
                      _MenuTile(
                        icon: Icons.bookmarks_outlined,
                        title: '我的视图',
                        subtitle: '保存的筛选条件快速访问',
                        onTap: () => _nav(context, const SmartListScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.widgets,
                        title: '桌面小组件',
                        subtitle: '查看与管理桌面小组件',
                        onTap: () => _nav(context, const WidgetGalleryScreen(), actions),
                      ),
                      _MenuTile(
                        icon: Icons.lock_outline,
                        title: '应用锁',
                        subtitle: 'PIN 码与生物识别设置',
                        onTap: () async {
                          Navigator.pop(context);
                          final isLocked = await AppLockService().isLockEnabled();
                          if (!context.mounted) return;
                          await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PinSetupScreen(isChange: isLocked)));
                        },
                      ),
                    ],
                  ),

                  // ════════════════════════════════════════
                  // 🧪 开发者（仅 debug）
                  // ════════════════════════════════════════
                  if (kDebugMode || demoSeedEnabled) ...[
                    _MenuSection(
                      icon: Icons.science_outlined,
                      title: '开发者工具',
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.science_outlined, size: 20),
                          title: const Text('测试数据开关', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('仅用于调试展示', style: TextStyle(fontSize: 12)),
                          value: demoSeedEnabled,
                          onChanged: (value) async {
                            setSheetState(() => demoSeedEnabled = value);
                            await actions.setDemoSeedEnabled(value);
                            actions.showMessage(value ? '已开启测试数据' : '已关闭测试数据');
                          },
                        ),
                        if (demoSeedEnabled) ...[
                          _MenuTile(
                            icon: Icons.auto_awesome,
                            title: '注入测试数据',
                            onTap: () async {
                              Navigator.pop(context);
                              final inserted = await actions.seedDemoData();
                              await Future.delayed(const Duration(milliseconds: 300));
                              await actions.loadTransactions();
                              actions.notifyDataChanged();
                              actions.showMessage(inserted ? '已注入测试数据' : '已有数据，未注入测试数据');
                            },
                          ),
                          _MenuTile(
                            icon: Icons.auto_awesome_motion,
                            title: '生成随机测试数据',
                            onTap: () async {
                              Navigator.pop(context);
                              await actions.randomSeed();
                              await Future.delayed(const Duration(milliseconds: 300));
                              await actions.loadTransactions();
                              actions.notifyDataChanged();
                            },
                          ),
                          _MenuTile(
                            icon: Icons.folder_special_outlined,
                            title: '生成项目测试数据（大量）',
                            onTap: () async {
                              Navigator.pop(context);
                              await actions.projectSeedLarge();
                            },
                          ),
                        ],
                        if (kDebugMode) ...[
                          _MenuTile(
                            icon: Icons.bolt_outlined,
                            title: '模拟自动记账',
                            onTap: () async {
                              Navigator.pop(context);
                              final now = DateTime.now();
                              await actions.simulateAutoEvent({
                                'source': 'WeChat',
                                'amount': '12.34',
                                'raw_text': '微信 支付成功 测试 12.34',
                                'type': 'expense',
                                'timestamp': now.millisecondsSinceEpoch,
                                'package_name': 'com.tencent.mm',
                              });
                            },
                          ),
                          _MenuTile(
                            icon: Icons.rule,
                            title: '自动规则测试',
                            onTap: () {
                              Navigator.pop(context);
                              actions.openAutoRuleTester();
                            },
                          ),
                          _MenuTile(
                            icon: Icons.restart_alt,
                            title: '重置系统分类',
                            titleColor: Colors.orangeAccent,
                            onTap: () async {
                              Navigator.pop(context);
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('重置系统分类'),
                                  content: const Text('将清空所有分类并重新载入系统分类，是否继续？'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重置')),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await CategoryService(isar).resetCategories();
                              await TransactionService(isar).migrateTransactionCategoryKeys();
                              await actions.loadTransactions();
                              actions.showMessage('已重置系统分类');
                            },
                          ),
                        ],
                        _MenuTile(
                          icon: Icons.delete_forever,
                          title: '清空数据',
                          titleColor: Colors.redAccent,
                          onTap: () async {
                            Navigator.pop(context);
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('清空数据'),
                                content: const Text('将删除全部交易、账户和分类数据，是否继续？'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            await actions.clearAllData();
                            actions.showMessage('已清空数据');
                          },
                        ),
                        _MenuTile(
                          icon: Icons.bug_report,
                          title: '导出调试日志',
                          onTap: () {
                            Navigator.pop(context);
                            JiveLogger.exportLogs();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Quick Grid — 常用功能网格（一眼可达）
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildQuickGrid(BuildContext context, HomeMenuActions actions, Isar isar) {
  final items = [
    _QuickItem(Icons.pie_chart_outline, '预算', () => _nav(context, const BudgetManagerScreen(), actions)),
    _QuickItem(Icons.savings_outlined, '储蓄', () => _nav(context, const SavingsGoalScreen(), actions)),
    _QuickItem(Icons.repeat, '周期', () async {
      Navigator.pop(context);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringRuleListScreen()));
      await actions.loadTransactions();
    }),
    _QuickItem(Icons.trending_up, '投资', () => _nav(context, const InvestmentScreen(), actions)),
    _QuickItem(Icons.event_note, '计划', () => _nav(context, const PlanHubScreen(), actions)),
    _QuickItem(Icons.auto_awesome, 'AI', () async {
      Navigator.pop(context);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(isar: isar)));
      await actions.loadTransactions();
    }),
    _QuickItem(Icons.picture_as_pdf, '报告', () => _nav(context, const AnnualReportScreen(), actions)),
    _QuickItem(Icons.settings_outlined, '设置', () => _nav(context, const SettingsScreen(), actions)),
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════

void _nav(BuildContext context, Widget screen, HomeMenuActions actions) {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _QuickItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickItem(this.icon, this.label, this.onTap);
}

class _MenuSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Widget? trailing;

  const _MenuSection({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon, size: 20, color: Colors.grey.shade600),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: children,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: titleColor ?? Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}

class _GatedMenuTile extends StatelessWidget {
  final FeatureId feature;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _GatedMenuTile({
    required this.feature,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GatedListTile(
      feature: feature,
      leading: Icon(icon, size: 20, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      onTap: onTap,
    );
  }
}
