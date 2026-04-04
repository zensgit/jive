import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/database/shared_ledger_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/shared_ledger_service.dart';

/// Screen for managing shared family ledgers.
class SharedLedgerScreen extends StatefulWidget {
  const SharedLedgerScreen({super.key});

  @override
  State<SharedLedgerScreen> createState() => _SharedLedgerScreenState();
}

class _SharedLedgerScreenState extends State<SharedLedgerScreen> {
  List<JiveSharedLedger> _ledgers = [];
  bool _isLoading = true;
  late SharedLedgerService _service;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isar = await DatabaseService.getInstance();
    _service = SharedLedgerService(isar);
    await _load();
  }

  Future<void> _load() async {
    final ledgers = await _service.getLedgers();
    if (mounted) {
      setState(() {
        _ledgers = ledgers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('家庭共享账本', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: '加入账本',
            onPressed: _showJoinDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: JiveTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ledgers.isEmpty
              ? _buildEmptyState()
              : _buildLedgerList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('还没有共享账本', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              '创建一个共享账本，邀请家人一起记账',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _showJoinDialog,
                  icon: const Icon(Icons.login),
                  label: const Text('加入'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('创建'),
                  style: FilledButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _ledgers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildLedgerCard(_ledgers[i]),
      ),
    );
  }

  Widget _buildLedgerCard(JiveSharedLedger ledger) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: JiveTheme.primaryGreen.withAlpha(30),
              child: Icon(Icons.family_restroom, color: JiveTheme.primaryGreen),
            ),
            title: Text(ledger.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _roleChip(ledger.role),
                    const SizedBox(width: 8),
                    Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${ledger.memberCount}人', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => [
                if (ledger.inviteCode != null)
                  const PopupMenuItem(value: 'invite', child: Text('邀请码')),
                const PopupMenuItem(value: 'members', child: Text('成员管理')),
                if (ledger.isOwner)
                  const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (action) => _handleAction(ledger, action),
            ),
          ),
          if (ledger.inviteCode != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.vpn_key, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    '邀请码: ${ledger.inviteCode}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: ledger.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('邀请码已复制'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Icon(Icons.copy, size: 14, color: JiveTheme.primaryGreen),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    final (label, color) = switch (role) {
      'owner' => ('管理员', JiveTheme.primaryGreen),
      'admin' => ('管理', Colors.blue),
      'readonly' => ('只读', Colors.grey),
      _ => ('成员', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建共享账本'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '如: 家庭日常开支',
            border: OutlineInputBorder(),
            labelText: '账本名称',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (result == null || result.isEmpty) return;

    await _service.createLedger(name: result, ownerUserId: 'local_user');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已创建"$result"')),
      );
    }
  }

  Future<void> _showJoinDialog() async {
    final codeCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加入共享账本'),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: '输入6位邀请码',
            border: OutlineInputBorder(),
            labelText: '邀请码',
          ),
          maxLength: 6,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim().toUpperCase()),
            style: FilledButton.styleFrom(backgroundColor: JiveTheme.primaryGreen),
            child: const Text('加入'),
          ),
        ],
      ),
    );
    codeCtrl.dispose();
    if (result == null || result.length != 6) return;

    final success = await _service.joinByInviteCode(
      inviteCode: result,
      userId: 'local_user',
      displayName: '新成员',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '已加入共享账本' : '邀请码无效')),
      );
      if (success) await _load();
    }
  }

  Future<void> _handleAction(JiveSharedLedger ledger, String action) async {
    switch (action) {
      case 'invite':
        if (ledger.inviteCode != null) {
          await Clipboard.setData(ClipboardData(text: ledger.inviteCode!));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('邀请码 ${ledger.inviteCode} 已复制')),
            );
          }
        }
        break;
      case 'members':
        await _showMembersDialog(ledger);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除共享账本'),
            content: Text('确定删除"${ledger.name}"吗？此操作不可撤销。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _service.deleteLedger(ledger.key);
          await _load();
        }
        break;
    }
  }

  Future<void> _showMembersDialog(JiveSharedLedger ledger) async {
    final members = await _service.getMembers(ledger.key);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${ledger.name} · 成员'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Text(m.displayName.isNotEmpty ? m.displayName[0] : '?'),
                ),
                title: Text(m.displayName),
                trailing: _roleChip(m.role),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }
}
