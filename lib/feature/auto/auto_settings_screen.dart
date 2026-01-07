import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/service/auto_settings.dart';
import '../../core/service/auto_supported_apps.dart';
import '../../core/service/demo_seed_service.dart';
import '../../core/utils/logger_util.dart';
import 'auto_drafts_screen.dart';
import 'auto_rule_tester_screen.dart';
import 'auto_supported_apps_screen.dart';

class AutoSettingsScreen extends StatefulWidget {
  const AutoSettingsScreen({
    super.key,
    required this.isar,
    required this.autoSettings,
    required this.pendingDraftCount,
    required this.demoSeedEnabled,
  });

  final Isar isar;
  final AutoSettings autoSettings;
  final int pendingDraftCount;
  final bool demoSeedEnabled;

  @override
  State<AutoSettingsScreen> createState() => _AutoSettingsScreenState();
}

class _AutoSettingsScreenState extends State<AutoSettingsScreen> {
  static const MethodChannel _methodChannel = MethodChannel('com.jive.app/methods');
  static const _prefKeyDemoSeedEnabled = 'demo_seed_enabled';

  late AutoSettings _autoSettings;
  late bool _demoSeedEnabled;
  int _pendingDraftCount = 0;
  bool _hasChanges = false;
  int _supportedAppsTotal = 0;
  int _supportedAppsEnabled = 0;

  @override
  void initState() {
    super.initState();
    _autoSettings = widget.autoSettings;
    _demoSeedEnabled = widget.demoSeedEnabled;
    _pendingDraftCount = widget.pendingDraftCount;
    _refreshPendingDraftCount();
    _loadSupportedApps();
  }

  Future<void> _refreshPendingDraftCount() async {
    final count = await widget.isar.collection<JiveAutoDraft>().count();
    if (!mounted) return;
    setState(() {
      _pendingDraftCount = count;
    });
  }

  Future<void> _loadSupportedApps() async {
    final apps = await AutoSupportedAppsStore.loadApps();
    final enabled = await AutoSupportedAppsStore.loadEnabledIds(apps: apps);
    if (!mounted) return;
    setState(() {
      _supportedAppsTotal = apps.length;
      _supportedAppsEnabled = enabled.length;
    });
  }

  Future<void> _setAutoSettings(AutoSettings settings) async {
    await AutoSettingsStore.save(settings);
    if (!mounted) return;
    setState(() {
      _autoSettings = settings;
    });
    _hasChanges = true;
  }

  Future<void> _setDemoSeedEnabled(bool enabled) async {
    setState(() {
      _demoSeedEnabled = enabled;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDemoSeedEnabled, enabled);
    _hasChanges = true;
  }

  Future<void> _seedDemoData() async {
    if (!_demoSeedEnabled) {
      _showMessage('请先开启测试数据开关');
      return;
    }
    final inserted = await DemoSeedService.seedIfNeeded(
      widget.isar,
      enabled: _demoSeedEnabled,
    );
    if (!mounted) return;
    if (inserted) {
      _hasChanges = true;
      _showMessage('已注入测试数据');
    } else {
      _showMessage('已有数据，未注入测试数据');
    }
  }

  Future<void> _resetCategories() async {
    final confirmed = await _confirmDialog(
      title: '重置系统分类',
      content: '将清空分类并重新载入系统分类，是否继续？',
    );
    if (confirmed != true) return;
    await DemoSeedService.resetCategories(widget.isar);
    _hasChanges = true;
    _showMessage('已重置系统分类');
  }

  Future<void> _clearAllData() async {
    final confirmed = await _confirmDialog(
      title: '清空数据',
      content: '将删除全部交易、账户和分类数据，是否继续？',
    );
    if (confirmed != true) return;
    await DemoSeedService.clearAllData(widget.isar);
    await _refreshPendingDraftCount();
    _hasChanges = true;
    _showMessage('已清空数据');
  }

  Future<void> _openAutoDrafts() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoDraftsScreen()),
    );
    if (changed == true) {
      _hasChanges = true;
      await _refreshPendingDraftCount();
    }
  }

  Future<void> _openAutoRuleTester() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoRuleTesterScreen(isar: widget.isar),
      ),
    );
  }

  Future<void> _openSupportedApps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSupportedAppsScreen()),
    );
    await _loadSupportedApps();
    _hasChanges = true;
  }

  Future<void> _openNotificationSettings() async {
    await _openAndroidSettings('openNotificationSettings');
  }

  Future<void> _openAccessibilitySettings() async {
    await _openAndroidSettings('openAccessibilitySettings');
  }

  Future<void> _openOverlaySettings() async {
    await _openAndroidSettings('openOverlaySettings');
  }

  Future<void> _openAndroidSettings(String method) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showMessage('该入口仅支持 Android');
      return;
    }
    var opened = false;
    try {
      opened = await _methodChannel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (opened) return;
    final vendorOpened = await _openVendorSettings();
    if (vendorOpened) {
      _showMessage('已打开厂商权限页，请手动开启');
      return;
    }
    final fallbackOpened = await _openAppDetailsSettings();
    if (!fallbackOpened) {
      _showMessage('无法打开系统设置，请手动在系统设置中开启权限');
    } else {
      _showMessage('已打开应用详情，请在权限中手动开启');
    }
  }

  Future<bool> _openAppDetailsSettings() async {
    try {
      return await _methodChannel.invokeMethod<bool>('openAppDetailsSettings') ?? false;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<bool> _openVendorSettings() async {
    try {
      return await _methodChannel.invokeMethod<bool>('openVendorSettings') ?? false;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  void _showIOSShortcutGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('iOS 快捷指令示例'),
        content: const Text(
          '将通知内容作为文本并 URL 编码后，打开：\n\n'
          'jive://auto?source=Alipay&text=<编码后的通知文本>\n\n'
          '可选参数：amount、type、timestamp\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showVendorGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '厂商权限指引',
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildGuideItem('小米 MIUI', '设置 > 应用管理 > Jive > 权限/通知/无障碍'),
                _buildGuideItem('OPPO ColorOS', '设置 > 应用管理 > Jive > 权限/通知/自启动'),
                _buildGuideItem('vivo OriginOS', '设置 > 应用与权限 > Jive > 权限/通知/后台高耗电'),
                _buildGuideItem('通用入口', '设置 > 应用详情 > 权限 / 通知 / 无障碍'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openAppDetailsSettings();
                        },
                        child: const Text('应用详情'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final opened = await _openVendorSettings();
                          if (!opened) {
                            await _openAppDetailsSettings();
                          }
                        },
                        child: const Text('尝试跳转'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAutoTroubleGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '自动记账不工作？',
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('请依次检查以下权限与系统开关（若无法跳转，进入应用详情设置）：'),
                const SizedBox(height: 12),
                _buildGuideItem('通知读取权限', '开启通知访问，确保通知内容可读取。'),
                _buildGuideItem('无障碍权限', '用于识别支付详情，建议开启。'),
                _buildGuideItem('后台运行', '允许后台运行/自启动/电池白名单。'),
                _buildGuideItem('悬浮窗权限', '用于提示或确认，必须开启。'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openAccessibilitySettings();
                        },
                        child: const Text('去开启无障碍'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openNotificationSettings();
                        },
                        child: const Text('去开启通知'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmPermissionOpen({
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('去开启'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text('自动记账', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildTipCard(),
            const SizedBox(height: 16),
            _buildSection(
              title: '基础开关',
              tiles: [
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome),
                  title: const Text('启用自动记账'),
                  subtitle: Text(_autoSettings.enabled ? '已开启' : '已关闭'),
                  value: _autoSettings.enabled,
                  onChanged: (value) async {
                    final updated = _autoSettings.copyWith(enabled: value);
                    await _setAutoSettings(updated);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.playlist_add_check),
                  title: const Text('自动入账'),
                  subtitle: const Text('关闭则进入待确认'),
                  value: _autoSettings.directCommit,
                  onChanged: (value) async {
                    final updated = _autoSettings.copyWith(directCommit: value);
                    await _setAutoSettings(updated);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '权限与引导',
              tiles: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('通知读取权限'),
                  subtitle: const Text('用于读取支付通知内容'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmPermissionOpen(
                    title: '通知读取权限',
                    content: '用于读取支付通知内容。\n将跳转至系统设置，若失败会打开应用详情。',
                    onConfirm: _openNotificationSettings,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.accessibility_new),
                  title: const Text('无障碍权限'),
                  subtitle: const Text('识别支付详情，提升准确度'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmPermissionOpen(
                    title: '无障碍权限',
                    content: '用于识别支付详情，提升准确度。\n将跳转至系统设置，若失败会打开应用详情。',
                    onConfirm: _openAccessibilitySettings,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_in_picture),
                  title: const Text('悬浮窗权限'),
                  subtitle: const Text('用于提示/确认（必需）'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmPermissionOpen(
                    title: '悬浮窗权限',
                    content: '用于浮窗提示与确认，必须开启。\n将跳转至系统设置，若失败会打开应用详情。',
                    onConfirm: _openOverlaySettings,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.device_hub),
                  title: const Text('厂商权限指引'),
                  subtitle: const Text('MIUI/ColorOS/OriginOS 入口参考'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showVendorGuide,
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('自动记账不工作？'),
                  subtitle: const Text('一键排查常见问题'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAutoTroubleGuide,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '偏好与管理',
              tiles: [
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: const Text('自动记账支持的应用'),
                  subtitle: Text('已启用 $_supportedAppsEnabled / $_supportedAppsTotal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSupportedApps,
                ),
                ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('待确认自动记账'),
                  subtitle: Text('当前 $_pendingDraftCount 条'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAutoDrafts,
                ),
                ListTile(
                  leading: const Icon(Icons.rule),
                  title: const Text('自动规则测试'),
                  subtitle: const Text('验证规则与分类命中'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAutoRuleTester,
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('自动修正管理'),
                  subtitle: const Text('功能建设中'),
                  enabled: false,
                ),
                ListTile(
                  leading: const Icon(Icons.image_search),
                  title: const Text('截图识别'),
                  subtitle: const Text('规划中，作为兜底方案'),
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
              _buildSection(
                title: 'iOS 快捷指令',
                tiles: [
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('快捷指令导入'),
                    subtitle: const Text('用 jive:// 将通知文本导入'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showIOSShortcutGuide,
                  ),
                ],
              ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              _buildSection(
                title: '调试',
                tiles: [
                  SwitchListTile(
                    secondary: const Icon(Icons.science_outlined),
                    title: const Text('测试数据开关'),
                    subtitle: const Text('仅用于调试展示'),
                    value: _demoSeedEnabled,
                    onChanged: (value) async {
                      await _setDemoSeedEnabled(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('注入测试数据'),
                    subtitle: Text(_demoSeedEnabled ? '写入一批示例数据' : '请先开启测试数据开关'),
                    onTap: _seedDemoData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
                    title: const Text('重置系统分类', style: TextStyle(color: Colors.orangeAccent)),
                    subtitle: const Text('清空分类并重新载入系统分类'),
                    onTap: _resetCategories,
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text('清空数据', style: TextStyle(color: Colors.redAccent)),
                    onTap: _clearAllData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('导出调试日志'),
                    onTap: JiveLogger.exportLogs,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '首次使用请先开启通知/无障碍/悬浮窗权限，建议先关闭自动入账，确认准确后再开启。',
              style: GoogleFonts.lato(color: const Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> tiles}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _withDividers(tiles),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    final items = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      items.add(tiles[i]);
      if (i != tiles.length - 1) {
        items.add(const Divider(height: 1));
      }
    }
    return items;
  }
}
