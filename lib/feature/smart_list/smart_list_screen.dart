import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/smart_list_model.dart';
import '../../core/model/transaction_list_filter_state.dart';
import '../../core/service/database_service.dart';
import '../../core/service/smart_list_service.dart';
import '../category/category_transactions_screen.dart';

/// 保存视图列表页 — 展示所有 SmartList，点击可打开已筛选的交易列表。
class SmartListScreen extends StatefulWidget {
  /// 如果提供，则在页面显示「保存当前筛选」入口。
  final TransactionListFilterState? currentFilter;
  final String? currentKeyword;

  const SmartListScreen({super.key, this.currentFilter, this.currentKeyword});

  @override
  State<SmartListScreen> createState() => _SmartListScreenState();
}

class _SmartListScreenState extends State<SmartListScreen> {
  late Isar _isar;
  late SmartListService _service;
  List<JiveSmartList> _items = [];
  int? _defaultSmartListId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = SmartListService(_isar);
    await _reload();
  }

  Future<void> _reload() async {
    final items = await _service.getAll();
    final defaultId = await _service.getDefaultId();
    if (mounted) {
      setState(() {
        _items = items;
        _defaultSmartListId = defaultId;
        _isLoading = false;
      });
    }
  }

  // ── actions ──

  String? get _normalizedCurrentKeyword {
    final keyword = widget.currentKeyword?.trim() ?? '';
    return keyword.isEmpty ? null : keyword;
  }

  bool get _canSaveCurrentView =>
      (widget.currentFilter?.hasAnyFilter ?? false) ||
      _normalizedCurrentKeyword != null;

  Future<void> _createFromCurrentFilter() async {
    final name = await _promptName();
    if (name == null || name.isEmpty) return;
    final sl = _service.fromFilterState(
      name: name,
      filterState: widget.currentFilter ?? const TransactionListFilterState(),
      keyword: _normalizedCurrentKeyword,
    );
    await _service.create(
      name: sl.name,
      categoryKeys: sl.categoryKeys,
      tagKeys: sl.tagKeys,
      accountId: sl.accountId,
      bookId: sl.bookId,
      transactionType: sl.transactionType,
      minAmount: sl.minAmount,
      maxAmount: sl.maxAmount,
      dateRangeType: sl.dateRangeType,
      customStartDate: sl.customStartDate,
      customEndDate: sl.customEndDate,
      keyword: sl.keyword,
    );
    await _reload();
  }

  Future<void> _openSmartList(JiveSmartList sl) async {
    final filter = _service.buildFilterState(sl);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryTransactionsScreen(
          title: sl.name,
          initialFilterState: filter,
          initialSearchQuery: sl.keyword,
          persistFilterState: false,
        ),
      ),
    );
  }

  Future<void> _togglePin(JiveSmartList sl) async {
    sl.isPinned = !sl.isPinned;
    await _service.update(sl);
    await _reload();
  }

  Future<void> _setDefault(JiveSmartList sl) async {
    await _service.setDefaultView(sl);
    await _reload();
  }

  Future<void> _clearDefault() async {
    await _service.clearDefaultView();
    await _reload();
  }

  Future<void> _deleteItem(JiveSmartList sl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除视图'),
        content: Text('确认删除「${sl.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.delete(sl.id);
      await _reload();
    }
  }

  Future<String?> _promptName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('命名视图'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：本月餐饮'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的视图')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _buildEmpty(theme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => _buildItem(_items[i], theme),
            ),
      floatingActionButton: _canSaveCurrentView
          ? FloatingActionButton.extended(
              onPressed: _createFromCurrentFilter,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('保存当前筛选'),
            )
          : null,
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmarks_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('还没有保存的视图', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            '在筛选交易后保存条件，下次可快速访问',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(JiveSmartList sl, ThemeData theme) {
    final summary = _service.describeSummary(sl);
    final isDefault = sl.id == _defaultSmartListId;

    return ListTile(
      leading: Icon(
        isDefault
            ? Icons.home_outlined
            : sl.isPinned
            ? Icons.push_pin
            : Icons.bookmark_outline,
        color: sl.colorHex != null
            ? Color(
                int.parse('FF${sl.colorHex!.replaceFirst('#', '')}', radix: 16),
              )
            : theme.colorScheme.primary,
      ),
      title: Row(
        children: [
          Expanded(child: Text(sl.name)),
          if (isDefault)
            Chip(
              label: const Text('默认'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide.none,
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
        ],
      ),
      subtitle: Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _openSmartList(sl),
      onLongPress: () => _showContextMenu(sl),
    );
  }

  void _showContextMenu(JiveSmartList sl) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                sl.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(sl.isPinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(sl);
              },
            ),
            ListTile(
              leading: Icon(
                sl.id == _defaultSmartListId
                    ? Icons.home_work_outlined
                    : Icons.home_outlined,
              ),
              title: Text(sl.id == _defaultSmartListId ? '取消默认视图' : '设为默认视图'),
              onTap: () {
                Navigator.pop(ctx);
                sl.id == _defaultSmartListId
                    ? _clearDefault()
                    : _setDefault(sl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem(sl);
              },
            ),
          ],
        ),
      ),
    );
  }
}
