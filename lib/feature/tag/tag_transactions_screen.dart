import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/design_system/theme.dart';

class TagTransactionsScreen extends StatefulWidget {
  final String tagKey;
  final String title;
  final Isar? isar;

  const TagTransactionsScreen({
    super.key,
    required this.tagKey,
    required this.title,
    this.isar,
  });

  @override
  State<TagTransactionsScreen> createState() => _TagTransactionsScreenState();
}

class _TagTransactionsScreenState extends State<TagTransactionsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  final DateFormat _dateFormat = DateFormat('MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
          ],
          directory: dir.path,
        );
      }

      final categories = await _isar.collection<JiveCategory>().where().findAll();
      final categoryMap = {for (final c in categories) c.key: c};
      final allTxs = await _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
      final txs = allTxs.where((tx) => tx.tagKeys.contains(widget.tagKey)).toList();
      if (!mounted) return;
      setState(() {
        _categoryByKey = categoryMap;
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _transactions.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) => _buildItem(_transactions[index]),
                    ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('暂无交易', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildItem(JiveTransaction tx) {
    final type = tx.type ?? 'expense';
    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';
    final amountPrefix = isTransfer ? '' : (isIncome ? '+ ' : '- ');
    final amountColor = isTransfer ? Colors.blueGrey : (isIncome ? Colors.green : Colors.redAccent);
    final parentName = _displayCategoryName(tx.categoryKey, tx.category);
    final subName = _displayCategoryName(tx.subCategoryKey, tx.subCategory);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
      ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: JiveTheme.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$subName • ${_dateFormat.format(tx.timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '$amountPrefix¥${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
          ),
        ],
      ),
    );
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '未分类';
  }
}
