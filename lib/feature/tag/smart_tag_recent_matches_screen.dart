import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/tag_rule_service.dart';
import '../transactions/transaction_detail_screen.dart';
import 'tag_icon_catalog.dart';

class SmartTagRecentMatchesScreen extends StatefulWidget {
  final JiveTag tag;
  final Isar? isar;

  const SmartTagRecentMatchesScreen({
    super.key,
    required this.tag,
    this.isar,
  });

  @override
  State<SmartTagRecentMatchesScreen> createState() =>
      _SmartTagRecentMatchesScreenState();
}

class _SmartTagRecentMatchesScreenState
    extends State<SmartTagRecentMatchesScreen> {
  late final NumberFormat _currency = NumberFormat.currency(symbol: '¥');
  late final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Isar? _isar;
  bool _loading = true;
  String? _error;
  List<JiveTransaction> _transactions = const [];
  final Map<int, JiveAccount> _accountById = {};
  final Map<String, JiveCategory> _categoryByKey = {};
  Map<int, SmartTagMatchExplanation> _explanations = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isar = await _ensureIsar();
      final service = TagRuleService(isar);
      final txs =
          await service.recentSmartMatchesForTag(widget.tag.key, limit: 50);

      final accounts = await isar.collection<JiveAccount>().where().findAll();
      final categories =
          await isar.collection<JiveCategory>().where().findAll();
      final explanations =
          await service.explainForTransactionsForTag(widget.tag.key, txs);

      if (!mounted) return;
      setState(() {
        _transactions = txs;
        _accountById
          ..clear()
          ..addEntries(accounts.map((a) => MapEntry(a.id, a)));
        _categoryByKey
          ..clear()
          ..addEntries(categories.map((c) => MapEntry(c.key, c)));
        _explanations = explanations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请重试';
        _loading = false;
      });
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (widget.isar != null) {
      _isar = widget.isar!;
      return _isar!;
    }
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    final title = tagDisplayName(widget.tag);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('最近命中 · $title'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _transactions.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: JiveTheme.primaryGreen,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final explanation = _explanations[tx.id];
                          return _buildTxCard(tx, explanation);
                        },
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? '', style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        '暂无最近命中记录',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildTxCard(
    JiveTransaction tx,
    SmartTagMatchExplanation? explanation,
  ) {
    final amountColor = tx.amount >= 0
        ? Colors.black87
        : Colors.redAccent;
    final amountPrefix = tx.amount >= 0 ? '' : '-';
    final summary = _explainSummary(tx, explanation);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await showTransactionDetailSheet(context, tx.id);
        if (result == true) {
          await _load();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryName(tx),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$amountPrefix${_currency.format(tx.amount.abs())}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _dateFormat.format(tx.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                if (summary.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: JiveTheme.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
            if (explanation != null) ...[
              const SizedBox(height: 8),
              Text(
                _firstRuleLine(tx, explanation),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryName(JiveTransaction tx) {
    final main = _categoryByKey[tx.categoryKey]?.name ?? tx.category ?? '未分类';
    final sub = _categoryByKey[tx.subCategoryKey]?.name ?? tx.subCategory;
    if (sub == null || sub.isEmpty) return main;
    return '$main · $sub';
  }

  String _explainSummary(
    JiveTransaction tx,
    SmartTagMatchExplanation? explanation,
  ) {
    if (explanation == null) return '';
    final matchCount = explanation.matches.length;
    if (matchCount <= 1) return '命中规则';
    return '命中 $matchCount 条';
  }

  String _firstRuleLine(
    JiveTransaction tx,
    SmartTagMatchExplanation explanation,
  ) {
    if (explanation.matches.isEmpty) return '';
    final detail = explanation.matches.first;
    final rule = detail.rule;
    final parts = <String>[];

    final type = (rule.applyType ?? 'all').toLowerCase();
    if (type != 'all') {
      parts.add(_typeLabel(type));
    }
    if (rule.accountIds.isNotEmpty) {
      final name = _accountById[detail.matchedAccountId]?.name ?? '指定账户';
      parts.add(name);
    }
    if (rule.categoryKey?.isNotEmpty ?? false) {
      parts.add(_categoryByKey[rule.categoryKey!]?.name ?? '指定分类');
    }
    if (rule.subCategoryKey?.isNotEmpty ?? false) {
      parts.add(_categoryByKey[rule.subCategoryKey!]?.name ?? '指定子类');
    }
    if (rule.minAmount != null || rule.maxAmount != null) {
      parts.add(_amountRange(rule.minAmount, rule.maxAmount));
    }
    if (detail.matchedKeywords.isNotEmpty) {
      parts.add('关键词:${detail.matchedKeywords.take(2).join(',')}');
    }
    if (parts.isEmpty) {
      parts.add('符合规则条件');
    }
    return parts.join(' · ');
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }

  String _amountRange(double? min, double? max) {
    if (min != null && max != null) {
      return '¥${min.toStringAsFixed(0)}-¥${max.toStringAsFixed(0)}';
    }
    if (min != null) return '≥¥${min.toStringAsFixed(0)}';
    if (max != null) return '≤¥${max.toStringAsFixed(0)}';
    return '';
  }
}
