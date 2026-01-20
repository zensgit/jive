import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/category_service.dart';
import '../../core/design_system/theme.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String title;
  final String? filterCategoryKey;
  final String? filterSubCategoryKey;

  const CategoryTransactionsScreen({
    super.key,
    required this.title,
    this.filterCategoryKey,
    this.filterSubCategoryKey,
  });

  @override
  State<CategoryTransactionsScreen> createState() => _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState extends State<CategoryTransactionsScreen> {
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
      final existing = Isar.getInstance();
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

      final String? subKey =
          (widget.filterSubCategoryKey != null && widget.filterSubCategoryKey!.isNotEmpty)
              ? widget.filterSubCategoryKey
              : null;
      final String? categoryKey =
          (widget.filterCategoryKey != null && widget.filterCategoryKey!.isNotEmpty)
              ? widget.filterCategoryKey
              : null;

      late final List<JiveTransaction> txs;
      if (subKey != null) {
        txs = await _isar.jiveTransactions
            .filter()
            .subCategoryKeyEqualTo(subKey)
            .sortByTimestampDesc()
            .findAll();
      } else if (categoryKey != null) {
        txs = await _isar.jiveTransactions
            .filter()
            .categoryKeyEqualTo(categoryKey)
            .sortByTimestampDesc()
            .findAll();
      } else {
        txs = await _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
      }

      if (mounted) {
        setState(() {
          _categoryByKey = categoryMap;
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Text('暂无账单', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildTransactionTile(_transactions[index]),
    );
  }

  Widget _buildTransactionTile(JiveTransaction tx) {
    final isIncome = (tx.type ?? 'expense') == 'income';
    final amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;
    final amountPrefix = isIncome ? '+' : '-';
    final categoryKey = tx.subCategoryKey ?? tx.categoryKey;
    final category = categoryKey != null ? _categoryByKey[categoryKey] : null;
    final icon = category?.iconName ?? 'category';
    final title = (tx.subCategory ?? '').isNotEmpty ? tx.subCategory! : (tx.category ?? '未分类');
    final parent = (tx.subCategory ?? '').isNotEmpty ? (tx.category ?? '') : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: CategoryService.buildIcon(
                icon,
                size: 20,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  [if (parent.isNotEmpty) parent, _dateFormat.format(tx.timestamp)].join(' · '),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
          ),
        ],
      ),
    );
  }
}
