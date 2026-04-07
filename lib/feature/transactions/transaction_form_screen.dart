import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/category_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../tag/tag_picker_sheet.dart';
import 'transaction_entry_params.dart';
import 'widgets/transaction_amount_display.dart';
import 'widgets/transaction_source_banner.dart';
import 'widgets/transaction_core_fields.dart';
import 'widgets/transaction_advanced_section.dart';
import 'widgets/transaction_footer_bar.dart';

/// Form-based transaction editor (完整编辑页).
///
/// An alternative to [AddTransactionScreen] (the calculator-based quick entry),
/// this screen provides a structured form layout using extracted S6 widgets.
/// Best suited for entries from voice, quick actions, deep links, and editing.
class TransactionFormScreen extends StatefulWidget {
  final TransactionEntryParams params;

  const TransactionFormScreen({super.key, required this.params});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late Isar _isar;
  bool _isLoading = true;
  bool _advancedExpanded = false;
  bool _continuousMode = false;
  bool _hasDataChanges = false;

  // Transaction state
  String _txType = 'expense';
  double _amount = 0;
  DateTime _selectedDate = DateTime.now();
  String _note = '';
  bool _excludeFromBudget = false;

  // Selections
  JiveCategory? _selectedCategory;
  JiveAccount? _selectedAccount;
  List<String> _selectedTagKeys = [];
  int? _selectedProjectId;

  // Loaded data
  List<JiveCategory> _categories = [];
  List<JiveAccount> _accounts = [];
  List<JiveTag> _tags = [];
  List<JiveProject> _projects = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();

    final categories = _isar.jiveCategorys.where().findAllSync();
    final accounts = _isar.jiveAccounts.where().findAllSync();
    final tags = _isar.jiveTags.where().findAllSync();
    final projects = _isar.jiveProjects.where().findAllSync();

    // Apply prefills from params
    final p = widget.params;
    if (p.prefillType != null) _txType = p.prefillType!;
    if (p.prefillAmount != null) _amount = p.prefillAmount!;
    if (p.prefillDate != null) _selectedDate = p.prefillDate!;
    if (p.prefillNote != null) _note = p.prefillNote!;
    if (p.prefillTagKeys != null) _selectedTagKeys = List.of(p.prefillTagKeys!);

    if (p.prefillCategoryKey != null) {
      _selectedCategory = categories
          .where((c) => c.key == p.prefillCategoryKey)
          .firstOrNull;
    }
    if (p.prefillAccountId != null) {
      _selectedAccount =
          accounts.where((a) => a.id == p.prefillAccountId).firstOrNull;
    }

    // For edit mode, populate from existing transaction
    if (p.editingTransaction != null) {
      final tx = p.editingTransaction!;
      _amount = tx.amount;
      _selectedDate = tx.timestamp;
      _note = tx.note ?? '';
      _excludeFromBudget = tx.excludeFromBudget;
      _txType = tx.type ?? 'expense';
      _selectedCategory =
          categories.where((c) => c.key == tx.categoryKey).firstOrNull;
      _selectedAccount =
          accounts.where((a) => a.id == tx.accountId).firstOrNull;
      _selectedTagKeys = List.of(tx.tagKeys);
      _selectedProjectId = tx.projectId;
    }

    setState(() {
      _categories = categories;
      _accounts = accounts;
      _tags = tags;
      _projects = projects;
      _isLoading = false;
    });
  }

  List<String> get _selectedTagNames {
    return _selectedTagKeys
        .map((key) => _tags.where((t) => t.key == key).firstOrNull?.name)
        .whereType<String>()
        .toList();
  }

  String? get _selectedProjectName {
    if (_selectedProjectId == null) return null;
    return _projects
        .where((p) => p.id == _selectedProjectId)
        .firstOrNull
        ?.name;
  }

  Future<void> _save({bool andNew = false}) async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }

    final tx = widget.params.editingTransaction ?? JiveTransaction();
    tx.amount = _amount;
    tx.timestamp = _selectedDate;
    tx.source = 'manual';
    tx.note = _note.isEmpty ? null : _note;
    tx.categoryKey = _selectedCategory?.key;
    tx.category = _selectedCategory?.name;
    tx.accountId = _selectedAccount?.id;
    tx.excludeFromBudget = _excludeFromBudget;
    tx.tagKeys = _selectedTagKeys;
    tx.projectId = _selectedProjectId;
    tx.type = _txType;
    tx.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTransactions.put(tx);
    });

    _hasDataChanges = true;
    DataReloadBus.notify();

    if (!mounted) return;

    if (andNew || _continuousMode) {
      setState(() {
        _amount = 0;
        _note = '';
        _selectedCategory = null;
        _selectedTagKeys = [];
        _selectedProjectId = null;
        _excludeFromBudget = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  void _showAmountInput() async {
    final controller = TextEditingController(
      text: _amount > 0 ? _amount.toString() : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入金额'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixText: '¥ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              Navigator.pop(ctx, val);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _amount = result);
    }
  }

  void _showCategoryPicker() async {
    final isIncome = _txType == 'income';
    final filtered = _categories
        .where((c) => c.isIncome == isIncome && !c.isHidden)
        .where((c) => c.parentKey == null) // only top-level
        .toList();

    final result = await showModalBottomSheet<JiveCategory>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择分类',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final cat = filtered[i];
                  final isSelected = cat.key == _selectedCategory?.key;
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, cat),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(ctx).colorScheme.primary,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CategoryService.buildIcon(
                            cat.iconName,
                            size: 24,
                            isSystemCategory: cat.isSystem,
                            forceTinted: cat.iconForceTinted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
    }
  }

  void _showAccountPicker() async {
    final result = await showModalBottomSheet<JiveAccount>(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        itemBuilder: (_, i) {
          final acct = _accounts[i];
          final isSelected = acct.id == _selectedAccount?.id;
          return ListTile(
            leading: Icon(
              Icons.account_balance_wallet,
              color: isSelected ? Theme.of(ctx).colorScheme.primary : null,
            ),
            title: Text(acct.name),
            subtitle: Text(acct.currency),
            selected: isSelected,
            onTap: () => Navigator.pop(ctx, acct),
          );
        },
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedAccount = result);
    }
  }

  void _showNoteInput() async {
    final controller = TextEditingController(text: _note);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('备注'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '添加备注...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _note = result);
    }
  }

  void _showTagPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TagPickerSheet(
        tags: _tags,
        selectedKeys: _selectedTagKeys,
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedTagKeys = result);
    }
  }

  void _showProjectPicker() async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('无项目'),
            onTap: () => Navigator.pop(ctx, -1),
          ),
          for (final project in _projects)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(project.name),
              selected: project.id == _selectedProjectId,
              onTap: () => Navigator.pop(ctx, project.id),
            ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedProjectId = result == -1 ? null : result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final params = widget.params;
    final amountStr =
        _amount > 0 ? _amount.toStringAsFixed(2) : '0.00';
    final currency =
        CurrencyDefaults.getSymbol(_selectedAccount?.currency ?? 'CNY');

    return Scaffold(
      appBar: AppBar(
        title: Text(params.pageTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, _hasDataChanges),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source banner
                  TransactionSourceBanner(params: params),
                  if (params.sourceBannerText != null)
                    const SizedBox(height: 12),

                  // Type selector
                  _TypeSelector(
                    currentType: _txType,
                    onChanged: (t) => setState(() => _txType = t),
                  ),
                  const SizedBox(height: 16),

                  // Amount display (tappable)
                  GestureDetector(
                    onTap: _showAmountInput,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TransactionAmountDisplay(
                        amountStr: amountStr,
                        currencySymbol: currency,
                        transactionType: _txType,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Core fields card
                  TransactionCoreFields(
                    categoryName: _selectedCategory?.name,
                    accountName: _selectedAccount?.name,
                    note: _note.isEmpty ? null : _note,
                    date: _selectedDate,
                    onCategoryTap: _showCategoryPicker,
                    onAccountTap: _showAccountPicker,
                    onNoteTap: _showNoteInput,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Advanced section
                  TransactionAdvancedSection(
                    isExpanded: _advancedExpanded,
                    onToggle: () =>
                        setState(() => _advancedExpanded = !_advancedExpanded),
                    tagNames: _selectedTagNames,
                    projectName: _selectedProjectName,
                    isExcludedFromBudget: _excludeFromBudget,
                    onTagsTap: _showTagPicker,
                    onProjectTap: _showProjectPicker,
                    onBudgetExclusionChanged: (v) =>
                        setState(() => _excludeFromBudget = v),
                  ),
                ],
              ),
            ),
          ),

          // Footer bar
          TransactionFooterBar(
            source: params.source,
            transactionType: _txType,
            isContinuousMode: _continuousMode,
            onToggleContinuous: () =>
                setState(() => _continuousMode = !_continuousMode),
            enabled: _amount > 0,
            onSave: () => _save(),
            onSaveAndNew: () => _save(andNew: true),
          ),
        ],
      ),
    );
  }
}

/// Segmented type selector for expense/income/transfer.
class _TypeSelector extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.currentType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'expense',
          label: Text('支出'),
          icon: Icon(Icons.arrow_upward, size: 16),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('收入'),
          icon: Icon(Icons.arrow_downward, size: 16),
        ),
        ButtonSegment(
          value: 'transfer',
          label: Text('转账'),
          icon: Icon(Icons.swap_horiz, size: 16),
        ),
      ],
      selected: {currentType},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}
