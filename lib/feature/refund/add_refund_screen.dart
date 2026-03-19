import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/database_service.dart';
import 'refund_service.dart';

class AddRefundScreen extends StatefulWidget {
  const AddRefundScreen({
    super.key,
    required this.originalTransactionId,
  });

  final int originalTransactionId;

  @override
  State<AddRefundScreen> createState() => _AddRefundScreenState();
}

class _AddRefundScreenState extends State<AddRefundScreen> {
  late final _RefundFormController _controller;
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _controller = _RefundFormController(
      originalTransactionId: widget.originalTransactionId,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(_RefundFormController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    try {
      await controller.submit();
      if (!mounted) return;
      DataReloadBus.notify();
      messenger.showSnackBar(
        const SnackBar(content: Text('退款已创建')),
      );
      Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_mapErrorMessage(error.message))),
      );
    } on StateError catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('原交易不存在或暂不支持退款')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('创建退款失败: $error')),
      );
    }
  }

  String _mapErrorMessage(Object? errorMessage) {
    switch ('$errorMessage') {
      case 'refund_amount_must_be_positive':
        return '退款金额必须大于 0';
      case 'refund_amount_exceeds_original':
        return '退款金额不能超过原交易金额';
      case 'refund_only_supports_expense_or_income':
        return '仅支出或收入交易支持退款';
      default:
        final text = '$errorMessage'.trim();
        return text.isEmpty || text == 'null'
            ? '退款信息不完整，请检查后重试'
            : text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_RefundFormController>.value(
      value: _controller,
      child: Consumer<_RefundFormController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '创建退款',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
            ),
            body: _buildBody(controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(_RefundFormController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: JiveTheme.secondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.initialize,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final original = controller.originalTransaction;
    if (original == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildOriginalSummary(original),
          const SizedBox(height: 16),
          _buildRefundOptions(controller, original),
          const SizedBox(height: 16),
          _buildNoteCard(controller),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: controller.isSubmitting
                ? null
                : () => _submit(controller),
            icon: controller.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.undo_rounded),
            label: Text(controller.isSubmitting ? '创建中...' : '确认退款'),
            style: FilledButton.styleFrom(
              backgroundColor: JiveTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalSummary(JiveTransaction original) {
    final amountColor = _amountColor(original.type);
    final amountPrefix = _amountPrefix(original.type);
    final note = original.note?.trim().isEmpty ?? true
        ? '无'
        : original.note!.trim();

    return _buildCard(
      title: '原交易',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$amountPrefix${_formatAmount(original.amount)}',
                      style: GoogleFonts.rubik(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _categoryLabel(original),
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: JiveTheme.textColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _typeLabel(original.type),
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('日期', _dateTimeFormat.format(original.timestamp)),
          _buildSummaryRow('备注', note),
        ],
      ),
    );
  }

  Widget _buildRefundOptions(
    _RefundFormController controller,
    JiveTransaction original,
  ) {
    return _buildCard(
      title: '退款设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '退款方式',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: JiveTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.fullscreen_rounded),
                label: Text('全额退款'),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.tune_rounded),
                label: Text('部分退款'),
              ),
            ],
            selected: {controller.isPartial},
            onSelectionChanged: (selection) {
              controller.setPartialMode(selection.first);
            },
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '将按原交易金额 ${_formatAmount(original.amount)} 创建退款。',
                style: GoogleFonts.lato(
                  color: JiveTheme.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            secondChild: TextField(
              controller: controller.amountController,
              onChanged: controller.updateAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '退款金额',
                hintText: '请输入不超过原金额的数值',
                errorText: controller.amountError,
                helperText: '原交易金额：${_formatAmount(original.amount)}',
                border: const OutlineInputBorder(),
              ),
            ),
            crossFadeState: controller.isPartial
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(_RefundFormController controller) {
    return _buildCard(
      title: '退款备注',
      child: TextField(
        controller: controller.noteController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: '备注',
          hintText: '可选，不填则沿用原交易备注',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JiveTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JiveTheme.dividerColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: JiveTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: GoogleFonts.lato(
                color: JiveTheme.secondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                color: JiveTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(JiveTransaction transaction) {
    final category = transaction.category?.trim();
    final subCategory = transaction.subCategory?.trim();
    if (category == null || category.isEmpty) {
      return '未分类';
    }
    if (subCategory == null || subCategory.isEmpty) {
      return category;
    }
    return '$category / $subCategory';
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }

  Color _amountColor(String? type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blueGrey;
      default:
        return Colors.redAccent;
    }
  }

  String _amountPrefix(String? type) {
    switch (type) {
      case 'income':
        return '+ ';
      case 'transfer':
        return '';
      default:
        return '- ';
    }
  }

  String _formatAmount(double amount) {
    final text = amount.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }
}

class _RefundFormController extends ChangeNotifier {
  _RefundFormController({
    required this.originalTransactionId,
  });

  final int originalTransactionId;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  Isar? _isar;
  JiveTransaction? originalTransaction;
  bool isLoading = true;
  bool isSubmitting = false;
  bool isPartial = false;
  String? errorMessage;
  String? amountError;

  Future<void> initialize() async {
    isLoading = true;
    isSubmitting = false;
    originalTransaction = null;
    errorMessage = null;
    amountError = null;
    notifyListeners();
    try {
      _isar = await DatabaseService.getInstance();
      final tx = await _isar!.jiveTransactions.get(originalTransactionId);
      if (tx == null) {
        throw StateError('transaction_missing');
      }
      if (tx.type == 'transfer') {
        throw ArgumentError('transfer_not_supported');
      }
      originalTransaction = tx;
      if (amountController.text.trim().isEmpty) {
        amountController.text = _formatAmount(tx.amount);
      }
    } on ArgumentError {
      errorMessage = '转账记录暂不支持退款';
    } on StateError {
      errorMessage = '未找到原交易记录';
    } catch (error) {
      errorMessage = '加载退款信息失败: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setPartialMode(bool value) {
    isPartial = value;
    amountError = value ? _validatePartialAmount(amountController.text) : null;
    notifyListeners();
  }

  void updateAmount(String value) {
    amountError = _validatePartialAmount(value);
    notifyListeners();
  }

  Future<JiveTransaction> submit() async {
    final original = originalTransaction;
    if (original == null) {
      throw StateError('transaction_missing');
    }
    final partialAmount = isPartial ? _parsePartialAmount() : null;
    isSubmitting = true;
    notifyListeners();
    try {
      return await RefundService(isar: _isar).createRefund(
        original.id,
        partialAmount: partialAmount,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  double? _parsePartialAmount() {
    final value = amountController.text.trim();
    final validationMessage = _validatePartialAmount(value);
    amountError = validationMessage;
    notifyListeners();
    if (validationMessage != null) {
      throw ArgumentError(validationMessage);
    }
    return double.parse(value);
  }

  String? _validatePartialAmount(String value) {
    if (!isPartial) return null;
    final original = originalTransaction;
    if (original == null) return '原交易不存在';
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '请输入退款金额';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return '请输入有效金额';
    }
    if (parsed > original.amount) {
      return '退款金额不能超过原交易金额';
    }
    return null;
  }

  String _formatAmount(double amount) {
    final text = amount.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
