import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/theme.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../core/entitlement/feature_gate.dart';
import '../../core/entitlement/feature_id.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_state.dart';

/// Settings screen for cloud sync status and controls.
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure SyncEngine is initialized when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncEngine>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<EntitlementService>();
    final isSubscriber = entitlement.tier.hasCloud;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '云同步设置',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (!isSubscriber) ...[
            _buildUpgradeCard(context),
            const SizedBox(height: 12),
          ],
          if (isSubscriber) ...[
            _buildStatusCard(context),
            const SizedBox(height: 12),
            _buildControlsCard(context),
            const SizedBox(height: 12),
          ],
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            '云同步需要订阅版',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '升级到订阅版即可开启云同步，支持多设备数据实时同步。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () =>
                  showUpgradePrompt(context, FeatureId.cloudSync),
              style: FilledButton.styleFrom(
                backgroundColor: JiveTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '了解订阅版',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final syncEngine = context.watch<SyncEngine>();
    final state = syncEngine.state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('同步状态', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusIcon(state.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel(state.status),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (state.lastSyncAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '上次同步：${_formatTime(state.lastSyncAt!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    final syncEngine = context.watch<SyncEngine>();
    final state = syncEngine.state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('同步控制', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用云同步'),
            subtitle: const Text('自动同步数据到云端'),
            value: state.isEnabled,
            activeTrackColor: JiveTheme.primaryGreen,
            onChanged: (enabled) => syncEngine.setEnabled(enabled),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isSyncing ? null : () => syncEngine.sync(),
              icon: state.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(state.isSyncing ? '同步中...' : '立即同步'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '云同步使用端到端加密，数据安全存储在云端。'
              '同步功能需要订阅版，支持多设备间实时同步交易数据。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.disabled:
        return Icon(Icons.cloud_off, size: 32, color: Colors.grey.shade400);
      case SyncStatus.idle:
        return Icon(Icons.cloud_done, size: 32, color: JiveTheme.primaryGreen);
      case SyncStatus.syncing:
        return SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: JiveTheme.primaryGreen,
          ),
        );
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, size: 32, color: Colors.red);
    }
  }

  String _statusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.disabled:
        return '同步已关闭';
      case SyncStatus.idle:
        return '同步就绪';
      case SyncStatus.syncing:
        return '正在同步...';
      case SyncStatus.error:
        return '同步出错';
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }
}
