import 'package:flutter/material.dart';

import '../../core/service/anomaly_detection_service.dart';

/// 消费异常检测设置页面
class AnomalySettingsScreen extends StatefulWidget {
  const AnomalySettingsScreen({super.key});

  @override
  State<AnomalySettingsScreen> createState() => _AnomalySettingsScreenState();
}

class _AnomalySettingsScreenState extends State<AnomalySettingsScreen> {
  bool _enabled = false;
  bool _largeExpense = true;
  bool _budgetExceeded = true;
  bool _duplicateCharge = true;
  bool _unusualTime = true;
  bool _monthlyBreach = true;
  double _thresholdMultiplier = 3.0;
  int _quietStart = 23;
  int _quietEnd = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await AnomalyDetectionService.isEnabled();
    final large =
        await AnomalyDetectionService.isTypeEnabled(AnomalyType.largeExpense);
    final budget =
        await AnomalyDetectionService.isTypeEnabled(AnomalyType.budgetExceeded);
    final duplicate =
        await AnomalyDetectionService.isTypeEnabled(AnomalyType.duplicateCharge);
    final unusual =
        await AnomalyDetectionService.isTypeEnabled(AnomalyType.unusualTime);
    final monthly =
        await AnomalyDetectionService.isTypeEnabled(AnomalyType.monthlyBreach);
    final multiplier = await AnomalyDetectionService.getThresholdMultiplier();
    final (quietStart, quietEnd) =
        await AnomalyDetectionService.getQuietHours();

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _largeExpense = large;
      _budgetExceeded = budget;
      _duplicateCharge = duplicate;
      _unusualTime = unusual;
      _monthlyBreach = monthly;
      _thresholdMultiplier = multiplier;
      _quietStart = quietStart;
      _quietEnd = quietEnd;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await AnomalyDetectionService.setEnabled(value);
  }

  Future<void> _setTypeEnabled(AnomalyType type, bool value) async {
    setState(() {
      switch (type) {
        case AnomalyType.largeExpense:
          _largeExpense = value;
        case AnomalyType.budgetExceeded:
          _budgetExceeded = value;
        case AnomalyType.duplicateCharge:
          _duplicateCharge = value;
        case AnomalyType.unusualTime:
          _unusualTime = value;
        case AnomalyType.monthlyBreach:
          _monthlyBreach = value;
      }
    });
    await AnomalyDetectionService.setTypeEnabled(type, value);
  }

  Future<void> _setThreshold(double value) async {
    setState(() => _thresholdMultiplier = value);
    await AnomalyDetectionService.setThresholdMultiplier(value);
  }

  Future<void> _pickQuietHours() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _quietStart, minute: 0),
      helpText: '免打扰开始时间',
    );
    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _quietEnd, minute: 0),
      helpText: '免打扰结束时间',
    );
    if (endTime == null || !mounted) return;

    setState(() {
      _quietStart = startTime.hour;
      _quietEnd = endTime.hour;
    });
    await AnomalyDetectionService.setQuietHours(startTime.hour, endTime.hour);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('消费异常检测')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── 总开关 ──
                SwitchListTile(
                  title: const Text('启用异常检测'),
                  subtitle: const Text('在记账时自动检测异常消费'),
                  value: _enabled,
                  onChanged: _setEnabled,
                ),
                const Divider(),

                // ── 检测类型 ──
                _sectionHeader('检测类型'),
                _typeToggle(
                  title: '大额消费',
                  subtitle: '金额超过日均的指定倍数时提醒',
                  icon: Icons.trending_up,
                  value: _largeExpense,
                  type: AnomalyType.largeExpense,
                ),
                _typeToggle(
                  title: '预算超支',
                  subtitle: '消费导致预算超出时提醒',
                  icon: Icons.account_balance_wallet,
                  value: _budgetExceeded,
                  type: AnomalyType.budgetExceeded,
                ),
                _typeToggle(
                  title: '重复扣费',
                  subtitle: '1小时内同金额同分类交易',
                  icon: Icons.content_copy,
                  value: _duplicateCharge,
                  type: AnomalyType.duplicateCharge,
                ),
                _typeToggle(
                  title: '异常时间',
                  subtitle: '工作日凌晨0-5点消费',
                  icon: Icons.nightlight_round,
                  value: _unusualTime,
                  type: AnomalyType.unusualTime,
                ),
                _typeToggle(
                  title: '月度超限',
                  subtitle: '当月总消费超过近3个月均值的120%',
                  icon: Icons.calendar_month,
                  value: _monthlyBreach,
                  type: AnomalyType.monthlyBreach,
                ),
                const Divider(),

                // ── 大额消费阈值 ──
                _sectionHeader('大额消费阈值'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('2x'),
                      Expanded(
                        child: Slider(
                          value: _thresholdMultiplier,
                          min: 2.0,
                          max: 5.0,
                          divisions: 6,
                          label:
                              '${_thresholdMultiplier.toStringAsFixed(1)}x',
                          onChanged: _enabled ? _setThreshold : null,
                        ),
                      ),
                      const Text('5x'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '当前：超过日均 '
                    '${_thresholdMultiplier.toStringAsFixed(1)} 倍时提醒',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),

                // ── 免打扰 ──
                _sectionHeader('免打扰时间'),
                ListTile(
                  leading: const Icon(Icons.do_not_disturb_on),
                  title: Text(
                    '${_quietStart.toString().padLeft(2, '0')}:00 — '
                    '${_quietEnd.toString().padLeft(2, '0')}:00',
                  ),
                  subtitle: const Text('此时段内不发送异常通知'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _enabled ? _pickQuietHours : null,
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionHeader(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isDark ? Colors.white60 : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _typeToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required AnomalyType type,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _enabled ? (v) => _setTypeEnabled(type, v) : null,
    );
  }
}
