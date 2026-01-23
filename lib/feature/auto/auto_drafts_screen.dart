import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/auto_draft_service.dart';
import '../../core/service/auto_account_mapping.dart';
import '../../core/service/account_service.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/service/tag_service.dart';
import '../tag/tag_icon_catalog.dart';
import '../tag/tag_picker_sheet.dart';

class AutoDraftsScreen extends StatefulWidget {
  const AutoDraftsScreen({super.key});

  @override
  State<AutoDraftsScreen> createState() => _AutoDraftsScreenState();
}

class _AutoDraftsScreenState extends State<AutoDraftsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  bool _hasChanges = false;
  List<JiveAutoDraft> _drafts = [];
  List<JiveAccount> _accounts = [];
  final Map<int, JiveAccount> _accountById = {};
  final DateFormat _timeFormat = DateFormat('MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
    } else {
      _isar = await Isar.open(
        [
          JiveTransactionSchema,
          JiveCategorySchema,
          JiveCategoryOverrideSchema,
          JiveAccountSchema,
          JiveAutoDraftSchema,
          JiveTagSchema,
          JiveTagGroupSchema,
          JiveTagConversionLogSchema,
        ],
        directory: dir.path,
      );
    }
    await _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final list = await _isar.collection<JiveAutoDraft>().where().sortByTimestampDesc().findAll();
    final accounts = await AccountService(_isar).getActiveAccounts();
    if (!mounted) return;
    setState(() {
      _drafts = list;
      _accounts = accounts;
      _accountById
        ..clear()
        ..addEntries(accounts.map((account) => MapEntry(account.id, account)));
      _isLoading = false;
    });
  }

  Future<void> _confirmDraft(JiveAutoDraft draft) async {
    final result = await _reviewDraftBeforeConfirm(draft);
    if (result == null) return;
    draft.amount = result.amount;
    draft.type = result.type;
    draft.category = result.categoryName;
    draft.subCategory = result.subCategoryName;
    draft.categoryKey = result.categoryKey;
    draft.subCategoryKey = result.subCategoryKey;
    draft.accountId = result.accountId;
    draft.toAccountId = result.toAccountId;
    draft.tagKeys = result.tagKeys;
    await _isar.writeTxn(() async {
      await _isar.collection<JiveAutoDraft>().put(draft);
    });
    await AutoDraftService(_isar).confirmDraft(draft);
    _hasChanges = true;
    await _loadDrafts();
  }

  Future<void> _discardDraft(JiveAutoDraft draft) async {
    await AutoDraftService(_isar).discardDraft(draft);
    _hasChanges = true;
    await _loadDrafts();
  }

  Future<void> _confirmAll() async {
    final service = AutoDraftService(_isar);
    for (final draft in List<JiveAutoDraft>.from(_drafts)) {
      if (_isTransferDraft(draft)) {
        final ready = await _ensureTransferAccounts(draft);
        if (!ready) break;
      }
      await service.confirmDraft(draft);
    }
    _hasChanges = true;
    await _loadDrafts();
  }

  Future<_DraftConfirmResult?> _reviewDraftBeforeConfirm(JiveAutoDraft draft) async {
    if (_accounts.isEmpty) {
      await _loadDrafts();
    }
    final options = await _loadCategoryOptions();
    final tagService = TagService(_isar);
    await tagService.initDefaultGroups();
    final tags = await tagService.getTags(includeArchived: false);
    var selectedTagKeys = List<String>.from(draft.tagKeys);
    var type = draft.type ?? (_isTransferDraft(draft) ? 'transfer' : 'expense');
    var amountText = draft.amount.toStringAsFixed(2);
    final amountController = TextEditingController(text: amountText);
    String? amountError;
    int? accountId = draft.accountId;
    int? toAccountId = draft.toAccountId;
    String? accountError;
    String? toAccountError;
    String? fromAccountError;

    final hints = _extractTransferHints(draft.rawText);
    accountId ??= _suggestAccountId(hints?.from ?? hints?.to);
    if (type != 'transfer' && accountId == null && _accounts.isNotEmpty) {
      accountId = _accounts.first.id;
    }
    if (type == 'transfer') {
      accountId ??= _suggestAccountId(hints?.from);
      toAccountId ??= _suggestAccountId(hints?.to);
      if (accountId == null && _accounts.isNotEmpty) {
        accountId = _accounts.first.id;
      }
      if (toAccountId == null && _accounts.length > 1) {
        toAccountId = _accounts.firstWhere((a) => a.id != accountId).id;
      }
    }

    var parentOptions = _parentsForType(type, options);
    var selectedParent = _pickCategory(parentOptions, draft.categoryKey, draft.category);
    selectedParent ??= parentOptions.isNotEmpty ? parentOptions.first : null;
    final initialParentKey = selectedParent?.key;
    var subOptions = initialParentKey == null
        ? <JiveCategory>[]
        : (options.subByParentKey[initialParentKey] ?? <JiveCategory>[]);
    var selectedSub = _pickCategory(subOptions, draft.subCategoryKey, draft.subCategory);
    selectedSub ??= subOptions.isNotEmpty ? subOptions.first : null;

    final result = await showModalBottomSheet<_DraftConfirmResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedTags = tags.where((tag) => selectedTagKeys.contains(tag.key)).toList();
            Future<void> pickTags() async {
              final picked = await showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return TagPickerSheet(
                    tags: tags,
                    selectedKeys: selectedTagKeys,
                    onCreateTag: (name) async {
                      final created = await TagService(_isar).createTag(name: name);
                      await _loadDrafts();
                      return created;
                    },
                  );
                },
              );
              if (picked == null) return;
              setSheetState(() {
                selectedTagKeys = picked;
              });
            }
            void refreshCategories() {
              parentOptions = _parentsForType(type, options);
              selectedParent = _pickCategory(parentOptions, draft.categoryKey, draft.category);
              selectedParent ??= parentOptions.isNotEmpty ? parentOptions.first : null;
              final parentKey = selectedParent?.key;
              subOptions = parentKey == null
                  ? <JiveCategory>[]
                  : (options.subByParentKey[parentKey] ?? <JiveCategory>[]);
              selectedSub = _pickCategory(subOptions, draft.subCategoryKey, draft.subCategory);
              selectedSub ??= subOptions.isNotEmpty ? subOptions.first : null;
            }

            return FractionallySizedBox(
              heightFactor: 0.82,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '确认自动记账',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('来源：${draft.source}'),
                                  ),
                                  Text(_timeFormat.format(draft.timestamp)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: '金额',
                                  prefixText: '¥ ',
                                  errorText: amountError,
                                ),
                                onChanged: (_) => setSheetState(() => amountError = null),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: type,
                                decoration: const InputDecoration(labelText: '类型'),
                                items: const [
                                  DropdownMenuItem(value: 'expense', child: Text('支出')),
                                  DropdownMenuItem(value: 'income', child: Text('收入')),
                                  DropdownMenuItem(value: 'transfer', child: Text('转账')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    type = value;
                                    refreshCategories();
                                    accountError = null;
                                    toAccountError = null;
                                    fromAccountError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              if (type != 'transfer') ...[
                                DropdownButtonFormField<int>(
                                  value: accountId,
                                  decoration: InputDecoration(
                                    labelText: '账户',
                                    errorText: accountError,
                                  ),
                                  items: [
                                    for (final account in _accounts)
                                      DropdownMenuItem(value: account.id, child: Text(account.name)),
                                  ],
                                  onChanged: (value) =>
                                      setSheetState(() {
                                        accountId = value;
                                        accountError = null;
                                      }),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedParent?.key,
                                  decoration: const InputDecoration(labelText: '分类'),
                                  items: [
                                    for (final category in parentOptions)
                                      DropdownMenuItem(value: category.key, child: Text(category.name)),
                                  ],
                                  onChanged: (value) {
                                    setSheetState(() {
                                      selectedParent = parentOptions.firstWhere(
                                        (cat) => cat.key == value,
                                        orElse: () => parentOptions.first,
                                      );
                                      subOptions = options.subByParentKey[selectedParent!.key] ?? <JiveCategory>[];
                                      selectedSub = subOptions.isNotEmpty ? subOptions.first : null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedSub?.key,
                                  decoration: const InputDecoration(labelText: '子分类'),
                                  items: [
                                    for (final sub in subOptions)
                                      DropdownMenuItem(value: sub.key, child: Text(sub.name)),
                                  ],
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == null) return;
                                      selectedSub = subOptions.firstWhere(
                                        (cat) => cat.key == value,
                                        orElse: () => subOptions.first,
                                      );
                                    });
                                  },
                                ),
                              ],
                              if (type == 'transfer') ...[
                                DropdownButtonFormField<int>(
                                  value: accountId,
                                  decoration: InputDecoration(
                                    labelText: '转出账户',
                                    errorText: fromAccountError,
                                  ),
                                  items: [
                                    for (final account in _accounts)
                                      DropdownMenuItem(value: account.id, child: Text(account.name)),
                                  ],
                                  onChanged: (value) => setSheetState(() {
                                    accountId = value;
                                    fromAccountError = null;
                                  }),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<int>(
                                  value: toAccountId,
                                  decoration: InputDecoration(
                                    labelText: '转入账户',
                                    errorText: toAccountError,
                                  ),
                                  items: [
                                    for (final account in _accounts)
                                      DropdownMenuItem(value: account.id, child: Text(account.name)),
                                  ],
                                  onChanged: (value) => setSheetState(() {
                                    toAccountId = value;
                                    toAccountError = null;
                                  }),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final tag in selectedTags)
                                      _buildDraftTagChip(
                                        tag,
                                        () => setSheetState(() {
                                          selectedTagKeys.remove(tag.key);
                                        }),
                                      ),
                                    ActionChip(
                                      label: Text(selectedTags.isEmpty ? '添加标签' : '编辑标签'),
                                      avatar: const Icon(Icons.label_outline, size: 16, color: Colors.black54),
                                      onPressed: pickTags,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if ((draft.rawText ?? '').isNotEmpty)
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('原始信息'),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        draft.rawText ?? '',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final parsed = double.tryParse(
                                    amountController.text.replaceAll(',', '').trim(),
                                  );
                                  if (parsed == null || parsed <= 0) {
                                    setSheetState(() => amountError = '金额无效');
                                    return;
                                  }
                                  if (type == 'transfer') {
                                    if (accountId == null) {
                                      setSheetState(() => fromAccountError = '请选择转出账户');
                                      return;
                                    }
                                    if (toAccountId == null) {
                                      setSheetState(() => toAccountError = '请选择转入账户');
                                      return;
                                    }
                                    if (accountId == toAccountId) {
                                      setSheetState(() => toAccountError = '转入账户不能与转出相同');
                                      return;
                                    }
                                  } else if (accountId == null) {
                                    setSheetState(() => accountError = '请选择账户');
                                    return;
                                  }

                                  Navigator.pop(
                                    context,
                                    _DraftConfirmResult(
                                      amount: parsed,
                                      type: type,
                                      accountId: accountId,
                                      toAccountId: type == 'transfer' ? toAccountId : null,
                                      categoryKey: type == 'transfer' ? null : selectedParent?.key,
                                      subCategoryKey: type == 'transfer' ? null : selectedSub?.key,
                                      categoryName: type == 'transfer'
                                          ? '转账'
                                          : (selectedParent?.name ?? draft.category ?? '未分类'),
                                      subCategoryName: type == 'transfer'
                                          ? '转账'
                                          : (selectedSub?.name ?? draft.subCategory ?? '未分类'),
                                      tagKeys: List<String>.from(selectedTagKeys),
                                    ),
                                  );
                                },
                                child: const Text('确认'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    return result;
  }

  Future<_CategoryOptions> _loadCategoryOptions() async {
    final categories =
        await _isar.collection<JiveCategory>().filter().isHiddenEqualTo(false).findAll();
    final parentsIncome = categories
        .where((cat) => cat.parentKey == null && cat.isIncome)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final parentsExpense = categories
        .where((cat) => cat.parentKey == null && !cat.isIncome)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final subByParentKey = <String, List<JiveCategory>>{};
    for (final cat in categories.where((cat) => cat.parentKey != null)) {
      final key = cat.parentKey!;
      subByParentKey.putIfAbsent(key, () => []).add(cat);
    }
    for (final entry in subByParentKey.entries) {
      entry.value.sort((a, b) => a.order.compareTo(b.order));
    }
    return _CategoryOptions(
      parentsIncome: parentsIncome,
      parentsExpense: parentsExpense,
      subByParentKey: subByParentKey,
    );
  }

  List<JiveCategory> _parentsForType(String type, _CategoryOptions options) {
    if (type == 'income') return options.parentsIncome;
    if (type == 'expense') return options.parentsExpense;
    return const <JiveCategory>[];
  }

  JiveCategory? _pickCategory(
    List<JiveCategory> categories,
    String? key,
    String? name,
  ) {
    if (key != null) {
      final match = categories.where((cat) => cat.key == key).toList();
      if (match.isNotEmpty) return match.first;
    }
    if (name != null && name.isNotEmpty) {
      final match = categories.where((cat) => cat.name == name).toList();
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("待确认自动记账", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            if (_drafts.isNotEmpty)
              TextButton(
                onPressed: _confirmAll,
                child: const Text("全部确认"),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDrafts,
                child: _drafts.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _drafts.length,
                        itemBuilder: (context, index) {
                          return _buildDraftCard(_drafts[index]);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Center(
          child: Text("暂无待确认记录", style: TextStyle(color: Colors.grey.shade500)),
        ),
      ],
    );
  }

  Widget _buildDraftTagChip(JiveTag tag, VoidCallback onDeleted) {
    final color = AccountService.parseColorHex(tag.colorHex) ?? Colors.blueGrey;
    return InputChip(
      label: Text(
        tagDisplayName(tag),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      onDeleted: onDeleted,
    );
  }


  Widget _buildDraftCard(JiveAutoDraft draft) {
    final type = draft.type ?? 'expense';
    final isTransfer = _isTransferDraft(draft);
    final amountPrefix = isTransfer ? '' : (type == 'income' ? '+ ' : '- ');
    final amountColor = isTransfer ? Colors.blueGrey : (type == 'income' ? Colors.green : Colors.redAccent);
    final category = draft.category ?? '自动记账';
    final sub = draft.subCategory ?? '未分类';
    final timeText = _timeFormat.format(draft.timestamp);
    final transferLine = _buildTransferLine(draft, timeText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTransfer ? '转账' : category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      isTransfer ? transferLine : "$sub • $timeText",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "$amountPrefix¥${draft.amount.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
              ),
            ],
          ),
          if ((draft.rawText ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              draft.rawText!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _discardDraft(draft),
                child: const Text("删除"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _confirmDraft(draft),
                child: const Text("确认"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildTransferLine(JiveAutoDraft draft, String timeText) {
    final fromName = _displayAccountName(draft.accountId) ?? '未指定';
    final toName = _displayAccountName(draft.toAccountId) ?? '待选择';
    return '$fromName → $toName • $timeText';
  }

  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  bool _isTransferDraft(JiveAutoDraft draft) {
    if (draft.type == 'transfer') return true;
    final text = draft.rawText ?? '';
    if (text.isEmpty) return false;
    for (final keyword in _transferKeywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  String? _displayAccountName(int? accountId) {
    if (accountId == null) return null;
    return _accountById[accountId]?.name;
  }

  Future<bool> _ensureTransferAccounts(JiveAutoDraft draft) async {
    if (_accounts.isEmpty) {
      await _loadDrafts();
    }
    final hints = _extractTransferHints(draft.rawText);
    final fromHint = hints?.from;
    final toHint = hints?.to;
    var fromId = draft.accountId;
    var toId = draft.toAccountId;
    if (fromId != null && fromHint != null) {
      final account = _accountById[fromId];
      if (account == null || !_accountMatchesHint(account, fromHint)) {
        fromId = null;
      }
    }
    if (toId != null && toHint != null) {
      final account = _accountById[toId];
      if (account == null || !_accountMatchesHint(account, toHint)) {
        toId = null;
      }
    }
    if (fromId != null && toId != null) {
      return true;
    }
    final selection = await _promptTransferAccounts(draft);
    if (selection == null) return false;
    draft.accountId = selection.fromId;
    draft.toAccountId = selection.toId;
    await _isar.writeTxn(() async {
      await _isar.collection<JiveAutoDraft>().put(draft);
    });
    return true;
  }

  Future<_TransferSelection?> _promptTransferAccounts(JiveAutoDraft draft) async {
    final hints = _extractTransferHints(draft.rawText);
    final fromHint = hints?.from;
    final toHint = hints?.to;
    int? fromId = draft.accountId;
    if (fromId != null && fromHint != null) {
      final account = _accountById[fromId];
      if (account == null || !_accountMatchesHint(account, fromHint)) {
        fromId = null;
      }
    }
    fromId ??= _suggestAccountId(fromHint);
    if (fromId == null && _accounts.length == 1) {
      fromId = _accounts.first.id;
    }
    int? toId = draft.toAccountId;
    if (toId != null && toHint != null) {
      final account = _accountById[toId];
      if (account == null || !_accountMatchesHint(account, toHint)) {
        toId = null;
      }
    }
    toId ??= _suggestAccountId(toHint);
    if (toHint != null && toHint.tail == null && toId != null) {
      final account = _accountById[toId];
      if (account != null && RegExp(r'\d{3,4}').hasMatch(account.name)) {
        toId = null;
      }
    }
    if (fromHint != null && fromHint.tail == null && fromId != null) {
      final account = _accountById[fromId];
      if (account != null && RegExp(r'\d{3,4}').hasMatch(account.name)) {
        fromId = null;
      }
    }
    bool rememberMapping = false;
    final mappingPreview = AutoAccountMappingStore.sanitizePattern(toHint?.name ?? '');
    final fromHintLabel = _buildAccountNameFromHint(fromHint);
    final toHintLabel = _buildAccountNameFromHint(toHint);
    final canQuickCreateBoth = fromHintLabel != null && toHintLabel != null && (fromId == null || toId == null);

    return await showModalBottomSheet<_TransferSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.68,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '补全转账账户',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (fromHintLabel != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '识别转出账户：$fromHintLabel',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              DropdownButtonFormField<int>(
                                value: fromId,
                                decoration: const InputDecoration(labelText: '转出账户'),
                                hint: fromHintLabel == null ? const Text('请选择') : Text(fromHintLabel),
                                items: [
                                  for (final account in _accounts)
                                    DropdownMenuItem(value: account.id, child: Text(account.name)),
                                ],
                                onChanged: (value) => setSheetState(() => fromId = value),
                              ),
                              if (fromId == null && fromHintLabel != null)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('未找到匹配转出账户，可新建'),
                                ),
                              const SizedBox(height: 12),
                              if (toHintLabel != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '识别转入账户：$toHintLabel',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              DropdownButtonFormField<int>(
                                value: toId,
                                decoration: const InputDecoration(labelText: '转入账户'),
                                hint: toHintLabel == null ? const Text('请选择') : Text(toHintLabel),
                                items: [
                                  for (final account in _accounts)
                                    DropdownMenuItem(value: account.id, child: Text(account.name)),
                                ],
                                onChanged: (value) => setSheetState(() => toId = value),
                              ),
                              if (toId == null && toHintLabel != null)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('未找到匹配转入账户，可新建'),
                                ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () async {
                                    final created = await _quickCreateAccount(fromHintLabel);
                                    if (created == null) return;
                                    setSheetState(() {
                                      _accounts = [..._accounts, created];
                                      _accountById[created.id] = created;
                                      fromId = created.id;
                                    });
                                  },
                                  child: const Text('新建转出账户'),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () async {
                                    final created = await _quickCreateAccount(toHintLabel);
                                    if (created == null) return;
                                    setSheetState(() {
                                      _accounts = [..._accounts, created];
                                      _accountById[created.id] = created;
                                      toId = created.id;
                                    });
                                  },
                                  child: const Text('新建转入账户'),
                                ),
                              ),
                              if (canQuickCreateBoth)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () async {
                                      final createdFrom = fromId == null && fromHintLabel != null
                                          ? await _createAccountWithName(fromHintLabel)
                                          : null;
                                      final createdTo = toId == null && toHintLabel != null
                                          ? await _createAccountWithName(toHintLabel)
                                          : null;
                                      if (createdFrom == null && createdTo == null) return;
                                      setSheetState(() {
                                        if (createdFrom != null) {
                                          _addAccountToCache(createdFrom);
                                          fromId = createdFrom.id;
                                        }
                                        if (createdTo != null) {
                                          _addAccountToCache(createdTo);
                                          toId = createdTo.id;
                                        }
                                      });
                                    },
                                    child: const Text('一键新建转入+转出'),
                                  ),
                                ),
                              if (mappingPreview.isNotEmpty)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: rememberMapping,
                                  onChanged: (value) =>
                                      setSheetState(() => rememberMapping = value ?? false),
                                  title: const Text('记住该账户映射'),
                                  subtitle: Text('下次自动匹配：$mappingPreview'),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (fromId == null || toId == null) return;
                                  if (rememberMapping && mappingPreview.isNotEmpty) {
                                    await AutoAccountMappingStore.upsert(
                                      AutoAccountMapping(
                                        pattern: mappingPreview,
                                        accountId: toId!,
                                        regex: false,
                                      ),
                                    );
                                  }
                                  Navigator.pop(
                                    context,
                                    _TransferSelection(fromId: fromId!, toId: toId!),
                                  );
                                },
                                child: const Text('确认'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<JiveAccount?> _quickCreateAccount(String? initialName) async {
    final controller = TextEditingController(text: initialName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建账户'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '账户名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return null;

    final inferred = _inferAccountType(name);
    final account = await AccountService(_isar).createAccount(
      name: name,
      type: inferred.type,
      subType: inferred.subType,
      openingBalance: 0,
    );
    return account;
  }

  void _addAccountToCache(JiveAccount account) {
    if (_accountById.containsKey(account.id)) return;
    _accounts = [..._accounts, account];
    _accountById[account.id] = account;
  }

  Future<JiveAccount?> _createAccountWithName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    for (final account in _accounts) {
      if (account.name == trimmed) return account;
    }
    final inferred = _inferAccountType(trimmed);
    return AccountService(_isar).createAccount(
      name: trimmed,
      type: inferred.type,
      subType: inferred.subType,
      openingBalance: 0,
    );
  }

  _AccountTypeHint _inferAccountType(String name) {
    if (name.contains('信用')) {
      return const _AccountTypeHint(type: AccountService.typeLiability, subType: 'credit');
    }
    if (name.contains('借') || name.contains('贷款')) {
      return const _AccountTypeHint(type: AccountService.typeLiability, subType: 'loan');
    }
    if (name.contains('微信') || name.contains('支付宝') || name.contains('钱包') || name.contains('余额宝')) {
      return const _AccountTypeHint(type: AccountService.typeAsset, subType: 'wallet');
    }
    return const _AccountTypeHint(type: AccountService.typeAsset, subType: 'bank');
  }

  _TransferAccountHints? _extractTransferHints(String? rawText) {
    if (rawText == null) return null;
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    final fromHint = _extractFromAccountHint(text);
    final toHint = _extractToAccountHint(text);
    if (fromHint == null && toHint == null) return null;
    return _TransferAccountHints(from: fromHint, to: toHint);
  }

  _AccountHint? _extractToAccountHint(String text) {
    final patterns = [
      RegExp(r'(?:到账银行卡|到账卡|收款银行卡|收款卡|收款账号|收款账户|转入卡|转出卡|银行卡)[:：]?\s*([^\s，,。;；]{2,30})'),
      RegExp(r'(?:转账到|转到|转至|转入至|到账至)[:：]?\s*([^\s，,。;；]{2,30})'),
    ];
    final name = _matchFirstGroup(text, patterns);
    return _buildAccountHint(name, text) ?? _inferAccountHintFromContext(text, preferWallet: false);
  }

  _AccountHint? _extractFromAccountHint(String text) {
    final patterns = [
      RegExp(r'(?:付款方式|付款信息|交易方式|退款方式|付款卡|付款方|扣款卡|支付方式|支付账户|付款账户)[:：]?\s*([^\s，,。;；]{2,30})'),
    ];
    final name = _matchFirstGroup(text, patterns);
    return _buildAccountHint(name, text) ?? _inferAccountHintFromContext(text, preferWallet: true);
  }

  String? _matchFirstGroup(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final name = match?.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  _AccountHint? _buildAccountHint(String? name, String text) {
    final tail = RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(text)?.group(1) ??
        RegExp(r'[（(](\d{3,4})[）)]').firstMatch(text)?.group(1);
    if (name == null || name.trim().isEmpty) {
      if (tail == null) return null;
      return _AccountHint(name: tail, tail: tail);
    }
    var cleaned = name.replaceAll(RegExp(r'[，,。\s]+$'), '').trim();
    String? tailFromName;
    final parenMatch = RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(cleaned);
    if (parenMatch != null) {
      tailFromName = parenMatch.group(1);
      cleaned = cleaned.replaceAll(parenMatch.group(0)!, '').trim();
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(cleaned)) {
      tailFromName ??= cleaned;
      cleaned = '';
    } else {
      final tailMatch = RegExp(r'^(.*?)(?:尾号|末四位|末尾)\s*(\d{3,4})$').firstMatch(cleaned);
      if (tailMatch != null) {
        cleaned = tailMatch.group(1)!.trim();
        tailFromName ??= tailMatch.group(2);
      }
    }
    final normalized = _sanitizeHintName(cleaned);
    if (normalized == null || normalized.isEmpty) {
      if (tailFromName == null) return null;
      return _AccountHint(name: tailFromName, tail: tailFromName);
    }
    final resolvedTail = tailFromName ??
        (RegExp(r'^\d{3,4}$').hasMatch(normalized) ? normalized : null);
    return _AccountHint(name: normalized, tail: resolvedTail);
  }

  _AccountHint? _inferAccountHintFromContext(String text, {required bool preferWallet}) {
    final bank = _extractBankName(text);
    String? wallet;
    for (final keyword in _walletHintKeywords) {
      if (text.contains(keyword)) {
        wallet = keyword;
        break;
      }
    }
    final primary = preferWallet ? (wallet ?? bank) : (bank ?? wallet);
    if (primary == null) return null;
    return _buildAccountHint(primary, text);
  }

  int? _suggestAccountId(_AccountHint? hint) {
    if (hint == null || _accounts.isEmpty) return null;
    return _matchAccountByHint(_accounts, hint);
  }

  String? _buildAccountNameFromHint(_AccountHint? hint) {
    if (hint == null) return null;
    var base = hint.name.trim();
    var tail = hint.tail;
    if (base.isEmpty) return null;
    if (RegExp(r'^\d{3,4}$').hasMatch(base)) {
      return '账户($base)';
    }
    if (tail != null && !base.contains(tail)) {
      return '$base($tail)';
    }
    return base;
  }

  String? _sanitizeHintName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final bank = _extractBankName(trimmed);
    if (bank != null) {
      if (trimmed.contains('信用卡')) return '$bank信用卡';
      if (trimmed.contains('储蓄卡')) return '$bank储蓄卡';
      return bank;
    }
    for (final keyword in _walletHintKeywords) {
      if (trimmed.contains(keyword)) return keyword;
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(trimmed)) return trimmed;
    if (RegExp(r'(?:元|今日|今天|昨天|交易|支付|消费|退款|收款|转入|转出|支出|收入|成功|失败|单次|定时|投资|理财)')
        .hasMatch(trimmed)) {
      return null;
    }
    if (trimmed.length > 12) return null;
    return trimmed;
  }

  static const _walletHintKeywords = [
    '支付宝',
    '微信',
    '余额宝',
    '零钱',
    '云闪付',
    '京东',
    '美团',
    '抖音',
    '拼多多',
    '淘宝',
    'QQ钱包',
    '钱包',
  ];

  int? _matchAccountByHint(List<JiveAccount> accounts, _AccountHint hint) {
    if (accounts.isEmpty) return null;
    final normalizedHint = _cleanAccountName(hint.name);
    final bank = _extractBankName(hint.name);
    final hintHasTail = hint.tail != null || RegExp(r'\d{3,4}').hasMatch(hint.name);

    if (hint.tail != null) {
      for (final account in accounts) {
        if (account.name.contains(hint.tail!)) return account.id;
      }
    }

    int? bestId;
    var bestScore = 0;
    var bestDiff = 999;
    for (final account in accounts) {
      if (!hintHasTail && RegExp(r'\d{3,4}').hasMatch(account.name)) {
        continue;
      }
      if (bank != null && account.name.contains('信用卡') && !account.name.contains(bank)) {
        continue;
      }
      final normalizedAccount = _cleanAccountName(account.name);
      final score = _longestCommonSubstring(normalizedAccount, normalizedHint);
      if (score == 0) continue;
      final diff = (normalizedAccount.length - score).abs();
      if (score > bestScore || (score == bestScore && diff < bestDiff)) {
        if (!(score == 2 && normalizedHint.startsWith('中国'))) {
          bestScore = score;
          bestDiff = diff;
          bestId = account.id;
        }
      }
    }

    if (bestScore >= 2) return bestId;
    return null;
  }

  String? _extractBankName(String text) {
    final match = RegExp(r'([\u4e00-\u9fa5]{2,10}银行)').firstMatch(text);
    return match?.group(1);
  }

  String _cleanAccountName(String name) {
    return name
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\([^(（【】）)]*\)'), '')
        .replaceAll(RegExp(r'[卡银行储蓄借记信用账户余额]'), '')
        .replaceAll('支付', '')
        .replaceAll('方式', '')
        .replaceAll('账户', '')
        .trim();
  }

  int _longestCommonSubstring(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final m = a.length;
    final n = b.length;
    final prev = List<int>.filled(n + 1, 0);
    final curr = List<int>.filled(n + 1, 0);
    var best = 0;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          curr[j] = prev[j - 1] + 1;
          if (curr[j] > best) best = curr[j];
        } else {
          curr[j] = 0;
        }
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
        curr[j] = 0;
      }
    }
    return best;
  }

  bool _accountMatchesHint(JiveAccount account, _AccountHint hint) {
    if (hint.tail != null) return account.name.contains(hint.tail!);
    if (RegExp(r'\d{3,4}').hasMatch(account.name)) return false;
    final normalizedAccount = _cleanAccountName(account.name);
    final normalizedHint = _cleanAccountName(hint.name);
    return _longestCommonSubstring(normalizedAccount, normalizedHint) >= 2;
  }
}

class _TransferSelection {
  final int fromId;
  final int toId;

  const _TransferSelection({required this.fromId, required this.toId});
}

class _AccountTypeHint {
  final String type;
  final String subType;

  const _AccountTypeHint({required this.type, required this.subType});
}

class _AccountHint {
  final String name;
  final String? tail;

  const _AccountHint({required this.name, this.tail});
}

class _TransferAccountHints {
  final _AccountHint? from;
  final _AccountHint? to;

  const _TransferAccountHints({required this.from, required this.to});
}

class _DraftConfirmResult {
  final double amount;
  final String type;
  final int? accountId;
  final int? toAccountId;
  final String? categoryKey;
  final String? subCategoryKey;
  final String? categoryName;
  final String? subCategoryName;
  final List<String> tagKeys;

  const _DraftConfirmResult({
    required this.amount,
    required this.type,
    required this.accountId,
    required this.toAccountId,
    required this.categoryKey,
    required this.subCategoryKey,
    required this.categoryName,
    required this.subCategoryName,
    required this.tagKeys,
  });
}

class _CategoryOptions {
  final List<JiveCategory> parentsIncome;
  final List<JiveCategory> parentsExpense;
  final Map<String, List<JiveCategory>> subByParentKey;

  const _CategoryOptions({
    required this.parentsIncome,
    required this.parentsExpense,
    required this.subByParentKey,
  });
}
