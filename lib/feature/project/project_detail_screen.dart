import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/project_service.dart';
import '../../core/design_system/theme.dart';
import '../../core/widgets/transaction_filter_sheet.dart';
import '../tag/tag_icon_catalog.dart';
import '../transactions/transaction_detail_screen.dart';
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
  List<DailySpending> _dailySpending = [];
  List<DailySpending> _cumulativeSpending = [];
  final Map<String, JiveCategory> _categoryByKey = {};
  final Map<int, JiveAccount> _accountById = {};
  final DateFormat _timeFormat = DateFormat('MM-dd HH:mm');
  final TextEditingController _linkSearchController = TextEditingController();
  bool _showCumulative = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _linkSearchController.dispose();
    super.dispose();
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
    final daily = await service.getProjectDailySpending(widget.projectId, days: 14);
    final cumulative = await service.getProjectCumulativeSpending(widget.projectId, days: 14);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final accounts = await isar.collection<JiveAccount>().where().findAll();

    if (!mounted) return;
    setState(() {
      _project = project;
      _totalSpent = spent;
      _transactions = transactions;
      _categoryStats = stats;
      _dailySpending = daily;
      _cumulativeSpending = cumulative;
      _categoryByKey
        ..clear()
        ..addEntries(categories.map((c) => MapEntry(c.key, c)));
      _accountById
        ..clear()
        ..addEntries(accounts.map((a) => MapEntry(a.id, a)));
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
                  const PopupMenuItem(value: 'link', child: Text('关联交易')),
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

    // 预警级别
    final warningLevel = project.budget > 0
        ? (progress >= 1.0
            ? 'exceeded'
            : progress >= 0.9
                ? 'critical'
                : progress >= 0.8
                    ? 'warning'
                    : null)
        : null;

    final progressColor = warningLevel == 'exceeded'
        ? Colors.red.shade700
        : warningLevel == 'critical'
            ? Colors.red
            : warningLevel == 'warning'
                ? Colors.orange
                : color;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 预警提示横幅
        if (warningLevel != null) ...[
          _buildWarningBanner(warningLevel, remaining),
          const SizedBox(height: 16),
        ],

        // 概览卡片 - 重新设计
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // 顶部渐变区域
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // 项目图标和名称
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: iconWidgetForName(project.iconName, size: 28, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (project.description != null && project.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  project.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 金额展示
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('已支出', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(
                                '¥${_formatAmount(_totalSpent)}',
                                style: GoogleFonts.rubik(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: warningLevel == 'exceeded' ? Colors.red : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (project.budget > 0) ...[
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('预算', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Text(
                                  '¥${_formatAmount(project.budget)}',
                                  style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 进度区域
              if (project.budget > 0)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 进度条
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '已使用 ${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.lato(fontSize: 13, color: progressColor, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: remaining < 0 ? Colors.red.shade50 : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              remaining < 0 ? '超支 ¥${_formatAmount(-remaining)}' : '剩余 ¥${_formatAmount(remaining)}',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: remaining < 0 ? Colors.red : color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text('未设置预算', style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 项目信息卡片
        const SizedBox(height: 16),
        _buildInfoCard(project, color),

        // 分类统计
        if (_categoryStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('按分类', Icons.pie_chart_outline),
          const SizedBox(height: 12),
          _buildCategoryStatsCard(color),
        ],

        // 支出趋势图表
        if (_dailySpending.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildTrendChart(color),
        ],

        // 交易记录
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('交易记录', Icons.receipt_long_outlined),
            Row(
              children: [
                if (_transactions.isNotEmpty)
                  TextButton.icon(
                    onPressed: _showUnlinkTransactionsSheet,
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('批量取消'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_transactions.length} 笔', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade700)),
                ),
              ],
            ),
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
            return _buildProjectTransactionRow(tx);
          }),
      ],
    );
  }

  Widget _buildProjectTransactionRow(JiveTransaction tx) {
    final type = tx.type ?? 'expense';
    final isTransfer = type == 'transfer';
    final isIncome = type == 'income';
    final amountPrefix = isTransfer ? '' : (isIncome ? '+ ' : '- ');
    final amountColor = isTransfer
        ? Colors.blueGrey
        : (isIncome ? Colors.green : Colors.redAccent);
    final title = isTransfer ? _transferTitle(tx) : _categoryTitle(tx);
    final subtitle = isTransfer ? _transferSubtitle(tx) : _categorySubtitle(tx);
    final timeLabel = _formatTime(tx.timestamp);
    final iconMeta = _buildIconMeta(isTransfer, isIncome);
    final fromAccount = _resolveAccountName(tx.accountId);
    final toAccount = _resolveAccountName(tx.toAccountId);
    final accountLabel = fromAccount.isNotEmpty ? fromAccount : toAccount;

    return InkWell(
      onTap: () => _showTransactionActions(tx),
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconMeta.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconMeta.icon, color: iconMeta.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? timeLabel : '$subtitle • $timeLabel',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix¥${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.rubik(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (accountLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    accountLabel,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}万';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoCard(JiveProject project, Color color) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.calendar_today_outlined, '开始日期',
                project.startDate != null ? dateFormat.format(project.startDate!) : '未设置'),
            if (project.endDate != null) ...[
              const Divider(height: 20),
              _buildInfoRow(Icons.event_outlined, '结束日期', dateFormat.format(project.endDate!)),
            ],
            if (project.status != 'active') ...[
              const Divider(height: 20),
              _buildInfoRow(
                project.status == 'completed' ? Icons.check_circle_outline : Icons.archive_outlined,
                '状态',
                project.status == 'completed' ? '已完成' : '已归档',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryTitle(JiveTransaction tx) {
    return _displayCategoryName(tx.categoryKey, tx.category);
  }

  String _categorySubtitle(JiveTransaction tx) {
    final sub = _displayCategoryName(tx.subCategoryKey, tx.subCategory);
    if (sub == '未分类') {
      return tx.note?.trim() ?? '';
    }
    return sub;
  }

  String _transferTitle(JiveTransaction tx) {
    return '转账';
  }

  String _transferSubtitle(JiveTransaction tx) {
    final fromName = _resolveAccountName(tx.accountId);
    final toName = _resolveAccountName(tx.toAccountId);
    if (fromName.isEmpty && toName.isEmpty) return '';
    if (fromName.isEmpty) return '到 $toName';
    if (toName.isEmpty) return '来自 $fromName';
    return '$fromName → $toName';
  }

  String _displayCategoryName(String? key, String? fallback) {
    if (key != null && _categoryByKey.containsKey(key)) {
      return _categoryByKey[key]!.name;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return '未分类';
  }

  String _resolveAccountName(int? accountId) {
    if (accountId == null) return '';
    return _accountById[accountId]?.name ?? '';
  }

  String _formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  _IconMeta _buildIconMeta(bool isTransfer, bool isIncome) {
    if (isTransfer) {
      return _IconMeta(
        icon: Icons.swap_horiz,
        color: Colors.blueGrey,
        background: Colors.blueGrey.shade50,
      );
    }
    if (isIncome) {
      return _IconMeta(
        icon: Icons.arrow_downward,
        color: Colors.green,
        background: Colors.green.shade50,
      );
    }
    return _IconMeta(
      icon: Icons.arrow_upward,
      color: Colors.redAccent,
      background: Colors.red.shade50,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCategoryStatsCard(Color color) {
    // 排序后的分类统计
    final sortedStats = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: sortedStats.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            final percent = _totalSpent > 0 ? (e.value / _totalSpent) : 0.0;
            final isLast = index == sortedStats.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // 分类名称
                      Expanded(
                        flex: 2,
                        child: Text(e.key, style: GoogleFonts.lato(fontSize: 14)),
                      ),
                      // 进度条
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.7 + 0.3 * (1 - index / sortedStats.length)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 金额和百分比
                      SizedBox(
                        width: 100,
                        child: Text(
                          '¥${e.value.toStringAsFixed(0)} (${(percent * 100).toStringAsFixed(0)}%)',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
              ],
            );
          }).toList(),
        ),
      ),
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
      case 'link':
        await _showLinkTransactionsSheet();
        break;
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

  Future<void> _showLinkTransactionsSheet() async {
    // 获取所有未关联项目的交易
    final unlinkedTransactions = await _isar!.jiveTransactions
        .filter()
        .projectIdIsNull()
        .typeEqualTo('expense')
        .sortByTimestampDesc()
        .limit(500)
        .findAll();

    if (unlinkedTransactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可关联的交易')),
      );
      return;
    }

    // 获取分类和账户信息
    final categories = await _isar!.collection<JiveCategory>().where().findAll();
    final accounts = await _isar!.collection<JiveAccount>().where().findAll();
    final categoryByKey = {for (final c in categories) c.key: c};
    final accountById = {for (final a in accounts) a.id: a};

    // 筛选状态
    final selected = <int>{};
    String? filterCategoryKey;
    int? filterAccountId;
    String? filterTag;
    DateTimeRange? filterDateRange;
    String sortBy = 'time_desc';
    String searchQuery = '';
    final searchController = _linkSearchController;
    searchController.text = '';

    // 计算日期范围
    DateTime? minDate;
    DateTime? maxDate;
    if (unlinkedTransactions.isNotEmpty) {
      minDate = unlinkedTransactions.last.timestamp;
      maxDate = unlinkedTransactions.first.timestamp;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            // 过滤交易
            List<JiveTransaction> filteredTransactions = unlinkedTransactions.where((tx) {
              // 模糊搜索
              if (searchQuery.isNotEmpty) {
                final query = searchQuery.toLowerCase();
                final categoryName = (tx.categoryKey != null
                    ? categoryByKey[tx.categoryKey]?.name ?? tx.category
                    : tx.category) ?? '';
                final accountName = tx.accountId != null
                    ? accountById[tx.accountId]?.name ?? ''
                    : '';
                final note = tx.note ?? '';
                final amount = tx.amount.toStringAsFixed(2);
                final date = tx.timestamp.toString().substring(0, 10);
                final searchText = '$categoryName $accountName $note $amount $date'.toLowerCase();
                if (!searchText.contains(query)) {
                  return false;
                }
              }
              // 分类筛选
              if (filterCategoryKey != null) {
                if (tx.categoryKey != filterCategoryKey && tx.subCategoryKey != filterCategoryKey) {
                  return false;
                }
              }
              // 账户筛选
              if (filterAccountId != null && tx.accountId != filterAccountId) {
                return false;
              }
              // 标签/备注筛选
              if (filterTag != null && filterTag!.isNotEmpty) {
                final note = tx.note?.toLowerCase() ?? '';
                if (!note.contains(filterTag!.toLowerCase())) {
                  return false;
                }
              }
              // 日期范围筛选
              if (filterDateRange != null) {
                final txDate = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
                final startDate = DateTime(filterDateRange!.start.year, filterDateRange!.start.month, filterDateRange!.start.day);
                final endDate = DateTime(filterDateRange!.end.year, filterDateRange!.end.month, filterDateRange!.end.day);
                if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
                  return false;
                }
              }
              return true;
            }).toList();

            // 排序
            filteredTransactions.sort((a, b) {
              switch (sortBy) {
                case 'time_asc':
                  return a.timestamp.compareTo(b.timestamp);
                case 'amount_desc':
                  return b.amount.compareTo(a.amount);
                case 'amount_asc':
                  return a.amount.compareTo(b.amount);
                case 'time_desc':
                default:
                  return b.timestamp.compareTo(a.timestamp);
              }
            });

            // 是否有筛选条件
            final hasFilter = filterCategoryKey != null ||
                filterAccountId != null ||
                (filterTag != null && filterTag!.isNotEmpty) ||
                filterDateRange != null;
            final hasSearch = searchQuery.isNotEmpty || hasFilter;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '选择要关联的交易',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '已选 ${selected.length} 笔 · 共 ${filteredTransactions.length} 笔',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: JiveTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 筛选条件显示
                    if (hasFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 14, color: JiveTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _buildFilterSummary(filterCategoryKey, filterAccountId, filterTag, filterDateRange, categoryByKey, accountById),
                                style: GoogleFonts.lato(fontSize: 11, color: JiveTheme.primaryGreen),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  filterCategoryKey = null;
                                  filterAccountId = null;
                                  filterTag = null;
                                  filterDateRange = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('清除', style: GoogleFonts.lato(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                    // 交易列表
                    Expanded(
                      child: filteredTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    '没有匹配的交易',
                                    style: GoogleFonts.lato(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(bottom: 140),
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = filteredTransactions[index];
                                final isSelected = selected.contains(tx.id);
                                final categoryName = tx.categoryKey != null
                                    ? categoryByKey[tx.categoryKey]?.name ?? tx.category
                                    : tx.category ?? '未分类';
                                final accountName = tx.accountId != null
                                    ? accountById[tx.accountId]?.name
                                    : null;
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        selected.add(tx.id);
                                      } else {
                                        selected.remove(tx.id);
                                      }
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          categoryName ?? '未分类',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '¥${tx.amount.toStringAsFixed(2)}',
                                        style: GoogleFonts.rubik(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            tx.timestamp.toString().substring(0, 16),
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          if (accountName != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              accountName,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (tx.note?.isNotEmpty == true)
                                        Text(
                                          tx.note!,
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  dense: true,
                                );
                              },
                            ),
                    ),
                    // 底部浮动工具栏
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 搜索栏 + 筛选 + 排序
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    // 搜索输入框
                                    Expanded(
                                      child: TextField(
                                        controller: searchController,
                                        onChanged: (value) {
                                          setSheetState(() => searchQuery = value.trim());
                                        },
                                        textInputAction: TextInputAction.search,
                                        decoration: InputDecoration(
                                          hintText: '查找账单',
                                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                                          filled: true,
                                          isDense: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          border: InputBorder.none,
                                          suffixIcon: hasSearch
                                              ? IconButton(
                                                  onPressed: () {
                                                    setSheetState(() {
                                                      searchQuery = '';
                                                      searchController.clear();
                                                      filterCategoryKey = null;
                                                      filterAccountId = null;
                                                      filterTag = null;
                                                      filterDateRange = null;
                                                    });
                                                  },
                                                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                                                  splashRadius: 18,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  // 筛选按钮
                                  IconButton(
                                    onPressed: () async {
                                      await showModalBottomSheet<void>(
                                        context: sheetContext,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        builder: (ctx) {
                                          return TransactionFilterSheet(
                                            categories: categories,
                                            accounts: accounts,
                                            initialCategoryKey: filterCategoryKey,
                                            initialAccountId: filterAccountId,
                                            initialTag: filterTag,
                                            initialDateRange: filterDateRange,
                                            minDate: minDate,
                                            maxDate: maxDate,
                                            title: '查找账单（按条件）',
                                            hint: '选择即生效',
                                            onChanged: (categoryKey, accountId, tag, dateRange) {
                                              setSheetState(() {
                                                filterCategoryKey = categoryKey;
                                                filterAccountId = accountId;
                                                filterTag = tag;
                                                filterDateRange = dateRange;
                                              });
                                            },
                                            onClear: () {
                                              setSheetState(() {
                                                filterCategoryKey = null;
                                                filterAccountId = null;
                                                filterTag = null;
                                                filterDateRange = null;
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                    icon: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(Icons.tune, size: 20, color: Colors.grey.shade700),
                                        if (hasFilter)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    splashRadius: 20,
                                  ),
                                  // 排序按钮
                                  IconButton(
                                    onPressed: () async {
                                      await _showSortOptions(sheetContext, sortBy, (newSort) {
                                        setSheetState(() => sortBy = newSort);
                                      });
                                    },
                                    icon: Icon(Icons.sort, size: 20, color: Colors.grey.shade700),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 关联按钮
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selected.isEmpty
                                    ? null
                                    : () => Navigator.pop(sheetContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JiveTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  selected.isEmpty ? '请选择要关联的交易' : '关联 ${selected.length} 笔交易',
                                  style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != true || selected.isEmpty) return;

    // 批量更新交易的 projectId
    await _isar!.writeTxn(() async {
      for (final id in selected) {
        final tx = await _isar!.jiveTransactions.get(id);
        if (tx != null) {
          tx.projectId = _project!.id;
          await _isar!.jiveTransactions.put(tx);
        }
      }
    });

    _hasChanges = true;
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已关联 ${selected.length} 笔交易')),
    );
  }

  Future<void> _showSortOptions(BuildContext context, String currentSort, Function(String) onChanged) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '排列方式',
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortOption('最新优先', 'time_desc', currentSort, onChanged, ctx),
                    _buildSortOption('最早优先', 'time_asc', currentSort, onChanged, ctx),
                    _buildSortOption('金额从高到低', 'amount_desc', currentSort, onChanged, ctx),
                    _buildSortOption('金额从低到高', 'amount_asc', currentSort, onChanged, ctx),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, String currentSort, Function(String) onChanged, BuildContext ctx) {
    final isSelected = currentSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: JiveTheme.primaryGreen.withOpacity(0.18),
      onSelected: (_) {
        onChanged(value);
        Navigator.pop(ctx);
      },
    );
  }

  String _buildFilterSummary(
    String? categoryKey,
    int? accountId,
    String? tag,
    DateTimeRange? dateRange,
    Map<String, JiveCategory> categoryByKey,
    Map<int, JiveAccount> accountById,
  ) {
    final parts = <String>[];
    if (categoryKey != null) {
      parts.add(categoryByKey[categoryKey]?.name ?? '分类');
    }
    if (accountId != null) {
      parts.add(accountById[accountId]?.name ?? '账户');
    }
    if (tag != null && tag.isNotEmpty) {
      parts.add('"$tag"');
    }
    if (dateRange != null) {
      final start = '${dateRange.start.month}/${dateRange.start.day}';
      final end = '${dateRange.end.month}/${dateRange.end.day}';
      parts.add('$start-$end');
    }
    return parts.join(' · ');
  }

  Future<void> _showTransactionActions(JiveTransaction tx) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.category ?? '未分类',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¥${tx.amount.toStringAsFixed(2)}  ${tx.timestamp.toString().substring(0, 16)}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.orange),
                title: const Text('取消关联'),
                subtitle: const Text('将此交易从项目中移除'),
                onTap: () => Navigator.pop(context, 'unlink'),
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: JiveTheme.primaryGreen),
                title: const Text('查看详情'),
                subtitle: const Text('查看交易完整信息'),
                onTap: () => Navigator.pop(context, 'detail'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    if (action == 'unlink') {
      await _unlinkTransaction(tx);
    } else if (action == 'detail') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionDetailScreen(transactionId: tx.id),
        ),
      );
      if (result == true) {
        _hasChanges = true;
        await _loadData();
      }
    }
  }

  Future<void> _unlinkTransaction(JiveTransaction tx) async {
    await _isar!.writeTxn(() async {
      tx.projectId = null;
      await _isar!.jiveTransactions.put(tx);
    });

    _hasChanges = true;
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消关联')),
    );
  }

  Future<void> _showUnlinkTransactionsSheet() async {
    if (_transactions.isEmpty) return;

    final selected = <int>{};

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '选择要取消关联的交易',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (selected.length == _transactions.length) {
                                  selected.clear();
                                } else {
                                  selected.addAll(_transactions.map((t) => t.id));
                                }
                              });
                            },
                            child: Text(
                              selected.length == _transactions.length ? '取消全选' : '全选',
                              style: TextStyle(color: JiveTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '已选 ${selected.length} 笔',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isSelected = selected.contains(tx.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(tx.id);
                                } else {
                                  selected.remove(tx.id);
                                }
                              });
                            },
                            title: Text(tx.category ?? '未分类'),
                            subtitle: Text(
                              '${tx.timestamp.toString().substring(0, 10)}  ¥${tx.amount.toStringAsFixed(2)}',
                            ),
                            secondary: tx.note?.isNotEmpty == true
                                ? Text(
                                    tx.note!,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selected.isEmpty
                                    ? null
                                    : () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('取消关联 ${selected.length} 笔'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != true || selected.isEmpty) return;

    // 批量取消关联
    await _isar!.writeTxn(() async {
      for (final id in selected) {
        final tx = await _isar!.jiveTransactions.get(id);
        if (tx != null) {
          tx.projectId = null;
          await _isar!.jiveTransactions.put(tx);
        }
      }
    });

    _hasChanges = true;
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已取消关联 ${selected.length} 笔交易')),
    );
  }

  Widget _buildWarningBanner(String level, double remaining) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final String title;
    final String message;
    final IconData icon;

    switch (level) {
      case 'exceeded':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade700;
        title = '预算已超支';
        message = '已超出预算 ¥${(-remaining).toStringAsFixed(0)}，请注意控制支出';
        icon = Icons.warning_rounded;
        break;
      case 'critical':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade100;
        textColor = Colors.red;
        title = '即将超支';
        message = '预算剩余不足10%，仅剩 ¥${remaining.toStringAsFixed(0)}';
        icon = Icons.error_outline;
        break;
      case 'warning':
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        title = '预算预警';
        message = '已使用超过80%预算，剩余 ¥${remaining.toStringAsFixed(0)}';
        icon = Icons.info_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(Color themeColor) {
    final data = _showCumulative ? _cumulativeSpending : _dailySpending;
    if (data.isEmpty) return const SizedBox.shrink();

    // 计算最大值用于Y轴
    final maxY = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final yInterval = maxY > 0 ? (maxY / 4).ceilToDouble() : 100.0;

    // 生成图表数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].amount));
    }

    final dateFormat = DateFormat('M/d');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '支出趋势',
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildChartToggle('每日', !_showCumulative, () {
                      setState(() => _showCumulative = false);
                    }),
                    const SizedBox(width: 8),
                    _buildChartToggle('累计', _showCumulative, () {
                      setState(() => _showCumulative = true);
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showCumulative ? '近14天累计支出' : '近14天每日支出',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval > 0 ? yInterval : 100,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: yInterval > 0 ? yInterval : 100,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toInt().toString(),
                            style: GoogleFonts.lato(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              dateFormat.format(data[index].date),
                              style: GoogleFonts.lato(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY > 0 ? maxY * 1.1 : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: themeColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: themeColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: themeColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index < 0 || index >= data.length) return null;
                          final item = data[index];
                          return LineTooltipItem(
                            '${dateFormat.format(item.date)}\n¥${item.amount.toStringAsFixed(0)}',
                            GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? JiveTheme.primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? JiveTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? JiveTheme.primaryGreen : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

}

class _IconMeta {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconMeta({
    required this.icon,
    required this.color,
    required this.background,
  });
}
