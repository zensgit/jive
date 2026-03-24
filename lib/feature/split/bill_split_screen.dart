import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/bill_split_model.dart';

class BillSplitScreen extends StatefulWidget {
  const BillSplitScreen({super.key});

  @override
  State<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends State<BillSplitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<JiveBillSplit> _open = [];
  List<JiveBillSplit> _settled = [];
  Map<int, List<JiveSplitMember>> _membersMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = Isar.getInstance()!;
    final splits = await isar.collection<JiveBillSplit>().where().findAll();
    final members = await isar.collection<JiveSplitMember>().where().findAll();

    final map = <int, List<JiveSplitMember>>{};
    for (final m in members) {
      map.putIfAbsent(m.splitId, () => []).add(m);
    }

    if (mounted) {
      setState(() {
        _open = splits.where((s) => s.status == 'open').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _settled = splits.where((s) => s.status == 'settled').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _membersMap = map;
        _loading = false;
      });
    }
  }

  Future<void> _settleAll(JiveBillSplit split) async {
    final members = _membersMap[split.id] ?? [];
    final isar = Isar.getInstance()!;
    final now = DateTime.now();
    await isar.writeTxn(() async {
      for (final m in members) {
        m.isPaid = true;
        m.paidAt = now;
        m.updatedAt = now;
        await isar.collection<JiveSplitMember>().put(m);
      }
      split.status = 'settled';
      split.updatedAt = now;
      await isar.collection<JiveBillSplit>().put(split);
    });
    _load();
  }

  Future<void> _delete(JiveBillSplit split) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除账单'),
        content: const Text('确定删除这条拆单记录？相关成员数据也将一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final isar = Isar.getInstance()!;
    final memberIds =
        (_membersMap[split.id] ?? []).map((m) => m.id).toList();
    await isar.writeTxn(() async {
      await isar.collection<JiveSplitMember>().deleteAll(memberIds);
      await isar.collection<JiveBillSplit>().delete(split.id);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AA 账单拆分', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '未结清'),
            Tab(text: '已结清'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建拆单',
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_open, settled: false),
                _buildList(_settled, settled: true),
              ],
            ),
    );
  }

  Widget _buildList(List<JiveBillSplit> items, {required bool settled}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              '还没有拆单记录',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settled ? '暂无已结清的拆单' : '点击右上角 + 创建新的AA账单',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            if (!settled) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建拆单'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final split = items[i];
          final members = _membersMap[split.id] ?? [];
          return _BillSplitCard(
            split: split,
            members: members,
            onSettleAll: split.status == 'open' ? () => _settleAll(split) : null,
            onEdit: () => _showCreateDialog(existing: split),
            onDelete: () => _delete(split),
            onManageMembers: () => _showMembersDialog(split),
          );
        },
      ),
    );
  }

  // ─── Create / Edit Dialog ───────────────────────────────────────────────────

  Future<void> _showCreateDialog({JiveBillSplit? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.totalAmount.toStringAsFixed(2) : '');
    final payerCtrl = TextEditingController(text: existing?.paidByName ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    // Seed member rows from existing data
    final existingMembers = existing != null
        ? List<JiveSplitMember>.from(_membersMap[existing.id] ?? [])
        : <JiveSplitMember>[];

    // Each row: {name, amount} controllers
    final List<Map<String, TextEditingController>> memberRows = existingMembers
        .map((m) => {
              'name': TextEditingController(text: m.name),
              'amount': TextEditingController(
                  text: m.shareAmount.toStringAsFixed(2)),
            })
        .toList();

    if (memberRows.isEmpty) {
      memberRows.add({
        'name': TextEditingController(),
        'amount': TextEditingController(),
      });
    }

    String? shareWarning;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) {
          void recalcWarning() {
            final total = double.tryParse(amountCtrl.text) ?? 0;
            final sum = memberRows.fold<double>(
              0,
              (s, r) => s + (double.tryParse(r['amount']!.text) ?? 0),
            );
            if (total > 0 && (sum - total).abs() > 0.01) {
              setLS(() => shareWarning =
                  '成员分摊总额 ${sum.toStringAsFixed(2)} 与账单总额 ${total.toStringAsFixed(2)} 不符');
            } else {
              setLS(() => shareWarning = null);
            }
          }

          void distributeEvenly() {
            final total = double.tryParse(amountCtrl.text) ?? 0;
            if (total <= 0 || memberRows.isEmpty) return;
            final each = total / memberRows.length;
            for (final r in memberRows) {
              r['amount']!.text = each.toStringAsFixed(2);
            }
            setLS(() => shareWarning = null);
          }

          return AlertDialog(
            title: Text(existing == null ? '新建拆单' : '编辑拆单'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: '账单标题 *',
                        border: OutlineInputBorder(),
                        hintText: '如：日本旅行餐费',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Total amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '总金额 *',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                      ),
                      onChanged: (_) => recalcWarning(),
                    ),
                    const SizedBox(height: 12),
                    // Payer
                    TextField(
                      controller: payerCtrl,
                      decoration: const InputDecoration(
                        labelText: '付款人',
                        border: OutlineInputBorder(),
                        hintText: '谁垫付了这笔费用？',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Note
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Members header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '参与成员',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        TextButton.icon(
                          onPressed: distributeEvenly,
                          icon: const Icon(Icons.auto_fix_high, size: 16),
                          label: const Text('平均分配'),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Member rows
                    ...List.generate(memberRows.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: memberRows[i]['name'],
                                decoration: InputDecoration(
                                  labelText: '姓名',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  hintText: '成员 ${i + 1}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: memberRows[i]['amount'],
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '金额',
                                  border: OutlineInputBorder(),
                                  prefixText: '¥',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                                onChanged: (_) => recalcWarning(),
                              ),
                            ),
                            if (memberRows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  setLS(() => memberRows.removeAt(i));
                                  recalcWarning();
                                },
                              )
                            else
                              const SizedBox(width: 40),
                          ],
                        ),
                      );
                    }),
                    // Add member button
                    TextButton.icon(
                      onPressed: () {
                        setLS(() => memberRows.add({
                              'name': TextEditingController(),
                              'amount': TextEditingController(),
                            }));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加成员'),
                    ),
                    // Warning banner
                    if (shareWarning != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shareWarning!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final total = double.tryParse(amountCtrl.text) ?? 0;
                  if (title.isEmpty || total <= 0) return;

                  final isar = Isar.getInstance()!;
                  final now = DateTime.now();

                  final split = existing ?? JiveBillSplit();
                  split
                    ..key = existing?.key ?? const Uuid().v4()
                    ..title = title
                    ..totalAmount = total
                    ..paidByName = payerCtrl.text.trim().isEmpty
                        ? null
                        : payerCtrl.text.trim()
                    ..note = noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim()
                    ..updatedAt = now;
                  if (existing == null) split.createdAt = now;

                  // Delete old members if editing
                  final oldMemberIds =
                      (existing != null ? _membersMap[existing.id] ?? [] : <JiveSplitMember>[])
                          .map((m) => m.id)
                          .toList();

                  await isar.writeTxn(() async {
                    final savedId =
                        await isar.collection<JiveBillSplit>().put(split);
                    if (oldMemberIds.isNotEmpty) {
                      await isar
                          .collection<JiveSplitMember>()
                          .deleteAll(oldMemberIds);
                    }
                    for (final row in memberRows) {
                      final name = row['name']!.text.trim();
                      final amt =
                          double.tryParse(row['amount']!.text) ?? 0;
                      if (name.isEmpty) continue;
                      final member = JiveSplitMember()
                        ..splitId = savedId
                        ..name = name
                        ..shareAmount = amt
                        ..isPaid = false
                        ..createdAt = now
                        ..updatedAt = now;
                      await isar.collection<JiveSplitMember>().put(member);
                    }
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Members Dialog ─────────────────────────────────────────────────────────

  Future<void> _showMembersDialog(JiveBillSplit split) async {
    final members = List<JiveSplitMember>.from(_membersMap[split.id] ?? []);
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该账单暂无成员')));
      return;
    }

    final fmt = NumberFormat('#,##0.00');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
          title: Text(split.title, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...members.map((m) {
                  return _MemberTile(
                    member: m,
                    fmt: fmt,
                    onToggle: () async {
                      final isar = Isar.getInstance()!;
                      final now = DateTime.now();
                      m.isPaid = !m.isPaid;
                      m.paidAt = m.isPaid ? now : null;
                      m.updatedAt = now;
                      await isar.writeTxn(() async {
                        await isar.collection<JiveSplitMember>().put(m);
                      });
                      setLS(() {});
                      _load();
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bill Split Card ──────────────────────────────────────────────────────────

class _BillSplitCard extends StatelessWidget {
  const _BillSplitCard({
    required this.split,
    required this.members,
    required this.onSettleAll,
    required this.onEdit,
    required this.onDelete,
    required this.onManageMembers,
  });

  final JiveBillSplit split;
  final List<JiveSplitMember> members;
  final VoidCallback? onSettleAll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageMembers;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final isOpen = split.status == 'open';
    final unpaidTotal = members
        .where((m) => !m.isPaid)
        .fold<double>(0, (s, m) => s + m.shareAmount);
    final accentColor = isOpen ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOpen ? Colors.blue.shade100 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onManageMembers,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.group_outlined, size: 20, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          split.title,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (split.note != null && split.note!.isNotEmpty)
                          Text(
                            split.note!,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${fmt.format(split.totalAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        split.currency,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
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
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              // ── Payer info ───────────────────────────────────────────────
              if (split.paidByName != null && split.paidByName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${split.paidByName} 垫付',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // ── Member chips ─────────────────────────────────────────────
              if (members.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: members.map((m) {
                    final chipColor =
                        m.isPaid ? Colors.green.shade600 : Colors.orange.shade700;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: chipColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '¥${fmt.format(m.shareAmount)}',
                            style: TextStyle(
                                fontSize: 11, color: chipColor.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              // ── Footer: outstanding + settle button ──────────────────────
              Row(
                children: [
                  if (isOpen) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: unpaidTotal > 0
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unpaidTotal > 0
                            ? '待收 ¥${fmt.format(unpaidTotal)}'
                            : '全部已付',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unpaidTotal > 0
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onSettleAll != null)
                      FilledButton.tonal(
                        onPressed: onSettleAll,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                        ),
                        child: const Text('一键结清', style: TextStyle(fontSize: 13)),
                      ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 13, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '已结清',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Member Tile ──────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.fmt,
    required this.onToggle,
  });

  final JiveSplitMember member;
  final NumberFormat fmt;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isPaid = member.isPaid;
    final badgeColor = isPaid ? Colors.green.shade600 : Colors.orange.shade700;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: badgeColor.withValues(alpha: 0.12),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (member.paidAt != null)
                    Text(
                      '付款于 ${DateFormat('MM/dd HH:mm').format(member.paidAt!)}',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                ],
              ),
            ),
            Text(
              '¥${fmt.format(member.shareAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPaid ? '已付' : '未付',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
