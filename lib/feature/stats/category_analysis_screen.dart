import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/currency_model.dart';
import '../../core/service/stats_aggregation_service.dart';
import '../category/category_transactions_screen.dart';

class CategoryAnalysisScreen extends StatefulWidget {
  final String? currencyCode;
  const CategoryAnalysisScreen({super.key, this.currencyCode});

  @override
  State<CategoryAnalysisScreen> createState() => _CategoryAnalysisScreenState();
}

class _CategoryAnalysisScreenState extends State<CategoryAnalysisScreen> {
  bool _isLoading = true;
  bool _showExpense = true;
  List<CategoryStat> _stats = [];
  int _touchedIndex = -1;
  DateTime _currentMonth = DateTime.now();

  static const List<Color> _palette = [
    Color(0xFFFF7043), Color(0xFF42A5F5), Color(0xFFFFA726), Color(0xFFAB47BC),
    Color(0xFF26A69A), Color(0xFFEF5350), Color(0xFF66BB6A), Color(0xFF8D6E63),
    Color(0xFF26C6DA), Color(0xFFEC407A), Color(0xFF7E57C2), Color(0xFFD4E157),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = await StatsAggregationService.create();
    final stats = await service.getCategoryBreakdown(
      _currentMonth,
      isExpense: _showExpense,
      currencyCode: widget.currencyCode,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
        _touchedIndex = -1;
      });
    }
  }

  void _changeMonth(int delta) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final symbol = CurrencyDefaults.getSymbol(widget.currencyCode ?? 'CNY');
    final total = _stats.fold<double>(0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        // Month + toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => _changeMonth(-1)),
              Text(DateFormat('yyyy年M月').format(_currentMonth), style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => _changeMonth(1)),
              const Spacer(),
              ToggleButtons(
                isSelected: [_showExpense, !_showExpense],
                onPressed: (i) {
                  _showExpense = i == 0;
                  _load();
                },
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 56),
                textStyle: const TextStyle(fontSize: 13),
                children: const [Text('支出'), Text('收入')],
              ),
            ],
          ),
        ),

        // Pie chart
        if (_stats.isNotEmpty)
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: _buildSections(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touchedIndex >= 0 ? _stats[_touchedIndex].name : (_showExpense ? '总支出' : '总收入'),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$symbol${NumberFormat.compact().format(_touchedIndex >= 0 ? _stats[_touchedIndex].amount : total)}',
                      style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200,
            child: Center(child: Text(_showExpense ? '本月暂无支出' : '本月暂无收入', style: TextStyle(color: Colors.grey.shade400))),
          ),

        // Category list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stats.length > 10 ? 10 : _stats.length,
            itemBuilder: (context, index) {
              final stat = _stats[index];
              final color = _palette[index % _palette.length];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryTransactionsScreen(
                        title: stat.name,
                        filterCategoryKey: stat.key,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: stat.percentage / 100,
                                backgroundColor: Colors.grey.shade100,
                                color: color,
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$symbol${stat.amount.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${stat.percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(_stats.length > 10 ? 10 : _stats.length, (i) {
      final isTouched = i == _touchedIndex;
      final stat = _stats[i];
      return PieChartSectionData(
        color: _palette[i % _palette.length],
        value: stat.amount,
        title: '${stat.percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 65.0 : 55.0,
        titleStyle: TextStyle(fontSize: isTouched ? 14.0 : 11.0, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
}
