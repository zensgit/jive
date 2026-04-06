import 'package:flutter/material.dart';

import '../../core/service/device_permission_guide_service.dart';

class DevicePermissionGuideScreen extends StatefulWidget {
  const DevicePermissionGuideScreen({super.key});

  @override
  State<DevicePermissionGuideScreen> createState() =>
      _DevicePermissionGuideScreenState();
}

class _DevicePermissionGuideScreenState
    extends State<DevicePermissionGuideScreen> {
  final _service = DevicePermissionGuideService();

  String _brand = 'other';
  List<PermissionStep> _steps = [];
  List<bool> _completions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final brand = await _service.getDeviceBrandAsync();
    final steps = _service.getPermissionGuideSteps(brand);
    final completions = await _service.loadAllStepCompletions(steps.length);
    if (!mounted) return;
    setState(() {
      _brand = brand;
      _steps = steps;
      _completions = completions;
      _loading = false;
    });
  }

  String _brandDisplayName(String brand) {
    switch (brand) {
      case 'xiaomi':
        return '小米 / Redmi / POCO';
      case 'huawei':
        return '华为 / 荣耀';
      case 'oppo':
        return 'OPPO';
      case 'vivo':
        return 'vivo';
      case 'samsung':
        return '三星 Samsung';
      case 'oneplus':
        return 'OnePlus 一加';
      case 'meizu':
        return '魅族 Meizu';
      case 'realme':
        return 'realme';
      default:
        return '通用设备';
    }
  }

  Future<void> _toggleStep(int index, bool? value) async {
    final completed = value ?? false;
    await _service.setStepCompleted(index, completed: completed);
    if (!mounted) return;
    setState(() {
      _completions[index] = completed;
    });
  }

  Future<void> _openSettings() async {
    await _service.openBatteryOptimizationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设备权限引导')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBrandHeader(theme),
                const SizedBox(height: 16),
                ..._buildStepCards(theme),
                const SizedBox(height: 24),
                _buildOpenSettingsButton(theme),
                const SizedBox(height: 16),
                _buildStatusSummary(theme),
              ],
            ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android,
              color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '检测到设备品牌',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  _brandDisplayName(_brand),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepCards(ThemeData theme) {
    return List.generate(_steps.length, (i) {
      final step = _steps[i];
      final completed = _completions[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: completed
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: completed
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              alignment: Alignment.center,
              child: completed
                  ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            title: Text(
              step.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration:
                    completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(step.description),
            trailing: Checkbox(
              value: completed,
              onChanged: (v) => _toggleStep(i, v),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOpenSettingsButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openSettings,
        icon: const Icon(Icons.settings),
        label: const Text('打开设置'),
      ),
    );
  }

  Widget _buildStatusSummary(ThemeData theme) {
    final total = _steps.length;
    final done = _completions.where((c) => c).length;
    final allDone = done == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.check_circle : Icons.info_outline,
            color: allDone ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allDone
                  ? '所有权限步骤已完成'
                  : '已完成 $done / $total 步',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: allDone
                    ? Colors.green.shade700
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
