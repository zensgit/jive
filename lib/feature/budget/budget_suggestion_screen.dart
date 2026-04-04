import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/budget_model.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/budget_suggestion_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// Screen that displays AI-powered budget suggestions based on historical
/// spending and lets the user adopt them individually or all at once.
class BudgetSuggestionScreen extends StatefulWidget {
  const BudgetSuggestionScreen({super.key});

  @override
  State<BudgetSuggestionScreen> createState() =>
      _BudgetSuggestionScreenState();
}

class _BudgetSuggestionScreenState extends State<BudgetSuggestionScreen> {
  bool _isLoading = true;
  String? _error;

  BudgetSuggestion? _totalSuggestion;
  List<BudgetSuggestion> _categorySuggestions = const [];
  List<AnomalyMonth> _anomalies = const [];

  BudgetService? _budgetService;
  String _currency = 'CNY';

  final Set<String> _adopted = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final isar = await DatabaseService.getInstance();
      final cs = CurrencyService(isar);
      _currency = await cs.getBaseCurrency();
      _budgetService = BudgetService(isar, cs);

      final service = await BudgetSuggestionService.create();
      final total = await service.suggestTotalBudget();
      final categories = await service.suggestBudgets();
      final anomalies = await service.detectAnomalyMonths();

      if (!mounted) return;
      setState(() {
        _totalSuggestion = total;
        _categorySuggestions = categories;
        _anomalies = anomalies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // -- adopt helpers --

  Future<void> _adoptOne(BudgetSuggestion s) async {
    if (_budgetService == null) return;
    final now = DateTime.now();
    final (start, end) = BudgetService.getPeriodDateRange(
      BudgetPeriod.monthly,
      referenceDate: now,
    );

    await _budgetService!.createBudget(
      name: s.categoryName,
      amount: s.suggestedAmount,
      currency: _currency,
      categoryKey: s.categoryKey,
      startDate: start,
      endDate: end,
      period: BudgetPeriod.monthly.value,
      alertEnabled: true,
      alertThreshold: 80,
    );

    if (!mounted) return;
    final key = s.categoryKey ?? '_total';
    setState(() => _adopted.add(key));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已采纳 ${s.categoryName} 预算')),
    );
  }

  Future<void> _adoptAll() async {
    if (_budgetService == null) return;

    // Adopt total first, then categories.
    if (_totalSuggestion != null && !_adopted.contains('_total')) {
      await _adoptOne(_totalSuggestion!);
    }
    for (final s in _categorySuggestions) {
      final key = s.categoryKey ?? '_total';
      if (_adopted.contains(key)) continue;
      await _adoptOne(s);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已全部采纳')),
    );
  }

  // -- build --

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('智能建议')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('加载失败: $_error'));
    }

    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: _currencySymbol(_currency),
      decimalDigits: 0,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header text
        Text(
          '基于您最近 3 个月的消费，我们建议以下预算',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),

        // Overall budget suggestion card
        if (_totalSuggestion != null) _buildTotalCard(formatter),

        const SizedBox(height: 16),

        // Anomaly warnings
        if (_anomalies.isNotEmpty) ...[
          _buildAnomalySection(formatter),
          const SizedBox(height: 16),
        ],

        // Category suggestions
        if (_categorySuggestions.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '分类预算建议',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: _adoptAll,
                child: const Text('全部采纳'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._categorySuggestions.map((s) => _buildCategoryTile(s, formatter)),
        ],

        if (_categorySuggestions.isEmpty && _totalSuggestion == null)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: Text('暂无足够历史数据生成建议')),
          ),
      ],
    );
  }

  Widget _buildTotalCard(NumberFormat fmt) {
    final s = _totalSuggestion!;
    final isAdopted = _adopted.contains('_total');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    size: 28, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('总预算建议',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _buildConfidenceBadge(s.confidence),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fmt.format(s.suggestedAmount),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '月均消费 ${fmt.format(s.averageSpend)}，'
              '范围 ${fmt.format(s.minSpend)} – ${fmt.format(s.maxSpend)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            _buildRangeBar(s),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isAdopted ? null : () => _adoptOne(s),
                child: Text(isAdopted ? '已采纳' : '采纳'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BudgetSuggestion s, NumberFormat fmt) {
    final key = s.categoryKey ?? '_total';
    final isAdopted = _adopted.contains(key);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  s.icon != null
                      ? CategoryService.getIcon(s.icon!)
                      : Icons.category,
                  size: 22,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  fmt.format(s.suggestedAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${fmt.format(s.minSpend)} – ${fmt.format(s.maxSpend)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            _buildRangeBar(s),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isAdopted ? null : () => _adoptOne(s),
                child: Text(isAdopted ? '已采纳' : '采纳'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeBar(BudgetSuggestion s) {
    // A simple visual bar showing min-avg-max relative positions.
    final range = s.maxSpend - s.minSpend;
    if (range <= 0) return const SizedBox.shrink();

    final avgFraction = (s.averageSpend - s.minSpend) / range;

    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              // Full range background
              Container(
                width: width,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Average marker
              Positioned(
                left: (avgFraction * width).clamp(0, width - 4),
                child: Container(
                  width: 4,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percent = (confidence * 100).round();
    Color color;
    if (confidence >= 0.7) {
      color = Colors.green;
    } else if (confidence >= 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '置信度 $percent%',
        style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAnomalySection(NumberFormat fmt) {
    final monthFmt = DateFormat('yyyy-MM');
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 6),
                Text(
                  '异常月份提醒',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final a in _anomalies)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${monthFmt.format(a.month)}: '
                  '消费 ${fmt.format(a.totalExpense)}，'
                  '高于均值 ${fmt.format(a.mean)} 超过 2 倍标准差',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'CNY':
        return '\u00a5';
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20ac';
      case 'GBP':
        return '\u00a3';
      case 'JPY':
        return '\u00a5';
      default:
        return code;
    }
  }
}
