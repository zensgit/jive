import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/user_auto_rule_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/auto_rule_engine.dart';
import '../../core/service/database_service.dart';

/// Screen to view built-in rules and manage user-defined auto-categorization rules.
class AutoRuleEditorScreen extends StatefulWidget {
  const AutoRuleEditorScreen({super.key});

  @override
  State<AutoRuleEditorScreen> createState() => _AutoRuleEditorScreenState();
}

class _AutoRuleEditorScreenState extends State<AutoRuleEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AutoRule> _builtInRules = [];
  List<JiveUserAutoRule> _userRules = [];
  Map<String, JiveCategory> _categoryByKey = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final engine = await AutoRuleEngine.instance();
    final isar = await DatabaseService.getInstance();
    final userRules = await isar.jiveUserAutoRules.where().sortByPriority().findAll();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    if (mounted) {
      setState(() {
        _builtInRules = engine.rules;
        _userRules = userRules;
        _categoryByKey = categoryMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('自动分类规则', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: JiveTheme.primaryGreen,
          tabs: [
            Tab(text: '自定义 (${_userRules.length})'),
            Tab(text: '内置 (${_builtInRules.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRuleDialog,
        backgroundColor: JiveTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserRulesList(),
                _buildBuiltInRulesList(),
              ],
            ),
    );
  }

  Widget _buildUserRulesList() {
    if (_userRules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('暂无自定义规则', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('点击右下角 + 添加', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _userRules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildUserRuleCard(_userRules[i]),
    );
  }

  Widget _buildUserRuleCard(JiveUserAutoRule rule) {
    final catName = rule.parentCategoryKey != null
        ? (_categoryByKey[rule.parentCategoryKey]?.name ?? rule.parentCategoryKey!)
        : '未指定';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rule.isEnabled ? Colors.grey.shade200 : Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.auto_fix_high,
          color: rule.isEnabled ? JiveTheme.primaryGreen : Colors.grey,
        ),
        title: Text(
          rule.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: rule.isEnabled ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关键词: ${rule.keywords}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '分类: $catName · 类型: ${_typeLabel(rule.type)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: rule.isEnabled ? 'disable' : 'enable',
              child: Text(rule.isEnabled ? '停用' : '启用'),
            ),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (action) => _handleRuleAction(rule, action),
        ),
      ),
    );
  }

  Widget _buildBuiltInRulesList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _builtInRules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final rule = _builtInRules[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.rule, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      '关键词: ${rule.keywords.join(", ")}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (rule.parent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryByKey[rule.parent]?.name ?? rule.parent!,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddRuleDialog({JiveUserAutoRule? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final keywordsCtrl = TextEditingController(text: editing?.keywords ?? '');
    final sourceCtrl = TextEditingController(text: editing?.source ?? '');
    String type = editing?.type ?? 'expense';
    String? parentKey = editing?.parentCategoryKey;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(editing == null ? '新建规则' : '编辑规则'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '规则名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keywordsCtrl,
                  decoration: const InputDecoration(
                    labelText: '关键词（逗号分隔）',
                    hintText: '如：美团,外卖',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sourceCtrl,
                  decoration: const InputDecoration(
                    labelText: '来源（可选）',
                    hintText: '如：微信支付',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: '类型', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('支出')),
                    DropdownMenuItem(value: 'income', child: Text('收入')),
                    DropdownMenuItem(value: 'transfer', child: Text('转账')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: parentKey,
                  decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('不指定')),
                    ..._categoryByKey.entries
                        .where((e) => e.value.parentKey == null || e.value.parentKey!.isEmpty)
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.name))),
                  ],
                  onChanged: (v) => setDialogState(() => parentKey = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != true) {
      nameCtrl.dispose();
      keywordsCtrl.dispose();
      sourceCtrl.dispose();
      return;
    }

    final isar = await DatabaseService.getInstance();
    await isar.writeTxn(() async {
      final rule = editing ?? JiveUserAutoRule();
      rule.name = nameCtrl.text.trim();
      rule.keywords = keywordsCtrl.text.trim();
      rule.source = sourceCtrl.text.trim().isEmpty ? null : sourceCtrl.text.trim();
      rule.type = type;
      rule.parentCategoryKey = parentKey;
      rule.updatedAt = DateTime.now();
      await isar.jiveUserAutoRules.put(rule);
    });

    nameCtrl.dispose();
    keywordsCtrl.dispose();
    sourceCtrl.dispose();
    await _load();
  }

  Future<void> _handleRuleAction(JiveUserAutoRule rule, String action) async {
    final isar = await DatabaseService.getInstance();
    switch (action) {
      case 'enable':
      case 'disable':
        await isar.writeTxn(() async {
          rule.isEnabled = action == 'enable';
          rule.updatedAt = DateTime.now();
          await isar.jiveUserAutoRules.put(rule);
        });
        await _load();
        break;
      case 'edit':
        await _showAddRuleDialog(editing: rule);
        break;
      case 'delete':
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除规则'),
            content: Text('确定删除"${rule.name}"吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await isar.writeTxn(() async {
          await isar.jiveUserAutoRules.delete(rule.id);
        });
        await _load();
        break;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income': return '收入';
      case 'transfer': return '转账';
      default: return '支出';
    }
  }
}
