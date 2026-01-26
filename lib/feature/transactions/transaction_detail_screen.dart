import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/template_model.dart';
import '../../core/service/template_service.dart';
import '../../core/design_system/theme.dart';
import 'add_transaction_screen.dart';
import 'widgets/transaction_action_bar.dart';
import 'widgets/transaction_hero_section.dart';
import 'widgets/transaction_info_card.dart';
import 'widgets/transaction_note_card.dart';
import 'widgets/transaction_raw_text_card.dart';
import '../template/widgets/save_template_dialog.dart';

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
  Isar? _isar;
  bool _isLoading = true;
  String? _errorMessage;
  JiveTransaction? _transaction;
  JiveCategory? _category;
  JiveCategory? _subCategory;
  JiveAccount? _account;
  JiveAccount? _toAccount;
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

      // 加载分类
      JiveCategory? category;
      JiveCategory? subCategory;
      if (tx.categoryKey != null) {
        category = await isar.jiveCategorys
            .filter()
            .keyEqualTo(tx.categoryKey!)
            .findFirst();
      }
      if (tx.subCategoryKey != null) {
        subCategory = await isar.jiveCategorys
            .filter()
            .keyEqualTo(tx.subCategoryKey!)
            .findFirst();
      }

      // 加载账户
      JiveAccount? account;
      if (tx.accountId != null) {
        account = await isar.jiveAccounts.get(tx.accountId!);
      }

      JiveAccount? toAccount;
      if (tx.toAccountId != null) {
        toAccount = await isar.jiveAccounts.get(tx.toAccountId!);
      }

      if (!mounted) return;
      setState(() {
        _transaction = tx;
        _category = category;
        _subCategory = subCategory;
        _account = account;
        _toAccount = toAccount;
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Future<void> _copyTransaction() async {
    final tx = _transaction;
    if (tx == null) return;

    // 复制一条新交易（时间为当前时间），然后打开编辑页面
    final newTx = JiveTransaction()
      ..amount = tx.amount
      ..type = tx.type
      ..source = '复制'
      ..timestamp = DateTime.now()
      ..accountId = tx.accountId
      ..toAccountId = tx.toAccountId
      ..categoryKey = tx.categoryKey
      ..subCategoryKey = tx.subCategoryKey
      ..category = tx.category
      ..subCategory = tx.subCategory
      ..note = tx.note;

    // 先保存交易
    await _isar!.writeTxn(() async {
      await _isar!.jiveTransactions.put(newTx);
    });

    _hasDataChanges = true;
    if (!mounted) return;

    // 打开编辑页面让用户修改
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(editingTransaction: newTx),
      ),
    );

    if (updated == true) {
      // 用户保存了修改
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交易已复制并保存')),
      );
    } else {
      // 用户取消了编辑，删除刚创建的交易
      await _isar!.writeTxn(() async {
        await _isar!.jiveTransactions.delete(newTx.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消复制')),
      );
    }
  }

  Future<void> _createRefund() async {
    final tx = _transaction;
    if (tx == null) return;

    // 底部弹窗让用户输入退款金额
    final refundAmount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RefundBottomSheet(originalAmount: tx.amount),
    );

    if (refundAmount == null) return;

    // 创建退款交易（类型相反）
    final refundType = tx.type == 'income' ? 'expense' : 'income';
    final isPartial = refundAmount < tx.amount;
    final refundTx = JiveTransaction()
      ..amount = refundAmount
      ..type = refundType
      ..source = '退款'
      ..timestamp = DateTime.now()
      ..accountId = tx.accountId
      ..categoryKey = tx.categoryKey
      ..subCategoryKey = tx.subCategoryKey
      ..category = tx.category
      ..subCategory = tx.subCategory
      ..note = isPartial
          ? '部分退款 (原¥${tx.amount.toStringAsFixed(2)}): ${tx.note ?? ''}'
          : '退款: ${tx.note ?? ''}';

    await _isar!.writeTxn(() async {
      await _isar!.jiveTransactions.put(refundTx);
    });

    _hasDataChanges = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPartial
            ? '已创建部分退款 ¥${refundAmount.toStringAsFixed(2)}'
            : '已创建全额退款'),
      ),
    );
  }

  void _shareTransaction() {
    final tx = _transaction;
    if (tx == null) return;

    final typeLabel = tx.type == 'income' ? '收入' : (tx.type == 'transfer' ? '转账' : '支出');
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.timestamp);
    final categoryName = _category?.name ?? tx.category ?? '未分类';
    final accountName = _account?.name ?? '未知账户';

    final text = '''
【Jive记账】
$typeLabel: ¥${tx.amount.toStringAsFixed(2)}
分类: $categoryName
账户: $accountName
时间: $dateStr
${tx.note != null && tx.note!.isNotEmpty ? '备注: ${tx.note}' : ''}
'''.trim();

    Share.share(text, subject: 'Jive记账 - $typeLabel');
  }

  Future<void> _saveAsTemplate() async {
    final tx = _transaction;
    if (tx == null) return;

    final result = await showSaveTemplateDialog(
      context: context,
      transaction: tx,
      categoryName: _category?.name ?? tx.category,
    );

    if (result == null) return;

    final service = TemplateService(_isar!);
    await service.createFromTransaction(
      transaction: tx,
      name: result['name'] as String,
      saveAmount: result['saveAmount'] as bool,
      groupName: result['groupName'] as String?,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已保存模板"${result['name']}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasDataChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: JiveTheme.surfaceWhite,
        body: _buildBody(),
        bottomNavigationBar: _transaction != null
            ? TransactionActionBar(
                onDelete: _deleteTransaction,
                onEdit: _editTransaction,
                onCopy: _copyTransaction,
                onSaveAsTemplate: _saveAsTemplate,
                onMarkRefund: _createRefund,
                onShare: _shareTransaction,
              )
            : null,
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

    return CustomScrollView(
      slivers: [
        // 透明 AppBar
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _buildBackButton(),
          pinned: true,
        ),
        // Hero 区域
        SliverToBoxAdapter(
          child: TransactionHeroSection(
            transaction: tx,
            category: _category,
            subCategory: _subCategory,
            account: _account,
            toAccount: _toAccount,
          ),
        ),
        // 信息卡片
        SliverToBoxAdapter(
          child: TransactionInfoCard(
            transaction: tx,
          ),
        ),
        // 备注卡片
        if (tx.note != null && tx.note!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: TransactionNoteCard(note: tx.note!),
          ),
        // 原始通知
        if (tx.rawText != null && tx.rawText!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: TransactionRawTextCard(rawText: tx.rawText!),
          ),
        // 底部留白
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => Navigator.pop(context, _hasDataChanges),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 退款金额输入底部弹窗
class _RefundBottomSheet extends StatefulWidget {
  final double originalAmount;

  const _RefundBottomSheet({required this.originalAmount});

  @override
  State<_RefundBottomSheet> createState() => _RefundBottomSheetState();
}

class _RefundBottomSheetState extends State<_RefundBottomSheet> {
  late TextEditingController _amountController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.originalAmount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validate() {
    final amount = double.tryParse(_amountController.text.trim());
    setState(() {
      if (amount == null || amount <= 0) {
        _errorText = '请输入有效的退款金额';
      } else if (amount > widget.originalAmount) {
        _errorText = '退款金额不能超过原交易金额';
      } else {
        _errorText = null;
      }
    });
  }

  void _submit() {
    _validate();
    if (_errorText != null) return;

    final amount = double.tryParse(_amountController.text.trim());
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动指示条
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
            const SizedBox(height: 16),
            // 标题
            Row(
              children: [
                const Icon(Icons.replay, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '创建退款',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 原交易金额提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '原交易金额: ¥${widget.originalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 退款金额输入
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '退款金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: _errorText,
                helperText: '可输入部分退款金额',
              ),
              autofocus: true,
              onChanged: (_) => _validate(),
            ),
            const SizedBox(height: 24),
            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('确认退款'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
