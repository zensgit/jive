import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/theme.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../core/service/locale_service.dart';
import '../../core/entitlement/feature_id.dart';
import '../../core/entitlement/gated_list_tile.dart';
import '../../core/service/category_icon_style.dart';
import '../../core/service/daily_reminder_service.dart';
import '../subscription/subscription_screen.dart';
import '../installment/installment_manage_screen.dart';
import '../budget/budget_settings_screen.dart';
import 'speech_settings_screen.dart';
import 'sync_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'webdav_settings_screen.dart';
import '../export/csv_export_screen.dart';
import '../theme/theme_provider.dart';
import '../theme/theme_selection_screen.dart';
import '../transactions/reimbursement_lab_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCategoryIconStyle(
    BuildContext context, {
    required CategoryIconStyle current,
  }) async {
    final picked = await showModalBottomSheet<CategoryIconStyle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "分类图标风格",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "关闭",
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...CategoryIconStyle.values.map((style) {
                  final isSelected = current == style;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: JiveTheme.primaryGreen,
                    ),
                    title: Text(style.label),
                    onTap: () => Navigator.pop(sheetContext, style),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || picked == current) return;
    await CategoryIconStyleStore.save(picked);
    CategoryIconStyleConfig.current = picked;
  }

  Widget _sectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("设置", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Consumer<EntitlementService>(
            builder: (context, entitlement, _) {
              return _sectionCard(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.workspace_premium,
                    color: JiveTheme.primaryGreen,
                  ),
                  title: const Text("账户与订阅"),
                  subtitle: Text('当前：${entitlement.tier.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _sectionCard(
            GatedListTile(
              feature: FeatureId.cloudSync,
              leading: Icon(
                Icons.cloud_sync_outlined,
                color: JiveTheme.primaryGreen,
              ),
              title: const Text('云同步设置'),
              subtitle: const Text('云端备份与多设备同步'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SyncSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("外观", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    final modeLabel =
                        themeProvider.isDarkMode ? '深色模式' : '浅色模式';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text("主题设置"),
                      subtitle: Text(
                        '${themeProvider.selectedPresetName} · $modeLabel',
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemeSelectionScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ValueListenableBuilder<CategoryIconStyle>(
                  valueListenable: CategoryIconStyleConfig.notifier,
                  builder: (context, style, _) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text("分类图标风格"),
                      subtitle: Text(style.label),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onTap: () =>
                          _pickCategoryIconStyle(context, current: style),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text("主题设置"),
                  subtitle: const Text("颜色、字体与显示模式"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("语言", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Consumer<LocaleService>(
                  builder: (context, localeService, _) {
                    final current = localeService.currentLocale;
                    final label = _localeLabel(current);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language),
                      title: const Text("应用语言"),
                      subtitle: Text(label),
                      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                      onTap: () => _showLanguagePicker(context, localeService),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("预算", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text("预算设置"),
                  subtitle: const Text("预算提醒与展示偏好"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            _NotificationSettingsSection(),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("语音与智能", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mic_none_rounded),
                  title: const Text("语音设置"),
                  subtitle: const Text("语音记账开关、语言与线上增强状态"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpeechSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("数据", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text("WebDAV 同步"),
                  subtitle: const Text("云端备份与恢复"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebDavSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text("导出数据"),
                  subtitle: const Text("按日期、分类和类型导出 CSV"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CsvExportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text("账务管理", style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.view_timeline_outlined),
                  title: const Text("分期管理（MVP）"),
                  subtitle: const Text("分期创建、到期执行、提前结清"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstallmentManageScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text("报销退款工作台（MVP）"),
                  subtitle: const Text("按账单创建报销或退款记录"),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReimbursementLabScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale) {
    switch ('${locale.languageCode}_${locale.countryCode}') {
      case 'zh_CN': return '简体中文';
      case 'zh_TW': return '繁體中文';
      case 'en_US': case 'en_': case 'en_null': return 'English';
      default: return locale.toString();
    }
  }

  void _showLanguagePicker(BuildContext context, LocaleService service) {
    final locales = service.getSupportedLocales();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('选择语言', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...locales.map((locale) {
              final isSelected = service.currentLocale == locale;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: JiveTheme.primaryGreen,
                ),
                title: Text(_localeLabel(locale)),
                onTap: () {
                  service.setLocale(locale);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsSection extends StatefulWidget {
  @override
  State<_NotificationSettingsSection> createState() => _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState extends State<_NotificationSettingsSection> {
  DailyReminderSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await DailyReminderService.loadSettings();
    if (mounted) setState(() => _settings = s);
  }

  Future<void> _update(DailyReminderSettings s) async {
    setState(() => _settings = s);
    await DailyReminderService.saveSettings(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    if (s == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("通知与提醒", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_none),
          title: const Text("每日记账提醒"),
          subtitle: Text(s.enabled ? '每天 ${s.hourLabel} 提醒记账' : '关闭'),
          value: s.enabled,
          onChanged: (v) => _update(s.copyWith(enabled: v)),
        ),
        if (s.enabled) ...[
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text("提醒时间"),
            subtitle: Text(s.hourLabel),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.hour, minute: 0),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                _update(s.copyWith(hour: picked.hour));
              }
            },
          ),
        ],
      ],
    );
  }
}
