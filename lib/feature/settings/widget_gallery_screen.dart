import 'package:flutter/material.dart';

import '../../core/service/widget_data_service.dart';

/// Gallery screen that previews all 5 home-screen widget types with live data.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  bool _loading = true;

  WidgetSummary? _todaySummary;
  CalendarWidgetData? _calendarData;
  WeeklyWidgetData? _weeklyData;
  DreamWidgetData? _dreamData;
  RepaymentWidgetData? _repaymentData;
  QuickInfoWidgetData? _quickInfoData;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final service = await WidgetDataService.create();
      final now = DateTime.now();
      final results = await Future.wait([
        service.getTodaySummary(),
        service.getCalendarWidgetData(now),
        service.getWeeklyWidgetData(),
        service.getDreamWidgetData(),
        service.getRepaymentWidgetData(),
        service.getQuickInfoWidgetData(),
      ]);
      if (mounted) {
        setState(() {
          _todaySummary = results[0] as WidgetSummary;
          _calendarData = results[1] as CalendarWidgetData;
          _weeklyData = results[2] as WeeklyWidgetData;
          _dreamData = results[3] as DreamWidgetData?;
          _repaymentData = results[4] as RepaymentWidgetData;
          _quickInfoData = results[5] as QuickInfoWidgetData;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('桌面小组件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTodaySummaryCard(),
                const SizedBox(height: 14),
                _buildCalendarCard(),
                const SizedBox(height: 14),
                _buildWeeklyCard(),
                const SizedBox(height: 14),
                _buildDreamCard(),
                const SizedBox(height: 14),
                _buildRepaymentCard(),
                const SizedBox(height: 14),
                _buildQuickInfoCard(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------------------

  Widget _buildTodaySummaryCard() {
    final s = _todaySummary;
    return _WidgetPreviewCard(
      title: '今日摘要',
      description: '显示今日收支与本月支出概览',
      child: s == null
          ? const Text('暂无数据')
          : Column(
              children: [
                _DataRow(label: '今日支出', value: _fmt(s.todayExpense)),
                _DataRow(label: '今日收入', value: _fmt(s.todayIncome)),
                _DataRow(label: '今日笔数', value: '${s.todayCount}'),
                _DataRow(label: '本月支出', value: _fmt(s.monthExpense)),
                if (s.monthBudgetRemaining != null)
                  _DataRow(
                    label: '预算剩余',
                    value: _fmt(s.monthBudgetRemaining!),
                    valueColor: s.monthBudgetRemaining! < 0
                        ? Colors.redAccent
                        : Colors.green,
                  ),
              ],
            ),
    );
  }

  Widget _buildCalendarCard() {
    final c = _calendarData;
    return _WidgetPreviewCard(
      title: '日历',
      description: '按日展示本月每天支出热力',
      child: c == null
          ? const Text('暂无数据')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DataRow(
                  label: '本月支出',
                  value: _fmt(c.totalMonthExpense),
                ),
                _DataRow(
                  label: '本月收入',
                  value: _fmt(c.totalMonthIncome),
                ),
                const SizedBox(height: 8),
                _buildMiniHeatmap(c.dailyExpense),
              ],
            ),
    );
  }

  Widget _buildMiniHeatmap(Map<int, double> dailyExpense) {
    if (dailyExpense.isEmpty) {
      return Text(
        '本月暂无支出记录',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }
    final maxAmount =
        dailyExpense.values.fold<double>(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: List.generate(daysInMonth, (i) {
        final day = i + 1;
        final amount = dailyExpense[day] ?? 0;
        final intensity =
            maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: amount > 0
                ? Color.lerp(
                    Colors.orange.shade100, Colors.orange.shade700, intensity)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 8,
              color: amount > 0 ? Colors.white : Colors.grey.shade500,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeeklyCard() {
    final w = _weeklyData;
    return _WidgetPreviewCard(
      title: '周报',
      description: '最近 7 天收支趋势',
      child: w == null
          ? const Text('暂无数据')
          : Column(
              children: [
                ...w.last7Days.map((d) => _DataRow(
                      label:
                          '${d.date.month}/${d.date.day}',
                      value:
                          '-${_fmt(d.expense)} / +${_fmt(d.income)}',
                    )),
                const Divider(height: 16),
                _DataRow(
                  label: '周支出合计',
                  value: _fmt(w.weekTotal),
                  valueColor: Colors.deepOrange,
                ),
              ],
            ),
    );
  }

  Widget _buildDreamCard() {
    final d = _dreamData;
    return _WidgetPreviewCard(
      title: '梦想目标',
      description: '展示进度最高的储蓄目标',
      child: d == null
          ? Text(
              '暂无进行中的储蓄目标',
              style: TextStyle(color: Colors.grey.shade500),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(d.progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: d.progress >= 1.0
                            ? Colors.green
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      d.progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_fmt(d.currentAmount)} / ${_fmt(d.targetAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRepaymentCard() {
    final r = _repaymentData;
    return _WidgetPreviewCard(
      title: '还款提醒',
      description: '未来 7 天内到期的周期记账',
      child: r == null || r.upcoming.isEmpty
          ? Text(
              '近 7 天无到期周期记账',
              style: TextStyle(color: Colors.grey.shade500),
            )
          : Column(
              children: [
                ...r.upcoming.map((item) => _DataRow(
                      label:
                          '${item.name} (${item.dueDate.month}/${item.dueDate.day})',
                      value: _fmt(item.amount),
                    )),
                const Divider(height: 16),
                _DataRow(label: '即将到期', value: '${r.count} 条'),
              ],
            ),
    );
  }

  Widget _buildQuickInfoCard() {
    final q = _quickInfoData;
    return _WidgetPreviewCard(
      title: '快捷信息',
      description: '净资产、预算剩余与待处理报销',
      child: q == null
          ? const Text('暂无数据')
          : Column(
              children: [
                _DataRow(label: '净资产', value: _fmt(q.netWorth)),
                if (q.monthBudgetRemaining != null)
                  _DataRow(
                    label: '预算剩余',
                    value: _fmt(q.monthBudgetRemaining!),
                    valueColor: q.monthBudgetRemaining! < 0
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                _DataRow(
                  label: '待处理报销',
                  value: '${q.unreadReimbursementCount} 条',
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _fmt(double v) => v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _WidgetPreviewCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _WidgetPreviewCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            child,
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '长按桌面空白 \u2192 小组件 \u2192 找到 Jive \u2192 添加到桌面',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
