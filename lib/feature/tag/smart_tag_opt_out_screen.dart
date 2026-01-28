import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/tag_rule_service.dart';
import '../transactions/transaction_detail_screen.dart';

class SmartTagOptOutScreen extends StatefulWidget {
  final Isar? isar;

  const SmartTagOptOutScreen({super.key, this.isar});

  @override
  State<SmartTagOptOutScreen> createState() => _SmartTagOptOutScreenState();
}

class _SmartTagOptOutScreenState extends State<SmartTagOptOutScreen> {
  late Isar _isar;
  bool _loading = true;
  List<JiveTransaction> _transactions = [];
  String _filter = 'all';
  String _sortField = 'time';
  bool _sortAsc = false;
  Map<String, JiveCategory> _categoryByKey = {};
  Map<String, JiveTag> _tagByKey = {};
  final _dateFormat = DateFormat('MM-dd HH:mm');
  final _currency = NumberFormat.currency(symbol: '¥');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
        ],
        directory: dir.path,
      );
    }

    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final tags = await _isar.collection<JiveTag>().where().findAll();
    final txs = await _isar.jiveTransactions
        .filter()
        .group(
          (q) => q.smartTagOptOutAllEqualTo(true).or().smartTagOptOutKeysIsNotEmpty(),
        )
        .sortByTimestampDesc()
        .findAll();

    if (!mounted) return;
    setState(() {
      _categoryByKey = {for (final c in categories) c.key: c};
      _tagByKey = {for (final t in tags) t.key: t};
      _transactions = txs;
      _loading = false;
    });
  }

  Future<void> _restoreTransaction(JiveTransaction tx) async {
    final matched =
        await TagRuleService(_isar).restoreAllSmartTagsForTransaction(tx.id);
    if (!mounted) return;
    DataReloadBus.notify();
    _showMessage(
      matched == 0
          ? '已恢复智能标签（当前规则未命中）'
          : '已恢复智能标签，命中 $matched 个',
    );
    await _load();
  }

  Future<void> _removeOptOut(JiveTransaction tx) async {
    final removed =
        await TagRuleService(_isar).clearAllOptOutsForTransaction(tx.id);
    if (!mounted) return;
    DataReloadBus.notify();
    _showMessage(
      removed == 0 ? '未找到可移除的豁免' : '已移除 $removed 个智能标签豁免',
    );
    await _load();
  }

  Future<void> _restoreAll() async {
    final target = _filteredTransactions();
    if (target.isEmpty) return;
    final confirmed = await _confirm(
      title: '恢复全部',
      message: '确认恢复当前筛选结果中的 ${target.length} 笔交易？',
    );
    if (confirmed != true) return;
    var matchedTotal = 0;
    for (final tx in target) {
      matchedTotal +=
          await TagRuleService(_isar).restoreAllSmartTagsForTransaction(tx.id);
    }
    if (!mounted) return;
    DataReloadBus.notify();
    _showMessage('已恢复 ${_transactions.length} 笔交易，命中 $matchedTotal 个');
    await _load();
  }

  Future<void> _removeAll() async {
    final target = _filteredTransactions();
    if (target.isEmpty) return;
    final confirmed = await _confirm(
      title: '移除全部豁免',
      message: '确认移除当前筛选结果中的 ${target.length} 笔交易的豁免？',
    );
    if (confirmed != true) return;
    var removedTotal = 0;
    for (final tx in target) {
      removedTotal +=
          await TagRuleService(_isar).clearAllOptOutsForTransaction(tx.id);
    }
    if (!mounted) return;
    DataReloadBus.notify();
    _showMessage('已移除 $removedTotal 个智能标签豁免');
    await _load();
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryName(JiveTransaction tx) {
    if (tx.categoryKey != null && _categoryByKey.containsKey(tx.categoryKey)) {
      return _categoryByKey[tx.categoryKey!]!.name;
    }
    if (tx.category != null && tx.category!.isNotEmpty) return tx.category!;
    return '未分类';
  }

  String _optOutSummary(JiveTransaction tx) {
    if (tx.smartTagOptOutAll) return '全部智能标签';
    if (tx.smartTagOptOutKeys.isEmpty) return '无';
    final names = tx.smartTagOptOutKeys.map((key) {
      final tag = _tagByKey[key];
      return tag == null ? '已删除' : (tag.name.isEmpty ? '未命名' : tag.name);
    }).toList();
    const maxItems = 3;
    if (names.length <= maxItems) return names.join('、');
    final head = names.take(maxItems).join('、');
    return '$head…等${names.length}个';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '停用智能标签',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_transactions.isNotEmpty) ...[
            IconButton(
              tooltip: '全部恢复',
              onPressed: _restoreAll,
              icon: const Icon(Icons.settings_backup_restore),
            ),
            IconButton(
              tooltip: '移除全部豁免',
              onPressed: _removeAll,
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Text(
                    '暂无停用记录',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _buildFilterRow(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: _buildSortRow(),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          final type = tx.type ?? 'expense';
                          final isIncome = type == 'income';
                          final amountColor =
                              isIncome ? Colors.green : Colors.redAccent;
                          final amountPrefix = isIncome ? '+ ' : '- ';
                          final note = (tx.note ?? '').trim();
                          final hasNote = note.isNotEmpty;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final updated = await showTransactionDetailSheet(
                                context,
                                tx.id,
                              );
                              if (updated == true) {
                                await _load();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _categoryName(tx),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$amountPrefix${_currency.format(tx.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: amountColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateFormat.format(tx.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      if (tx.smartTagOptOutAll)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.red.shade100,
                                            ),
                                          ),
                                          child: const Text(
                                            '全部停用',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      if (!tx.smartTagOptOutAll &&
                                          tx.smartTagOptOutKeys.isNotEmpty) ...[
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.orange.shade100,
                                            ),
                                          ),
                                          child: Text(
                                            '停用 ${tx.smartTagOptOutKeys.length}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '停用：${_optOutSummary(tx)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (hasNote) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _removeOptOut(tx),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                          ),
                                          child: const Text('移除豁免'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _restoreTransaction(tx),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: JiveTheme.primaryGreen,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('恢复'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  List<JiveTransaction> _filteredTransactions() {
    List<JiveTransaction> base;
    if (_filter == 'all') {
      base = [..._transactions];
    } else if (_filter == 'all_off') {
      base = _transactions.where((tx) => tx.smartTagOptOutAll).toList();
    } else if (_filter == 'partial') {
      base = _transactions
          .where((tx) => !tx.smartTagOptOutAll && tx.smartTagOptOutKeys.isNotEmpty)
          .toList();
    } else {
      base = [..._transactions];
    }

    base.sort((a, b) {
      int cmp;
      if (_sortField == 'amount') {
        cmp = a.amount.compareTo(b.amount);
      } else {
        cmp = a.timestamp.compareTo(b.timestamp);
      }
      if (!_sortAsc) cmp = -cmp;
      if (cmp == 0) {
        cmp = b.timestamp.compareTo(a.timestamp);
      }
      return cmp;
    });
    return base;
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('全部'),
          selected: _filter == 'all',
          selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
          onSelected: (_) => setState(() => _filter = 'all'),
        ),
        ChoiceChip(
          label: const Text('全部停用'),
          selected: _filter == 'all_off',
          selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
          onSelected: (_) => setState(() => _filter = 'all_off'),
        ),
        ChoiceChip(
          label: const Text('部分停用'),
          selected: _filter == 'partial',
          selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
          onSelected: (_) => setState(() => _filter = 'partial'),
        ),
      ],
    );
  }

  Widget _buildSortRow() {
    return Row(
      children: [
        Text(
          '排序',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('时间'),
                selected: _sortField == 'time',
                selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
                onSelected: (_) => setState(() => _sortField = 'time'),
              ),
              ChoiceChip(
                label: const Text('金额'),
                selected: _sortField == 'amount',
                selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
                onSelected: (_) => setState(() => _sortField = 'amount'),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _sortAsc ? '升序' : '降序',
          onPressed: () => setState(() => _sortAsc = !_sortAsc),
          icon: Icon(
            _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
            color: JiveTheme.primaryGreen,
          ),
        ),
      ],
    );
  }
}
