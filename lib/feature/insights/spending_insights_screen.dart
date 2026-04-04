import 'package:flutter/material.dart';

import '../../core/service/spending_analysis_service.dart';

/// Screen displaying AI-generated spending insights.
class SpendingInsightsScreen extends StatefulWidget {
  const SpendingInsightsScreen({super.key});

  @override
  State<SpendingInsightsScreen> createState() => _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState extends State<SpendingInsightsScreen> {
  SpendingAnalysis? _analysis;
  bool _loading = true;
  int _months = 3;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _loading = true);
    try {
      final service = await SpendingAnalysisService.create();
      final analysis = await service.analyzeSpending(_months);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('财务洞察'),
        actions: [
          _PeriodSelector(
            value: _months,
            onChanged: (v) {
              setState(() => _months = v);
              _loadInsights();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _analysis == null || _analysis!.insights.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无洞察',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _analysis!.insights.length,
                    itemBuilder: (context, index) {
                      return _InsightCard(
                          insight: _analysis!.insights[index]);
                    },
                  ),
      ),
    );
  }
}

// ── Period selector ──

class _PeriodSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('1月')),
          ButtonSegment(value: 3, label: Text('3月')),
          ButtonSegment(value: 6, label: Text('6月')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }
}

// ── Insight card ──

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final colorScheme = _colorForType(insight.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForName(insight.iconName),
                color: colorScheme.foreground,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──

class _InsightColorScheme {
  final Color foreground;
  final Color background;
  final Color border;

  const _InsightColorScheme({
    required this.foreground,
    required this.background,
    required this.border,
  });
}

_InsightColorScheme _colorForType(InsightType type) {
  switch (type) {
    case InsightType.achievement:
      return const _InsightColorScheme(
        foreground: Color(0xFF2E7D32),
        background: Color(0xFFE8F5E9),
        border: Color(0xFFA5D6A7),
      );
    case InsightType.warning:
      return const _InsightColorScheme(
        foreground: Color(0xFFE65100),
        background: Color(0xFFFFF3E0),
        border: Color(0xFFFFCC80),
      );
    case InsightType.tip:
      return const _InsightColorScheme(
        foreground: Color(0xFF0277BD),
        background: Color(0xFFE1F5FE),
        border: Color(0xFF81D4FA),
      );
  }
}

IconData _iconForName(String name) {
  const map = <String, IconData>{
    'trending_down': Icons.trending_down,
    'trending_up': Icons.trending_up,
    'warning_amber': Icons.warning_amber,
    'pie_chart': Icons.pie_chart,
    'savings': Icons.savings,
    'calendar_today': Icons.calendar_today,
    'work_outline': Icons.work_outline,
    'speed': Icons.speed,
    'error_outline': Icons.error_outline,
    'info_outline': Icons.info_outline,
  };
  return map[name] ?? Icons.lightbulb_outline;
}
