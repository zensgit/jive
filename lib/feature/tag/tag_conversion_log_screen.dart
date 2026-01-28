import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_rule_model.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  String _typeFilter = 'all';
  String _policyFilter = 'all';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
            JiveTagRuleSchema,
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
    final visibleLogs = _filteredLogs;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _selectionMode ? '已选 ${_selectedIds.length}' : '转换记录',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: _buildActions(visibleLogs),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _logs.isEmpty
                  ? _buildEmpty()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: _buildFilterBar(visibleLogs.length),
                        ),
                        Expanded(
                          child: visibleLogs.isEmpty
                              ? Center(
                                  child: Text(
                                    '没有匹配的转换记录',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: visibleLogs.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildLogCard(visibleLogs[index]),
                                ),
                        ),
                      ],
                    ),
    );
  }

  List<Widget> _buildActions(List<JiveTagConversionLog> visibleLogs) {
    if (_selectionMode) {
      final allSelected =
          _selectedIds.length == visibleLogs.length && visibleLogs.isNotEmpty;
      return [
        IconButton(
          tooltip: allSelected ? '取消全选' : '全选',
          onPressed: () => _toggleSelectAll(visibleLogs),
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
          } else if (value == _LogMenuAction.export) {
            await _exportLogs(visibleLogs);
          } else if (value == _LogMenuAction.clearAll) {
            await _clearAll();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _LogMenuAction.export,
            child: Text('导出 CSV'),
          ),
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

  List<JiveTagConversionLog> get _filteredLogs {
    final query = _query.toLowerCase();
    return _logs.where((log) {
      if (_typeFilter == 'income' && !log.categoryIsIncome) return false;
      if (_typeFilter == 'expense' && log.categoryIsIncome) return false;
      if (_policyFilter != 'all' && log.migratePolicy != _policyFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack = [
          log.tagName,
          log.categoryName,
          log.parentCategoryName ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildFilterBar(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索标签/分类',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _selectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('全部'),
              selected: _typeFilter == 'all',
              onSelected: (_) => _setTypeFilter('all'),
            ),
            ChoiceChip(
              label: const Text('支出'),
              selected: _typeFilter == 'expense',
              onSelected: (_) => _setTypeFilter('expense'),
            ),
            ChoiceChip(
              label: const Text('收入'),
              selected: _typeFilter == 'income',
              onSelected: (_) => _setTypeFilter('income'),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('全部策略'),
              selected: _policyFilter == 'all',
              onSelected: (_) => _setPolicyFilter('all'),
            ),
            ChoiceChip(
              label: const Text('仅补全空分类'),
              selected: _policyFilter == 'onlyNull',
              onSelected: (_) => _setPolicyFilter('onlyNull'),
            ),
            ChoiceChip(
              label: const Text('覆盖同类型'),
              selected: _policyFilter == 'overwrite',
              onSelected: (_) => _setPolicyFilter('overwrite'),
            ),
            ChoiceChip(
              label: const Text('不迁移'),
              selected: _policyFilter == 'none',
              onSelected: (_) => _setPolicyFilter('none'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '共 $total 条',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
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

  void _toggleSelectAll(List<JiveTagConversionLog> visibleLogs) {
    setState(() {
      if (_selectedIds.length == visibleLogs.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(visibleLogs.map((log) => log.id));
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _selectionMode = false;
        _selectedIds.clear();
      });
    });
  }

  void _setTypeFilter(String value) {
    setState(() {
      _typeFilter = value;
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _setPolicyFilter(String value) {
    setState(() {
      _policyFilter = value;
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _exportLogs(List<JiveTagConversionLog> logs) async {
    if (logs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可导出的记录')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tag_conversion_logs_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final buffer = StringBuffer();
    buffer.writeln(
      '时间,标签,分类,父级分类,类型,策略,更新数,关联数,跳过(策略),跳过(已有分类),跳过(类型不一致),跳过(分类缺失),保留标签',
    );
    for (final log in logs) {
      final typeLabel = log.categoryIsIncome ? '收入' : '支出';
      final policyLabel = _policyLabel(log.migratePolicy);
      buffer.writeln([
        _timeFormat.format(log.createdAt),
        _csvSafe(log.tagName),
        _csvSafe(log.categoryName),
        _csvSafe(log.parentCategoryName ?? ''),
        typeLabel,
        policyLabel,
        log.updatedTransactionCount,
        log.taggedTransactionCount,
        log.skippedByPolicyCount,
        log.skippedExistingCategoryCount,
        log.skippedTypeMismatchCount,
        log.skippedUnknownCategoryCount,
        log.keepTagActive ? '是' : '否',
      ].join(','));
    }
    await file.writeAsString(buffer.toString(), flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '转换记录导出（CSV）',
    );
  }

  String _csvSafe(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
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

enum _LogMenuAction { select, export, clearAll }
