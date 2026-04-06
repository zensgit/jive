import 'package:flutter/material.dart';

import '../../core/service/auto_capture_enhanced_service.dart';
import '../../core/service/auto_settings.dart';
import '../../core/service/payment_notification_parser.dart';
import 'auto_capture_notification_settings.dart';

class AutoCaptureSettingsScreen extends StatefulWidget {
  const AutoCaptureSettingsScreen({super.key});

  @override
  State<AutoCaptureSettingsScreen> createState() =>
      _AutoCaptureSettingsScreenState();
}

class _AutoCaptureSettingsScreenState extends State<AutoCaptureSettingsScreen> {
  bool _loading = true;
  AutoSettings? _settings;

  bool _wechatEnabled = true;
  bool _alipayEnabled = true;
  bool _bankEnabled = true;

  CaptureStats _stats = CaptureStats.zero;
  List<CaptureRecord> _recentCaptures = const [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final settings = await AutoSettingsStore.load();
    final wechat =
        await AutoCaptureEnhancedService.getSourceEnabled(PaymentSource.wechat);
    final alipay =
        await AutoCaptureEnhancedService.getSourceEnabled(PaymentSource.alipay);
    final bank =
        await AutoCaptureEnhancedService.getSourceEnabled(PaymentSource.bank);

    final service = AutoCaptureEnhancedService();

    if (!mounted) return;
    setState(() {
      _settings = settings;
      _wechatEnabled = wechat;
      _alipayEnabled = alipay;
      _bankEnabled = bank;
      _stats = service.getCaptureStats();
      _recentCaptures = service.getRecentCaptures(count: 10);
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    final next = _settings!.copyWith(enabled: value);
    setState(() => _settings = next);
    await AutoSettingsStore.save(next);
  }

  Future<void> _toggleSource(PaymentSource source, bool value) async {
    await AutoCaptureEnhancedService.setSourceEnabled(source, enabled: value);
    if (!mounted) return;
    setState(() {
      switch (source) {
        case PaymentSource.wechat:
          _wechatEnabled = value;
        case PaymentSource.alipay:
          _alipayEnabled = value;
        case PaymentSource.bank:
          _bankEnabled = value;
        case PaymentSource.unknown:
          break;
      }
    });
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

  Widget _buildHeaderCard() {
    final enabled = _settings?.enabled ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "自动记账",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  enabled
                      ? "已启用。监听支付通知并自动创建待确认草稿。"
                      : "当前已关闭。开启后可自动捕获微信、支付宝等支付通知。",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle() {
    return _sectionCard(
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("启用自动记账",
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text("监听支付通知并自动创建草稿"),
        value: _settings?.enabled ?? false,
        onChanged: _toggleEnabled,
        activeTrackColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildSourceToggles() {
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("通知来源",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("微信支付"),
            subtitle: const Text("com.tencent.mm"),
            value: _wechatEnabled,
            onChanged: (v) => _toggleSource(PaymentSource.wechat, v),
            activeTrackColor: const Color(0xFF2E7D32),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("支付宝"),
            subtitle: const Text("com.eg.android.AlipayGphone"),
            value: _alipayEnabled,
            onChanged: (v) => _toggleSource(PaymentSource.alipay, v),
            activeTrackColor: const Color(0xFF2E7D32),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("银行短信"),
            subtitle: const Text("工商/建设/农业/中国/招商/交通"),
            value: _bankEnabled,
            onChanged: (v) => _toggleSource(PaymentSource.bank, v),
            activeTrackColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text("捕获统计",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Row(
            children: [
              _statItem("今日", _stats.today),
              const SizedBox(width: 24),
              _statItem("本周", _stats.thisWeek),
              const SizedBox(width: 24),
              _statItem("本月", _stats.thisMonth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildRecentCaptures() {
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("最近捕获",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (_recentCaptures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text("暂无记录",
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...List.generate(_recentCaptures.length, (i) {
              final record = _recentCaptures[i];
              final isIncome = record.type == 'income';
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isIncome ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      record.merchant ?? record.source,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      record.source,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: Text(
                      "${isIncome ? '+' : '-'}${record.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.green : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text("如何开启通知监听权限",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "1. 打开系统「设置」\n"
            "2. 进入「通知使用权」或「通知访问权限」\n"
            "3. 找到 Jive 并开启权限\n"
            "4. 返回应用即可自动捕获支付通知",
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openNotificationAccessSettings,
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text("前往系统通知设置"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNotificationAccessSettings() {
    // On Android this would use android_intent or similar to open
    // Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS.
    // Since we are Dart-side only, we show a snackbar as a placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("请在系统设置中搜索「通知使用权」并开启 Jive 的权限"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title:
            const Text("自动记账设置", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _loading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 14),
                _buildMasterToggle(),
                const SizedBox(height: 14),
                _buildSourceToggles(),
                const SizedBox(height: 14),
                const AutoCaptureNotificationSettings(),
                const SizedBox(height: 14),
                _buildStatsCard(),
                const SizedBox(height: 14),
                _buildRecentCaptures(),
                const SizedBox(height: 14),
                _buildPermissionCard(),
              ],
            ),
    );
  }
}
