import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/instalment_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/instalment_service.dart';
import 'add_instalment_screen.dart';

enum _InstalmentAction { markPaid, edit, delete }

class InstalmentListScreen extends StatefulWidget {
  const InstalmentListScreen({super.key});

  @override
  State<InstalmentListScreen> createState() => _InstalmentListScreenState();
}

class _InstalmentListScreenState extends State<InstalmentListScreen> {
  final DateFormat _dateFormat = DateFormat('MM月dd日');
  Isar? _isar;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _loadError;
  List<JiveInstalment> _instalments = [];

  @override
  void initState() {
    super.initState();
    _loadInstalments();
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  Future<void> _loadInstalments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final isar = await _ensureIsar();
      final instalments = await InstalmentService(isar).getAll();
      if (!mounted) return;
      setState(() {
        _instalments = instalments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _instalments = [];
        _loadError = '加载分期失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({JiveInstalment? instalment}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddInstalmentScreen(
          editingInstalment: instalment,
        ),
      ),
    );
    if (saved != true) return;
    await _loadInstalments();
  }

  Future<void> _handleAction(
    _InstalmentAction action,
    JiveInstalment instalment,
  ) async {
    switch (action) {
      case _InstalmentAction.markPaid:
        await _markPaid(instalment);
        break;
      case _InstalmentAction.edit:
        await _openForm(instalment: instalment);
        break;
      case _InstalmentAction.delete:
        await _deleteInstalment(instalment);
        break;
    }
  }

  Future<void> _showActionSheet(JiveInstalment instalment) async {
    final actions = _availableActions(instalment);
    final selected = await showModalBottomSheet<_InstalmentAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: actions
                .map(
                  (action) => ListTile(
                    leading: Icon(_iconForAction(action)),
                    title: Text(_labelForAction(action)),
                    onTap: () => Navigator.pop(context, action),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected == null) return;
    await _handleAction(selected, instalment);
  }

  List<_InstalmentAction> _availableActions(JiveInstalment instalment) {
    final actions = <_InstalmentAction>[];
    if (instalment.status == 'active') {
      actions.add(_InstalmentAction.markPaid);
    }
    actions.add(_InstalmentAction.edit);
    actions.add(_InstalmentAction.delete);
    return actions;
  }

  Future<void> _markPaid(JiveInstalment instalment) async {
    if (_isProcessing) return;
    if (mounted) {
      setState(() => _isProcessing = true);
    }
    try {
      final isar = await _ensureIsar();
      final updated = await InstalmentService(isar).markPaid(instalment.id);
      await _loadInstalments();
      if (!mounted || updated == null) return;
      final message = updated.status == 'completed'
          ? '${updated.name} 已完成全部还款'
          : '${updated.name} 已记录本期付款';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('记录付款失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteInstalment(JiveInstalment instalment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分期'),
        content: Text('确定删除“${instalment.name}”？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final isar = await _ensureIsar();
      await InstalmentService(isar).delete(instalment.id);
      await _loadInstalments();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分期已删除')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeInstalments = _instalments
        .where((item) => item.status == 'active')
        .toList();
    final completedInstalments = _instalments
        .where((item) => item.status != 'active')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '分期管理',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '进行中'),
              Tab(text: '已完成'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: JiveTheme.primaryGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('新增分期'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildErrorState()
            : TabBarView(
                children: [
                  _buildInstalmentList(
                    items: activeInstalments,
                    emptyTitle: '还没有进行中的分期',
                    emptySubtitle: '新增信用卡分期或贷款计划后，会显示在这里。',
                    emptyIcon: Icons.credit_card_outlined,
                  ),
                  _buildInstalmentList(
                    items: completedInstalments,
                    emptyTitle: '还没有已完成分期',
                    emptySubtitle: '已还清或已取消的分期会显示在这里。',
                    emptyIcon: Icons.task_alt_outlined,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              '分期加载失败',
              style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInstalments,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalmentList({
    required List<JiveInstalment> items,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emptyIcon,
                  size: 48,
                  color: JiveTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyTitle,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInstalments,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildInstalmentCard(items[index]),
      ),
    );
  }

  Widget _buildInstalmentCard(JiveInstalment instalment) {
    final progress = instalment.instalmentCount <= 0
        ? 0.0
        : instalment.paidCount / instalment.instalmentCount;
    final progressValue = progress < 0
        ? 0.0
        : progress > 1
        ? 1.0
        : progress;
    final statusColor = _statusColor(instalment.status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onLongPress: () => _showActionSheet(instalment),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.payments_outlined, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instalment.name,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已还 ${instalment.paidCount}/${instalment.instalmentCount} 期',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(instalment),
                PopupMenuButton<_InstalmentAction>(
                  onSelected: (action) => _handleAction(action, instalment),
                  itemBuilder: (context) => _availableActions(instalment)
                      .map(
                        (action) => PopupMenuItem<_InstalmentAction>(
                          value: action,
                          child: Text(_labelForAction(action)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  icon: Icons.schedule_outlined,
                  text: '每月 ¥${instalment.monthlyAmount.toStringAsFixed(2)}',
                ),
                _buildMetaChip(
                  icon: Icons.event_outlined,
                  text: instalment.status == 'active'
                      ? '下次 ${_dateFormat.format(instalment.nextPaymentDate)}'
                      : _statusText(instalment.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(JiveInstalment instalment) {
    final color = _statusColor(instalment.status);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusText(instalment.status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return JiveTheme.primaryGreen;
      case 'cancelled':
        return Colors.orange.shade700;
      case 'active':
      default:
        return Colors.blue.shade700;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'active':
      default:
        return '进行中';
    }
  }

  String _labelForAction(_InstalmentAction action) {
    switch (action) {
      case _InstalmentAction.markPaid:
        return '标记本期已还';
      case _InstalmentAction.edit:
        return '编辑';
      case _InstalmentAction.delete:
        return '删除';
    }
  }

  IconData _iconForAction(_InstalmentAction action) {
    switch (action) {
      case _InstalmentAction.markPaid:
        return Icons.check_circle_outline;
      case _InstalmentAction.edit:
        return Icons.edit_outlined;
      case _InstalmentAction.delete:
        return Icons.delete_outline;
    }
  }
}
