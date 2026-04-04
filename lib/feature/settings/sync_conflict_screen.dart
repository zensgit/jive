import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/sync_conflict_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/sync/sync_engine.dart';

/// Screen to view and resolve sync conflicts.
class SyncConflictScreen extends StatefulWidget {
  const SyncConflictScreen({super.key});

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  List<JiveSyncConflict> _conflicts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    final service = context.read<SyncEngine>().conflictService;
    final conflicts = await service.getPendingConflicts();
    if (mounted) {
      setState(() {
        _conflicts = conflicts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('同步冲突', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          if (_conflicts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleBatchAction,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'keepLocal', child: Text('全部保留本地')),
                const PopupMenuItem(value: 'keepRemote', child: Text('全部保留云端')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? _buildEmptyState()
              : _buildConflictList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: JiveTheme.primaryGreen),
          const SizedBox(height: 16),
          const Text('没有同步冲突', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('数据同步一切正常', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildConflictList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _conflicts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildConflictCard(_conflicts[index]),
    );
  }

  Widget _buildConflictCard(JiveSyncConflict conflict) {
    final localData = _parseJson(conflict.localJson);
    final remoteData = _parseJson(conflict.remoteJson);
    final diffs = _computeDiffs(localData, remoteData);
    final tableName = _tableDisplayName(conflict.table);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$tableName #${conflict.localId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatTime(conflict.detectedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Diff details
          if (diffs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('变更字段', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...diffs.map((diff) => _buildDiffRow(diff)),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveConflict(conflict, 'keepLocal'),
                    icon: const Icon(Icons.phone_android, size: 16),
                    label: const Text('保留本地'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolveConflict(conflict, 'keepRemote'),
                    icon: const Icon(Icons.cloud, size: 16),
                    label: const Text('保留云端'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(_DiffEntry diff) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              diff.field,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.phone_android, size: 12, color: Colors.blue.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diff.localValue,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.cloud, size: 12, color: Colors.green.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diff.remoteValue,
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveConflict(JiveSyncConflict conflict, String strategy) async {
    final engine = context.read<SyncEngine>();
    final service = engine.conflictService;

    if (strategy == 'keepLocal') {
      await service.resolveKeepLocal(conflict.id);
    } else {
      await service.resolveKeepRemote(conflict.id);
      engine.scheduleSync();
    }

    await engine.refreshConflictCount();
    await _loadConflicts();
  }

  Future<void> _handleBatchAction(String strategy) async {
    final engine = context.read<SyncEngine>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strategy == 'keepLocal' ? '全部保留本地版本？' : '全部保留云端版本？'),
        content: Text('将对所有 ${_conflicts.length} 个冲突执行此操作'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final service = engine.conflictService;
    await service.resolveAll(strategy);
    if (strategy == 'keepRemote') {
      engine.scheduleSync();
    }
    await engine.refreshConflictCount();
    await _loadConflicts();
  }

  Map<String, dynamic> _parseJson(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  List<_DiffEntry> _computeDiffs(Map<String, dynamic> local, Map<String, dynamic> remote) {
    final diffs = <_DiffEntry>[];
    final allKeys = {...local.keys, ...remote.keys};

    for (final key in allKeys) {
      // Skip metadata fields
      if (key == 'user_id' || key == 'id' || key == 'local_id') continue;

      final localVal = local[key]?.toString() ?? '(空)';
      final remoteVal = remote[key]?.toString() ?? '(空)';

      if (localVal != remoteVal) {
        diffs.add(_DiffEntry(
          field: _fieldDisplayName(key),
          localValue: localVal,
          remoteValue: remoteVal,
        ));
      }
    }

    return diffs;
  }

  String _tableDisplayName(String table) {
    switch (table) {
      case 'transactions': return '交易';
      case 'accounts': return '账户';
      case 'categories': return '分类';
      case 'tags': return '标签';
      case 'budgets': return '预算';
      default: return table;
    }
  }

  String _fieldDisplayName(String field) {
    const names = {
      'amount': '金额',
      'source': '来源',
      'type': '类型',
      'timestamp': '时间',
      'category_key': '分类',
      'sub_category_key': '子分类',
      'category': '分类名',
      'sub_category': '子分类名',
      'note': '备注',
      'account_id': '账户',
      'raw_text': '原文',
      'updated_at': '更新时间',
      'name': '名称',
      'opening_balance': '初始余额',
      'credit_limit': '信用额度',
      'currency': '币种',
      'is_archived': '已归档',
      'parent_key': '父分类',
      'icon_name': '图标',
      'is_income': '收入类',
      'is_system': '系统类',
      'is_hidden': '已隐藏',
      'group_key': '标签组',
      'color_hex': '颜色',
      'period': '周期',
      'start_date': '开始日期',
      'end_date': '结束日期',
      'category_keys': '关联分类',
      'is_active': '启用',
      'carry_over': '结转',
      'sub_type': '子类型',
    };
    return names[field] ?? field;
  }

  String _formatTime(DateTime time) {
    return DateFormat('MM-dd HH:mm').format(time);
  }
}

class _DiffEntry {
  final String field;
  final String localValue;
  final String remoteValue;

  const _DiffEntry({
    required this.field,
    required this.localValue,
    required this.remoteValue,
  });
}
