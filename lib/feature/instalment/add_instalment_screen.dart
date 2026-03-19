import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/instalment_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/instalment_service.dart';
import '../../core/widgets/jive_calendar/jive_calendar.dart';
import '../category/category_picker_screen.dart';
import '../category/category_search_delegate.dart';

class AddInstalmentScreen extends StatefulWidget {
  const AddInstalmentScreen({super.key, this.editingInstalment});

  final JiveInstalment? editingInstalment;

  @override
  State<AddInstalmentScreen> createState() => _AddInstalmentScreenState();
}

class _AddInstalmentScreenState extends State<AddInstalmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _instalmentCountController = TextEditingController(text: '12');
  final _noteController = TextEditingController();

  Isar? _isar;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  DateTime _startDate = DateTime.now();
  int? _accountId;
  String? _categoryKey;
  List<JiveAccount> _accounts = [];
  List<JiveCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    final editing = widget.editingInstalment;
    if (editing != null) {
      _nameController.text = editing.name;
      _totalAmountController.text = editing.totalAmount.toStringAsFixed(2);
      _instalmentCountController.text = editing.instalmentCount.toString();
      _noteController.text = editing.note ?? '';
      _startDate = editing.startDate;
      _accountId = editing.accountId;
      _categoryKey = editing.categoryKey;
    }
    _totalAmountController.addListener(_onAmountChanged);
    _instalmentCountController.addListener(_onAmountChanged);
    _loadData();
  }

  @override
  void dispose() {
    _totalAmountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    _nameController.dispose();
    _instalmentCountController
      ..removeListener(_onAmountChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final isar = await _ensureIsar();
      final accounts = await AccountService(isar).getActiveAccounts();
      final categories = await isar.collection<JiveCategory>().where().findAll();
      final filteredCategories = categories
          .where((category) => !category.isHidden && !category.isIncome)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final hasSelectedAccount = _accountId != null &&
          accounts.any((account) => account.id == _accountId);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _categories = filteredCategories;
        if (!hasSelectedAccount) {
          _accountId = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '加载分期表单失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  void _onAmountChanged() {
    if (!mounted) return;
    setState(() {});
  }

  double? get _calculatedMonthlyAmount {
    final total = double.tryParse(_totalAmountController.text.trim());
    final count = int.tryParse(_instalmentCountController.text.trim());
    if (total == null || total <= 0 || count == null || count <= 0) {
      return null;
    }
    return total / count;
  }

  Future<void> _pickStartDate() async {
    final result = await JiveDatePicker.pickDateResult(
      context,
      initialDay: _startDate,
      firstDay: DateTime(2010),
      lastDay: DateTime(2100),
      bottomLabel: '选择首期日期',
    );
    if (!mounted) return;
    final picked = result.value;
    if (!result.didChange || picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickCategory() async {
    final isar = await _ensureIsar();
    if (!mounted) return;
    final picked = await Navigator.push<CategorySearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(
          isIncome: false,
          isar: isar,
          title: '选择分期分类',
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _categoryKey = picked.sub?.key ?? picked.parent.key;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = double.tryParse(_totalAmountController.text.trim());
    final instalmentCount = int.tryParse(_instalmentCountController.text.trim());
    if (totalAmount == null || totalAmount <= 0) {
      _showMessage('请输入有效总金额');
      return;
    }
    if (instalmentCount == null || instalmentCount <= 0) {
      _showMessage('请输入有效期数');
      return;
    }
    if (_accountId == null) {
      _showMessage('请选择扣款账户');
      return;
    }
    if (_categoryKey == null || _categoryKey!.isEmpty) {
      _showMessage('请选择分类');
      return;
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }
    try {
      final isar = await _ensureIsar();
      final service = InstalmentService(isar);
      final editing = widget.editingInstalment;
      final monthlyAmount = totalAmount / instalmentCount;
      final paidCount = editing?.paidCount ?? 0;
      final status = editing?.status ?? 'active';
      final nextPaymentDate = _advanceMonths(_startDate, paidCount);

      if (editing == null) {
        final instalment = JiveInstalment()
          ..name = _nameController.text.trim()
          ..totalAmount = totalAmount
          ..instalmentCount = instalmentCount
          ..paidCount = 0
          ..monthlyAmount = monthlyAmount
          ..startDate = _startDate
          ..nextPaymentDate = _startDate
          ..accountId = _accountId
          ..categoryKey = _categoryKey
          ..note = _noteController.text.trim()
          ..status = 'active'
          ..createdAt = DateTime.now();
        await service.create(instalment);
      } else {
        final instalment = editing
          ..name = _nameController.text.trim()
          ..totalAmount = totalAmount
          ..instalmentCount = instalmentCount
          ..paidCount = paidCount
          ..monthlyAmount = monthlyAmount
          ..startDate = _startDate
          ..nextPaymentDate = nextPaymentDate
          ..accountId = _accountId
          ..categoryKey = _categoryKey
          ..note = _noteController.text.trim()
          ..status = status;
        await service.update(instalment);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('保存失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  DateTime _advanceMonths(DateTime from, int months) {
    if (months <= 0) return from;
    final targetMonth = from.month + months;
    final targetYear = from.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(
      targetYear,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingInstalment != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '编辑分期' : '新增分期',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildLoadErrorState()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: '分期名称'),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? '请输入分期名称'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _totalAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: '总金额'),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').trim());
                          if (amount == null || amount <= 0) {
                            return '请输入有效总金额';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instalmentCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '分期期数'),
                        validator: (value) {
                          final count = int.tryParse((value ?? '').trim());
                          if (count == null || count <= 0) {
                            return '请输入有效期数';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMonthlyAmountCard(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _accountId,
                        decoration: const InputDecoration(labelText: '扣款账户'),
                        items: _accounts
                            .map(
                              (account) => DropdownMenuItem(
                                value: account.id,
                                child: Text(account.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _accountId = value),
                        validator: (value) => value == null ? '请选择扣款账户' : null,
                      ),
                      const SizedBox(height: 12),
                      FormField<String>(
                        validator: (_) =>
                            _categoryKey == null || _categoryKey!.isEmpty
                            ? '请选择分类'
                            : null,
                        builder: (field) {
                          final selected = _buildSelectedCategoryInfo();
                          final label = selected?.label ?? '请选择分类';
                          final resolvedColor = selected?.color;
                          final leading = selected == null
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.category_outlined,
                                    size: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 14,
                                  backgroundColor: resolvedColor!.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: CategoryService.buildIcon(
                                    selected.iconName,
                                    size: 18,
                                    color: resolvedColor,
                                    isSystemCategory: selected.isSystem,
                                    forceTinted: selected.forceTinted,
                                  ),
                                );
                          return InkWell(
                            onTap: () async {
                              await _pickCategory();
                              if (!mounted) return;
                              field.didChange(_categoryKey);
                              field.validate();
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: '分类',
                                errorText: field.errorText,
                              ),
                              child: Row(
                                children: [
                                  leading,
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected == null
                                            ? Colors.black38
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade500,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('首期日期'),
                        subtitle: Text(_formatDate(_startDate)),
                        trailing: const Icon(Icons.date_range_outlined),
                        onTap: _pickStartDate,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: '备注',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: JiveTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? '保存修改' : '创建分期',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              '分期表单加载失败',
              style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyAmountCard() {
    final monthlyAmount = _calculatedMonthlyAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '每期应还',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            monthlyAmount == null ? '请先填写金额和期数' : '¥${monthlyAmount.toStringAsFixed(2)}',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: JiveTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  _SelectedCategoryInfo? _buildSelectedCategoryInfo() {
    final selectedKey = _categoryKey;
    if (selectedKey == null || selectedKey.isEmpty) return null;

    JiveCategory? selected;
    JiveCategory? parent;
    for (final category in _categories) {
      if (category.key == selectedKey) {
        selected = category;
        break;
      }
    }
    if (selected == null) return null;

    if (selected.parentKey == null) {
      parent = selected;
    } else {
      for (final category in _categories) {
        if (category.key == selected.parentKey) {
          parent = category;
          break;
        }
      }
    }

    return _SelectedCategoryInfo(
      label: selected.parentKey == null
          ? selected.name
          : '${parent?.name ?? '分类'} / ${selected.name}',
      iconName: selected.iconName,
      color:
          CategoryService.parseColorHex(selected.colorHex) ??
          JiveTheme.categoryIconInactive,
      isSystem: selected.isSystem,
      forceTinted: selected.iconForceTinted,
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class _SelectedCategoryInfo {
  const _SelectedCategoryInfo({
    required this.label,
    required this.iconName,
    required this.color,
    required this.isSystem,
    required this.forceTinted,
  });

  final String label;
  final String iconName;
  final Color color;
  final bool isSystem;
  final bool forceTinted;
}
