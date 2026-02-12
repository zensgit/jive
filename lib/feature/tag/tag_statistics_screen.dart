import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/data_reload_bus.dart';
import '../../core/widgets/date_range_picker_sheet.dart';

class TagStatisticsScreen extends StatefulWidget {
  final JiveTag tag;
  final Isar? isar;

  const TagStatisticsScreen({
    super.key,
    required this.tag,
    this.isar,
  });

  @override
  State<TagStatisticsScreen> createState() => _TagStatisticsScreenState();
}

class _TagStatisticsScreenState extends State<TagStatisticsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  String? _error;
  DateTimeRange _range = _defaultRange();
  List<JiveTransaction> _transactions = [];
  Map<String, JiveCategory> _categoryByKey = {};
  bool _showIncome = false;
  double _expenseTotal = 0;
  double _incomeTotal = 0;
  int _transactionCount = 0;
  List<_TagStat> _stats = [];
  int _touchedIndex = -1;
  bool _ready = false;

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    return DateTimeRange(start: start, end: end);
  }

  final List<Color> _palette = const [
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFFFA726),
    Color(0xFF7E57C2),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF26C6DA),
    Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    DataReloadBus.notifier.addListener(_handleReload);
  }

  @override
  void dispose() {
    DataReloadBus.notifier.removeListener(_handleReload);
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      _isar = widget.isar ?? await DatabaseService.getInstance();

      final categories = await _isar.collection<JiveCategory>().where().findAll();
      final categoryMap = {for (final c in categories) c.key: c};
      final rangeStart = DateTime(
        _range.start.year,
        _range.start.month,
        _range.start.day,
      );
      final rangeEndExclusive = DateTime(
        _range.end.year,
        _range.end.month,
        _range.end.day,
      ).add(const Duration(days: 1));
      final txs = await _isar.jiveTransactions
          .filter()
          .tagKeysElementEqualTo(widget.tag.key)
          .timestampBetween(rangeStart, rangeEndExclusive, includeUpper: false)
          .findAll();

      _transactions = txs;
      _categoryByKey = categoryMap;
      _rebuildStats();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
          _ready = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleReload() {
    if (!_ready || _isLoading) return;
    _loadStats();
  }

  void _rebuildStats() {
    double expenseTotal = 0;
    double incomeTotal = 0;
    int count = 0;
    for (final tx in _transactions) {
      final type = tx.type ?? 'expense';
      if (type == 'transfer') continue;
      count += 1;
      if (type == 'income') {
        incomeTotal += tx.amount;
      } else {
        expenseTotal += tx.amount;
      }
    }

    if (!_showIncome && incomeTotal > 0 && expenseTotal == 0) {
      _showIncome = true;
    }

    final filtered = _transactions.where((tx) {
      final type = tx.type ?? 'expense';
      if (type == 'transfer') return false;
      return _showIncome ? type == 'income' : type == 'expense';
    }).toList();

    final grouped = <String, double>{};
    for (final tx in filtered) {
      if (tx.amount <= 0) continue;
      final key = _groupKeyFor(tx);
      grouped[key] = (grouped[key] ?? 0) + tx.amount;
    }

    final stats = <_TagStat>[];
    grouped.forEach((key, value) {
      stats.add(
        _TagStat(
          name: _displayNameForGroupKey(key),
          amount: value,
          color: _colorForKey(key),
        ),
      );
    });
    stats.sort((a, b) => b.amount.compareTo(a.amount));

    _expenseTotal = expenseTotal;
    _incomeTotal = incomeTotal;
    _transactionCount = count;
    _stats = stats;
  }

  String _displayNameForGroupKey(String key) {
    final category = _categoryByKey[key];
    return category?.name ?? key;
  }

  String _groupKeyFor(JiveTransaction tx) {
    final subKey = tx.subCategoryKey;
    if (subKey != null && subKey.isNotEmpty) return subKey;
    final parentKey = tx.categoryKey;
    if (parentKey != null && parentKey.isNotEmpty) return parentKey;
    return tx.category ?? '未分类';
  }

  Color _colorForKey(String key) {
    final colorHex = _categoryByKey[key]?.colorHex;
    final parsed = AccountService.parseColorHex(colorHex);
    if (parsed != null) return parsed;
    return _palette[_stableHash(key) % _palette.length];
  }

  int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> _pickRange() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: DateRangePickerSheet(
            initialRange: _range,
            onChanged: (range) {
              if (range == null) return;
              setState(() {
                _range = range;
                _isLoading = true;
              });
              _loadStats();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('标签统计', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('标签统计', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            tooltip: '选择日期范围',
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildHeader(),
                _buildToggle(),
                Expanded(child: _buildStatsBody()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final rangeText =
        '${DateFormat('yyyy.MM.dd').format(_range.start)} - ${DateFormat('yyyy.MM.dd').format(_range.end)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tag.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(rangeText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetric('交易数', _transactionCount.toString()),
                _buildMetric('支出', _currency(_expenseTotal)),
                _buildMetric('收入', _currency(_incomeTotal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) {
    return NumberFormat.compactCurrency(symbol: '¥', decimalDigits: 0).format(value);
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _buildToggle() {
    final hasIncome = _incomeTotal > 0;
    final hasExpense = _expenseTotal > 0;
    if (!(hasIncome && hasExpense)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('支出'),
            selected: !_showIncome,
            selectedColor: Colors.green.shade50,
            onSelected: (_) {
              setState(() {
                _showIncome = false;
                _rebuildStats();
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('收入'),
            selected: _showIncome,
            selectedColor: Colors.green.shade50,
            onSelected: (_) {
              setState(() {
                _showIncome = true;
                _rebuildStats();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBody() {
    if (_stats.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      children: [
        SizedBox(height: 260, child: _buildPieChart()),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _stats.length,
            itemBuilder: (context, index) {
              final stat = _stats[index];
              final total = _stats.fold<double>(0, (sum, item) => sum + item.amount);
              final percent = total == 0 ? 0.0 : stat.amount / total;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: stat.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Text(stat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          "¥${stat.amount.toStringAsFixed(1)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(percent * 100).toStringAsFixed(1)}%",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey.shade100,
                        color: stat.color,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final total = _stats.fold<double>(0, (sum, item) => sum + item.amount);
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 56,
            sections: List.generate(_stats.length, (index) {
              final stat = _stats[index];
              final isTouched = index == _touchedIndex;
              return PieChartSectionData(
                color: stat.color,
                value: stat.amount,
                title: total == 0 ? '' : '${(stat.amount / total * 100).toStringAsFixed(0)}%',
                radius: isTouched ? 68 : 58,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _touchedIndex == -1 ? (_showIncome ? '总收入' : '总支出') : _stats[_touchedIndex].name,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.compactCurrency(symbol: '¥', decimalDigits: 0).format(
                _touchedIndex == -1
                    ? (_showIncome ? _incomeTotal : _expenseTotal)
                    : _stats[_touchedIndex].amount,
              ),
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('该时间范围内暂无标签数据', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _TagStat {
  final String name;
  final double amount;
  final Color color;

  _TagStat({
    required this.name,
    required this.amount,
    required this.color,
  });
}
