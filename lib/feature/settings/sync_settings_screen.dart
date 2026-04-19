import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/design_system/theme.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../core/entitlement/feature_gate.dart';
import '../../core/entitlement/feature_id.dart';
import '../../core/sync/sync_config.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_state.dart';
import 'sync_conflict_screen.dart';

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
    final authService = context.watch<AuthService>();
    final isSubscriber = entitlement.tier.hasCloud;
    final hasSignedInUser = authService.isLoggedIn;
    final hasSyncConfig = SyncConfig.isConfigured;

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
            if (!hasSignedInUser || !hasSyncConfig) ...[
              _buildPrerequisiteCard(
                hasSignedInUser: hasSignedInUser,
                hasSyncConfig: hasSyncConfig,
              ),
              const SizedBox(height: 12),
            ],
            _buildStatusCard(
              context,
              hasSignedInUser: hasSignedInUser,
              hasSyncConfig: hasSyncConfig,
            ),
            const SizedBox(height: 12),
            _buildConflictCard(context),
            const SizedBox(height: 12),
            _buildControlsCard(
              context,
              hasSignedInUser: hasSignedInUser,
              hasSyncConfig: hasSyncConfig,
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoCard(
            hasSignedInUser: hasSignedInUser,
            hasSyncConfig: hasSyncConfig,
          ),
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
            '升级到订阅版即可开启云同步，登录并联网后可在多设备间同步数据。',
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

  Widget _buildPrerequisiteCard({
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    String title;
    String message;

    if (!hasSyncConfig) {
      title = '当前构建未配置云同步';
      message = '需要在构建时注入同步服务配置后，才能启用云同步。';
    } else if (!hasSignedInUser) {
      title = '请先登录';
      message = '当前处于本地模式。登录后才能把数据同步到云端并在多设备间使用。';
    } else {
      title = '云同步暂不可用';
      message = '请检查登录状态与同步配置后重试。';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.amber.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    final syncEngine = context.watch<SyncEngine>();
    final state = syncEngine.state;
    final detail = _statusDetail(
      state,
      hasSignedInUser: hasSignedInUser,
      hasSyncConfig: hasSyncConfig,
    );

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
                      _statusLabel(
                        state.status,
                        hasSignedInUser: hasSignedInUser,
                        hasSyncConfig: hasSyncConfig,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
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

  Widget _buildControlsCard(
    BuildContext context, {
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    final syncEngine = context.watch<SyncEngine>();
    final state = syncEngine.state;
    final canInteract = hasSignedInUser && hasSyncConfig;

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
            subtitle: Text(
              _controlsSubtitle(
                hasSignedInUser: hasSignedInUser,
                hasSyncConfig: hasSyncConfig,
              ),
            ),
            value: state.isEnabled,
            activeTrackColor: JiveTheme.primaryGreen,
            onChanged: canInteract
                ? (enabled) => syncEngine.setEnabled(enabled)
                : null,
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: !canInteract || state.isSyncing
                  ? null
                  : () => syncEngine.sync(),
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

  Widget _buildConflictCard(BuildContext context) {
    final syncEngine = context.watch<SyncEngine>();
    final conflictCount = syncEngine.state.conflictCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: conflictCount > 0 ? Colors.orange.shade300 : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          conflictCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: conflictCount > 0 ? Colors.orange : JiveTheme.primaryGreen,
        ),
        title: const Text('同步冲突'),
        subtitle: Text(
          conflictCount > 0 ? '$conflictCount 个冲突待处理' : '没有冲突',
          style: TextStyle(
            color: conflictCount > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: conflictCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$conflictCount',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncConflictScreen()),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    final extraNote = !hasSyncConfig
        ? ' 当前构建尚未注入同步服务配置。'
        : !hasSignedInUser
        ? ' 当前处于本地模式，请先登录后再启用同步。'
        : '';

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
              '云同步通过 HTTPS 加密传输，并存储在 Supabase。'
              '当前版本不提供端到端加密密钥管理；同步功能需要订阅版，登录并联网后可在多设备间同步交易数据。'
              '$extraNote',
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

  String _statusLabel(
    SyncStatus status, {
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    if (!hasSyncConfig) return '当前构建未配置同步服务';
    if (!hasSignedInUser) return '请先登录后再同步';

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

  String? _statusDetail(
    SyncState state, {
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    if (!hasSyncConfig) {
      return '需要在构建时注入同步服务配置。';
    }
    if (!hasSignedInUser) {
      return '登录后才能将本地数据同步到云端。';
    }
    if (state.status == SyncStatus.disabled) {
      return '自动同步当前已关闭，可在下方重新启用。';
    }
    if (state.status == SyncStatus.idle && state.lastSyncAt == null) {
      return '已满足同步条件，可手动发起首次同步。';
    }
    return null;
  }

  String _controlsSubtitle({
    required bool hasSignedInUser,
    required bool hasSyncConfig,
  }) {
    if (!hasSyncConfig) return '当前构建未配置同步服务';
    if (!hasSignedInUser) return '请先登录后再启用自动同步';
    return '登录并联网后与服务器同步交易数据';
  }

  String _formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }
}
