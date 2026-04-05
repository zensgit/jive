import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/json_rule_engine.dart';

/// Preference key used to persist JSON rules.
const _kJsonRulesKey = 'json_rules_v1';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

Future<List<JsonRule>> loadJsonRules() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kJsonRulesKey);
  if (raw == null || raw.isEmpty) return [];
  return raw.map((s) {
    final map = jsonDecode(s) as Map<String, dynamic>;
    return JsonRule.fromJson(map);
  }).toList();
}

Future<void> saveJsonRules(List<JsonRule> rules) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = rules.map((r) => jsonEncode(r.toJson())).toList();
  await prefs.setStringList(_kJsonRulesKey, raw);
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class JsonRuleEditorScreen extends StatefulWidget {
  const JsonRuleEditorScreen({super.key});

  @override
  State<JsonRuleEditorScreen> createState() => _JsonRuleEditorScreenState();
}

class _JsonRuleEditorScreenState extends State<JsonRuleEditorScreen> {
  List<JsonRule> _rules = [];
  Map<String, JiveCategory> _categoryByKey = {};
  List<JiveTag> _tags = [];
  List<JiveAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isar = await DatabaseService.getInstance();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final tags = await isar.collection<JiveTag>().where().findAll();
    final accounts = await isar.collection<JiveAccount>().where().findAll();
    final rules = await loadJsonRules();

    if (!mounted) return;
    setState(() {
      _categoryByKey = {for (final c in categories) c.key: c};
      _tags = tags;
      _accounts = accounts;
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _persist() async {
    await saveJsonRules(_rules);
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('JSON 规则引擎',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        backgroundColor: JiveTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rule_folder, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('暂无高级规则',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('点击右下角 + 创建',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _rules.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) => _buildRuleCard(_rules[i], i),
    );
  }

  Widget _buildRuleCard(JsonRule rule, int index) {
    final condSummary = rule.conditions
        .map((c) => '${_fieldLabel(c.field)} ${_opLabel(c.operator)}')
        .join(rule.conditionLogic == 'or' ? ' | ' : ' & ');
    final actionSummary = rule.actions.map((a) {
      switch (a.type) {
        case 'setCategory':
          final cat = _categoryByKey[a.value];
          return '分类=${cat?.name ?? a.value}';
        case 'setType':
          return '类型=${_typeLabel(a.value)}';
        case 'addTag':
          final tag = _tags.where((t) => t.key == a.value).firstOrNull;
          return '标签+${tag?.name ?? a.value}';
        case 'setAccount':
          final acct = _accounts
              .where((ac) => ac.id.toString() == a.value)
              .firstOrNull;
          return '账户=${acct?.name ?? a.value}';
        default:
          return a.type;
      }
    }).join(', ');

    return Card(
      key: ValueKey('rule_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.account_tree,
            color: rule.isEnabled ? JiveTheme.primaryGreen : Colors.grey),
        title: Row(
          children: [
            Expanded(
              child: Text(rule.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: rule.isEnabled ? Colors.black87 : Colors.grey,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('P${rule.priority}',
                  style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (condSummary.isNotEmpty)
              Text('条件: $condSummary',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            if (actionSummary.isNotEmpty)
              Text('动作: $actionSummary',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: rule.isEnabled ? 'disable' : 'enable',
              child: Text(rule.isEnabled ? '停用' : '启用'),
            ),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'test', child: Text('测试规则')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (action) => _handleAction(rule, index, action),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _rules.removeAt(oldIndex);
      _rules.insert(newIndex, item);
      // Reassign priorities based on new order.
      _rules = [
        for (int i = 0; i < _rules.length; i++)
          _rules[i].copyWith(priority: i),
      ];
    });
    _persist();
  }

  Future<void> _handleAction(JsonRule rule, int index, String action) async {
    switch (action) {
      case 'enable':
      case 'disable':
        setState(() {
          _rules[index] = rule.copyWith(isEnabled: action == 'enable');
        });
        await _persist();
        break;
      case 'edit':
        await _openEditor(index);
        break;
      case 'test':
        if (!mounted) return;
        await _showTestDialog(rule);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除规则'),
            content: Text('确定删除"${rule.name}"吗？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child:
                      const Text('删除', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (ok == true) {
          setState(() => _rules.removeAt(index));
          await _persist();
        }
        break;
    }
  }

  // -----------------------------------------------------------------------
  // Test dialog
  // -----------------------------------------------------------------------

  Future<void> _showTestDialog(JsonRule rule) async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '0');
    final sourceCtrl = TextEditingController();
    final merchantCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('测试规则'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: '描述', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '金额', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: sourceCtrl,
                      decoration: const InputDecoration(
                          labelText: '来源', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: merchantCtrl,
                      decoration: const InputDecoration(
                          labelText: '商户/备注',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final tx = JiveTransaction()
                          ..amount =
                              double.tryParse(amountCtrl.text) ?? 0
                          ..source = sourceCtrl.text
                          ..rawText = descCtrl.text
                          ..note = merchantCtrl.text;
                        const engine = JsonRuleEngine();
                        final result =
                            engine.evaluateTransaction(tx, [rule]);
                        setDialogState(() {}); // trigger rebuild
                        final msg = result != null
                            ? '匹配成功!\n${result.matchedConditions.join('\n')}'
                            : '未匹配';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('运行测试'),
                      style: FilledButton.styleFrom(
                          backgroundColor: JiveTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭')),
            ],
          );
        },
      ),
    );

    descCtrl.dispose();
    amountCtrl.dispose();
    sourceCtrl.dispose();
    merchantCtrl.dispose();
  }

  // -----------------------------------------------------------------------
  // Rule editor dialog (create / edit)
  // -----------------------------------------------------------------------

  Future<void> _openEditor(int? editIndex) async {
    final existing = editIndex != null ? _rules[editIndex] : null;

    final result = await showModalBottomSheet<JsonRule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => _RuleEditorSheet(
        initial: existing,
        categoryByKey: _categoryByKey,
        tags: _tags,
        accounts: _accounts,
      ),
    );

    if (result == null) return;

    setState(() {
      if (editIndex != null) {
        _rules[editIndex] = result;
      } else {
        _rules.add(result);
      }
    });
    await _persist();
  }

  // -----------------------------------------------------------------------
  // Label helpers
  // -----------------------------------------------------------------------

  String _fieldLabel(String f) {
    switch (f) {
      case 'description':
        return '描述';
      case 'amount':
        return '金额';
      case 'source':
        return '来源';
      case 'merchant':
        return '商户';
      default:
        return f;
    }
  }

  String _opLabel(String o) {
    switch (o) {
      case 'contains':
        return '包含';
      case 'equals':
        return '=';
      case 'startsWith':
        return '开头';
      case 'endsWith':
        return '结尾';
      case 'regex':
        return '正则';
      case 'gt':
        return '>';
      case 'lt':
        return '<';
      case 'between':
        return '区间';
      default:
        return o;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }
}

// ===========================================================================
// Rule editor bottom-sheet (stateful)
// ===========================================================================

class _RuleEditorSheet extends StatefulWidget {
  const _RuleEditorSheet({
    this.initial,
    required this.categoryByKey,
    required this.tags,
    required this.accounts,
  });

  final JsonRule? initial;
  final Map<String, JiveCategory> categoryByKey;
  final List<JiveTag> tags;
  final List<JiveAccount> accounts;

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priorityCtrl;
  late String _logic;
  late List<_ConditionRow> _conditions;
  late List<_ActionRow> _actions;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _priorityCtrl =
        TextEditingController(text: (r?.priority ?? 0).toString());
    _logic = r?.conditionLogic ?? 'and';
    _conditions = r?.conditions
            .map((c) => _ConditionRow(
                  field: c.field,
                  operator: c.operator,
                  valueCtrl: TextEditingController(text: c.value?.toString()),
                  secondValueCtrl: TextEditingController(
                      text: c.secondValue?.toString() ?? ''),
                ))
            .toList() ??
        [_ConditionRow.empty()];
    _actions = r?.actions
            .map((a) => _ActionRow(type: a.type, value: a.value))
            .toList() ??
        [_ActionRow.empty()];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priorityCtrl.dispose();
    for (final c in _conditions) {
      c.valueCtrl.dispose();
      c.secondValueCtrl.dispose();
    }
    super.dispose();
  }

  JsonRule _build() {
    return JsonRule(
      name: _nameCtrl.text.trim(),
      conditions: _conditions.map((c) {
        dynamic val = c.valueCtrl.text;
        dynamic secondVal =
            c.secondValueCtrl.text.isEmpty ? null : c.secondValueCtrl.text;
        // Parse numeric values for amount field
        if (c.field == 'amount') {
          val = num.tryParse(c.valueCtrl.text) ?? 0;
          if (secondVal != null) {
            secondVal = num.tryParse(c.secondValueCtrl.text);
          }
        }
        return RuleCondition(
          field: c.field,
          operator: c.operator,
          value: val,
          secondValue: secondVal,
        );
      }).toList(),
      conditionLogic: _logic,
      actions: _actions
          .map((a) => RuleAction(type: a.type, value: a.value))
          .toList(),
      priority: int.tryParse(_priorityCtrl.text) ?? 0,
      isEnabled: widget.initial?.isEnabled ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.initial == null ? '新建规则' : '编辑规则',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: '规则名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Priority
            TextField(
              controller: _priorityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '优先级 (数字越小越优先)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            // --- Conditions ---
            Row(
              children: [
                const Text('条件',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'and', label: Text('AND')),
                    ButtonSegment(value: 'or', label: Text('OR')),
                  ],
                  selected: {_logic},
                  onSelectionChanged: (v) =>
                      setState(() => _logic = v.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._conditions.asMap().entries.map((e) =>
                _buildConditionRow(e.key, e.value)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _conditions.add(_ConditionRow.empty())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加条件'),
              ),
            ),
            const SizedBox(height: 16),

            // --- Actions ---
            const Text('动作',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._actions
                .asMap()
                .entries
                .map((e) => _buildActionRow(e.key, e.value)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _actions.add(_ActionRow.empty())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加动作'),
              ),
            ),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入规则名称')),
                    );
                    return;
                  }
                  Navigator.pop(context, _build());
                },
                style: FilledButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Condition row
  // -----------------------------------------------------------------------

  static const _fields = [
    ('description', '描述'),
    ('amount', '金额'),
    ('source', '来源'),
    ('merchant', '商户'),
  ];

  static const _textOps = [
    ('contains', '包含'),
    ('equals', '等于'),
    ('startsWith', '开头是'),
    ('endsWith', '结尾是'),
    ('regex', '正则'),
  ];

  static const _numOps = [
    ('equals', '等于'),
    ('gt', '大于'),
    ('lt', '小于'),
    ('between', '介于'),
  ];

  Widget _buildConditionRow(int index, _ConditionRow cond) {
    final isAmount = cond.field == 'amount';
    final ops = isAmount ? _numOps : _textOps;

    // If current operator is invalid for the field, reset it.
    if (!ops.any((o) => o.$1 == cond.operator)) {
      cond.operator = ops.first.$1;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Field picker
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: cond.field,
              isDense: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
              items: _fields
                  .map((f) =>
                      DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  cond.field = v;
                  final newOps = v == 'amount' ? _numOps : _textOps;
                  if (!newOps.any((o) => o.$1 == cond.operator)) {
                    cond.operator = newOps.first.$1;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          // Operator picker
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: cond.operator,
              isDense: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
              items: ops
                  .map((o) =>
                      DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => cond.operator = v);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Value input
          Expanded(
            flex: 4,
            child: TextField(
              controller: cond.valueCtrl,
              keyboardType:
                  isAmount ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: isAmount ? '数值' : '文本',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          if (cond.operator == 'between') ...[
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: TextField(
                controller: cond.secondValueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '上限',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ],
          // Remove button
          if (_conditions.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: Colors.red),
              onPressed: () => setState(() {
                _conditions[index].valueCtrl.dispose();
                _conditions[index].secondValueCtrl.dispose();
                _conditions.removeAt(index);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Action row
  // -----------------------------------------------------------------------

  static const _actionTypes = [
    ('setCategory', '设置分类'),
    ('setType', '设置类型'),
    ('addTag', '添加标签'),
    ('setAccount', '设置账户'),
  ];

  Widget _buildActionRow(int index, _ActionRow action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Action type
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: action.type,
              isDense: true,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
              items: _actionTypes
                  .map((t) =>
                      DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  action.type = v;
                  action.value = '';
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          // Value picker (context-sensitive)
          Expanded(flex: 6, child: _buildActionValuePicker(action)),
          // Remove
          if (_actions.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: Colors.red),
              onPressed: () => setState(() => _actions.removeAt(index)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionValuePicker(_ActionRow action) {
    switch (action.type) {
      case 'setCategory':
        final parentCats = widget.categoryByKey.entries
            .where(
                (e) => e.value.parentKey == null || e.value.parentKey!.isEmpty)
            .toList();
        return DropdownButtonFormField<String>(
          initialValue: action.value.isEmpty ? null : action.value,
          isDense: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
          items: parentCats
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value.name)))
              .toList(),
          onChanged: (v) => setState(() => action.value = v ?? ''),
        );
      case 'setType':
        return DropdownButtonFormField<String>(
          initialValue: action.value.isEmpty ? 'expense' : action.value,
          isDense: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
          items: const [
            DropdownMenuItem(value: 'expense', child: Text('支出')),
            DropdownMenuItem(value: 'income', child: Text('收入')),
            DropdownMenuItem(value: 'transfer', child: Text('转账')),
          ],
          onChanged: (v) => setState(() => action.value = v ?? 'expense'),
        );
      case 'addTag':
        final activeTags =
            widget.tags.where((t) => !t.isArchived).toList();
        return DropdownButtonFormField<String>(
          initialValue: action.value.isEmpty ? null : action.value,
          isDense: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
          items: activeTags
              .map((t) =>
                  DropdownMenuItem(value: t.key, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() => action.value = v ?? ''),
        );
      case 'setAccount':
        final visibleAccounts =
            widget.accounts.where((a) => !a.isHidden).toList();
        return DropdownButtonFormField<String>(
          initialValue: action.value.isEmpty ? null : action.value,
          isDense: true,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
          items: visibleAccounts
              .map((a) => DropdownMenuItem(
                  value: a.id.toString(), child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => action.value = v ?? ''),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Mutable helper classes for editor state
// ---------------------------------------------------------------------------

class _ConditionRow {
  _ConditionRow({
    required this.field,
    required this.operator,
    required this.valueCtrl,
    required this.secondValueCtrl,
  });

  factory _ConditionRow.empty() => _ConditionRow(
        field: 'description',
        operator: 'contains',
        valueCtrl: TextEditingController(),
        secondValueCtrl: TextEditingController(),
      );

  String field;
  String operator;
  final TextEditingController valueCtrl;
  final TextEditingController secondValueCtrl;
}

class _ActionRow {
  _ActionRow({required this.type, required this.value});

  factory _ActionRow.empty() =>
      _ActionRow(type: 'setCategory', value: '');

  String type;
  String value;
}
