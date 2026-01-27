import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../tag/tag_rule_screen.dart';
import '../tag/tag_icon_catalog.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;
  final bool isSheet;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.isSheet = false,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final NumberFormat _currency = NumberFormat.currency(symbol: "¥");
  late final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  Isar? _isar;
  bool _isLoading = true;
  String? _errorMessage;
  JiveTransaction? _transaction;
  final Map<String, JiveCategory> _categoryByKey = {};
  final Map<int, JiveAccount> _accountById = {};
  final Map<String, JiveTag> _tagByKey = {};
  bool _hasDataChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final isar = await _ensureIsar();
      final tx = await isar.jiveTransactions.get(widget.transactionId);
      if (tx == null) {
        throw StateError('transaction_missing');
      }
      final categories = await isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final accounts = await isar.collection<JiveAccount>().where().findAll();
      final tags = await isar.collection<JiveTag>().where().findAll();

      if (!mounted) return;
      setState(() {
        _transaction = tx;
        _categoryByKey
          ..clear()
          ..addEntries(categories.map((c) => MapEntry(c.key, c)));
        _accountById
          ..clear()
          ..addEntries(accounts.map((a) => MapEntry(a.id, a)));
        _tagByKey
          ..clear()
          ..addEntries(tags.map((t) => MapEntry(t.key, t)));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is StateError ? '记录不存在' : '加载失败，请重试';
        _isLoading = false;
      });
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      JiveTransactionSchema,
      JiveCategorySchema,
      JiveCategoryOverrideSchema,
      JiveAccountSchema,
      JiveAutoDraftSchema,
      JiveTagSchema,
      JiveTagGroupSchema,
      JiveTagRuleSchema,
      JiveTagConversionLogSchema,
    ], directory: dir.path);
    return _isar!;
  }

  Future<void> _editTransaction() async {
    final tx = _transaction;
    if (tx == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(editingTransaction: tx),
      ),
    );
    if (updated == true) {
      _hasDataChanges = true;
      await _loadData();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _copyTransaction() async {
    final tx = _transaction;
    if (tx == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(prefillTransaction: tx),
      ),
    );
    if (updated == true) {
      _hasDataChanges = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final tx = _transaction;
    if (tx == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除交易'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _isar!.writeTxn(() async {
      await _isar!.jiveTransactions.delete(tx.id);
    });
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasDataChanges);
        return false;
      },
      child: widget.isSheet ? _buildSheet() : _buildScreen(),
    );
  }

  Widget _buildScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasDataChanges),
        ),
        title: Text(
          '交易详情',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSheet() {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.67,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '交易详情',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context, _hasDataChanges),
                        icon: const Icon(Icons.close),
                        tooltip: '关闭',
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(scrollController: scrollController)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({ScrollController? scrollController}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }
    final tx = _transaction;
    if (tx == null) {
      return _buildErrorState('暂无数据');
    }
    final type = tx.type ?? 'expense';
    final isTransfer = type == 'transfer';
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (type == 'income' ? Colors.green : Colors.redAccent);
    final amountPrefix = isTransfer ? '' : (type == 'income' ? '+ ' : '- ');
    final title = isTransfer ? _transferTitle(tx) : _categoryTitle(tx);
    final subtitle = isTransfer ? _transferSubtitle(tx) : _categorySubtitle(tx);
    final tags = _resolveTags(tx);
    final smartTagKeys = tx.smartTagKeys.toSet();
    final smartTags = tags.where((tag) => smartTagKeys.contains(tag.key)).toList();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final amountFontSize = isLandscape ? 26.0 : 32.0;
    final titleFontSize = isLandscape ? 12.0 : 14.0;
    final subtitleFontSize = isLandscape ? 11.0 : 12.0;
    final headerTopSpacing = isLandscape ? 8.0 : 16.0;
    final headerBottomSpacing = isLandscape ? 12.0 : 20.0;
    final listPhysics = scrollController == null
        ? const ClampingScrollPhysics()
        : const AlwaysScrollableScrollPhysics();

    final header = Column(
      children: [
        SizedBox(height: headerTopSpacing),
        Text(
          '$amountPrefix${_currency.format(tx.amount)}',
          style: GoogleFonts.rubik(
            fontSize: amountFontSize,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: subtitleFontSize,
              color: Colors.grey.shade500,
            ),
          ),
        SizedBox(height: headerBottomSpacing),
      ],
    );

    final detailCards = [
      _buildDetailCard([
        _buildDetailRow('类型', _typeLabel(type)),
        _buildDetailRow('时间', _dateTimeFormat.format(tx.timestamp)),
        _buildDetailRow('来源', tx.source),
      ]),
      const SizedBox(height: 12),
      _buildDetailCard([
        if (!isTransfer) _buildDetailRow('分类', _categoryTitle(tx)),
        if (!isTransfer) _buildDetailRow('子类', _categorySubtitle(tx)),
        _buildDetailRow('账户', _resolveAccountName(tx.accountId)),
        if (isTransfer)
          _buildDetailRow('转入账户', _resolveAccountName(tx.toAccountId)),
      ]),
      const SizedBox(height: 12),
      _buildDetailCard([
        _buildTagRow(tags, smartTagKeys),
        if (smartTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSmartTagHint(smartTags),
        ],
      ]),
      const SizedBox(height: 12),
      _buildDetailCard([
        _buildDetailRow(
          '备注',
          tx.note?.trim().isEmpty ?? true ? '无' : tx.note!.trim(),
        ),
        _buildDetailRow(
          '原始信息',
          tx.rawText?.trim().isEmpty ?? true ? '无' : tx.rawText!.trim(),
        ),
      ]),
    ];

    final actionRow = SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionIcon(
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            tooltip: '删除',
            onPressed: _deleteTransaction,
          ),
          _buildActionIcon(
            icon: Icons.copy_rounded,
            color: Colors.blueGrey,
            tooltip: '复制',
            onPressed: _copyTransaction,
          ),
          _buildActionIcon(
            icon: Icons.edit_rounded,
            color: JiveTheme.primaryGreen,
            tooltip: '编辑',
            onPressed: _editTransaction,
          ),
        ],
      ),
    );

    if (isLandscape) {
      return ListView(
        controller: scrollController,
        physics: listPhysics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          header,
          ...detailCards,
          const SizedBox(height: 12),
          actionRow,
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(
          child: ListView(
            controller: scrollController,
            physics: listPhysics,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...detailCards,
              const SizedBox(height: 80),
            ],
          ),
        ),
        actionRow,
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<JiveTag> _resolveTags(JiveTransaction tx) {
    if (tx.tagKeys.isEmpty) return [];
    final seen = <String>{};
    final items = <JiveTag>[];
    for (final key in tx.tagKeys) {
      if (!seen.add(key)) continue;
      final tag = _tagByKey[key];
      if (tag != null) {
        items.add(tag);
      }
    }
    return items;
  }

  Widget _buildTagRow(List<JiveTag> tags, Set<String> smartKeys) {
    if (tags.isEmpty) {
      return _buildDetailRow('标签', '无');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签',
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) => _buildTagChip(tag, smartKeys.contains(tag.key))).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(JiveTag tag, bool isSmart) {
    final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    final icon = hasTagIcon(tag)
        ? tagIconWidget(tag, size: 12, color: color)
        : null;
    return InputChip(
      onPressed: () => _openTagRules(tag),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tagDisplayName(tag),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSmart) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: JiveTheme.primaryGreen.withOpacity(0.4)),
              ),
              child: Text(
                '智能',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: JiveTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
      avatar: icon == null
          ? null
          : CircleAvatar(
              radius: 10,
              backgroundColor: color.withOpacity(0.15),
              child: icon,
            ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }

  Widget _buildSmartTagHint(List<JiveTag> smartTags) {
    final names = smartTags.map(tagDisplayName).join('、');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JiveTheme.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: JiveTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '智能标签：$names（可点标签管理规则）',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTagRules(JiveTag tag) {
    if (_isar == null) return Future.value();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagRuleScreen(tag: tag, isar: _isar),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.lato(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
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

  String _categoryTitle(JiveTransaction tx) {
    return _displayCategoryName(tx.categoryKey, tx.category);
  }

  String _categorySubtitle(JiveTransaction tx) {
    final sub = _displayCategoryName(tx.subCategoryKey, tx.subCategory);
    return sub == '未分类' ? '' : sub;
  }

  String _transferTitle(JiveTransaction tx) {
    return '转账';
  }

  String _transferSubtitle(JiveTransaction tx) {
    final fromName = _resolveAccountName(tx.accountId);
    final toName = _resolveAccountName(tx.toAccountId);
    if (fromName.isEmpty && toName.isEmpty) return '';
    if (fromName.isEmpty) return '到 $toName';
    if (toName.isEmpty) return '来自 $fromName';
    return '$fromName → $toName';
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '未分类';
  }

  String _resolveAccountName(int? accountId) {
    if (accountId == null) return '未指定';
    return _accountById[accountId]?.name ?? '未指定';
  }
}

Future<bool?> showTransactionDetailSheet(
  BuildContext context,
  int transactionId,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        TransactionDetailScreen(transactionId: transactionId, isSheet: true),
  );
}
