import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/batch_operation_service.dart';
import '../../core/service/database_service.dart';
import '../../core/sync/sync_delete_marker_service.dart';

/// Multi-select batch operations on transactions.
class BatchOperationsScreen extends StatefulWidget {
  final List<JiveTransaction> transactions;
  final VoidCallback onComplete;

  const BatchOperationsScreen({
    super.key,
    required this.transactions,
    required this.onComplete,
  });

  @override
  State<BatchOperationsScreen> createState() => _BatchOperationsScreenState();
}

class _BatchOperationsScreenState extends State<BatchOperationsScreen> {
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    // Select all by default
    _selected.addAll(widget.transactions.map((t) => t.id));
  }

  List<JiveTransaction> get _selectedTxs =>
      widget.transactions.where((t) => _selected.contains(t.id)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('批量操作 (${_selected.length}/${widget.transactions.length})'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_selected.length == widget.transactions.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(widget.transactions.map((t) => t.id));
                }
              });
            },
            child: Text(
              _selected.length == widget.transactions.length ? '取消全选' : '全选',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Action bar
          _buildActionBar(),
          _buildEnhancedActionBar(),
          // Transaction list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.transactions.length,
              itemBuilder: (_, i) =>
                  _buildTransactionTile(widget.transactions[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.category,
            label: '改分类',
            onTap: _selected.isEmpty ? null : _batchRecategorize,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.label,
            label: '改类型',
            onTap: _selected.isEmpty ? null : _batchChangeType,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.delete_outline,
            label: '删除',
            color: Colors.red,
            onTap: _selected.isEmpty ? null : _batchDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.store,
            label: '改商户',
            onTap: _selected.isEmpty ? null : _batchUpdateMerchant,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.label_outline,
            label: '改标签',
            onTap: _selected.isEmpty ? null : _batchUpdateTags,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.account_balance_wallet,
            label: '改账户',
            onTap: _selected.isEmpty ? null : _batchUpdateAccount,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.clear_all,
            label: '清除',
            onTap: _selected.isEmpty ? null : _batchClearField,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(JiveTransaction tx) {
    final isSelected = _selected.contains(tx.id);
    final typeColor = tx.type == 'income'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? JiveTheme.primaryGreen.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? JiveTheme.primaryGreen.withAlpha(80)
              : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        activeColor: JiveTheme.primaryGreen,
        onChanged: (_) {
          setState(() {
            if (isSelected) {
              _selected.remove(tx.id);
            } else {
              _selected.add(tx.id);
            }
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                tx.category ?? tx.categoryKey ?? '未分类',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${tx.timestamp.toString().substring(0, 10)} · ${tx.note ?? tx.source}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _batchUpdateMerchant() async {
    final controller = TextEditingController();
    if (!mounted) return;
    final merchant = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置商户名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入商户名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (merchant == null || merchant.isEmpty || !mounted) return;

    final isar = await DatabaseService.getInstance();
    final svc = BatchOperationService(isar);
    final count = await svc.batchUpdateMerchant(_selected.toList(), merchant);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已更新 $count 笔交易的商户')),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchUpdateTags() async {
    final isar = await DatabaseService.getInstance();
    final allTags = await isar.collection<JiveTag>().where().findAll();
    if (allTags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无标签，请先创建标签')),
        );
      }
      return;
    }
    if (!mounted) return;
    final selectedKeys = <String>{};
    final picked = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('选择标签'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isOn = selectedKeys.contains(tag.key);
                return FilterChip(
                  label: Text(tag.name),
                  selected: isOn,
                  onSelected: (v) {
                    setDlgState(() {
                      if (v) {
                        selectedKeys.add(tag.key);
                      } else {
                        selectedKeys.remove(tag.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
          ],
        ),
      ),
    );
    if (picked != true || !mounted) return;

    final svc = BatchOperationService(isar);
    final count = await svc.batchUpdateTags(_selected.toList(), selectedKeys.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已更新 $count 笔交易的标签')),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchUpdateAccount() async {
    final isar = await DatabaseService.getInstance();
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    if (!mounted) return;
    final selected = await showDialog<JiveAccount>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择账户'),
        children: accounts
            .map((a) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, a),
                  child: Text(a.name),
                ))
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;

    final svc = BatchOperationService(isar);
    final count = await svc.batchUpdateAccount(_selected.toList(), selected.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已将 $count 笔交易移至"${selected.name}"')),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchClearField() async {
    if (!mounted) return;
    final field = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('清除字段'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'note'), child: const Text('备注')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'tags'), child: const Text('标签')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'merchant'), child: const Text('商户')),
        ],
      ),
    );
    if (field == null || !mounted) return;

    final isar = await DatabaseService.getInstance();
    final svc = BatchOperationService(isar);
    final count = await svc.batchClearField(_selected.toList(), field);
    final label = field == 'note' ? '备注' : field == 'tags' ? '标签' : '商户';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清除 $count 笔交易的$label')),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchRecategorize() async {
    final isar = await DatabaseService.getInstance();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final parentCats = categories
        .where((c) => c.parentKey == null || c.parentKey!.isEmpty)
        .toList();

    if (!mounted) return;
    final selected = await showDialog<JiveCategory>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择新分类'),
        children: parentCats
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c),
                child: Text(c.name),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || !mounted) return;

    // Processing batch operation
    await isar.writeTxn(() async {
      for (final tx in _selectedTxs) {
        tx.categoryKey = selected.key;
        tx.category = selected.name;
        tx.updatedAt = DateTime.now();
      }
      await isar.jiveTransactions.putAll(_selectedTxs);
    });
    // Batch operation complete

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将 ${_selectedTxs.length} 笔改为"${selected.name}"'),
        ),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchChangeType() async {
    if (!mounted) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择类型'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'expense'),
            child: const Text('支出'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'income'),
            child: const Text('收入'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'transfer'),
            child: const Text('转账'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    final isar = await DatabaseService.getInstance();
    // Processing batch operation
    await isar.writeTxn(() async {
      for (final tx in _selectedTxs) {
        tx.type = selected;
        tx.updatedAt = DateTime.now();
      }
      await isar.jiveTransactions.putAll(_selectedTxs);
    });
    // Batch operation complete

    if (mounted) {
      final label = selected == 'income'
          ? '收入'
          : selected == 'transfer'
          ? '转账'
          : '支出';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已将 ${_selectedTxs.length} 笔改为"$label"')),
      );
      widget.onComplete();
    }
  }

  Future<void> _batchDelete() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 $count 笔交易吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final isar = await DatabaseService.getInstance();
    final transactions = await isar.jiveTransactions.getAll(_selected.toList());
    await SyncDeleteMarkerService(
      isar,
    ).markTransactionsDeleted(transactions.whereType<JiveTransaction>());
    // Processing batch operation
    await isar.writeTxn(() async {
      await isar.jiveTransactions.deleteAll(_selected.toList());
    });
    // Batch operation complete

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除 $count 笔交易')));
      widget.onComplete();
      Navigator.pop(context);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? JiveTheme.primaryGreen;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: onTap != null ? c : Colors.grey),
        label: Text(
          label,
          style: TextStyle(color: onTap != null ? c : Colors.grey),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onTap != null ? c.withAlpha(100) : Colors.grey.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
