import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/auto_account_mapping.dart';

class AutoAccountMappingScreen extends StatefulWidget {
  const AutoAccountMappingScreen({super.key, required this.isar});

  final Isar isar;

  @override
  State<AutoAccountMappingScreen> createState() => _AutoAccountMappingScreenState();
}

class _AutoAccountMappingScreenState extends State<AutoAccountMappingScreen> {
  bool _loading = true;
  List<JiveAccount> _accounts = [];
  List<AutoAccountMapping> _mappings = [];
  final Map<int, JiveAccount> _accountById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AccountService(widget.isar).getActiveAccounts();
    final mappings = await AutoAccountMappingStore.load();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _mappings = mappings;
      _accountById
        ..clear()
        ..addEntries(accounts.map((account) => MapEntry(account.id, account)));
      _loading = false;
    });
  }

  Future<void> _addMapping() async {
    if (_accounts.isEmpty) {
      _showMessage('请先创建账户');
      return;
    }
    final patternController = TextEditingController();
    var useRegex = false;
    int? accountId = _accounts.first.id;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增账户映射'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: patternController,
                    decoration: const InputDecoration(
                      labelText: '匹配关键词',
                      hintText: '如：银行卡尾号1234 / 余额宝',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: '映射到账户'),
                    items: [
                      for (final account in _accounts)
                        DropdownMenuItem(value: account.id, child: Text(account.name)),
                    ],
                    onChanged: (value) => setDialogState(() => accountId = value),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('使用正则匹配'),
                    value: useRegex,
                    onChanged: (value) => setDialogState(() => useRegex = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final rawPattern = patternController.text.trim();
    if (rawPattern.isEmpty || accountId == null) {
      _showMessage('请输入关键词并选择账户');
      return;
    }

    final pattern = useRegex ? rawPattern : AutoAccountMappingStore.sanitizePattern(rawPattern);
    if (pattern.isEmpty) {
      _showMessage('关键词无效，请重新输入');
      return;
    }

    await AutoAccountMappingStore.upsert(
      AutoAccountMapping(pattern: pattern, accountId: accountId!, regex: useRegex),
    );
    await _load();
  }

  Future<void> _deleteMapping(AutoAccountMapping mapping) async {
    final next = [
      for (final entry in _mappings)
        if (entry.pattern != mapping.pattern || entry.regex != mapping.regex) entry,
    ];
    await AutoAccountMappingStore.save(next);
    await _load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户映射规则'),
        actions: [
          IconButton(
            onPressed: _addMapping,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mappings.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemBuilder: (context, index) {
                    final mapping = _mappings[index];
                    final accountName = _accountById[mapping.accountId]?.name ?? '已删除账户';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(mapping.regex ? Icons.code : Icons.link),
                      title: Text(mapping.pattern),
                      subtitle: Text('映射到：$accountName'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteMapping(mapping),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _mappings.length,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMapping,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('暂无映射规则', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _addMapping,
            child: const Text('新增映射'),
          ),
        ],
      ),
    );
  }
}
