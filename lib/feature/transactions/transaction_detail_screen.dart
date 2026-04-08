import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/service/database_service.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/tag_rule_service.dart';
import '../../core/sync/sync_delete_marker_service.dart';
import '../refund/add_refund_screen.dart';
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
  late final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  Isar? _isar;
  bool _isLoading = true;
  String? _errorMessage;
  JiveTransaction? _transaction;
  final Map<String, JiveCategory> _categoryByKey = {};
  final Map<int, JiveAccount> _accountById = {};
  final Map<String, JiveTag> _tagByKey = {};
  final Map<int, JiveProject> _projectById = {};
  Set<String> _smartDisplayKeys = {};
  Map<String, SmartTagMatchExplanation> _smartExplainByTag = {};
  bool _hasDataChanges = false;

  // 多币种支持
  String _baseCurrency = 'CNY';
  CurrencyService? _currencyService;
  double? _convertedAmount;

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
      final projects = await isar.collection<JiveProject>().where().findAll();
      final hasStoredSmartKeys = tx.smartTagKeys.isNotEmpty;
      var displaySmartKeys = <String>{};
      if (hasStoredSmartKeys) {
        displaySmartKeys = tx.smartTagKeys.toSet();
      } else if (tx.tagKeys.isNotEmpty) {
        displaySmartKeys = (await TagRuleService(
          isar,
        ).resolveMatchingTags(tx)).toSet();
      }
      final explainByTag = <String, SmartTagMatchExplanation>{};
      if (displaySmartKeys.isNotEmpty) {
        final explanations = await TagRuleService(isar).explainForTransaction(
          tx,
          tagKeys: displaySmartKeys,
          onlySmartTagged: hasStoredSmartKeys,
        );
        explainByTag.addEntries(
          explanations.map((item) => MapEntry(item.tagKey, item)),
        );
      }

      // 加载多币种转换数据
      _currencyService ??= CurrencyService(isar);
      final baseCurrency = await _currencyService!.getBaseCurrency();
      final accountById = {for (final a in accounts) a.id: a};
      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double? convertedAmount;
      if (txCurrency != baseCurrency) {
        convertedAmount = await _currencyService!.convert(
          tx.amount,
          txCurrency,
          baseCurrency,
        );
      }

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
        _smartDisplayKeys = displaySmartKeys;
        _smartExplainByTag = explainByTag;
        _projectById
          ..clear()
          ..addEntries(projects.map((p) => MapEntry(p.id, p)));
        _baseCurrency = baseCurrency;
        _convertedAmount = convertedAmount;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('TransactionDetailScreen error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = e is StateError ? '记录不存在' : '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
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
        setState(() {
          // trigger rebuild after transaction edited and data reloaded
        });
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
      if (mounted) {
        setState(() {
          _hasDataChanges = true;
        });
      }
    }
  }

  Future<void> _createRefund() async {
    final tx = _transaction;
    if (tx == null || (tx.type ?? 'expense') == 'transfer') {
      return;
    }
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRefundScreen(originalTransactionId: tx.id),
      ),
    );
    if (created == true) {
      if (mounted) {
        setState(() {
          _hasDataChanges = true;
        });
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
    await SyncDeleteMarkerService(_isar!).markTransactionDeleted(tx);
    await _isar!.writeTxn(() async {
      await _isar!.jiveTransactions.delete(tx.id);
    });
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasDataChanges);
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
    final canRefund = !isTransfer;
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (type == 'income' ? Colors.green : Colors.redAccent);
    final amountPrefix = isTransfer ? '' : (type == 'income' ? '+ ' : '- ');
    final title = isTransfer ? _transferTitle(tx) : _categoryTitle(tx);
    final subtitle = isTransfer ? _transferSubtitle(tx) : _categorySubtitle(tx);
    final tags = _resolveTags(tx);
    final smartTagKeys = _smartDisplayKeys.isEmpty
        ? tx.smartTagKeys.toSet()
        : _smartDisplayKeys;
    final smartTags = tags
        .where((tag) => smartTagKeys.contains(tag.key))
        .toList();
    final optOutTags = _resolveOptOutTags(tx);
    final isOptOutAll = tx.smartTagOptOutAll;
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

    // 获取交易账户的货币符号
    final account = tx.accountId != null ? _accountById[tx.accountId] : null;
    final txCurrency = account?.currency ?? 'CNY';
    final txCurrencySymbol = CurrencyDefaults.getSymbol(txCurrency);
    final baseCurrencySymbol = CurrencyDefaults.getSymbol(_baseCurrency);
    final txDecimals = CurrencyDefaults.getDecimalPlaces(txCurrency);
    final baseDecimals = CurrencyDefaults.getDecimalPlaces(_baseCurrency);
    final amountText =
        '$amountPrefix$txCurrencySymbol${tx.amount.toStringAsFixed(txDecimals)}';

    final header = Column(
      children: [
        SizedBox(height: headerTopSpacing),
        Text(
          amountText,
          style: GoogleFonts.rubik(
            fontSize: amountFontSize,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
        // 如果货币不同，显示转换后金额
        if (_convertedAmount != null) ...[
          const SizedBox(height: 4),
          Text(
            '≈ $baseCurrencySymbol${_convertedAmount!.toStringAsFixed(baseDecimals)}',
            style: GoogleFonts.rubik(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
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
        // 跨币种转账信息
        if (isTransfer && tx.toAmount != null) ...[_buildCrossCurrencyRow(tx)],
        _buildProjectRow(tx.projectId),
      ]),
      const SizedBox(height: 12),
      _buildDetailCard([
        _buildTagRow(tags, smartTagKeys, smartTags, optOutTags, isOptOutAll),
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
          if (canRefund)
            _buildActionIcon(
              icon: Icons.undo_rounded,
              color: Colors.orangeAccent,
              tooltip: '退款',
              onPressed: _createRefund,
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
            children: [...detailCards, const SizedBox(height: 80)],
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
      color: color.withValues(alpha: 0.12),
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
            color: Colors.black.withValues(alpha: 0.03),
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

  Widget _buildCrossCurrencyRow(JiveTransaction tx) {
    final fromAccount = tx.accountId != null
        ? _accountById[tx.accountId]
        : null;
    final toAccount = tx.toAccountId != null
        ? _accountById[tx.toAccountId]
        : null;
    final fromCurrency = fromAccount?.currency ?? 'CNY';
    final toCurrency = toAccount?.currency ?? 'CNY';

    if (fromCurrency == toCurrency) return const SizedBox.shrink();

    final toSymbol = CurrencyDefaults.getSymbol(toCurrency);
    final toDecimals = CurrencyDefaults.getDecimalPlaces(toCurrency);

    final rateText = tx.exchangeRate != null
        ? '1 $fromCurrency = ${tx.exchangeRate!.toStringAsFixed(4)} $toCurrency'
        : '汇率未记录';
    final toAmountText = '$toSymbol${tx.toAmount!.toStringAsFixed(toDecimals)}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  '转入金额',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      toAmountText,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  '使用汇率',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rateText,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildTagRow(
    List<JiveTag> tags,
    Set<String> smartKeys,
    List<JiveTag> smartTags,
    List<JiveTag> optOutTags,
    bool isOptOutAll,
  ) {
    if (tags.isEmpty) {
      return _buildDetailRow('标签', '无');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            if (smartTags.isNotEmpty)
              Expanded(child: _buildSmartSummary(smartTags)),
          ],
        ),
        if (optOutTags.isNotEmpty || isOptOutAll) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: _buildOptOutSummary(optOutTags, isOptOutAll),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags
              .map((tag) => _buildTagChip(tag, smartKeys.contains(tag.key)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSmartSummary(List<JiveTag> smartTags, {int maxLines = 1}) {
    const label = '智能标签：点击查看命中规则';
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _openSmartExplainListSheet(smartTags),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          alignment: Alignment.centerRight,
        ),
        child: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          softWrap: true,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: JiveTheme.primaryGreen,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildOptOutSummary(List<JiveTag> optOutTags, bool isOptOutAll) {
    final label = isOptOutAll ? '已停用全部智能标签：点击恢复' : '已停用智能标签：点击恢复';
    return TextButton(
      onPressed: () => _openSmartOptOutSheet(optOutTags, isOptOutAll),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.redAccent,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  List<JiveTag> _resolveOptOutTags(JiveTransaction tx) {
    if (tx.smartTagOptOutKeys.isEmpty) return const [];
    final items = <JiveTag>[];
    for (final key in tx.smartTagOptOutKeys) {
      final tag = _tagByKey[key];
      if (tag != null) {
        items.add(tag);
      }
    }
    items.sort((a, b) => tagDisplayName(a).compareTo(tagDisplayName(b)));
    return items;
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
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 12,
                color: JiveTheme.primaryGreen,
              ),
            ),
          ],
        ],
      ),
      avatar: icon == null
          ? null
          : CircleAvatar(
              radius: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              child: icon,
            ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }

  Future<void> _openSmartExplainListSheet(List<JiveTag> smartTags) async {
    final sortedTags = [...smartTags]
      ..sort((a, b) => tagDisplayName(a).compareTo(tagDisplayName(b)));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: JiveTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '智能标签命中规则',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${sortedTags.length} 个标签',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '点击标签可查看命中详情与停止自动打标',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: sortedTags.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final tag = sortedTags[index];
                          final explanation = _smartExplainByTag[tag.key];
                          final matchCount = explanation?.matches.length ?? 0;
                          final summary = matchCount == 0
                              ? '查看命中规则'
                              : matchCount == 1
                              ? '匹配 1 条规则'
                              : '匹配 $matchCount 条规则';
                          final color =
                              AccountService.parseColorHex(tag.colorHex) ??
                              JiveTheme.primaryGreen;
                          final tagIcon = hasTagIcon(tag)
                              ? tagIconWidget(tag, size: 14, color: color)
                              : const Icon(Icons.label_outline, size: 16);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                Navigator.pop(context);
                                await _openSmartExplainSheet(tag, explanation);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: color.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: tagIcon,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tagDisplayName(tag),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            summary,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

  Future<void> _openSmartOptOutSheet(
    List<JiveTag> optOutTags,
    bool isOptOutAll,
  ) async {
    final sortedTags = [...optOutTags]
      ..sort((a, b) => tagDisplayName(a).compareTo(tagDisplayName(b)));
    final currentTags = <JiveTag>[...sortedTags];
    var globalOptOut = isOptOutAll;
    String? bannerMessage;
    DateTime? bannerShownAt;

    void scheduleBannerClear(
      BuildContext sheetContext,
      StateSetter setSheetState,
      DateTime shownAt,
    ) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || !sheetContext.mounted) return;
        setSheetState(() {
          if (bannerShownAt == shownAt) {
            bannerMessage = null;
          }
        });
      });
    }

    void showBanner(
      BuildContext sheetContext,
      StateSetter setSheetState,
      String message,
    ) {
      final shownAt = DateTime.now();
      setSheetState(() {
        bannerMessage = message;
        bannerShownAt = shownAt;
      });
      scheduleBannerClear(sheetContext, setSheetState, shownAt);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                final tagCount = currentTags.length;
                final hasAnyOptOut = globalOptOut || tagCount > 0;
                return Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            children: [
                              const Icon(Icons.block, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(
                                '已停用智能标签',
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (tagCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$tagCount 个标签',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '点击“恢复”可重新启用本笔交易的智能打标',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton(
                                  onPressed: hasAnyOptOut
                                      ? () async {
                                          final countBefore =
                                              currentTags.length;
                                          final wasGlobal = globalOptOut;
                                          final matchedCount = wasGlobal
                                              ? await _restoreAllSmartTagsForTransaction()
                                              : await _restoreAllSmartTags(
                                                  currentTags,
                                                );
                                          if (!mounted || !context.mounted) {
                                            return;
                                          }
                                          setSheetState(() {
                                            currentTags.clear();
                                            globalOptOut = false;
                                          });
                                          final message = wasGlobal
                                              ? matchedCount == 0
                                                    ? '已恢复全部智能标签（当前规则未命中）'
                                                    : '已恢复全部智能标签，命中 $matchedCount 个'
                                              : matchedCount == 0
                                              ? '已恢复 $countBefore 个标签（当前规则未命中）'
                                              : matchedCount == countBefore
                                              ? '已恢复 $countBefore 个智能标签'
                                              : '已恢复 $countBefore 个标签，命中 $matchedCount 个';
                                          showBanner(
                                            context,
                                            setSheetState,
                                            message,
                                          );
                                        }
                                      : null,
                                  child: const Text('全部恢复'),
                                ),
                                TextButton(
                                  onPressed: hasAnyOptOut
                                      ? () async {
                                          final removed =
                                              await _clearAllOptOuts();
                                          if (!mounted || !context.mounted) {
                                            return;
                                          }
                                          setSheetState(() {
                                            currentTags.clear();
                                            globalOptOut = false;
                                          });
                                          final message = removed == 0
                                              ? '未找到可移除的豁免'
                                              : '已移除 $removed 个智能标签豁免';
                                          showBanner(
                                            context,
                                            setSheetState,
                                            message,
                                          );
                                        }
                                      : null,
                                  child: const Text('移除豁免'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (bannerMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Text(
                                bannerMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                        if (globalOptOut)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                '本笔交易已停用全部智能标签，可点“全部恢复”重新启用',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: tagCount == 0
                              ? Center(
                                  child: Text(
                                    globalOptOut ? '暂无单独停用的标签' : '暂无停用的智能标签',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    16,
                                  ),
                                  itemCount: currentTags.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final tag = currentTags[index];
                                    final color =
                                        AccountService.parseColorHex(
                                          tag.colorHex,
                                        ) ??
                                        JiveTheme.primaryGreen;
                                    final tagIcon = hasTagIcon(tag)
                                        ? tagIconWidget(
                                            tag,
                                            size: 14,
                                            color: color,
                                          )
                                        : const Icon(
                                            Icons.label_outline,
                                            size: 16,
                                          );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            child: tagIcon,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              tagDisplayName(tag),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: globalOptOut
                                                ? null
                                                : () async {
                                                    final restored =
                                                        await _restoreSmartTag(
                                                          tag,
                                                        );
                                                    if (!mounted ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    setSheetState(() {
                                                      currentTags.removeWhere(
                                                        (item) =>
                                                            item.key == tag.key,
                                                      );
                                                    });
                                                    final message = restored
                                                        ? '已恢复智能标签：${tagDisplayName(tag)}'
                                                        : '已恢复自动打标（当前规则未命中）';
                                                    showBanner(
                                                      context,
                                                      setSheetState,
                                                      message,
                                                    );
                                                  },
                                            child: const Text('恢复'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
      },
    );
  }

  Future<bool> _restoreSmartTag(JiveTag tag) async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return false;
    final matched = await TagRuleService(
      isar,
    ).restoreOptOutForTransaction(tx.id, tag.key);
    _hasDataChanges = true;
    if (!mounted) return matched;
    await _loadData();
    return matched;
  }

  Future<int> _restoreAllSmartTags(List<JiveTag> tags) async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return 0;
    var matchedCount = 0;
    for (final tag in tags) {
      final matched = await TagRuleService(
        isar,
      ).restoreOptOutForTransaction(tx.id, tag.key);
      if (matched) matchedCount += 1;
    }
    _hasDataChanges = true;
    if (!mounted) return matchedCount;
    await _loadData();
    return matchedCount;
  }

  Future<int> _restoreAllSmartTagsForTransaction() async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return 0;
    final matchedCount = await TagRuleService(
      isar,
    ).restoreAllSmartTagsForTransaction(tx.id);
    _hasDataChanges = true;
    if (!mounted) return matchedCount;
    await _loadData();
    return matchedCount;
  }

  Future<int> _clearAllOptOuts() async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return 0;
    final removed = await TagRuleService(
      isar,
    ).clearAllOptOutsForTransaction(tx.id);
    _hasDataChanges = true;
    if (!mounted) return removed;
    await _loadData();
    return removed;
  }

  Future<void> _openSmartExplainSheet(
    JiveTag tag,
    SmartTagMatchExplanation? explanation,
  ) async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SmartTagExplainSheet(
          tag: tag,
          explanation: explanation,
          resolveAccountName: _resolveAccountName,
          displayCategoryName: _displayCategoryName,
          typeLabel: _typeLabel,
          amountRange: _amountRange,
          onOptOut: () async {
            final didOptOut = await _optOutSmartTag(tag);
            if (didOptOut && context.mounted) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  String _amountRange(double? min, double? max) {
    if (min != null && max != null) {
      return '¥${min.toStringAsFixed(0)} - ¥${max.toStringAsFixed(0)}';
    }
    if (min != null) return '≥ ¥${min.toStringAsFixed(0)}';
    if (max != null) return '≤ ¥${max.toStringAsFixed(0)}';
    return '';
  }

  Future<bool> _optOutSmartTag(JiveTag tag) async {
    final tx = _transaction;
    final isar = _isar;
    if (tx == null || isar == null) return false;
    var applyAll = false;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final message = applyAll
                ? '本笔交易将不再自动打上任何智能标签，并移除当前智能标签记录。是否继续？'
                : '本笔交易将不再自动打上「${tagDisplayName(tag)}」，并移除当前智能标签记录。是否继续？';
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '停止自动打标',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '同时停用本笔所有智能标签',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: applyAll,
                            onChanged: (value) {
                              setSheetState(() {
                                applyAll = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('继续'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (confirmed != true) return false;

    if (applyAll) {
      await TagRuleService(isar).optOutAllForTransaction(tx.id);
    } else {
      await TagRuleService(isar).optOutTagForTransaction(tx.id, tag.key);
    }
    _hasDataChanges = true;
    if (!mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applyAll ? '已停止本笔交易的全部智能标签' : '已停止本笔交易的智能标签：${tagDisplayName(tag)}',
        ),
      ),
    );
    await _loadData();
    return true;
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

  Widget _buildProjectRow(int? projectId) {
    if (projectId == null) {
      return _buildDetailRow('项目', '无');
    }
    final project = _projectById[projectId];
    if (project == null) {
      return _buildDetailRow('项目', '无');
    }
    final color = project.colorHex != null
        ? Color(int.parse(project.colorHex!.replaceFirst('#', '0xFF')))
        : JiveTheme.primaryGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '项目',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidgetForName(project.iconName, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  project.name,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartTagExplainSheet extends StatelessWidget {
  final JiveTag tag;
  final SmartTagMatchExplanation? explanation;
  final String Function(int? accountId) resolveAccountName;
  final String Function(String? key, String? fallback) displayCategoryName;
  final String Function(String type) typeLabel;
  final String Function(double? min, double? max) amountRange;
  final Future<void> Function() onOptOut;

  const _SmartTagExplainSheet({
    required this.tag,
    required this.explanation,
    required this.resolveAccountName,
    required this.displayCategoryName,
    required this.typeLabel,
    required this.amountRange,
    required this.onOptOut,
  });

  @override
  Widget build(BuildContext context) {
    final matches = explanation?.matches ?? const <RuleMatchDetail>[];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: JiveTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tagDisplayName(tag),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          matches.isEmpty ? '无命中' : '命中 ${matches.length} 条',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: JiveTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: matches.isEmpty
                      ? Center(
                          child: Text(
                            '未找到命中规则（可能规则已停用）',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final detail = matches[index];
                            return _RuleExplainCard(
                              index: index + 1,
                              detail: detail,
                              resolveAccountName: resolveAccountName,
                              displayCategoryName: displayCategoryName,
                              typeLabel: typeLabel,
                              amountRange: amountRange,
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onOptOut,
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('本笔不再自动打标'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RuleExplainCard extends StatelessWidget {
  final int index;
  final RuleMatchDetail detail;
  final String Function(int? accountId) resolveAccountName;
  final String Function(String? key, String? fallback) displayCategoryName;
  final String Function(String type) typeLabel;
  final String Function(double? min, double? max) amountRange;

  const _RuleExplainCard({
    required this.index,
    required this.detail,
    required this.resolveAccountName,
    required this.displayCategoryName,
    required this.typeLabel,
    required this.amountRange,
  });

  @override
  Widget build(BuildContext context) {
    final rule = detail.rule;
    final lines = _buildLines(rule);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '规则 $index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MM-dd HH:mm').format(rule.updatedAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $line',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildLines(JiveTagRule rule) {
    final lines = <String>[];
    final type = (rule.applyType ?? 'all').toLowerCase();
    if (type != 'all') {
      lines.add('类型：${typeLabel(type)}');
    }
    if (rule.minAmount != null || rule.maxAmount != null) {
      final range = amountRange(rule.minAmount, rule.maxAmount);
      if (range.isNotEmpty) {
        lines.add('金额：$range');
      }
    }
    if (rule.accountIds.isNotEmpty) {
      final name = resolveAccountName(detail.matchedAccountId);
      lines.add('账户：$name');
    }
    if (rule.categoryKey?.isNotEmpty ?? false) {
      lines.add('分类：${displayCategoryName(rule.categoryKey, null)}');
    }
    if (rule.subCategoryKey?.isNotEmpty ?? false) {
      lines.add('子类：${displayCategoryName(rule.subCategoryKey, null)}');
    }
    if (detail.matchedKeywords.isNotEmpty) {
      lines.add('关键词：${detail.matchedKeywords.join('、')}');
    }
    if (lines.isEmpty) {
      lines.add('满足规则条件');
    }
    return lines;
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
