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
  final TextEditingController _unlinkSearchController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();
  bool _showCumulative = true;
  bool _hasChanges = false;
  bool _categoryExpanded = true;
  double? _pendingScrollOffset;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _contentScrollController.addListener(() {
      _lastScrollOffset = _contentScrollController.offset;
    });
    _loadData();
  }

  @override
  void dispose() {
    _linkSearchController.dispose();
    _unlinkSearchController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

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

  Future<void> _reloadPreservingScroll() async {
    if (_contentScrollController.hasClients) {
      _pendingScrollOffset = _contentScrollController.offset;
    } else {
      _pendingScrollOffset = _lastScrollOffset;
    }
    await _loadData(showLoading: false);
    if (!mounted || _pendingScrollOffset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_contentScrollController.hasClients) return;
      final maxOffset = _contentScrollController.position.maxScrollExtent;
      final target = _pendingScrollOffset!.clamp(0.0, maxOffset).toDouble();
      _contentScrollController.jumpTo(target);
    });
    _pendingScrollOffset = null;
  }

  Future<void> _openAllTransactionsPage() async {
    if (_transactions.isEmpty) return;
    final categories = _categoryByKey.values.toList(growable: false);
    final accounts = _accountById.values.toList(growable: false);
    final isar = await _ensureIsar();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProjectTransactionsPage(
          title: '交易记录',
          projectId: widget.projectId,
          isActive: _project?.status == 'active',
          transactions: List<JiveTransaction>.from(_transactions),
          categories: categories,
          accounts: accounts,
          isar: isar,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
      await _reloadPreservingScroll();
    }
  }

  Future<void> _openCategoryTransactions(String categoryName) async {
    if (_transactions.isEmpty) return;
    final categories = _categoryByKey.values.toList(growable: false);
    final accounts = _accountById.values.toList(growable: false);
    final isar = await _ensureIsar();
    final filtered = _transactions.where((tx) {
      return _displayCategoryName(tx.categoryKey, tx.category) == categoryName;
    }).toList();

    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该分类暂无交易')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProjectTransactionsPage(
          title: categoryName,
          projectId: widget.projectId,
          isActive: _project?.status == 'active',
          transactions: filtered,
          categories: categories,
          accounts: accounts,
          isar: isar,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
      await _reloadPreservingScroll();
    }
  }

  Future<void> _reloadAndScrollTop() async {
    await _loadData(showLoading: false);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_contentScrollController.hasClients) return;
      _contentScrollController.jumpTo(0);
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
              if (_project!.status == 'active')
                IconButton(icon: const Icon(Icons.edit), onPressed: _editProject),
              PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];

                  if (_project!.status == 'active') {
                    items.add(const PopupMenuItem(value: 'complete', child: Text('标记完成')));
                    items.add(const PopupMenuItem(value: 'archive', child: Text('归档')));
                  } else if (_project!.status == 'completed') {
                    items.add(const PopupMenuItem(value: 'reopen', child: Text('恢复进行中')));
                    items.add(const PopupMenuItem(value: 'archive', child: Text('归档')));
                  } else if (_project!.status == 'archived') {
                    items.add(const PopupMenuItem(value: 'reopen', child: Text('恢复进行中')));
                  }

                  items.add(const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除', style: TextStyle(color: Colors.red)),
                  ));
                  return items;
                },
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
      controller: _contentScrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // 预警提示横幅
        if (warningLevel != null) ...[
          _buildWarningBanner(warningLevel, remaining),
          const SizedBox(height: 16),
        ],

        // 概览卡片 - 重新设计
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
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
      const SizedBox(height: 16),
      _buildTimelineCard(project, color),

        // 分类统计
        if (_categoryStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              setState(() => _categoryExpanded = !_categoryExpanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text('按分类',
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(
                    _categoryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_categoryExpanded) _buildCategoryStatsCard(color),
        ],

        // 支出趋势图表
        if (_dailySpending.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildTrendChart(color),
        ],

        // 交易记录
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text('交易记录', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('· ${_transactions.length} 笔',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500)),
            const Spacer(),
            if (_transactions.isNotEmpty)
              TextButton(
                onPressed: _openAllTransactionsPage,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '查看全部',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: JiveTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_transactions.isNotEmpty && _project?.status == 'active') ...[
              _buildHeaderIconAction(
                icon: Icons.link,
                tooltip: '关联交易',
                color: JiveTheme.primaryGreen,
                onTap: _showLinkTransactionsSheet,
              ),
              const SizedBox(width: 4),
              _buildHeaderIconAction(
                icon: Icons.link_off,
                tooltip: '批量取消',
                color: Colors.grey.shade700,
                onTap: _showUnlinkTransactionsSheet,
              ),
            ],
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
    return _buildTransactionCard(
      tx,
      compact: true,
      onTap: () => _showTransactionActions(tx),
      onAmountTap: () async {
        final result = await showTransactionDetailSheet(context, tx.id);
        if (result == true) {
          _hasChanges = true;
          await _reloadPreservingScroll();
        }
      },
    );
  }

  Widget _buildSelectableTransactionRow(
    JiveTransaction tx, {
    required bool selected,
    required VoidCallback onToggle,
  }) {
    return _buildTransactionCard(
      tx,
      compact: true,
      selected: selected,
      leading: Checkbox(
        value: selected,
        onChanged: (_) => onToggle(),
        activeColor: JiveTheme.primaryGreen,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onTap: onToggle,
    );
  }

  Widget _buildTransactionCard(
    JiveTransaction tx, {
    bool selected = false,
    bool compact = false,
    Widget? leading,
    VoidCallback? onAmountTap,
    VoidCallback? onTap,
  }) {
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
    final subtitleText = subtitle.isEmpty ? timeLabel : '$subtitle • $timeLabel';

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(14);
    final margin = compact
        ? const EdgeInsets.fromLTRB(4, 4, 4, 6)
        : const EdgeInsets.fromLTRB(4, 4, 4, 8);
    final titleSize = compact ? 13.0 : 14.0;
    final subtitleSize = compact ? 11.0 : 12.0;
    final amountSize = compact ? 13.0 : 14.0;
    final accountSize = compact ? 10.0 : 11.0;
    final iconPadding = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 18.0;
    final rowGap = compact ? 8.0 : 12.0;

    final detailTap = onAmountTap ?? onTap;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: JiveTheme.primaryGreen.withOpacity(0.35))
              : null,
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
            if (leading != null) ...[
              leading,
              const SizedBox(width: 4),
            ],
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: iconMeta.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconMeta.icon, color: iconMeta.color, size: iconSize),
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: GoogleFonts.lato(
                      fontSize: subtitleSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  onTap: detailTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      '$amountPrefix¥${tx.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.rubik(
                        color: amountColor,
                        fontSize: amountSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (accountLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: detailTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Text(
                        accountLabel,
                        style: GoogleFonts.lato(
                          fontSize: accountSize,
                          color: Colors.grey.shade500,
                        ),
                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget _buildTimelineCard(JiveProject project, Color color) {
    final start = project.startDate;
    final end = project.endDate;
    final now = DateTime.now();

    if (start == null && end == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timeline, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              '项目进度时间线',
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '未设置',
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    DateTime startDate = start ?? now;
    DateTime endDate = end ?? now;
    if (endDate.isBefore(startDate)) {
      final temp = startDate;
      startDate = endDate;
      endDate = temp;
    }

    final totalMinutes = endDate.difference(startDate).inMinutes;
    double progress = 1.0;
    if (totalMinutes > 0) {
      if (now.isBefore(startDate)) {
        progress = 0.0;
      } else if (now.isAfter(endDate)) {
        progress = 1.0;
      } else {
        progress = now.difference(startDate).inMinutes / totalMinutes;
      }
    }

    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                '项目进度时间线',
                style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.lato(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final dotSize = 12.0;
              final left = (width - dotSize) * progress;
              return SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      child: Column(
                        children: [
                          Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: color, width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('今天',
                              style: GoogleFonts.lato(fontSize: 10, color: color)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                start != null ? dateFormat.format(startDate) : '未设置开始',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                end != null ? dateFormat.format(endDate) : '未设置结束',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
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

  Widget _buildHeaderActionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildCategoryStatsCard(Color color) {
    // 排序后的分类统计
    final sortedStats = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = _totalSpent > 0 ? _totalSpent : 0.0;
    final palette = [
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFF03A9F4),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    final topCount = sortedStats.length > 6 ? 6 : sortedStats.length;
    final topEntries = sortedStats.take(topCount).toList();
    final othersValue = sortedStats.skip(topCount).fold<double>(0, (sum, e) => sum + e.value);
    final sections = <PieChartSectionData>[
      for (var i = 0; i < topEntries.length; i++)
        PieChartSectionData(
          color: palette[i % palette.length],
          value: topEntries[i].value,
          radius: 48,
          showTitle: false,
        ),
      if (othersValue > 0)
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: othersValue,
          radius: 48,
          showTitle: false,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            if (total > 0 && sections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '分类占比',
                      style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '合计 ¥${total.toStringAsFixed(0)}',
                      style: GoogleFonts.rubik(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...sortedStats.asMap().entries.map((entry) {
              final index = entry.key;
              final e = entry.value;
              final percent = _totalSpent > 0 ? (e.value / _totalSpent) : 0.0;
              final isLast = index == sortedStats.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () => _openCategoryTransactions(e.key),
                      borderRadius: BorderRadius.circular(10),
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
                            width: 112,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    '¥${e.value.toStringAsFixed(0)} (${(percent * 100).toStringAsFixed(0)}%)',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _editProject() async {
    if (_project == null || _project!.status != 'active') return;
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => ProjectFormScreen(project: _project)));
    if (result == true) {
      _hasChanges = true;
      _reloadPreservingScroll();
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
        _reloadPreservingScroll();
        break;
      case 'archive':
        await service.archiveProject(_project!);
        _hasChanges = true;
        if (!mounted) return;
        Navigator.pop(context, true);
        break;
      case 'reopen':
        await service.reactivateProject(_project!);
        _hasChanges = true;
        _reloadPreservingScroll();
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
    if (_project?.status != 'active') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('仅进行中项目可关联交易')),
      );
      return;
    }
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
                                return _buildSelectableTransactionRow(
                                  tx,
                                  selected: isSelected,
                                  onToggle: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selected.remove(tx.id);
                                      } else {
                                        selected.add(tx.id);
                                      }
                                    });
                                  },
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
                                    : () async {
                                        if (selected.length >= 500) {
                                          final confirmed = await showDialog<bool>(
                                            context: sheetContext,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('已选交易较多'),
                                              content: const Text('已选交易超过 500 笔，可能较慢，是否继续关联？'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('取消'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('继续'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true) return;
                                        }
                                        Navigator.pop(sheetContext, true);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JiveTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  selected.isEmpty
                                      ? '请选择要关联的交易'
                                      : selected.length >= 200
                                          ? '关联 ${selected.length} 笔 · 较多可能较慢'
                                          : '关联 ${selected.length} 笔交易',
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

    if (_project != null && _project!.budget > 0) {
      final selectedTotal = unlinkedTransactions
          .where((tx) => selected.contains(tx.id))
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final projected = _totalSpent + selectedTotal;
      if (projected > _project!.budget) {
        final over = projected - _project!.budget;
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('预算将超支'),
            content: Text('关联后将超支 ¥${over.toStringAsFixed(0)}，是否继续？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('继续')),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

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
    await _reloadPreservingScroll();

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
    final canUnlink = _project?.status == 'active';
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
              if (canUnlink)
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
        await _reloadPreservingScroll();
      }
    }
  }

  Future<void> _unlinkTransaction(JiveTransaction tx) async {
    await _isar!.writeTxn(() async {
      tx.projectId = null;
      await _isar!.jiveTransactions.put(tx);
    });

    _hasChanges = true;
    await _reloadPreservingScroll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消关联')),
    );
  }

  Future<void> _showUnlinkTransactionsSheet() async {
    if (_project?.status != 'active') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('仅进行中项目可取消关联')),
      );
      return;
    }
    if (_transactions.isEmpty) return;

    final selected = <int>{};
    final categories = await _isar!.collection<JiveCategory>().where().findAll();
    final accounts = await _isar!.collection<JiveAccount>().where().findAll();
    final categoryByKey = {for (final c in categories) c.key: c};
    final accountById = {for (final a in accounts) a.id: a};

    String? filterCategoryKey;
    int? filterAccountId;
    String? filterTag;
    DateTimeRange? filterDateRange;
    String sortBy = 'time_desc';
    String searchQuery = '';
    final searchController = _unlinkSearchController;
    searchController.text = '';

    DateTime? minDate;
    DateTime? maxDate;
    if (_transactions.isNotEmpty) {
      final sortedByTime = [..._transactions]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      minDate = sortedByTime.first.timestamp;
      maxDate = sortedByTime.last.timestamp;
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
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            List<JiveTransaction> filteredTransactions = _transactions.where((tx) {
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
              if (filterCategoryKey != null) {
                if (tx.categoryKey != filterCategoryKey && tx.subCategoryKey != filterCategoryKey) {
                  return false;
                }
              }
              if (filterAccountId != null && tx.accountId != filterAccountId) {
                return false;
              }
              if (filterTag != null && filterTag!.isNotEmpty) {
                final note = tx.note?.toLowerCase() ?? '';
                if (!note.contains(filterTag!.toLowerCase())) {
                  return false;
                }
              }
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

            final hasFilter = filterCategoryKey != null ||
                filterAccountId != null ||
                (filterTag != null && filterTag!.isNotEmpty) ||
                filterDateRange != null;
            final hasSearch = searchQuery.isNotEmpty || hasFilter;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
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
                      child: Row(
                        children: [
                          Text(
                            '已选 ${selected.length} 笔',
                            style: GoogleFonts.lato(fontSize: 13, color: Colors.orange),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${filteredTransactions.length} 笔',
                            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
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
                              padding: const EdgeInsets.only(bottom: 150),
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = filteredTransactions[index];
                                final isSelected = selected.contains(tx.id);
                                return _buildSelectableTransactionRow(
                                  tx,
                                  selected: isSelected,
                                  onToggle: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selected.remove(tx.id);
                                      } else {
                                        selected.add(tx.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
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
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
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
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(sheetContext, false),
                                      child: const Text('取消'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: selected.isEmpty
                                          ? null
                                          : () => Navigator.pop(sheetContext, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('取消关联 ${selected.length} 笔'),
                                    ),
                                  ),
                                ],
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
    await _reloadPreservingScroll();

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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

class _ProjectTransactionsPage extends StatefulWidget {
  final String title;
  final int projectId;
  final bool isActive;
  final List<JiveTransaction> transactions;
  final List<JiveCategory> categories;
  final List<JiveAccount> accounts;
  final Isar isar;

  const _ProjectTransactionsPage({
    required this.title,
    required this.projectId,
    required this.isActive,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.isar,
  });

  @override
  State<_ProjectTransactionsPage> createState() => _ProjectTransactionsPageState();
}

class _ProjectTransactionsPageState extends State<_ProjectTransactionsPage> {
  final DateFormat _timeFormat = DateFormat('MM-dd HH:mm');
  late final TextEditingController _searchController;
  late Map<String, JiveCategory> _categoryByKey;
  late Map<int, JiveAccount> _accountById;
  late List<JiveTransaction> _allTransactions;
  final Set<int> _selected = {};

  bool _batchMode = false;
  bool _changed = false;
  String _searchQuery = '';
  String? _filterCategoryKey;
  int? _filterAccountId;
  String? _filterTag;
  DateTimeRange? _filterDateRange;
  String _sortBy = 'time_desc';
  DateTime? _minDate;
  DateTime? _maxDate;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _categoryByKey = {for (final c in widget.categories) c.key: c};
    _accountById = {for (final a in widget.accounts) a.id: a};
    _allTransactions = [...widget.transactions];
    if (_allTransactions.isNotEmpty) {
      final sortedByTime = [..._allTransactions]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _minDate = sortedByTime.first.timestamp;
      _maxDate = sortedByTime.last.timestamp;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions();
    final hasFilter = _filterCategoryKey != null ||
        _filterAccountId != null ||
        (_filterTag != null && _filterTag!.isNotEmpty) ||
        _filterDateRange != null;
    final hasSearch = _searchQuery.isNotEmpty || hasFilter;
    final bottomPadding = 120 + (_batchMode ? 64 : 0) + (hasFilter ? 28 : 0);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            if (widget.isActive)
              IconButton(
                onPressed: _toggleBatchMode,
                tooltip: _batchMode ? '退出批量' : '批量取消',
                icon: Icon(
                  _batchMode ? Icons.close : Icons.link_off,
                  color: _batchMode ? Colors.orange : Colors.grey.shade700,
                ),
              ),
          ],
        ),
        backgroundColor: JiveTheme.surfaceWhite,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '共 ${_allTransactions.length} 笔',
                    style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (_batchMode)
                    Text(
                      '已选 ${_selected.length} 笔',
                      style: GoogleFonts.lato(fontSize: 12, color: Colors.orange),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('没有匹配的交易', style: GoogleFonts.lato(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: bottomPadding.toDouble()),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        if (_batchMode) {
                          final isSelected = _selected.contains(tx.id);
                          return _buildTransactionCard(
                            tx,
                            compact: true,
                            selected: isSelected,
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelect(tx.id),
                              activeColor: JiveTheme.primaryGreen,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onTap: () => _toggleSelect(tx.id),
                          );
                        }
                        return _buildTransactionCard(
                          tx,
                          compact: true,
                          onTap: () async {
                            final result = await showTransactionDetailSheet(context, tx.id);
                            if (result == true) {
                              _changed = true;
                            }
                          },
                          onAmountTap: () async {
                            final result = await showTransactionDetailSheet(context, tx.id);
                            if (result == true) {
                              _changed = true;
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_batchMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _toggleBatchMode,
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selected.isEmpty ? null : _unlinkSelected,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('取消关联 ${_selected.length} 笔'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: JiveTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _buildFilterSummary(
                            _filterCategoryKey,
                            _filterAccountId,
                            _filterTag,
                            _filterDateRange,
                            _categoryByKey,
                            _accountById,
                          ),
                          style: GoogleFonts.lato(fontSize: 11, color: JiveTheme.primaryGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value.trim());
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: '查找账单',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                            filled: true,
                            isDense: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: InputBorder.none,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: _clearSearch,
                                    icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                                    splashRadius: 18,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showFilterSheet,
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
                    IconButton(
                      onPressed: () async {
                        await _showSortOptions(context, _sortBy, (newSort) {
                          setState(() => _sortBy = newSort);
                        });
                      },
                      icon: Icon(Icons.sort, size: 20, color: Colors.grey.shade700),
                      splashRadius: 20,
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

  void _toggleBatchMode() {
    setState(() {
      _batchMode = !_batchMode;
      _selected.clear();
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filterCategoryKey = null;
      _filterAccountId = null;
      _filterTag = null;
      _filterDateRange = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _filterCategoryKey = null;
      _filterAccountId = null;
      _filterTag = null;
      _filterDateRange = null;
    });
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return TransactionFilterSheet(
          categories: widget.categories,
          accounts: widget.accounts,
          initialCategoryKey: _filterCategoryKey,
          initialAccountId: _filterAccountId,
          initialTag: _filterTag,
          initialDateRange: _filterDateRange,
          minDate: _minDate,
          maxDate: _maxDate,
          onChanged: (categoryKey, accountId, tag, dateRange) {
            setState(() {
              _filterCategoryKey = categoryKey;
              _filterAccountId = accountId;
              _filterTag = tag;
              _filterDateRange = dateRange;
            });
          },
          onClear: _clearFilters,
        );
      },
    );
  }

  List<JiveTransaction> _filteredTransactions() {
    final filtered = _allTransactions.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final categoryName = (tx.categoryKey != null
            ? _categoryByKey[tx.categoryKey]?.name ?? tx.category
            : tx.category) ?? '';
        final accountName = tx.accountId != null ? _accountById[tx.accountId]?.name ?? '' : '';
        final note = tx.note ?? '';
        final amount = tx.amount.toStringAsFixed(2);
        final date = tx.timestamp.toString().substring(0, 10);
        final searchText = '$categoryName $accountName $note $amount $date'.toLowerCase();
        if (!searchText.contains(query)) {
          return false;
        }
      }
      if (_filterCategoryKey != null) {
        if (tx.categoryKey != _filterCategoryKey && tx.subCategoryKey != _filterCategoryKey) {
          return false;
        }
      }
      if (_filterAccountId != null && tx.accountId != _filterAccountId) {
        return false;
      }
      if (_filterTag != null && _filterTag!.isNotEmpty) {
        final note = tx.note?.toLowerCase() ?? '';
        if (!note.contains(_filterTag!.toLowerCase())) {
          return false;
        }
      }
      if (_filterDateRange != null) {
        final txDate = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
        final startDate = DateTime(
          _filterDateRange!.start.year,
          _filterDateRange!.start.month,
          _filterDateRange!.start.day,
        );
        final endDate = DateTime(
          _filterDateRange!.end.year,
          _filterDateRange!.end.month,
          _filterDateRange!.end.day,
        );
        if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
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

    return filtered;
  }

  Future<void> _unlinkSelected() async {
    if (_selected.isEmpty) return;
    await widget.isar.writeTxn(() async {
      for (final id in _selected) {
        final tx = await widget.isar.jiveTransactions.get(id);
        if (tx != null) {
          tx.projectId = null;
          await widget.isar.jiveTransactions.put(tx);
        }
      }
    });
    setState(() {
      _allTransactions.removeWhere((tx) => _selected.contains(tx.id));
      _selected.clear();
      _batchMode = false;
    });
    _changed = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消关联交易')),
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
                const SizedBox(height: 12),
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

  Widget _buildSortOption(
    String label,
    String value,
    String currentSort,
    Function(String) onChanged,
    BuildContext ctx,
  ) {
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

  Widget _buildTransactionCard(
    JiveTransaction tx, {
    bool selected = false,
    bool compact = false,
    Widget? leading,
    VoidCallback? onAmountTap,
    VoidCallback? onTap,
  }) {
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
    final subtitleText = subtitle.isEmpty ? timeLabel : '$subtitle • $timeLabel';

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(14);
    final margin = compact
        ? const EdgeInsets.fromLTRB(4, 4, 4, 6)
        : const EdgeInsets.fromLTRB(4, 4, 4, 8);
    final titleSize = compact ? 13.0 : 14.0;
    final subtitleSize = compact ? 11.0 : 12.0;
    final amountSize = compact ? 13.0 : 14.0;
    final accountSize = compact ? 10.0 : 11.0;
    final iconPadding = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 18.0;
    final rowGap = compact ? 8.0 : 12.0;

    final detailTap = onAmountTap ?? onTap;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: JiveTheme.primaryGreen.withOpacity(0.35))
              : null,
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
            if (leading != null) ...[
              leading,
              const SizedBox(width: 4),
            ],
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: iconMeta.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconMeta.icon, color: iconMeta.color, size: iconSize),
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: GoogleFonts.lato(
                      fontSize: subtitleSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  onTap: detailTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      '$amountPrefix¥${tx.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.rubik(
                        color: amountColor,
                        fontSize: amountSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (accountLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: detailTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Text(
                        accountLabel,
                        style: GoogleFonts.lato(
                          fontSize: accountSize,
                          color: Colors.grey.shade500,
                        ),
                      ),
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
