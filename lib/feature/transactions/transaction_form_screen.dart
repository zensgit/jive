import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/category_service.dart';
import '../../core/service/category_path_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/service/template_service.dart';
import '../../core/repository/transaction_repository.dart';
import '../../core/repository/isar_transaction_repository.dart';
import '../tag/tag_picker_sheet.dart';
import '../template/widgets/save_template_dialog.dart';
import 'transaction_entry_params.dart';
import 'widgets/transaction_amount_display.dart';
import 'widgets/transaction_source_banner.dart';
import 'widgets/transaction_core_fields.dart';
import 'widgets/transaction_advanced_section.dart';
import 'widgets/transaction_footer_bar.dart';
import 'widgets/quick_action_suggest_bar.dart';

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
  late TransactionRepository _transactionRepo;
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
  JiveAccount? _selectedToAccount;
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
    _transactionRepo = IsarTransactionRepository(_isar);

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

    if (p.prefillCategoryKey != null || p.prefillSubCategoryKey != null) {
      final key = p.prefillSubCategoryKey ?? p.prefillCategoryKey;
      _selectedCategory = categories
          .where((c) => c.key == key || c.name == key)
          .firstOrNull;
    }
    if (p.prefillAccountId != null) {
      _selectedAccount = accounts
          .where((a) => a.id == p.prefillAccountId)
          .firstOrNull;
    }
    if (p.prefillToAccountId != null) {
      _selectedToAccount = accounts
          .where((a) => a.id == p.prefillToAccountId)
          .firstOrNull;
    }

    // For edit mode, populate from existing transaction
    if (p.editingTransaction != null) {
      final tx = p.editingTransaction!;
      _amount = tx.amount;
      _selectedDate = tx.timestamp;
      _note = tx.note ?? '';
      _excludeFromBudget = tx.excludeFromBudget;
      _txType = tx.type ?? 'expense';
      _selectedCategory = categories
          .where((c) => c.key == (tx.subCategoryKey ?? tx.categoryKey))
          .firstOrNull;
      _selectedAccount = accounts
          .where((a) => a.id == tx.accountId)
          .firstOrNull;
      _selectedToAccount = accounts
          .where((a) => a.id == tx.toAccountId)
          .firstOrNull;
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
    return _projects.where((p) => p.id == _selectedProjectId).firstOrNull?.name;
  }

  Future<void> _save({bool andNew = false}) async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择账户')));
      return;
    }
    if (_txType == 'transfer') {
      if (_selectedToAccount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择转入账户')));
        return;
      }
      if (_selectedToAccount?.id == _selectedAccount?.id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('转出和转入账户不能相同')));
        return;
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    final categoryKeys = const CategoryPathService().toTransactionKeys(
      _categories,
      _selectedCategory,
    );
    final tx = widget.params.editingTransaction ?? JiveTransaction();
    tx.amount = _amount;
    tx.timestamp = _selectedDate;
    tx.source = _sourceStorageValue(widget.params.source, existing: tx.source);
    tx.note = _note.isEmpty ? null : _note;
    tx.rawText = widget.params.prefillRawText ?? tx.rawText;
    tx.categoryKey = _txType == 'transfer' ? null : categoryKeys.categoryKey;
    tx.subCategoryKey = _txType == 'transfer'
        ? null
        : categoryKeys.subCategoryKey;
    tx.category = _txType == 'transfer' ? '转账' : categoryKeys.categoryName;
    tx.subCategory = _txType == 'transfer'
        ? null
        : categoryKeys.subCategoryName;
    tx.accountId = _selectedAccount?.id;
    tx.toAccountId = _txType == 'transfer' ? _selectedToAccount?.id : null;
    tx.exchangeFee = _txType == 'transfer'
        ? (widget.params.prefillExchangeFee ?? tx.exchangeFee)
        : null;
    tx.exchangeFeeType = _txType == 'transfer' && tx.exchangeFee != null
        ? (widget.params.prefillExchangeFeeType ??
              tx.exchangeFeeType ??
              'fixed')
        : null;
    tx.excludeFromBudget = _excludeFromBudget;
    tx.tagKeys = _selectedTagKeys;
    tx.projectId = _selectedProjectId;
    tx.bookId = widget.params.prefillBookId ?? tx.bookId;
    tx.type = _txType;
    tx.quickActionId = _parseQuickActionLegacyId(widget.params.quickActionId);
    tx.updatedAt = DateTime.now();

    if (widget.params.editingTransaction != null) {
      await _transactionRepo.update(tx);
    } else {
      await _transactionRepo.insert(tx);
    }

    _hasDataChanges = true;
    DataReloadBus.notify();

    if (!mounted) return;

    if (andNew || _continuousMode) {
      setState(() {
        _amount = 0;
        _note = '';
        _selectedCategory = null;
        _selectedToAccount = null;
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
          decoration: const InputDecoration(hintText: '0.00', prefixText: '¥ '),
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
    final paths = const CategoryPathService().visiblePaths(
      _categories,
      isIncome: isIncome,
    );

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
              child: Text('选择分类', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: paths.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final path = paths[i];
                  final cat = path.leaf!;
                  final isSelected = cat.key == _selectedCategory?.key;
                  return ListTile(
                    leading: CategoryService.buildIcon(
                      cat.iconName,
                      size: 24,
                      isSystemCategory: cat.isSystem,
                      forceTinted: cat.iconForceTinted,
                    ),
                    title: Text(path.displayName),
                    subtitle: path.segments.length > 1
                        ? Text('叶子分类: ${cat.name}')
                        : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, cat),
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

  void _showToAccountPicker() async {
    final candidates = _accounts
        .where((a) => a.id != _selectedAccount?.id)
        .toList();
    final result = await showModalBottomSheet<JiveAccount>(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: candidates.length,
        itemBuilder: (_, i) {
          final acct = candidates[i];
          final isSelected = acct.id == _selectedToAccount?.id;
          return ListTile(
            leading: Icon(
              Icons.call_received,
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
      setState(() => _selectedToAccount = result);
    }
  }

  Future<void> _saveCurrentAsQuickAction() async {
    if (_amount <= 0 || _selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先补全金额和账户')));
      return;
    }
    if (_txType != 'transfer' && _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择分类')));
      return;
    }

    final categoryKeys = const CategoryPathService().toTransactionKeys(
      _categories,
      _selectedCategory,
    );
    final tx = JiveTransaction()
      ..amount = _amount
      ..source = 'quick_action_seed'
      ..timestamp = _selectedDate
      ..type = _txType
      ..categoryKey = _txType == 'transfer' ? null : categoryKeys.categoryKey
      ..subCategoryKey = _txType == 'transfer'
          ? null
          : categoryKeys.subCategoryKey
      ..category = _txType == 'transfer' ? '转账' : categoryKeys.categoryName
      ..subCategory = _txType == 'transfer'
          ? null
          : categoryKeys.subCategoryName
      ..accountId = _selectedAccount?.id
      ..toAccountId = _txType == 'transfer' ? _selectedToAccount?.id : null
      ..note = _note.isEmpty ? null : _note
      ..tagKeys = List<String>.from(_selectedTagKeys);

    final result = await showSaveTemplateDialog(
      context: context,
      transaction: tx,
      categoryName: categoryKeys.subCategoryName ?? categoryKeys.categoryName,
    );
    if (result == null) return;

    await TemplateService(_isar).createFromTransaction(
      transaction: tx,
      name: result['name'] as String,
      saveAmount: result['saveAmount'] as bool? ?? true,
      groupName: result['groupName'] as String?,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存为快速动作')));
  }

  static int? _parseQuickActionLegacyId(String? id) {
    if (id == null || id.isEmpty) return null;
    if (id.startsWith('template:')) {
      return int.tryParse(id.substring('template:'.length));
    }
    return int.tryParse(id);
  }

  static String _sourceStorageValue(
    TransactionEntrySource source, {
    String? existing,
  }) {
    switch (source) {
      case TransactionEntrySource.manual:
        return 'manual';
      case TransactionEntrySource.quickAction:
        return 'quick_action';
      case TransactionEntrySource.voice:
        return 'voice';
      case TransactionEntrySource.conversation:
        return 'conversation';
      case TransactionEntrySource.autoDraft:
        return 'auto_draft';
      case TransactionEntrySource.ocrScreenshot:
        return 'ocr_screenshot';
      case TransactionEntrySource.shareReceive:
        return 'share_receive';
      case TransactionEntrySource.deepLink:
        return 'deep_link';
      case TransactionEntrySource.edit:
        final value = existing?.trim() ?? '';
        return value.isEmpty ? 'manual' : value;
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
      builder: (ctx) =>
          TagPickerSheet(tags: _tags, selectedKeys: _selectedTagKeys),
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
    final amountStr = _amount > 0 ? _amount.toStringAsFixed(2) : '0.00';
    final currency = CurrencyDefaults.getSymbol(
      _selectedAccount?.currency ?? 'CNY',
    );
    final selectedCategoryName = _selectedCategory == null
        ? null
        : const CategoryPathService()
              .resolveFromSelection(_categories, _selectedCategory)
              .displayName;
    final highlightAmount =
        params.shouldHighlight(TransactionHighlightField.amount) &&
        _amount <= 0;
    final highlightCategory =
        params.shouldHighlight(TransactionHighlightField.category) &&
        _txType != 'transfer' &&
        _selectedCategory == null;
    final highlightAccount =
        params.shouldHighlight(TransactionHighlightField.account) &&
        _selectedAccount == null;
    final highlightTransferAccount =
        params.shouldHighlight(TransactionHighlightField.transferAccount) &&
        _txType == 'transfer' &&
        _selectedToAccount == null;
    final canSave =
        _amount > 0 &&
        _selectedAccount != null &&
        (_txType == 'transfer'
            ? _selectedToAccount != null &&
                  _selectedToAccount?.id != _selectedAccount?.id
            : _selectedCategory != null);

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
                        border: highlightAmount
                            ? Border.all(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                      ),
                      child: TransactionAmountDisplay(
                        amountStr: amountStr,
                        currencySymbol: currency,
                        transactionType: _txType,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  QuickActionSuggestBar(
                    onSaveAsAction: _amount > 0 && _selectedAccount != null
                        ? _saveCurrentAsQuickAction
                        : null,
                  ),
                  if (_amount > 0 && _selectedAccount != null)
                    const SizedBox(height: 12),

                  // Core fields card
                  TransactionCoreFields(
                    categoryName: _txType == 'transfer'
                        ? '转账'
                        : selectedCategoryName,
                    accountName: _selectedAccount?.name,
                    note: _note.isEmpty ? null : _note,
                    date: _selectedDate,
                    highlightCategory: highlightCategory,
                    highlightAccount: highlightAccount,
                    highlightDate: params.shouldHighlight(
                      TransactionHighlightField.time,
                    ),
                    highlightNote: params.shouldHighlight(
                      TransactionHighlightField.note,
                    ),
                    onCategoryTap: _txType == 'transfer'
                        ? null
                        : _showCategoryPicker,
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
                  if (_txType == 'transfer') ...[
                    const SizedBox(height: 12),
                    _TransferTargetCard(
                      accountName: _selectedToAccount?.name,
                      highlighted: highlightTransferAccount,
                      onTap: _showToAccountPicker,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Advanced section
                  TransactionAdvancedSection(
                    isExpanded: _advancedExpanded,
                    onToggle: () =>
                        setState(() => _advancedExpanded = !_advancedExpanded),
                    tagNames: _selectedTagNames,
                    projectName: _selectedProjectName,
                    isExcludedFromBudget: _excludeFromBudget,
                    highlightTags:
                        params.shouldHighlight(
                          TransactionHighlightField.tags,
                        ) &&
                        _selectedTagKeys.isEmpty,
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
            enabled: canSave,
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

class _TransferTargetCard extends StatelessWidget {
  final String? accountName;
  final bool highlighted;
  final VoidCallback onTap;

  const _TransferTargetCard({
    required this.accountName,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlighted
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted
                ? theme.colorScheme.error
                : theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.call_received,
              color: highlighted
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('转入账户'),
            const Spacer(),
            if (highlighted)
              Text(
                '待补全',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (highlighted) const SizedBox(width: 8),
            Text(
              accountName ?? '未选择',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accountName == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
