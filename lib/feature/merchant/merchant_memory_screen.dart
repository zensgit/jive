import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/merchant_memory_model.dart';
import '../../core/database/category_model.dart';
import '../../core/service/merchant_memory_service.dart';

/// 商户记忆管理页面 —— 可查看/编辑/删除/批量初始化
class MerchantMemoryScreen extends StatefulWidget {
  const MerchantMemoryScreen({super.key});

  @override
  State<MerchantMemoryScreen> createState() => _MerchantMemoryScreenState();
}

class _MerchantMemoryScreenState extends State<MerchantMemoryScreen> {
  late MerchantMemoryService _service;
  List<JiveMerchantMemory> _all = [];
  List<JiveMerchantMemory> _filtered = [];
  Map<String, String> _catNames = {};
  bool _loading = true;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = MerchantMemoryService(Isar.getInstance()!);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = Isar.getInstance()!;
    final merchants = await isar
        .collection<JiveMerchantMemory>()
        .where()
        .findAll()
      ..sort((a, b) => b.transactionCount.compareTo(a.transactionCount));

    final cats = await isar.collection<JiveCategory>().where().findAll();
    final catMap = <String, String>{};
    for (final c in cats) {
      catMap[c.key] = c.name;
    }

    if (mounted) {
      setState(() {
        _all = merchants;
        _filtered = merchants;
        _catNames = catMap;
        _loading = false;
      });
    }
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((m) =>
              m.displayName.toLowerCase().contains(lower) ||
              m.normalizedName.contains(lower) ||
              m.aliases.any((a) => a.toLowerCase().contains(lower))).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: '搜索商户...', border: InputBorder.none),
                onChanged: _onSearch,
              )
            : const Text('商户记忆'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  _filtered = _all;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'init') _initFromHistory();
              if (v == 'clear') _clearAll();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'init', child: Text('从历史记录初始化')),
              PopupMenuItem(
                value: 'clear',
                child: Text('清空全部', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? _EmptyState(
                  hasData: _all.isNotEmpty,
                  onInit: _initFromHistory,
                )
              : Column(
                  children: [
                    _StatsBar(total: _all.length, filtered: _filtered.length),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _MerchantCard(
                            memory: _filtered[i],
                            catNames: _catNames,
                            onEdit: () => _editMerchant(_filtered[i]),
                            onDelete: () => _deleteMerchant(_filtered[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _initFromHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('从历史记录初始化'),
        content: const Text('将扫描最近 500 条交易记录，\n自动建立商户记忆。\n\n已有记忆将被更新（不会删除）。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('开始初始化')),
        ],
      ),
    );
    if (confirm != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在初始化商户记忆...')),
      );
    }

    final count = await _service.learnFromHistory(limit: 500);
    _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已学习 $count 条历史记录')),
      );
    }
  }

  Future<void> _deleteMerchant(JiveMerchantMemory m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除商户记忆'),
        content: Text('删除"${m.displayName}"的记忆后，该商户将不再有自动填充建议。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Isar.getInstance()!.writeTxn(() async {
        await Isar.getInstance()!
            .collection<JiveMerchantMemory>()
            .delete(m.id);
      });
      _load();
    }
  }

  Future<void> _editMerchant(JiveMerchantMemory m) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MerchantEditScreen(
          memory: m,
          catNames: _catNames,
          onSave: (updated) async {
            await Isar.getInstance()!.writeTxn(() async {
              await Isar.getInstance()!
                  .collection<JiveMerchantMemory>()
                  .put(updated);
            });
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空全部商户记忆'),
        content: const Text('此操作不可恢复，确定要删除所有商户记忆吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Isar.getInstance()!.writeTxn(() async {
        await Isar.getInstance()!.collection<JiveMerchantMemory>().clear();
      });
      _load();
    }
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.total, required this.filtered});
  final int total;
  final int filtered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            filtered == total
                ? '共 $total 个商户记忆'
                : '显示 $filtered / $total',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Merchant card ────────────────────────────────────────────────────────────

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.memory,
    required this.catNames,
    required this.onEdit,
    required this.onDelete,
  });

  final JiveMerchantMemory memory;
  final Map<String, String> catNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final topCat = memory.topCategoryKey != null
        ? catNames[memory.topCategoryKey] ?? memory.topCategoryKey!
        : null;
    final topSubCat = memory.topSubCategoryKey != null
        ? catNames[memory.topSubCategoryKey] ?? memory.topSubCategoryKey!
        : null;

    // Parse category frequency
    Map<String, int> catFreq = {};
    try {
      final decoded = json.decode(memory.categoryFrequencyJson) as Map;
      catFreq = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (_) {}

    final sortedCats = catFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: memory.isUserConfirmed
              ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _MerchantAvatar(name: memory.displayName),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(memory.displayName,
                              style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        if (memory.isUserConfirmed)
                          const Icon(Icons.verified,
                              size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              size: 18, color: Colors.grey.shade400),
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('删除',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Category suggestion
                    if (topCat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined,
                                size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              topSubCat != null
                                  ? '$topCat › $topSubCat'
                                  : topCat,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    // Recent remarks
                    if (memory.recentRemarks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '备注: ${memory.recentRemarks.take(2).join('、')}',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Tags row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.receipt_long,
                          label: '${memory.transactionCount} 次',
                        ),
                        if (memory.averageAmount > 0)
                          _InfoChip(
                            icon: Icons.attach_money,
                            label: '均 ¥${memory.averageAmount.toStringAsFixed(0)}',
                          ),
                        if (sortedCats.length > 1)
                          _InfoChip(
                            icon: Icons.auto_graph,
                            label: '${sortedCats.length} 种分类',
                          ),
                        if (memory.aliases.isNotEmpty)
                          _InfoChip(
                            icon: Icons.link,
                            label: '${memory.aliases.length} 别名',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantAvatar extends StatelessWidget {
  const _MerchantAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final first = name.isNotEmpty ? name.characters.first : '?';
    final colors = [
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.purple.shade200,
      Colors.teal.shade200,
    ];
    final color = colors[name.hashCode.abs() % colors.length];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(first,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasData, required this.onInit});
  final bool hasData;
  final VoidCallback onInit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('暂无商户记忆',
              style: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('每次记账后自动学习商户偏好\n或点击下方从历史记录初始化',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onInit,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('从历史记录初始化'),
          ),
        ],
      ),
    );
  }
}

// ─── Edit screen ──────────────────────────────────────────────────────────────

class _MerchantEditScreen extends StatefulWidget {
  const _MerchantEditScreen({
    required this.memory,
    required this.catNames,
    required this.onSave,
  });

  final JiveMerchantMemory memory;
  final Map<String, String> catNames;
  final void Function(JiveMerchantMemory) onSave;

  @override
  State<_MerchantEditScreen> createState() => _MerchantEditScreenState();
}

class _MerchantEditScreenState extends State<_MerchantEditScreen> {
  final _nameCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    final m = widget.memory;
    _nameCtrl.text = m.displayName;
    _confirmed = m.isUserConfirmed;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑商户记忆'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Display name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '商户名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Confirmed toggle
          SwitchListTile(
            title: const Text('已手动确认'),
            subtitle: const Text('标记为已确认的商户具有更高的建议优先级'),
            secondary: const Icon(Icons.verified_outlined),
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          _buildSection('统计', [
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long, size: 20),
              title: const Text('交易次数'),
              trailing: Text('${m.transactionCount}'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.attach_money, size: 20),
              title: const Text('平均金额'),
              trailing: Text('¥${m.averageAmount.toStringAsFixed(2)}'),
            ),
            if (m.lastTransactionAt != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 20),
                title: const Text('最近交易'),
                trailing: Text(
                    DateFormat('yyyy/MM/dd').format(m.lastTransactionAt!)),
              ),
          ]),
          const SizedBox(height: 16),

          // Recent remarks
          if (m.recentRemarks.isNotEmpty)
            _buildSection('最近备注', [
              for (final r in m.recentRemarks)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.comment_outlined, size: 18),
                  title: Text(r, style: const TextStyle(fontSize: 14)),
                ),
            ]),
          if (m.recentRemarks.isNotEmpty) const SizedBox(height: 16),

          // Aliases
          _buildSection('别名列表', [
            for (final alias in m.aliases)
              ListTile(
                dense: true,
                leading: const Icon(Icons.link, size: 18),
                title: Text(alias),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    setState(() {
                      m.aliases.remove(alias);
                    });
                  },
                ),
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add, size: 18),
              title: TextField(
                controller: _aliasCtrl,
                decoration: const InputDecoration(
                  hintText: '添加别名...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      m.aliases.add(v.trim());
                      _aliasCtrl.clear();
                    });
                  }
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title,
              style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade600)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _save() {
    final m = widget.memory;
    m.displayName = _nameCtrl.text.trim().isEmpty ? m.displayName : _nameCtrl.text.trim();
    m.isUserConfirmed = _confirmed;
    m.updatedAt = DateTime.now();
    widget.onSave(m);
    Navigator.pop(context);
  }
}
