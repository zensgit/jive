import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service/conversational_parser.dart';
import '../transactions/transaction_entry_params.dart';
import '../transactions/transaction_form_screen.dart';

/// Chat-style conversational input screen for natural language bookkeeping.
class ConversationalInputScreen extends StatefulWidget {
  final int? bookId;

  const ConversationalInputScreen({super.key, this.bookId});

  @override
  State<ConversationalInputScreen> createState() =>
      _ConversationalInputScreenState();
}

class _ConversationalInputScreenState extends State<ConversationalInputScreen> {
  final _controller = TextEditingController();
  final _parser = ConversationalParser();
  final _focusNode = FocusNode();

  List<_EditableTransaction> _results = [];
  bool _parsed = false;

  static const _examples = [
    '昨天和两个朋友吃火锅AA了300',
    '上周五打车25块',
    '买了咖啡30和面包15',
    '用信用卡买衣服花了500',
    '三个人AA午餐180',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = _parser.parseConversation(text);
    setState(() {
      _parsed = true;
      _results = result.transactions
          .map((t) => _EditableTransaction.fromParsed(t))
          .toList();
    });
  }

  void _reset() {
    setState(() {
      _parsed = false;
      _results = [];
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  Future<void> _saveAll() async {
    var confirmed = 0;
    for (var i = 0; i < _results.length; i += 1) {
      if (_results[i].saved) continue;
      final saved = await _confirmSingle(i);
      if (saved) {
        confirmed += 1;
      } else {
        break;
      }
    }
    if (mounted && confirmed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已确认 $confirmed 笔交易'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveSingle(int index) async {
    if (_results[index].saved) return;
    final saved = await _confirmSingle(index);
    if (mounted && saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已记录'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _confirmSingle(int index) async {
    final et = _results[index];
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(params: _paramsFor(et)),
      ),
    );
    if (!mounted || saved != true) return false;
    setState(() => et.saved = true);
    return true;
  }

  TransactionEntryParams _paramsFor(_EditableTransaction et) {
    return TransactionEntryParams(
      source: TransactionEntrySource.conversation,
      sourceLabel: '来自对话记账',
      prefillAmount: et.amount,
      prefillType: et.type,
      prefillCategoryKey: et.category,
      prefillSubCategoryKey: et.subCategory,
      prefillBookId: widget.bookId,
      prefillNote: et.note,
      prefillDate: et.date,
      prefillRawText: _controller.text.trim(),
      highlightFields: _missingFieldsFor(et),
    );
  }

  List<String> _missingFieldsFor(_EditableTransaction et) {
    final fields = <String>[];
    if (et.amount <= 0) {
      fields.add(TransactionHighlightField.amount);
    }
    fields.add(TransactionHighlightField.account);
    if (et.type == 'transfer') {
      fields.add(TransactionHighlightField.transferAccount);
    } else {
      fields.add(TransactionHighlightField.category);
    }
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('对话记账'),
        actions: [
          if (_parsed)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新输入',
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Input area.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 2,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _parse(),
                decoration: InputDecoration(
                  hintText: '用自然语言描述您的消费...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withAlpha(102),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(51),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                    onPressed: _parse,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Example hints or results.
            Expanded(
              child: _parsed ? _buildResults(theme) : _buildHints(theme),
            ),

            // Save-all button.
            if (_parsed && _results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _results.every((e) => e.saved) ? null : _saveAll,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _results.every((e) => e.saved) ? '全部已确认' : '逐笔确认',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHints(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '试试这些说法：',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ),
        ..._examples.map(
          (example) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(example),
              avatar: const Icon(Icons.lightbulb_outline, size: 18),
              onPressed: () {
                _controller.text = example;
                _parse();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: 12),
            Text(
              '未能识别交易信息，请换个说法试试',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _results.length,
      itemBuilder: (context, index) => _TransactionCard(
        transaction: _results[index],
        onSave: () => _saveSingle(index),
        onChanged: () => setState(() {}),
      ),
    );
  }
}

// ----- Editable wrapper -----

class _EditableTransaction {
  double amount;
  String type;
  String? category;
  String? subCategory;
  DateTime date;
  String? note;
  String? accountHint;
  int? splitCount;
  bool saved = false;

  _EditableTransaction({
    required this.amount,
    required this.type,
    this.category,
    this.subCategory,
    required this.date,
    this.note,
    this.accountHint,
    this.splitCount,
  });

  factory _EditableTransaction.fromParsed(ParsedTransaction pt) {
    return _EditableTransaction(
      amount: pt.amount,
      type: pt.type,
      category: pt.category,
      subCategory: pt.subCategory,
      date: pt.date,
      note: pt.note,
      accountHint: pt.accountHint,
      splitCount: pt.splitCount,
    );
  }

  String? get categoryPath {
    final parent = category?.trim() ?? '';
    final child = subCategory?.trim() ?? '';
    if (parent.isEmpty && child.isEmpty) return null;
    if (parent.isEmpty) return child;
    if (child.isEmpty || child == parent) return parent;
    return '$parent / $child';
  }
}

// ----- Transaction preview card -----

class _TransactionCard extends StatelessWidget {
  final _EditableTransaction transaction;
  final VoidCallback onSave;
  final VoidCallback onChanged;

  const _TransactionCard({
    required this.transaction,
    required this.onSave,
    required this.onChanged,
  });

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

  Color _typeColor(String type, ColorScheme cs) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      default:
        return cs.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tx = transaction;
    final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: tx.saved ? 0 : 1,
      color: tx.saved ? cs.surfaceContainerHighest.withAlpha(128) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: amount + type badge.
            Row(
              children: [
                Text(
                  '${tx.amount.toStringAsFixed(tx.amount == tx.amount.roundToDouble() ? 0 : 2)} 元',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _typeColor(tx.type, cs),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor(tx.type, cs).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _typeLabel(tx.type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _typeColor(tx.type, cs),
                    ),
                  ),
                ),
                if (tx.splitCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AA ${tx.splitCount}人',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (tx.saved)
                  Icon(Icons.check_circle, color: cs.primary, size: 20)
                else
                  TextButton(onPressed: onSave, child: const Text('确认')),
              ],
            ),
            const SizedBox(height: 8),
            // Detail chips.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _infoChip(Icons.calendar_today, dateStr, theme),
                if (tx.categoryPath != null)
                  _infoChip(Icons.category, tx.categoryPath!, theme),
                if (tx.note != null && tx.note!.isNotEmpty)
                  _infoChip(Icons.notes, tx.note!, theme),
                if (tx.accountHint != null)
                  _infoChip(
                    Icons.account_balance_wallet,
                    tx.accountHint!,
                    theme,
                  ),
              ],
            ),
            // Editable fields.
            if (!tx.saved) ...[const Divider(height: 20), _editRow(context)],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withAlpha(153)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _editRow(BuildContext context) {
    return Row(
      children: [
        // Editable amount.
        Expanded(
          child: _MiniField(
            label: '金额',
            value: transaction.amount.toStringAsFixed(
              transaction.amount == transaction.amount.roundToDouble() ? 0 : 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed > 0) {
                transaction.amount = parsed;
                onChanged();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // Editable category.
        Expanded(
          child: _MiniField(
            label: '分类',
            value: transaction.category ?? '',
            onChanged: (v) {
              transaction.category = v.isEmpty ? null : v;
              transaction.subCategory = null;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        // Editable note.
        Expanded(
          flex: 2,
          child: _MiniField(
            label: '备注',
            value: transaction.note ?? '',
            onChanged: (v) {
              transaction.note = v.isEmpty ? null : v;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}

// ----- Mini inline edit field -----

class _MiniField extends StatefulWidget {
  final String label;
  final String value;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _MiniField({
    required this.label,
    required this.value,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  State<_MiniField> createState() => _MiniFieldState();
}

class _MiniFieldState extends State<_MiniField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_MiniField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: widget.keyboardType,
      style: Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
