import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/activity_log_model.dart';
import '../../core/service/activity_log_service.dart';

/// Screen that displays a chronological audit log of data changes.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  late final ActivityLogService _service;
  List<JiveActivityLog> _logs = [];
  bool _loading = true;

  String? _filterEntityType;
  DateTimeRange? _filterDateRange;

  static const _entityTypes = [
    'transaction',
    'account',
    'budget',
    'category',
    'goal',
    'ledger',
  ];

  static const _entityTypeLabels = {
    'transaction': '交易',
    'account': '账户',
    'budget': '预算',
    'category': '分类',
    'goal': '目标',
    'ledger': '账本',
  };

  @override
  void initState() {
    super.initState();
    final isar = Isar.getInstance()!;
    _service = ActivityLogService(isar);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await _service.getRecentLogs(limit: 200);
      if (mounted) {
        setState(() {
          _logs = _applyFilters(logs);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<JiveActivityLog> _applyFilters(List<JiveActivityLog> logs) {
    var result = logs;
    if (_filterEntityType != null) {
      result =
          result.where((l) => l.entityType == _filterEntityType).toList();
    }
    if (_filterDateRange != null) {
      final start = _filterDateRange!.start;
      final end = _filterDateRange!.end
          .add(const Duration(days: 1)); // inclusive end
      result = result
          .where((l) =>
              l.createdAt.isAfter(start) && l.createdAt.isBefore(end))
          .toList();
    }
    return result;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterDateRange,
    );
    if (range != null) {
      setState(() => _filterDateRange = range);
      await _loadLogs();
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.remove_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'create':
        return '创建';
      case 'update':
        return '修改';
      case 'delete':
        return '删除';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: '按日期筛选',
            onPressed: _pickDateRange,
          ),
          if (_filterEntityType != null || _filterDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '清除筛选',
              onPressed: () {
                setState(() {
                  _filterEntityType = null;
                  _filterDateRange = null;
                });
                _loadLogs();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('暂无操作日志'))
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) =>
                              _buildLogTile(_logs[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterEntityType,
              decoration: const InputDecoration(
                labelText: '类型筛选',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ..._entityTypes.map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_entityTypeLabels[t] ?? t),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _filterEntityType = value);
                _loadLogs();
              },
            ),
          ),
          if (_filterDateRange != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(
                '${DateFormat('MM/dd').format(_filterDateRange!.start)}'
                ' - '
                '${DateFormat('MM/dd').format(_filterDateRange!.end)}',
                style: const TextStyle(fontSize: 12),
              ),
              onDeleted: () {
                setState(() => _filterDateRange = null);
                _loadLogs();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogTile(JiveActivityLog log) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt);
    final typeLabel = _entityTypeLabels[log.entityType] ?? log.entityType;

    return ExpansionTile(
      leading: Icon(
        _actionIcon(log.action),
        color: _actionColor(log.action),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _actionColor(log.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 12,
                color: _actionColor(log.action),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.entityName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${log.userName} ${_actionLabel(log.action)} · $dateStr',
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        if (log.details != null && log.details!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                log.details!,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ),
        if (log.bookKey != null && log.bookKey!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '账本: ${log.bookKey}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
