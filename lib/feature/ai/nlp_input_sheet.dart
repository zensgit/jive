import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NlpResult {
  final double amount;
  final String type; // expense / income / transfer
  final String? category;
  final String? note;
  final DateTime? date;

  const NlpResult({
    required this.amount,
    required this.type,
    this.category,
    this.note,
    this.date,
  });
}

/// 顶层解析函数，供测试直接调用
NlpResult parseNlp(String text, {DateTime? now}) {
  final trimmed = text.trim();
  final ref = now ?? DateTime.now();

  final amountRegex = RegExp(r'(\d+(?:\.\d+)?)');
  final amountMatch = amountRegex.firstMatch(trimmed);
  final amount = amountMatch != null ? double.parse(amountMatch.group(1)!) : 0.0;

  String type;
  if (RegExp(r'工资|收入|到账|发工资|薪资').hasMatch(trimmed)) {
    type = 'income';
  } else if (RegExp(r'转账|给').hasMatch(trimmed)) {
    type = 'transfer';
  } else {
    type = 'expense';
  }

  DateTime? date;
  if (trimmed.contains('今天')) {
    date = ref;
  } else if (trimmed.contains('昨天')) {
    date = ref.subtract(const Duration(days: 1));
  } else if (trimmed.contains('明天')) {
    date = ref.add(const Duration(days: 1));
  } else {
    final datePattern = RegExp(r'(\d{1,2})[月/](\d{1,2})[日号]?');
    final dateMatch = datePattern.firstMatch(trimmed);
    if (dateMatch != null) {
      final month = int.parse(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      date = DateTime(ref.year, month, day);
    }
  }

  String? category;
  if (RegExp(r'餐|饭|咖啡|奶茶|吃').hasMatch(trimmed)) {
    category = '餐饮';
  } else if (RegExp(r'打车|地铁|公交|油').hasMatch(trimmed)) {
    category = '交通';
  } else if (RegExp(r'超市|购物|买').hasMatch(trimmed)) {
    category = '购物';
  } else if (RegExp(r'工资|薪资').hasMatch(trimmed)) {
    category = '工资收入';
  } else if (trimmed.contains('房租')) {
    category = '房租';
  } else {
    category = '其他';
  }

  return NlpResult(amount: amount, type: type, category: category, note: trimmed, date: date);
}

class NlpInputSheet extends StatelessWidget {
  final void Function(NlpResult result) onConfirm;

  const NlpInputSheet({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required void Function(NlpResult result) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NlpInputSheet(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _NlpInputSheetContent();
  }
}

class _NlpInputSheetContent extends StatefulWidget {
  const _NlpInputSheetContent();

  @override
  State<_NlpInputSheetContent> createState() => _NlpInputSheetContentState();
}

class _NlpInputSheetContentState extends State<_NlpInputSheetContent> {
  final TextEditingController _controller = TextEditingController();
  NlpResult? _parsedResult;
  bool _isParsing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  NlpResult _parseNlp(String text) => parseNlp(text);

  Future<void> _handleParse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isParsing = true;
      _parsedResult = null;
    });
    // Simulate brief processing delay for UX feel
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final result = _parseNlp(text);
    setState(() {
      _parsedResult = result;
      _isParsing = false;
    });
  }

  void _handleConfirm() {
    if (_parsedResult == null) return;
    final sheet = context.findAncestorWidgetOfExactType<NlpInputSheet>();
    sheet?.onConfirm(_parsedResult!);
    Navigator.of(context).pop();
  }

  void _handleReset() {
    setState(() {
      _parsedResult = null;
      _controller.clear();
    });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'income':
        return const Color(0xFF2E7D32);
      case 'transfer':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFE53935);
    }
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

  String _typeAmountPrefix(String type) {
    switch (type) {
      case 'income':
        return '+¥';
      case 'transfer':
        return '¥';
      default:
        return '-¥';
    }
  }

  Widget _buildResultCard(NlpResult result) {
    final color = _typeColor(result.type);
    final label = _typeLabel(result.type);
    final prefix = _typeAmountPrefix(result.type);
    final amountStr = NumberFormat('#,##0.00').format(result.amount);
    final dateStr = result.date != null
        ? DateFormat('yyyy年MM月dd日').format(result.date!)
        : '未识别日期';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '解析结果',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$prefix$amountStr',
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          _ResultRow(
            icon: Icons.category_outlined,
            label: '类别',
            value: result.category ?? '其他',
          ),
          const SizedBox(height: 6),
          _ResultRow(
            icon: Icons.calendar_today_outlined,
            label: '日期',
            value: dateStr,
          ),
          if (result.note != null && result.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ResultRow(
              icon: Icons.notes_outlined,
              label: '备注',
              value: result.note!,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '智能记账',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '用自然语言描述一笔交易',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input field
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText:
                            '昨天在星巴克买咖啡花了38块\n今天工资收入8500元\n转账给老婆500',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          height: 1.6,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Parse button
                    FilledButton.icon(
                      onPressed: _isParsing ? null : _handleParse,
                      icon: _isParsing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: Text(_isParsing ? '解析中...' : '解析'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    // Parsed result card
                    if (_parsedResult != null) ...[
                      _buildResultCard(_parsedResult!),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleReset,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('重新输入'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _handleConfirm,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('使用此记账'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Info banner
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '提示：未来版本将接入大语言模型实现更精准解析',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label：',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
