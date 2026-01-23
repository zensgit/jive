import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';

class TagConversionLogScreen extends StatefulWidget {
  final Isar? isar;

  const TagConversionLogScreen({super.key, this.isar});

  @override
  State<TagConversionLogScreen> createState() => _TagConversionLogScreenState();
}

class _TagConversionLogScreenState extends State<TagConversionLogScreen> {
  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  List<JiveTagConversionLog> _logs = [];
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  final DateFormat _timeFormat = DateFormat('MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final existing = widget.isar ?? Isar.getInstance();
      if (existing != null) {
        _isar = existing;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _isar = await Isar.open(
          [
            JiveTransactionSchema,
            JiveCategorySchema,
            JiveCategoryOverrideSchema,
            JiveAccountSchema,
            JiveAutoDraftSchema,
            JiveTagSchema,
            JiveTagGroupSchema,
            JiveTagConversionLogSchema,
          ],
          directory: dir.path,
        );
      }
      await _loadLogs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLogs() async {
    final list = await _isar.collection<JiveTagConversionLog>()
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    if (!mounted) return;
    setState(() {
      _logs = list;
      _isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _selectionMode ? '已选 ${_selectedIds.length}' : '转换记录',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: _buildActions(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _logs.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildLogCard(_logs[index]),
                    ),
    );
  }

  List<Widget> _buildActions() {
    if (_selectionMode) {
      final allSelected = _selectedIds.length == _logs.length && _logs.isNotEmpty;
      return [
        IconButton(
          tooltip: allSelected ? '取消全选' : '全选',
          onPressed: _toggleSelectAll,
          icon: Icon(allSelected ? Icons.remove_done : Icons.done_all),
        ),
        IconButton(
          tooltip: '删除',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
          icon: const Icon(Icons.delete_outline),
        ),
      ];
    }
    return [
      PopupMenuButton<_LogMenuAction>(
        onSelected: (value) async {
          if (value == _LogMenuAction.select) {
            setState(() => _selectionMode = true);
          } else if (value == _LogMenuAction.clearAll) {
            await _clearAll();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _LogMenuAction.select,
            child: Text('批量删除'),
          ),
          PopupMenuItem(
            value: _LogMenuAction.clearAll,
            child: Text('清空全部'),
          ),
        ],
      ),
    ];
  }

  Widget _buildEmpty() {
    return Center(
      child: Text('暂无转换记录', style: TextStyle(color: Colors.grey.shade500)),
    );
  }

  Widget _buildLogCard(JiveTagConversionLog log) {
    final typeLabel = log.categoryIsIncome ? '收入' : '支出';
    final policyLabel = _policyLabel(log.migratePolicy);
    final skipInfo = _buildSkipSummary(log);
    final selected = _selectedIds.contains(log.id);
    return InkWell(
      onLongPress: () => _toggleSelection(log.id),
      onTap: _selectionMode ? () => _toggleSelection(log.id) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${log.tagName} → ${log.categoryName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _timeFormat.format(log.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (_selectionMode) ...[
                  const SizedBox(width: 8),
                  Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleSelection(log.id),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$typeLabel · $policyLabel · 更新 ${log.updatedTransactionCount}/${log.taggedTransactionCount}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            if (skipInfo != null) ...[
              const SizedBox(height: 4),
              Text(skipInfo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
            if (log.parentCategoryName != null && log.parentCategoryName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('父级：${log.parentCategoryName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirmDialog('确认清空全部转换记录吗？');
    if (confirmed != true) return;
    await _isar.writeTxn(() async {
      await _isar.collection<JiveTagConversionLog>().where().deleteAll();
    });
    if (!mounted) return;
    setState(() {
      _logs = [];
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final confirmed = await _confirmDialog('确认删除已选 $count 条记录吗？');
    if (confirmed != true) return;
    await _isar.writeTxn(() async {
      await _isar.collection<JiveTagConversionLog>().deleteAll(_selectedIds.toList());
    });
    await _loadLogs();
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<bool?> _confirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('确定')),
        ],
      ),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      _selectionMode = true;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _logs.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(_logs.map((log) => log.id));
      }
    });
  }

  String _policyLabel(String raw) {
    switch (raw) {
      case 'onlyNull':
        return '仅补全空分类';
      case 'overwrite':
        return '覆盖同类型';
      case 'none':
        return '不迁移';
      default:
        return raw;
    }
  }

  String? _buildSkipSummary(JiveTagConversionLog log) {
    final parts = <String>[];
    if (log.skippedByPolicyCount > 0) {
      parts.add('不迁移 ${log.skippedByPolicyCount}');
    }
    if (log.skippedExistingCategoryCount > 0) {
      parts.add('已有分类 ${log.skippedExistingCategoryCount}');
    }
    if (log.skippedTypeMismatchCount > 0) {
      parts.add('类型不一致 ${log.skippedTypeMismatchCount}');
    }
    if (log.skippedUnknownCategoryCount > 0) {
      parts.add('分类缺失 ${log.skippedUnknownCategoryCount}');
    }
    if (parts.isEmpty) return null;
    return '跳过：${parts.join(' / ')}';
  }
}

enum _LogMenuAction { select, clearAll }
