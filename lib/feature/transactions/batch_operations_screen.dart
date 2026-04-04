import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';

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
            child: Text(_selected.length == widget.transactions.length ? '取消全选' : '全选'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Action bar
          _buildActionBar(),
          // Transaction list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.transactions.length,
              itemBuilder: (_, i) => _buildTransactionTile(widget.transactions[i]),
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

  Widget _buildTransactionTile(JiveTransaction tx) {
    final isSelected = _selected.contains(tx.id);
    final typeColor = tx.type == 'income' ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? JiveTheme.primaryGreen.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? JiveTheme.primaryGreen.withAlpha(80) : Colors.grey.shade200,
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${tx.type == 'income' ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: typeColor),
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

  Future<void> _batchRecategorize() async {
    final isar = await DatabaseService.getInstance();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final parentCats = categories.where((c) => c.parentKey == null || c.parentKey!.isEmpty).toList();

    if (!mounted) return;
    final selected = await showDialog<JiveCategory>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择新分类'),
        children: parentCats.map((c) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, c),
          child: Text(c.name),
        )).toList(),
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
        SnackBar(content: Text('已将 ${_selectedTxs.length} 笔改为"${selected.name}"')),
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
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'expense'), child: const Text('支出')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'income'), child: const Text('收入')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'transfer'), child: const Text('转账')),
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
      final label = selected == 'income' ? '收入' : selected == 'transfer' ? '转账' : '支出';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final isar = await DatabaseService.getInstance();
    // Processing batch operation
    await isar.writeTxn(() async {
      await isar.jiveTransactions.deleteAll(_selected.toList());
    });
    // Batch operation complete

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 笔交易')),
      );
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
        label: Text(label, style: TextStyle(color: onTap != null ? c : Colors.grey)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: onTap != null ? c.withAlpha(100) : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
