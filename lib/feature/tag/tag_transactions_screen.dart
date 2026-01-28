import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/ui_pref_service.dart';
import '../transactions/transaction_detail_screen.dart';

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
  final DateFormat _dayFormat = DateFormat('MM.dd');
  final NumberFormat _currency = NumberFormat.currency(symbol: '¥');
  bool _groupByDate = false;
  bool _showSmartTagBadge = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadGroupingPreference();
    _load();
    DataReloadBus.notifier.addListener(_handleReload);
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
            JiveTagRuleSchema,
            JiveTagConversionLogSchema,
          ],
          directory: dir.path,
        );
      }

      final showBadge = await UiPrefService.getShowSmartTagBadge();
      final categories = await _isar.collection<JiveCategory>().where().findAll();
      final categoryMap = {for (final c in categories) c.key: c};
      final allTxs = await _isar.jiveTransactions.where().sortByTimestampDesc().findAll();
      final txs = allTxs.where((tx) => tx.tagKeys.contains(widget.tagKey)).toList();
      if (!mounted) return;
      setState(() {
        _categoryByKey = categoryMap;
        _transactions = txs;
        _showSmartTagBadge = showBadge;
        _isLoading = false;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleReload() {
    if (!_ready || _isLoading) return;
    _load();
  }

  @override
  void dispose() {
    DataReloadBus.notifier.removeListener(_handleReload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildListItems();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openGroupingSheet,
            icon: const Icon(Icons.sort),
            tooltip: '排列方式',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _transactions.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is _TagDayHeader) {
                          return _buildDayHeader(item);
                        }
                        final entryItem = item as _TagEntryItem;
                        return _buildItem(entryItem.transaction);
                      },
                    ),
    );
  }

  Future<void> _openGroupingSheet() async {
    var groupByDate = _groupByDate;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '排列方式',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '模式',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('账单模式'),
                          selected: groupByDate,
                          selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
                          onSelected: (_) => setModalState(() => groupByDate = true),
                        ),
                        ChoiceChip(
                          label: const Text('列表模式'),
                          selected: !groupByDate,
                          selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
                          onSelected: (_) => setModalState(() => groupByDate = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _groupByDate = groupByDate);
                          _saveGroupingPreference(groupByDate);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JiveTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('应用'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadGroupingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_groupingPreferenceKey());
    if (stored == null || !mounted) return;
    setState(() => _groupByDate = stored);
  }

  Future<void> _saveGroupingPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_groupingPreferenceKey(), value);
  }

  String _groupingPreferenceKey() {
    return 'transactions_grouping_v1_tag_${widget.tagKey}';
  }

  List<_TagListItem> _buildListItems() {
    if (!_groupByDate) {
      return _transactions.map(_TagEntryItem.new).toList();
    }
    final grouped = <DateTime, List<JiveTransaction>>{};
    for (final tx in _transactions) {
      final day = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      grouped.putIfAbsent(day, () => []).add(tx);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final items = <_TagListItem>[];
    for (final day in days) {
      final dayEntries = grouped[day] ?? const [];
      dayEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      var income = 0.0;
      var expense = 0.0;
      for (final tx in dayEntries) {
        final type = tx.type ?? 'expense';
        if (type == 'income') {
          income += tx.amount.abs();
        } else if (type == 'expense') {
          expense += tx.amount.abs();
        }
      }
      items.add(
        _TagDayHeader(
          date: day,
          income: income,
          expense: expense,
          count: dayEntries.length,
        ),
      );
      items.addAll(dayEntries.map(_TagEntryItem.new));
    }
    return items;
  }

  Widget _buildDayHeader(_TagDayHeader header) {
    final dateLabel = _dayFormat.format(header.date);
    final weekdayLabel = _weekdayLabel(header.date);
    final countLabel = '${header.count}笔';
    final incomeLabel = _currency.format(header.income);
    final expenseLabel = _currency.format(header.expense);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$dateLabel $weekdayLabel · $countLabel',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '收 $incomeLabel',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                ),
                TextSpan(
                  text: ' / ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                TextSpan(
                  text: '支 $expenseLabel',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
    }
    return '';
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
    final showSmartBadge = _showSmartTagBadge && tx.smartTagKeys.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final updated = await showTransactionDetailSheet(context, tx.id);
        if (updated == true) {
          await _load();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long,
                color: JiveTheme.primaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$subName • ${_dateFormat.format(tx.timestamp)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                      if (showSmartBadge) ...[
                        const SizedBox(width: 6),
                        _buildSmartTagBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$amountPrefix¥${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTagBadge() {
    final badge = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: JiveTheme.primaryGreen.withOpacity(0.4)),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 12,
        color: JiveTheme.primaryGreen,
      ),
    );
    return Tooltip(
      message: '该交易由智能标签自动打标',
      triggerMode: TooltipTriggerMode.longPress,
      child: badge,
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

abstract class _TagListItem {
  const _TagListItem();
}

class _TagDayHeader extends _TagListItem {
  final DateTime date;
  final double income;
  final double expense;
  final int count;

  const _TagDayHeader({
    required this.date,
    required this.income,
    required this.expense,
    required this.count,
  });
}

class _TagEntryItem extends _TagListItem {
  final JiveTransaction transaction;

  const _TagEntryItem(this.transaction);
}
