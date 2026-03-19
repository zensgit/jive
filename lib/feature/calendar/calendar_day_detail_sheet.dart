import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../transactions/transaction_detail_screen.dart';

class CalendarDayDetailSheet extends StatefulWidget {
  final DateTime day;

  const CalendarDayDetailSheet({
    super.key,
    required this.day,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DateTime day,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalendarDayDetailSheet(day: day),
    );
  }

  @override
  State<CalendarDayDetailSheet> createState() => _CalendarDayDetailSheetState();
}

class _CalendarDayDetailSheetState extends State<CalendarDayDetailSheet> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );
  final DateFormat _headerFormat = DateFormat('M月d日 EEEE', 'zh_CN');
  final DateFormat _timeFormat = DateFormat('HH:mm', 'zh_CN');

  Isar? _isar;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasDataChanges = false;

  List<JiveTransaction> _transactions = const [];
  Map<String, JiveCategory> _categoryByKey = const {};
  _DaySummary _summary = const _DaySummary();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final isar = await _ensureIsar();
      final dayStart = DateUtils.dateOnly(widget.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final txFuture = isar.jiveTransactions
          .filter()
          .timestampBetween(dayStart, dayEnd, includeUpper: false)
          .findAll();
      final categoryFuture = isar.collection<JiveCategory>().where().findAll();

      final transactions = await txFuture;
      final categories = await categoryFuture;
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      var income = 0.0;
      var expense = 0.0;
      for (final tx in transactions) {
        final type = tx.type ?? 'expense';
        final amount = tx.amount.abs();
        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _categoryByKey = {for (final category in categories) category.key: category};
        _summary = _DaySummary(income: income, expense: expense);
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('CalendarDayDetailSheet load error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载交易失败：$e';
      });
    }
  }

  Future<void> _openTransaction(JiveTransaction transaction) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transactionId: transaction.id),
      ),
    );
    if (changed == true) {
      _hasDataChanges = true;
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasDataChanges);
      },
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Material(
              color: JiveTheme.cardColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: _buildBody(scrollController),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当日账单',
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_headerFormat.format(widget.day)} · ${_transactions.length} 笔',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: '收入',
                value: _currency.format(_summary.income),
                valueColor: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryChip(
                label: '支出',
                value: _currency.format(_summary.expense),
                valueColor: colorScheme.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryChip(
                label: '结余',
                value: _currency.format(_summary.balance),
                valueColor: _summary.balance >= 0
                    ? JiveTheme.primaryGreen
                    : colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_transactions.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          const SizedBox(height: 72),
          Icon(
            Icons.event_note_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '这一天还没有交易记录',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionTile(transaction);
      },
    );
  }

  Widget _buildTransactionTile(JiveTransaction transaction) {
    final type = transaction.type ?? 'expense';
    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = isTransfer
        ? colorScheme.tertiary
        : (isIncome ? JiveTheme.primaryGreen : colorScheme.error);
    final amountPrefix = isTransfer ? '' : (isIncome ? '+' : '-');
    final iconColor = _resolveCategoryColor(transaction) ?? colorScheme.primary;
    final note = (transaction.note ?? '').trim();
    final categoryLabel = _resolveCategoryLabel(transaction);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openTransaction(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isTransfer
                    ? Icon(
                        Icons.swap_horiz,
                        color: colorScheme.tertiary,
                        size: 22,
                      )
                    : CategoryService.buildIcon(
                        _resolveCategoryModel(transaction)?.iconName ?? 'category',
                        size: 22,
                        color: iconColor,
                        isSystemCategory: _resolveCategoryModel(transaction)?.isSystem,
                        forceTinted:
                            _resolveCategoryModel(transaction)?.iconForceTinted ?? false,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note.isEmpty ? '无备注' : note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${_currency.format(transaction.amount.abs())}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeFormat.format(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  JiveCategory? _resolveCategoryModel(JiveTransaction transaction) {
    final key = transaction.subCategoryKey ?? transaction.categoryKey;
    if (key == null || key.isEmpty) return null;
    return _categoryByKey[key];
  }

  Color? _resolveCategoryColor(JiveTransaction transaction) {
    final category = _resolveCategoryModel(transaction);
    return CategoryService.parseColorHex(category?.colorHex);
  }

  String _resolveCategoryLabel(JiveTransaction transaction) {
    if ((transaction.type ?? 'expense') == 'transfer') {
      return '转账';
    }

    final parent = _displayCategoryName(transaction.categoryKey, transaction.category);
    final sub = _displayCategoryName(
      transaction.subCategoryKey,
      transaction.subCategory,
    );
    final hasSubCategory =
        (transaction.subCategoryKey?.trim().isNotEmpty ?? false) ||
        ((transaction.subCategory ?? '').trim().isNotEmpty);

    if (hasSubCategory && sub != '未分类' && parent != '未分类') {
      return '$parent · $sub';
    }
    if (sub != '未分类') return sub;
    return parent;
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    final text = fallback?.trim() ?? '';
    if (text.isNotEmpty) return text;
    return '未分类';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySummary {
  final double income;
  final double expense;

  const _DaySummary({
    this.income = 0,
    this.expense = 0,
  });

  double get balance => income - expense;
}
