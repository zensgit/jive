import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../../core/entitlement/feature_id.dart';
import '../../../core/entitlement/gated_list_tile.dart';
import '../../../core/service/auto_app_registry.dart';
import '../../../core/service/auto_settings.dart';
import '../../../core/service/category_service.dart';
import '../../../core/service/transaction_service.dart';
import '../../../core/utils/logger_util.dart';
import '../../assistant/assistant_screen.dart';
import '../../bill_relation/bill_relation_screen.dart';
import '../../books/book_manager_screen.dart';
import '../../budget/budget_manager_screen.dart';
import '../../currency/currency_settings_screen.dart';
import '../../debt/debt_list_screen.dart';
import '../../installment/installment_list_screen.dart';
import '../../investment/investment_screen.dart';
import '../../merchant/merchant_memory_screen.dart';
import '../../project/project_list_screen.dart';
import '../../recurring/recurring_rule_list_screen.dart';
import '../../savings/savings_goal_screen.dart';
import '../../security/pin_setup_screen.dart';
import '../../settings/csv_export_screen.dart';
import '../../settings/settings_screen.dart';
import '../../split/bill_split_screen.dart';
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
                  SwitchListTile(
                    secondary: const Icon(Icons.science_outlined),
                    title: const Text("测试数据开关"),
                    subtitle: const Text("仅用于调试展示"),
                    value: demoSeedEnabled,
                    onChanged: (value) async {
                      setSheetState(() {
                        demoSeedEnabled = value;
                      });
                      await actions.setDemoSeedEnabled(value);
                      actions.showMessage(value ? "已开启测试数据" : "已关闭测试数据");
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
                        actions.showMessage("请先开启测试数据开关");
                        return;
                      }
                      Navigator.pop(context);
                      final inserted = await actions.seedDemoData();
                      await actions.loadTransactions();
                      if (inserted) {
                        actions.notifyDataChanged();
                      }
                      actions.showMessage(
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
                        actions.showMessage("请先开启测试数据开关");
                        return;
                      }
                      Navigator.pop(context);
                      await actions.randomSeed();
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
                        actions.showMessage("请先开启测试数据开关");
                        return;
                      }
                      Navigator.pop(context);
                      await actions.projectSeedLarge();
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
                        await actions.simulateAutoEvent({
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
                      await actions.openCategoryManager();
                    },
                  ),
                  GatedListTile(
                    feature: FeatureId.csvExport,
                    leading: const Icon(Icons.table_view_outlined),
                    title: const Text("导出 CSV"),
                    subtitle: const Text("按时间范围和分类导出交易"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CsvExportScreen(),
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
                  GatedListTile(
                    feature: FeatureId.projectTracking,
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text("项目追踪"),
                    subtitle: const Text("追踪旅行、装修等专项支出"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProjectListScreen(),
                        ),
                      );
                      await actions.loadTransactions();
                    },
                  ),
                  GatedListTile(
                    feature: FeatureId.multiCurrency,
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text("货币与汇率"),
                    subtitle: const Text("管理多币种和汇率"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CurrencySettingsScreen(),
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
                  GatedListTile(
                    feature: FeatureId.recurringRules,
                    leading: const Icon(Icons.repeat),
                    title: const Text("周期记账"),
                    subtitle: const Text("自动生成草稿或入账"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecurringRuleListScreen(),
                        ),
                      );
                      await actions.loadTransactions();
                      await actions.loadAutoDraftCount();
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
                      await actions.loadTransactions();
                    },
                  ),
                  GatedListTile(
                    feature: FeatureId.voiceBookkeeping,
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
                      await actions.loadTransactions();
                    },
                  ),
                  GatedListTile(
                    feature: FeatureId.merchantMemory,
                    leading: const Icon(Icons.store_outlined),
                    title: const Text("商户记忆"),
                    subtitle: const Text("管理商户名称与分类偏好"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantMemoryScreen(),
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
                  GatedListTile(
                    feature: FeatureId.debtManagement,
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
                  GatedListTile(
                    feature: FeatureId.billSplit,
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
                  GatedListTile(
                    feature: FeatureId.savingsGoals,
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
                  GatedListTile(
                    feature: FeatureId.debtManagement,
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
                  GatedListTile(
                    feature: FeatureId.debtManagement,
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
                  GatedListTile(
                    feature: FeatureId.investmentTracking,
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
                        await actions.loadTransactions();
                        actions.showMessage("已重置系统分类");
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
                      await actions.clearAllData();
                      actions.showMessage("已清空数据");
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
                      await actions.exportBackup();
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
                      await actions.importBackup();
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
                      await actions.openImportCenter();
                    },
                  ),
                  const Divider(height: 1),
                  GatedSwitchListTile(
                    feature: FeatureId.autoBookkeeping,
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
                      await actions.setAutoSettings(updated);
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
                      await actions.setAutoSettings(updated);
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
                      await actions.openAutoSupportedApps();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inbox_outlined),
                    title: const Text("待确认自动记账"),
                    subtitle: Text("当前 $pendingDraftCount 条"),
                    onTap: () async {
                      Navigator.pop(context);
                      await actions.openAutoDrafts();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rule),
                    title: const Text("自动规则测试"),
                    onTap: () async {
                      Navigator.pop(context);
                      await actions.openAutoRuleTester();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("自动记账设置"),
                    onTap: () {
                      Navigator.pop(context);
                      actions.openAutoSettings();
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
}
