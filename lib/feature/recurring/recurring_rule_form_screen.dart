import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/recurring_rule_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/account_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/recurring_service.dart';
import '../../core/service/tag_service.dart';
import '../category/category_picker_screen.dart';
import '../category/category_search_delegate.dart';
import '../tag/tag_picker_sheet.dart';

class RecurringRuleSaveResult {
  const RecurringRuleSaveResult({
    required this.saved,
    required this.generatedDrafts,
    required this.committedTransactions,
    this.processingError,
  });

  final bool saved;
  final int generatedDrafts;
  final int committedTransactions;
  final String? processingError;
}

class RecurringRuleFormScreen extends StatefulWidget {
  final JiveRecurringRule? editingRule;

  const RecurringRuleFormScreen({super.key, this.editingRule});

  @override
  State<RecurringRuleFormScreen> createState() =>
      _RecurringRuleFormScreenState();
}

class _RecurringRuleFormScreenState extends State<RecurringRuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _intervalValueController = TextEditingController(text: '1');
  final _dayOfMonthController = TextEditingController();

  Isar? _isar;
  List<JiveAccount> _accounts = [];
  List<JiveTag> _tags = [];
  List<_CategoryOption> _categories = [];

  String _type = 'expense';
  String _intervalType = 'month';
  String _commitMode = 'draft';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _accountId;
  int? _toAccountId;
  String? _categoryKey;
  String? _subCategoryKey;
  List<String> _tagKeys = [];
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    final editing = widget.editingRule;
    if (editing != null) {
      _nameController.text = editing.name;
      _amountController.text = editing.amount.toStringAsFixed(2);
      _intervalValueController.text = editing.intervalValue.toString();
      _dayOfMonthController.text = editing.dayOfMonth?.toString() ?? '';
      _type = editing.type;
      _intervalType = editing.intervalType;
      _commitMode = editing.commitMode;
      _startDate = editing.startDate;
      _endDate = editing.endDate;
      _accountId = editing.accountId;
      _toAccountId = editing.toAccountId;
      _categoryKey = editing.categoryKey;
      _subCategoryKey = editing.subCategoryKey;
      _tagKeys = List<String>.from(editing.tagKeys);
      _isActive = editing.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _intervalValueController.dispose();
    _dayOfMonthController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isar = await _ensureIsar();
    final accounts = await AccountService(isar).getActiveAccounts();
    final tags = await TagService(isar).getTags(includeArchived: false);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final options = _buildCategoryOptions(categories);
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _tags = tags;
      _categories = options;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  List<_CategoryOption> _buildCategoryOptions(List<JiveCategory> categories) {
    final parents =
        categories.where((c) => c.parentKey == null && !c.isHidden).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final children =
        categories.where((c) => c.parentKey != null && !c.isHidden).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final options = <_CategoryOption>[];
    for (final parent in parents) {
      options.add(
        _CategoryOption(
          key: parent.key,
          name: parent.name,
          isIncome: parent.isIncome,
        ),
      );
      for (final child in children.where((c) => c.parentKey == parent.key)) {
        options.add(
          _CategoryOption(
            key: child.key,
            name: child.name,
            isIncome: child.isIncome,
            parentKey: parent.key,
            parentName: parent.name,
          ),
        );
      }
    }
    return options;
  }

  Future<void> _pickTags() async {
    if (_tags.isEmpty) {
      await _loadData();
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return TagPickerSheet(
          tags: _tags,
          selectedKeys: _tagKeys,
          onCreateTag: (name) async {
            final created = await TagService(_isar!).createTag(name: name);
            await _loadData();
            return created;
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _tagKeys = selected;
    });
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => _endDate = date);
  }

  Future<void> _pickCategory() async {
    if (_type == 'transfer') return;
    if (_categories.isEmpty) {
      await _loadData();
    }
    final isar = await _ensureIsar();
    if (!mounted) return;
    final picked = await Navigator.push<CategorySearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(
          isIncome: _type == 'income',
          isar: isar,
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _categoryKey = picked.parent.key;
      _subCategoryKey = picked.sub?.key;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showMessage('金额必须大于0');
      return;
    }
    final intervalValue =
        int.tryParse(_intervalValueController.text.trim()) ?? 1;
    if (intervalValue <= 0) {
      _showMessage('间隔必须大于0');
      return;
    }
    if (_type == 'transfer' &&
        (_accountId == null ||
            _toAccountId == null ||
            _accountId == _toAccountId)) {
      _showMessage('转账需要选择不同的转出/转入账户');
      return;
    }
    if (_type != 'transfer') {
      final option = _categoryOptionByKey(_subCategoryKey ?? _categoryKey);
      if (option == null) {
        _showMessage('请选择分类');
        return;
      }
      final shouldBeIncome = _type == 'income';
      if (option.isIncome != shouldBeIncome) {
        _showMessage('分类与类型不一致');
        return;
      }
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }
    try {
      final isar = await _ensureIsar();
      final service = RecurringService(isar);

      if (widget.editingRule == null) {
        final rule = JiveRecurringRule()
          ..name = _nameController.text.trim()
          ..type = _type
          ..amount = amount
          ..accountId = _accountId
          ..toAccountId = _type == 'transfer' ? _toAccountId : null
          ..categoryKey = _type == 'transfer' ? null : _categoryKey
          ..subCategoryKey = _type == 'transfer' ? null : _subCategoryKey
          ..note = null
          ..tagKeys = List<String>.from(_tagKeys)
          ..projectId = null
          ..commitMode = _commitMode
          ..startDate = _startDate
          ..endDate = _endDate
          ..intervalType = _intervalType
          ..intervalValue = intervalValue
          ..dayOfMonth = _parseDayOfMonth()
          ..dayOfWeek = null
          ..nextRunAt = _startDate
          ..isActive = _isActive
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await service.createRule(rule);
      } else {
        final rule = widget.editingRule!
          ..name = _nameController.text.trim()
          ..type = _type
          ..amount = amount
          ..accountId = _accountId
          ..toAccountId = _type == 'transfer' ? _toAccountId : null
          ..categoryKey = _type == 'transfer' ? null : _categoryKey
          ..subCategoryKey = _type == 'transfer' ? null : _subCategoryKey
          ..tagKeys = List<String>.from(_tagKeys)
          ..commitMode = _commitMode
          ..startDate = _startDate
          ..endDate = _endDate
          ..intervalType = _intervalType
          ..intervalValue = intervalValue
          ..dayOfMonth = _parseDayOfMonth()
          ..isActive = _isActive
          ..updatedAt = DateTime.now();
        await service.updateRule(rule);
      }

      int generatedDrafts = 0;
      int committedTransactions = 0;
      String? processingError;
      try {
        final processResult = await service.processDueRules();
        generatedDrafts = processResult.generatedDrafts;
        committedTransactions = processResult.committedTransactions;
      } catch (e) {
        processingError = e.toString();
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        RecurringRuleSaveResult(
          saved: true,
          generatedDrafts: generatedDrafts,
          committedTransactions: committedTransactions,
          processingError: processingError,
        ),
      );
    } catch (e) {
      _showMessage('保存失败：$e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int? _parseDayOfMonth() {
    if (_intervalType != 'month' && _intervalType != 'year') return null;
    final value = int.tryParse(_dayOfMonthController.text.trim());
    return value;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingRule != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '编辑周期规则' : '新建周期规则',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '规则名称'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入名称' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('支出')),
                    DropdownMenuItem(value: 'income', child: Text('收入')),
                    DropdownMenuItem(value: 'transfer', child: Text('转账')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                      if (_type == 'transfer') {
                        _categoryKey = null;
                        _subCategoryKey = null;
                      } else if (!_categoryMatchesType()) {
                        _categoryKey = null;
                        _subCategoryKey = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: '金额'),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) return '请输入有效金额';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: '账户'),
                  items: _accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _accountId = value;
                    if (_toAccountId == value) _toAccountId = null;
                  }),
                  validator: (value) => value == null ? '请选择账户' : null,
                ),
                if (_type == 'transfer')
                  DropdownButtonFormField<int>(
                    initialValue: _toAccountId,
                    decoration: const InputDecoration(labelText: '转入账户'),
                    items: _accounts
                        .where((account) => account.id != _accountId)
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _toAccountId = value),
                    validator: (value) {
                      if (_type != 'transfer') return null;
                      if (value == null) return '请选择转入账户';
                      if (_accountId != null && value == _accountId) {
                        return '转入账户不能与转出账户相同';
                      }
                      return null;
                    },
                  ),
                if (_type != 'transfer')
                  FormField<_CategoryOption>(
                    validator: (_) {
                      if (_type == 'transfer') return null;
                      final option = _categoryOptionByKey(_subCategoryKey ?? _categoryKey);
                      if (option == null) return '请选择分类';
                      final shouldBeIncome = _type == 'income';
                      if (option.isIncome != shouldBeIncome) return '分类与类型不一致';
                      return null;
                    },
                    builder: (field) {
                      final selected = _categoryOptionByKey(_subCategoryKey ?? _categoryKey);
                      final label = selected?.displayName() ?? '请选择分类';
                      return InkWell(
                        onTap: () async {
                          await _pickCategory();
                          if (!mounted) return;
                          field.didChange(_categoryOptionByKey(_subCategoryKey ?? _categoryKey));
                          field.validate();
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '分类',
                            errorText: field.errorText,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selected == null ? Colors.black38 : Colors.black87,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('标签'),
                  subtitle: Text(
                    _tagKeys.isEmpty ? '无' : '已选择 ${_tagKeys.length} 个标签',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTags,
                ),
                const Divider(height: 32),
                Text(
                  '周期设置',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _intervalType,
                  decoration: const InputDecoration(labelText: '周期类型'),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('按天')),
                    DropdownMenuItem(value: 'week', child: Text('按周')),
                    DropdownMenuItem(value: 'month', child: Text('按月')),
                    DropdownMenuItem(value: 'year', child: Text('按年')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _intervalType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _intervalValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '间隔'),
                  validator: (value) {
                    final interval = int.tryParse((value ?? '').trim());
                    if (interval == null || interval <= 0) return '间隔必须大于0';
                    return null;
                  },
                ),
                if (_intervalType == 'month' || _intervalType == 'year')
                  TextFormField(
                    controller: _dayOfMonthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '每月日期（可选）'),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return null;
                      final day = int.tryParse(text);
                      if (day == null || day < 1 || day > 31) return '日期需在1-31';
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开始日期'),
                  subtitle: Text(_formatDate(_startDate)),
                  trailing: const Icon(Icons.date_range),
                  onTap: _pickStartDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('结束日期（可选）'),
                  subtitle: Text(
                    _endDate == null ? '无' : _formatDate(_endDate!),
                  ),
                  trailing: const Icon(Icons.date_range),
                  onTap: _pickEndDate,
                ),
                const Divider(height: 32),
                Text(
                  '生成方式',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: _commitMode,
                  onChanged: (value) =>
                      setState(() => _commitMode = value ?? 'draft'),
                  child: Column(
                    children: const [
                      RadioListTile<String>(
                        value: 'draft',
                        title: Text('生成草稿'),
                      ),
                      RadioListTile<String>(
                        value: 'commit',
                        title: Text('直接入账'),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用规则'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
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
                          isEditing ? '保存修改' : '创建规则',
                          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CategoryOption? _categoryOptionByKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final option in _categories) {
      if (option.key == key) return option;
    }
    return null;
  }

  bool _categoryMatchesType() {
    if (_type == 'transfer') return true;
    final option = _categoryOptionByKey(_subCategoryKey ?? _categoryKey);
    if (option == null) return false;
    return _type == 'income' ? option.isIncome : !option.isIncome;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _CategoryOption {
  final String key;
  final String name;
  final bool isIncome;
  final String? parentKey;
  final String? parentName;

  _CategoryOption({
    required this.key,
    required this.name,
    required this.isIncome,
    this.parentKey,
    this.parentName,
  });

  String displayName() {
    if (parentName != null) return '$parentName · $name';
    return name;
  }
}
