import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/template_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/project_service.dart';
import '../../core/design_system/theme.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Isar? _isar;
  bool _isLoading = true;
  JiveProject? _project;
  double _totalSpent = 0;
  List<JiveTransaction> _transactions = [];
  Map<String, double> _categoryStats = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final isar = await _ensureIsar();
    final project = await isar.jiveProjects.get(widget.projectId);
    if (project == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final service = ProjectService(isar);
    final spent = await service.calculateProjectSpending(widget.projectId);
    final transactions = await service.getProjectTransactions(widget.projectId);
    final stats = await service.getProjectCategoryStats(widget.projectId);

    if (!mounted) return;
    setState(() {
      _project = project;
      _totalSpent = spent;
      _transactions = transactions;
      _categoryStats = stats;
      _isLoading = false;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      JiveTransactionSchema, JiveCategorySchema, JiveCategoryOverrideSchema,
      JiveAccountSchema, JiveAutoDraftSchema, JiveTemplateSchema,
      JiveTagSchema, JiveProjectSchema,
    ], directory: dir.path);
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_project?.name ?? '项目详情'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            if (_project != null) ...[
              IconButton(icon: const Icon(Icons.edit), onPressed: _editProject),
              PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  if (_project!.status == 'active')
                    const PopupMenuItem(value: 'complete', child: Text('标记完成')),
                  const PopupMenuItem(value: 'archive', child: Text('归档')),
                  const PopupMenuItem(value: 'delete',
                      child: Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ],
        ),
        backgroundColor: JiveTheme.surfaceWhite,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
                ? const Center(child: Text('项目不存在'))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final project = _project!;
    final progress = project.budget > 0 ? (_totalSpent / project.budget).clamp(0.0, 1.0) : 0.0;
    final remaining = project.budget > 0 ? project.budget - _totalSpent : 0.0;
    final color = project.colorHex != null
        ? Color(int.parse(project.colorHex!.replaceFirst('#', '0xFF')))
        : JiveTheme.primaryGreen;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 概览卡片
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('已支出', style: GoogleFonts.lato(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('¥${_totalSpent.toStringAsFixed(2)}',
                    style: GoogleFonts.rubik(fontSize: 32, fontWeight: FontWeight.bold)),
                if (project.budget > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progress > 0.9 ? Colors.red : color),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('预算 ¥${project.budget.toStringAsFixed(0)}',
                          style: GoogleFonts.lato(color: Colors.grey.shade600)),
                      Text('剩余 ¥${remaining.toStringAsFixed(0)}',
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              color: remaining < 0 ? Colors.red : color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // 分类统计
        if (_categoryStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('按分类', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _categoryStats.entries.map((e) {
                final percent = _totalSpent > 0 ? (e.value / _totalSpent * 100) : 0;
                return ListTile(
                  title: Text(e.key),
                  trailing: Text('¥${e.value.toStringAsFixed(0)} (${percent.toStringAsFixed(0)}%)',
                      style: GoogleFonts.rubik(fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ),
        ],

        // 交易记录
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('交易记录', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${_transactions.length} 笔', style: GoogleFonts.lato(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('暂无交易记录', style: GoogleFonts.lato(color: Colors.grey)),
              ),
            ),
          )
        else
          ...List.generate(_transactions.length.clamp(0, 10), (i) {
            final tx = _transactions[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(tx.category ?? '未分类'),
                subtitle: Text(tx.timestamp.toString().substring(0, 16)),
                trailing: Text(
                  '${tx.type == 'income' ? '+' : '-'}¥${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w600,
                    color: tx.type == 'income' ? Colors.green : Colors.black87,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _editProject() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => ProjectFormScreen(project: _project)));
    if (result == true) {
      _hasChanges = true;
      _loadData();
    }
  }

  void _handleAction(String action) async {
    final service = ProjectService(_isar!);
    switch (action) {
      case 'complete':
        await service.completeProject(_project!);
        _hasChanges = true;
        _loadData();
        break;
      case 'archive':
        await service.archiveProject(_project!);
        _hasChanges = true;
        if (!mounted) return;
        Navigator.pop(context, true);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除项目'),
            content: const Text('删除后无法恢复，关联的交易不会被删除'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await service.deleteProject(_project!.id);
          if (!mounted) return;
          Navigator.pop(context, true);
        }
        break;
    }
  }
}
