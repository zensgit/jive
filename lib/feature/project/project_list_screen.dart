import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../../core/database/project_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/project_service.dart';
import '../../core/design_system/theme.dart';
import '../tag/tag_icon_catalog.dart';
import 'project_form_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  Isar? _isar;
  bool _isLoading = true;
  List<JiveProject> _activeProjects = [];
  List<JiveProject> _otherProjects = [];
  Map<int, double> _projectSpending = {};
  Map<int, int> _projectTransactionCount = {};
  double _totalBudget = 0;
  double _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);

    final isar = await _ensureIsar();
    final service = ProjectService(isar);
    final grouped = await service.getProjectsGrouped();

    final active = <JiveProject>[];
    final other = <JiveProject>[];
    final spending = <int, double>{};
    final txCount = <int, int>{};
    double totalBudget = 0;
    double totalSpent = 0;

    for (final entry in grouped.entries) {
      for (final project in entry.value) {
        final spent = await service.calculateProjectSpending(project.id);
        final txs = await service.getProjectTransactions(project.id);
        spending[project.id] = spent;
        txCount[project.id] = txs.length;

        if (entry.key == '进行中') {
          active.add(project);
          totalBudget += project.budget;
          totalSpent += spent;
        } else {
          other.add(project);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _activeProjects = active;
      _otherProjects = other;
      _projectSpending = spending;
      _projectTransactionCount = txCount;
      _totalBudget = totalBudget;
      _totalSpent = totalSpent;
      _isLoading = false;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    _isar = await DatabaseService.getInstance();
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeProjects.isEmpty && _otherProjects.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch_outlined, size: 56, color: JiveTheme.primaryGreen),
              ),
              const SizedBox(height: 32),
              Text(
                '开始追踪您的项目',
                style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                '创建项目来追踪旅行、装修、婚礼等\n专项支出，轻松掌控每一笔开销',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('创建第一个项目', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // 顶部大标题区域
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        // 进行中的项目
        if (_activeProjects.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '进行中',
                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProjectCard(_activeProjects[index], isActive: true),
                childCount: _activeProjects.length,
              ),
            ),
          ),
        ],
        // 已完成/已归档的项目
        if (_otherProjects.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '已完成 / 已归档',
                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProjectCard(_otherProjects[index], isActive: false),
                childCount: _otherProjects.length,
              ),
            ),
          ),
        ],
        // 底部间距
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    final progress = _totalBudget > 0 ? (_totalSpent / _totalBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JiveTheme.primaryGreen,
            JiveTheme.primaryGreen.withOpacity(0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '项目追踪',
                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _createProject,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // 总览数据
          if (_activeProjects.isNotEmpty) ...[
            Text(
              '进行中项目总支出',
              style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              '¥${_formatLargeAmount(_totalSpent)}',
              style: GoogleFonts.rubik(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (_totalBudget > 0) ...[
              const SizedBox(height: 20),
              // 进度条
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '总预算 ¥${_formatLargeAmount(_totalBudget)}',
                    style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ],
          ] else ...[
            Text(
              '暂无进行中的项目',
              style: GoogleFonts.lato(fontSize: 15, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 创建新项目',
              style: GoogleFonts.lato(fontSize: 13, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectCard(JiveProject project, {required bool isActive}) {
    final spent = _projectSpending[project.id] ?? 0;
    final txCount = _projectTransactionCount[project.id] ?? 0;
    final progress = project.budget > 0 ? (spent / project.budget).clamp(0.0, 1.0) : 0.0;
    final remaining = project.budget > 0 ? project.budget - spent : 0.0;
    final color = project.colorHex != null
        ? Color(int.parse(project.colorHex!.replaceFirst('#', '0xFF')))
        : JiveTheme.primaryGreen;

    final isOverBudget = remaining < 0;
    final progressColor = isOverBudget ? Colors.red : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProject(project),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部
                Row(
                  children: [
                    // 图标
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: iconWidgetForName(project.iconName, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    // 名称
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          if (project.description != null && project.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              project.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 状态/箭头
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.status == 'completed' ? '已完成' : '已归档',
                          style: GoogleFonts.lato(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      )
                    else
                      Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 24),
                  ],
                ),
                const SizedBox(height: 20),
                // 金额区域
                if (project.budget > 0) ...[
                  // 金额数字
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('已支出', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text(
                              '¥${_formatLargeAmount(spent)}',
                              style: GoogleFonts.rubik(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isOverBudget ? Colors.red : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOverBudget ? Colors.red.shade50 : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isOverBudget ? '超支' : '剩余',
                              style: GoogleFonts.lato(fontSize: 11, color: isOverBudget ? Colors.red : color),
                            ),
                            Text(
                              '¥${_formatLargeAmount(remaining.abs())}',
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isOverBudget ? Colors.red : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 进度条
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [progressColor, progressColor.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 预算和百分比
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '预算 ¥${_formatLargeAmount(project.budget)}',
                        style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: progressColor),
                      ),
                    ],
                  ),
                ] else ...[
                  // 无预算
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('已支出', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            '¥${_formatLargeAmount(spent)}',
                            style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '无预算限制',
                          style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
                // 底部信息
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        '$txCount 笔交易',
                        style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDateRange(project),
                          style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLargeAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(amount >= 100000 ? 0 : 1)}万';
    } else if (amount >= 1000) {
      return NumberFormat('#,##0', 'en_US').format(amount.round());
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDateRange(JiveProject project) {
    final dateFormat = DateFormat('MM/dd');
    final start = project.startDate != null ? dateFormat.format(project.startDate!) : '未设置';
    if (project.endDate != null) {
      return '$start - ${dateFormat.format(project.endDate!)}';
    }
    return '始于 $start';
  }

  void _createProject() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ProjectFormScreen()));
    if (result == true) _loadProjects();
  }

  void _openProject(JiveProject project) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProjectDetailScreen(projectId: project.id)));
    if (result == true) _loadProjects();
  }
}
