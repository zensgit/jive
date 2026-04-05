import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/database/transaction_model.dart';
import '../../core/service/merchant_analytics_service.dart';
import 'merchant_memory_screen.dart';

/// Merchant analytics screen — view top merchants, spending ranking, and details.
class MerchantAnalyticsScreen extends StatefulWidget {
  const MerchantAnalyticsScreen({super.key});

  @override
  State<MerchantAnalyticsScreen> createState() =>
      _MerchantAnalyticsScreenState();
}

class _MerchantAnalyticsScreenState extends State<MerchantAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  MerchantAnalyticsService? _service;
  List<MerchantStat> _topByFrequency = [];
  List<MerchantStat> _topByAmount = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _service = await MerchantAnalyticsService.create();
    await _load();
  }

  Future<void> _load() async {
    if (_service == null) return;
    setState(() => _loading = true);
    try {
      final byFreq = await _service!.getTopMerchants(limit: 50);
      final byAmount = await _service!.getMerchantRanking(12);
      if (!mounted) return;
      setState(() {
        _topByFrequency = byFreq;
        _topByAmount = byAmount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<MerchantStat> _filter(List<MerchantStat> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((s) => s.merchantName.toLowerCase().contains(q))
        .toList();
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
                  hintText: '搜索商户...',
                  border: InputBorder.none,
                ),
                onChanged: (q) => setState(() => _searchQuery = q),
              )
            : const Text('商户分析'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: '商户记忆管理',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MerchantMemoryScreen(),
                ),
              );
              _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '常去商户'),
            Tab(text: '消费排行'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFrequencyTab(),
                _buildAmountTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Top by frequency ──

  Widget _buildFrequencyTab() {
    final list = _filter(_topByFrequency);
    if (list.isEmpty) return _buildEmpty('暂无常去商户数据');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = list[i];
          return _MerchantTile(
            stat: s,
            rank: i + 1,
            subtitle:
                '${s.transactionCount} 次  |  共 ${_fmt(s.totalAmount)}  |  最近 ${_dateFmt(s.lastVisitDate)}',
            onTap: () => _showDetail(s),
          );
        },
      ),
    );
  }

  // ── Tab 2: Top by amount ──

  Widget _buildAmountTab() {
    final list = _filter(_topByAmount);
    if (list.isEmpty) return _buildEmpty('暂无消费排行数据');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = list[i];
          return _MerchantTile(
            stat: s,
            rank: i + 1,
            subtitle:
                '共 ${_fmt(s.totalAmount)}  |  均 ${_fmt(s.avgAmount)}/次  |  ${s.transactionCount} 次',
            onTap: () => _showDetail(s),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            '记录更多交易后会自动出现',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Detail bottom sheet ──

  void _showDetail(MerchantStat stat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MerchantDetailSheet(
        stat: stat,
        service: _service!,
        onAliasPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantMemoryScreen(),
            ),
          );
        },
      ),
    );
  }

  static String _fmt(double v) =>
      NumberFormat.currency(locale: 'zh_CN', symbol: '\u00a5', decimalDigits: 0)
          .format(v);

  static String _dateFmt(DateTime d) => DateFormat('MM/dd').format(d);
}

// ── Merchant list tile ──

class _MerchantTile extends StatelessWidget {
  const _MerchantTile({
    required this.stat,
    required this.rank,
    required this.subtitle,
    required this.onTap,
  });

  final MerchantStat stat;
  final int rank;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _RankBadge(rank: rank),
        title: Text(
          stat.merchantName,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.amber.shade700,
      Colors.blueGrey.shade400,
      Colors.brown.shade400,
    ];
    final color = rank <= 3 ? colors[rank - 1] : Colors.grey.shade400;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ──

class _MerchantDetailSheet extends StatefulWidget {
  const _MerchantDetailSheet({
    required this.stat,
    required this.service,
    required this.onAliasPressed,
  });

  final MerchantStat stat;
  final MerchantAnalyticsService service;
  final VoidCallback onAliasPressed;

  @override
  State<_MerchantDetailSheet> createState() => _MerchantDetailSheetState();
}

class _MerchantDetailSheetState extends State<_MerchantDetailSheet> {
  List<MonthAmount> _trend = [];
  List<JiveTransaction> _recentTxs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final trend =
        await widget.service.getMerchantTrend(widget.stat.merchantName, 6);
    final txs = await widget.service
        .getMerchantHistory(widget.stat.merchantName, limit: 10);
    if (!mounted) return;
    setState(() {
      _trend = trend;
      _recentTxs = txs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    final fmt = NumberFormat.currency(
        locale: 'zh_CN', symbol: '\u00a5', decimalDigits: 0);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollCtrl) {
        return _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    stat.merchantName,
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        label: '总消费',
                        value: fmt.format(stat.totalAmount),
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: '消费次数',
                        value: '${stat.transactionCount} 次',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: '均次',
                        value: fmt.format(stat.avgAmount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Trend chart
                  if (_trend.isNotEmpty) ...[
                    Text(
                      '月度消费趋势（近 6 月）',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: _TrendChart(data: _trend),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '最近交易',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '共 ${_recentTxs.length} 条',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_recentTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '暂无交易记录',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_recentTxs.length, (i) {
                      final tx = _recentTxs[i];
                      return _TxTile(tx: tx);
                    }),
                  const SizedBox(height: 16),

                  // Alias button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onAliasPressed,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('设置别名'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});
  final List<MonthAmount> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(0, (m, e) => e.amount > m ? e.amount : m);
    final effectiveMaxY = maxY == 0 ? 100.0 : maxY * 1.2;

    return BarChart(
      BarChartData(
        maxY: effectiveMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\u00a5${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[idx].label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].amount,
                width: 20,
                color: Colors.blue.shade400,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final JiveTransaction tx;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MM/dd HH:mm');
    final amountFmt = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '\u00a5',
      decimalDigits: 2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.receipt_outlined, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note ?? tx.rawText ?? '---',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  dateFmt.format(tx.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            amountFmt.format(tx.amount),
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
