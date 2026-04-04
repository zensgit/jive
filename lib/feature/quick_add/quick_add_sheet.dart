import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/transaction_service.dart';

/// Compact bottom-sheet for quick transaction entry.
///
/// Shows an amount input, type chips, the 6 most-recently-used categories,
/// an optional note field, and a save button.
class QuickAddSheet extends StatefulWidget {
  /// If provided the sheet will use this book for the new transaction.
  final int? bookId;

  const QuickAddSheet({super.key, this.bookId});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedType = 'expense'; // expense | income | transfer
  List<JiveCategory> _recentCategories = [];
  JiveCategory? _selectedCategory;
  late Isar _isar;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _isar = await DatabaseService.getInstance();
    await _loadRecentCategories();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _loadRecentCategories() async {
    // Fetch last 50 transactions and pick distinct parent category keys.
    final txs = await _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .limit(50)
        .findAll();

    final seen = <String>{};
    final keys = <String>[];
    for (final tx in txs) {
      final key = tx.categoryKey;
      if (key != null && key.isNotEmpty && seen.add(key)) {
        keys.add(key);
        if (keys.length >= 6) break;
      }
    }

    if (keys.isEmpty) {
      // Fallback: first 6 non-hidden expense categories
      final cats = await _isar
          .collection<JiveCategory>()
          .where()
          .filter()
          .parentKeyIsNull()
          .and()
          .isHiddenEqualTo(false)
          .and()
          .isIncomeEqualTo(false)
          .sortByOrder()
          .limit(6)
          .findAll();
      _recentCategories = cats;
    } else {
      final allCats =
          await _isar.collection<JiveCategory>().where().findAll();
      final catMap = {for (final c in allCats) c.key: c};
      _recentCategories =
          keys.map((k) => catMap[k]).whereType<JiveCategory>().toList();
    }

    if (_recentCategories.isNotEmpty) {
      _selectedCategory = _recentCategories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showToast('请输入有效金额');
      return;
    }

    if (_selectedType != 'transfer' && _selectedCategory == null) {
      _showToast('请选择分类');
      return;
    }

    final tx = JiveTransaction()
      ..amount = amount
      ..source = 'QuickAdd'
      ..type = _selectedType
      ..timestamp = DateTime.now()
      ..category = _selectedCategory?.name
      ..categoryKey = _selectedCategory?.key
      ..note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim()
      ..bookId = widget.bookId;

    TransactionService.touchSyncMetadata(tx);

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
      _showToast('已保存');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  '快捷记账',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    hintText: '金额',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Type chips
                _buildTypeChips(),
                const SizedBox(height: 14),

                // Category quick picks
                if (_dbReady) _buildCategoryChips(),
                const SizedBox(height: 10),

                // Note
                TextField(
                  controller: _noteController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: '备注（可选）',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Type chips
  // ---------------------------------------------------------------------------

  Widget _buildTypeChips() {
    const types = <String, String>{
      'expense': '支出',
      'income': '收入',
      'transfer': '转账',
    };
    return Wrap(
      spacing: 8,
      children: types.entries.map((e) {
        final selected = _selectedType == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          selectedColor: const Color(0xFF4CAF50).withAlpha(51),
          onSelected: (_) => setState(() => _selectedType = e.key),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Category chips
  // ---------------------------------------------------------------------------

  Widget _buildCategoryChips() {
    if (_recentCategories.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷分类',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _recentCategories.map((cat) {
            final selected = _selectedCategory?.key == cat.key;
            final icon = CategoryService.getIcon(cat.iconName);
            return ChoiceChip(
              avatar: Icon(icon, size: 18),
              label: Text(cat.name),
              selected: selected,
              selectedColor: const Color(0xFF4CAF50).withAlpha(51),
              onSelected: (_) =>
                  setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),
      ],
    );
  }
}
