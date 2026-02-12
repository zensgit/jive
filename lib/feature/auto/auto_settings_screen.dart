import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/auto_draft_model.dart';
import '../../core/service/auto_app_registry.dart';
import '../../core/service/auto_app_settings.dart';
import '../../core/service/auto_permission_service.dart';
import '../../core/service/auto_settings.dart';
import 'auto_drafts_screen.dart';
import 'auto_account_mapping_screen.dart';
import 'auto_keepalive_screen.dart';
import 'auto_rule_tester_screen.dart';
import 'auto_supported_apps_screen.dart';

class AutoSettingsScreen extends StatefulWidget {
  const AutoSettingsScreen({super.key, required this.isar});

  final Isar isar;

  @override
  State<AutoSettingsScreen> createState() => _AutoSettingsScreenState();
}

class _AutoSettingsScreenState extends State<AutoSettingsScreen> with WidgetsBindingObserver {
  AutoSettings _settings = AutoSettingsStore.defaults;
  AutoPermissionStatus _permissions = AutoPermissionStatus.empty;
  int _enabledAppCount = 0;
  int _pendingDraftCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _load() async {
    final settings = await AutoSettingsStore.load();
    final permissions = await AutoPermissionService.getStatus();
    final enabledMap = await AutoAppSettingsStore.loadEnabledMap();
    final enabledCount = AutoAppSettingsStore.enabledCount(enabledMap);
    final pending = await widget.isar.collection<JiveAutoDraft>().count();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permissions = permissions;
      _enabledAppCount = enabledCount;
      _pendingDraftCount = pending;
      _loading = false;
    });
  }

  Future<void> _refreshPermissions() async {
    final permissions = await AutoPermissionService.getStatus();
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
    });
  }

  Future<void> _toggleAutoEnabled(bool value) async {
    if (value && !_permissions.allRequired) {
      await _showMissingPermissionDialog();
      return;
    }
    final updated = _settings.copyWith(enabled: value);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _toggleDirectCommit(bool value) async {
    final updated = _settings.copyWith(directCommit: value);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _toggleKeywordFilter(bool value) async {
    final updated = _settings.copyWith(keywordFilterEnabled: value);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _toggleTransferRecognition(bool value) async {
    final updated = _settings.copyWith(autoTransferRecognition: value);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _updateTransferWindow(int seconds) async {
    final updated = _settings.copyWith(autoTransferWindowSeconds: seconds);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _openSupportedApps() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoSupportedAppsScreen()),
    );
    final enabledMap = await AutoAppSettingsStore.loadEnabledMap();
    if (!mounted) return;
    setState(() {
      _enabledAppCount = AutoAppSettingsStore.enabledCount(enabledMap);
    });
  }

  Future<void> _openAutoDrafts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoDraftsScreen()),
    );
    final pending = await widget.isar.collection<JiveAutoDraft>().count();
    if (!mounted) return;
    setState(() {
      _pendingDraftCount = pending;
    });
  }

  Future<void> _openRuleTester() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoRuleTesterScreen(isar: widget.isar)),
    );
  }

  Future<void> _openAccountMapping() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoAccountMappingScreen(isar: widget.isar)),
    );
  }

  Future<void> _editKeywordFilters() async {
    final controller = TextEditingController(text: _settings.keywordFilters.join('\n'));
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关键词过滤列表'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '每行一个关键词',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存')),
        ],
      ),
    );
    if (saved != true) return;
    final lines = controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final updated = _settings.copyWith(keywordFilters: lines);
    setState(() => _settings = updated);
    await AutoSettingsStore.save(updated);
  }

  Future<void> _showMissingPermissionDialog() async {
    final missing = _permissions.missingRequiredLabels();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要开启权限'),
        content: Text('未开启：${missing.join('、')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showTroubleshootSheet();
            },
            child: const Text('去开启'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVendorGuideSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('厂商权限指引', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _GuideRow(
                title: '小米 MIUI',
                body: '设置 > 应用管理 > Jive > 权限/通知/无障碍',
              ),
              const _GuideRow(
                title: 'OPPO ColorOS',
                body: '设置 > 应用管理 > Jive > 权限/通知/自启动',
              ),
              const _GuideRow(
                title: 'vivo OriginOS',
                body: '设置 > 应用与权限 > Jive > 权限/通知/后台高耗电',
              ),
              const _GuideRow(
                title: '通用入口',
                body: '设置 > 应用详情 > 权限/通知/无障碍',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.openAppDetails();
                      },
                      child: const Text('应用详情'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.openAccessibilitySettings();
                      },
                      child: const Text('无障碍设置'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openKeepAlive() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoKeepAliveScreen()),
    );
  }

  Future<void> _showTroubleshootSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('自动记账不工作？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatusRow(
                title: '通知读取权限',
                enabled: _permissions.notification,
              ),
              _StatusRow(
                title: '无障碍权限',
                enabled: _permissions.accessibility,
              ),
              _StatusRow(
                title: '悬浮窗权限',
                enabled: _permissions.overlay,
              ),
              _StatusRow(
                title: '后台优化',
                enabled: _permissions.batteryOptimization,
                hint: '建议关闭电池优化',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.openAccessibilitySettings();
                      },
                      child: const Text('去开启无障碍'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.openNotificationSettings();
                      },
                      child: const Text('去开启通知'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.openOverlaySettings();
                      },
                      child: const Text('去开启悬浮窗'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AutoPermissionService.requestIgnoreBatteryOptimizations();
                      },
                      child: const Text('后台优化'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        );

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动记账'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '首次使用请先开启通知/无障碍/悬浮窗权限，建议先关闭自动入账，确认准确后再开启。',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('权限用途说明', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                _InlineBullet(text: '通知读取：读取支付通知，作为兜底识别来源。'),
                _InlineBullet(text: '无障碍：识别支付详情页金额/商户，是主要识别通道。'),
                _InlineBullet(text: '悬浮窗：用于提示/确认与引导（必需）。'),
                _InlineBullet(text: '后台优化：防止被系统清理，提升稳定性。'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('基础开关', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('启用自动记账'),
                  subtitle: Text(_settings.enabled ? '已开启' : '已关闭'),
                  value: _settings.enabled,
                  onChanged: _toggleAutoEnabled,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('自动入账'),
                  subtitle: const Text('关闭则进入待确认'),
                  value: _settings.directCommit,
                  onChanged: _settings.enabled ? _toggleDirectCommit : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('识别偏好', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('关键词过滤'),
                  subtitle: Text(_settings.keywordFilterEnabled ? '仅识别包含关键词的通知/详情' : '已关闭'),
                  value: _settings.keywordFilterEnabled,
                  onChanged: _toggleKeywordFilter,
                ),
                ListTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: const Text('过滤关键词列表'),
                  subtitle: Text('当前 ${_settings.keywordFilters.length} 个关键词'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _settings.keywordFilterEnabled ? _editKeywordFilters : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('转账合并识别'),
                  subtitle: Text(_settings.autoTransferRecognition ? '自动合并为转账' : '已关闭'),
                  value: _settings.autoTransferRecognition,
                  onChanged: _toggleTransferRecognition,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('转账合并时间窗口（秒）'),
                      Slider(
                        value: _settings.autoTransferWindowSeconds.toDouble(),
                        min: 10,
                        max: 300,
                        divisions: 29,
                        label: '${_settings.autoTransferWindowSeconds}s',
                        onChanged: _settings.autoTransferRecognition
                            ? (value) => _updateTransferWindow(value.round())
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('权限与引导', style: sectionTitleStyle),
          const SizedBox(height: 8),
          _PermissionTile(
            title: '通知读取权限',
            subtitle: '读取支付通知，兜底识别来源',
            enabled: _permissions.notification,
            onTap: AutoPermissionService.openNotificationSettings,
          ),
          _PermissionTile(
            title: '无障碍权限',
            subtitle: '识别支付详情页金额/商户',
            enabled: _permissions.accessibility,
            onTap: AutoPermissionService.openAccessibilitySettings,
          ),
          _PermissionTile(
            title: '悬浮窗权限（必需）',
            subtitle: '用于提示/确认与引导',
            enabled: _permissions.overlay,
            onTap: AutoPermissionService.openOverlaySettings,
          ),
          _PermissionTile(
            title: '后台优化（建议）',
            subtitle: '关闭电池优化提升稳定性',
            enabled: _permissions.batteryOptimization,
            onTap: AutoPermissionService.requestIgnoreBatteryOptimizations,
          ),
          _PermissionTile(
            title: '厂商权限指引',
            subtitle: 'MIUI/ColorOS/OriginOS 入口参考',
            enabled: true,
            onTap: _showVendorGuideSheet,
          ),
          _PermissionTile(
            title: '稳定运行设置',
            subtitle: '后台保活与支付保护说明',
            enabled: true,
            onTap: _openKeepAlive,
          ),
          _PermissionTile(
            title: '自动记账不工作？',
            subtitle: '一键排查常见问题',
            enabled: true,
            onTap: _showTroubleshootSheet,
          ),
          const SizedBox(height: 16),
          Text('偏好与管理', style: sectionTitleStyle),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('自动记账支持的应用'),
            subtitle: Text('已启用 $_enabledAppCount / ${AutoAppRegistry.apps.length}'),
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
            onTap: _openRuleTester,
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('账户映射规则'),
            subtitle: const Text('为转账账户建立匹配规则'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openAccountMapping,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = enabled ? '已开启' : '未开启';
    final statusColor = enabled ? Colors.green : Colors.orange;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(statusText, style: TextStyle(color: statusColor)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _InlineBullet extends StatelessWidget {
  const _InlineBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF64748B))),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.title,
    required this.enabled,
    this.hint,
  });

  final String title;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(enabled ? Icons.check_circle : Icons.error, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
          if (hint != null)
            Text(hint!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
