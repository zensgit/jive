import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import 'date_range_picker_sheet.dart';

class TransactionFilterSheet extends StatefulWidget {
  final List<JiveCategory> categories;
  final List<JiveAccount> accounts;
  final String? initialCategoryKey;
  final int? initialAccountId;
  final String? initialTag;
  final DateTimeRange? initialDateRange;
  final void Function(
    String? categoryKey,
    int? accountId,
    String? tag,
    DateTimeRange? dateRange,
  ) onChanged;
  final VoidCallback onClear;
  final String title;
  final String hint;
  final String categoryLabel;
  final String accountLabel;
  final String tagLabel;
  final String dateRangeLabel;
  final bool showDateRange;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Set<int>? enabledYears;

  const TransactionFilterSheet({
    super.key,
    required this.categories,
    required this.accounts,
    required this.initialCategoryKey,
    required this.initialAccountId,
    required this.initialTag,
    required this.initialDateRange,
    required this.onChanged,
    required this.onClear,
    this.title = '查找账单（按条件）',
    this.hint = '选择即生效',
    this.categoryLabel = '分类',
    this.accountLabel = '账户',
    this.tagLabel = '标签（备注中的词）',
    this.dateRangeLabel = '日期范围',
    this.showDateRange = true,
    this.minDate,
    this.maxDate,
    this.enabledYears,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  String? _categoryKey;
  int? _accountId;
  late final TextEditingController _tagController;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _categoryKey = widget.initialCategoryKey;
    _accountId = widget.initialAccountId;
    _tagController = TextEditingController(text: widget.initialTag ?? '');
    _dateRange = widget.initialDateRange;
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final tag = _tagController.text.trim();
    widget.onChanged(
      _categoryKey,
      _accountId,
      tag.isEmpty ? null : tag,
      _dateRange,
    );
  }

  void _handleClear() {
    setState(() {
      _categoryKey = null;
      _accountId = null;
      _tagController.clear();
      _dateRange = null;
    });
    widget.onClear();
  }

  String _formatRange(DateTimeRange range) {
    final start = '${range.start.year}-${_two(range.start.month)}-${_two(range.start.day)}';
    final end = '${range.end.year}-${_two(range.end.month)}-${_two(range.end.day)}';
    return '$start - $end';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _pickDateRange() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DateRangePickerSheet(
          initialRange: _dateRange,
          firstDay: widget.minDate,
          lastDay: widget.maxDate,
          enabledYears: widget.enabledYears,
          onChanged: (range) {
            setState(() => _dateRange = range);
            _notifyChange();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ],
            ),
            if (widget.hint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.hint,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.showDateRange) ...[
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.dateRangeLabel,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateRange == null ? '不限' : _formatRange(_dateRange!),
                          style: GoogleFonts.lato(fontSize: 13),
                        ),
                      ),
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<String?>(
              value: _categoryKey,
              decoration: InputDecoration(
                labelText: widget.categoryLabel,
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('全部分类'),
                ),
                ...widget.categories.map((category) {
                  final label = category.parentKey == null
                      ? category.name
                      : '  └ ${category.name}';
                  return DropdownMenuItem<String?>(
                    value: category.key,
                    child: Text(label),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _categoryKey = value);
                _notifyChange();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              value: _accountId,
              decoration: InputDecoration(
                labelText: widget.accountLabel,
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('全部账户'),
                ),
                ...widget.accounts.map((account) {
                  return DropdownMenuItem<int?>(
                    value: account.id,
                    child: Text(account.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _accountId = value);
                _notifyChange();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: widget.tagLabel,
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleClear,
                    child: const Text('清除'),
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
