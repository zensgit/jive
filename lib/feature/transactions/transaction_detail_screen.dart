import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
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
      final categories =
          await isar.collection<JiveCategory>().where().findAll();
      final accounts =
          await isar.collection<JiveAccount>().where().findAll();

      if (!mounted) return;
      setState(() {
        _transaction = tx;
        _categoryByKey
          ..clear()
          ..addEntries(categories.map((c) => MapEntry(c.key, c)));
        _accountById
          ..clear()
          ..addEntries(accounts.map((a) => MapEntry(a.id, a)));
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
    _isar = await Isar.open(
      [
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
      ],
      directory: dir.path,
    );
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
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildBody() {
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
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          '$amountPrefix${_currency.format(tx.amount)}',
          style: GoogleFonts.rubik(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildDetailCard([
                _buildDetailRow('类型', _typeLabel(type)),
                _buildDetailRow('时间', _dateTimeFormat.format(tx.timestamp)),
                _buildDetailRow('来源', tx.source),
              ]),
              const SizedBox(height: 12),
              _buildDetailCard([
                if (!isTransfer)
                  _buildDetailRow('分类', _categoryTitle(tx)),
                if (!isTransfer)
                  _buildDetailRow('子类', _categorySubtitle(tx)),
                _buildDetailRow('账户', _resolveAccountName(tx.accountId)),
                if (isTransfer)
                  _buildDetailRow('转入账户', _resolveAccountName(tx.toAccountId)),
              ]),
              const SizedBox(height: 12),
              _buildDetailCard([
                _buildDetailRow('备注', tx.note?.trim().isEmpty ?? true ? '无' : tx.note!.trim()),
                _buildDetailRow('原始信息', tx.rawText?.trim().isEmpty ?? true ? '无' : tx.rawText!.trim()),
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteTransaction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('删除'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _editTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('编辑'),
                ),
              ),
            ],
          ),
        ),
      ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: GoogleFonts.lato(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
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
