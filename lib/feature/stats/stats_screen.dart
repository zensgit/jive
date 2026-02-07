import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/account_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/database/tag_conversion_log.dart';
import '../../core/database/tag_rule_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../settings/report_export_screen.dart';

class StatsScreen extends StatefulWidget {
  final String? filterCategoryKey;
  final String? filterSubCategoryKey;
  final ValueListenable<int>? reloadSignal;

  const StatsScreen({
    super.key,
    this.filterCategoryKey,
    this.filterSubCategoryKey,
    this.reloadSignal,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Isar _isar;
  bool _isLoading = true;
  Map<String, JiveCategory> _categoryByKey = {};

  // 统计数据
  double _totalExpense = 0;
  List<CategoryStat> _categoryStats = [];
  int _touchedIndex = -1; // 当前点击的饼图区块索引
  bool _showIncomeStats = false;
  double _creditLimit = 0;
  double _creditUsed = 0;
  double _creditAvailable = 0;

  // 多币种支持
  String _displayCurrency = 'CNY'; // 显示用的货币（可切换）
  CurrencyService? _currencyService;
  List<String> _availableCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    widget.reloadSignal?.addListener(_handleReload);
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) {
      oldWidget.reloadSignal?.removeListener(_handleReload);
      widget.reloadSignal?.addListener(_handleReload);
    }
  }

  @override
  void dispose() {
    widget.reloadSignal?.removeListener(_handleReload);
    super.dispose();
  }

  void _handleReload() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    _isar = await DatabaseService.getInstance();

    // 初始化货币服务
    _currencyService ??= CurrencyService(_isar);
    final baseCurrency = await _currencyService!.getBaseCurrency();
    final pref = await _currencyService!.getPreference();
    final enabledCurrencies = pref?.enabledCurrencies ?? [baseCurrency];

    // 如果 _displayCurrency 还未初始化，使用基础货币
    if (_displayCurrency == 'CNY' && baseCurrency != 'CNY') {
      _displayCurrency = baseCurrency;
    }

    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    final showIncome = _shouldShowIncomeStats(categoryMap);
    final accountService = AccountService(_isar);
    final accounts = await accountService.getActiveAccounts();
    final accountById = {for (final a in accounts) a.id: a};
    final balances = await accountService.computeBalances(accounts: accounts);
    final creditSummary = await _computeCreditSummary(accounts, balances, _displayCurrency);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(monthStart, monthEnd, includeUpper: false);

    if (widget.filterCategoryKey != null && widget.filterCategoryKey!.isNotEmpty) {
      query = query.categoryKeyEqualTo(widget.filterCategoryKey!);
    }
    if (widget.filterSubCategoryKey != null && widget.filterSubCategoryKey!.isNotEmpty) {
      query = query.subCategoryKeyEqualTo(widget.filterSubCategoryKey!);
    }

    final txs = await query.findAll();

    // 聚合计算（支持多币种转换）
    final Map<String, double> grouped = {};
    double total = 0;

    for (var tx in txs) {
      if (!_includeInStats(tx, showIncome)) continue;
      if (tx.amount <= 0) continue;

      // 获取交易对应账户的币种
      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';

      // 转换为显示货币
      double convertedAmount = tx.amount;
      if (txCurrency != _displayCurrency) {
        convertedAmount =
            await _currencyService!.convert(tx.amount, txCurrency, _displayCurrency) ?? tx.amount;
      }

      final key = _groupKeyFor(tx);
      grouped[key] = (grouped[key] ?? 0) + convertedAmount;
      total += convertedAmount;
    }

    // 转换为列表并排序
    final List<CategoryStat> stats = [];
    grouped.forEach((key, value) {
      stats.add(CategoryStat(
        name: _displayNameForGroupKey(key, categoryMap),
        amount: value,
        color: _getColor(key),
      ));
    });

    // 按金额降序
    stats.sort((a, b) => b.amount.compareTo(a.amount));

    if (mounted) {
      setState(() {
        _categoryByKey = categoryMap;
        _totalExpense = total;
        _categoryStats = stats;
        _isLoading = false;
        _showIncomeStats = showIncome;
        _creditLimit = creditSummary.limit;
        _creditUsed = creditSummary.used;
        _creditAvailable = creditSummary.available;
        _availableCurrencies = enabledCurrencies;
      });
    }
  }

  bool _shouldShowIncomeStats(Map<String, JiveCategory> categoryMap) {
    final filterKey = widget.filterSubCategoryKey ?? widget.filterCategoryKey;
    if (filterKey != null && filterKey.isNotEmpty) {
      return categoryMap[filterKey]?.isIncome ?? false;
    }
    return false;
  }

  bool _includeInStats(JiveTransaction tx, bool showIncome) {
    final type = tx.type ?? "expense";
    if (type == "transfer") return false;
    if (showIncome) return type == "income";
    return type == "expense";
  }

  Color _getColor(String key) {
    switch (key) {
      case '餐饮': return const Color(0xFFFF7043);
      case '购物': return const Color(0xFF42A5F5);
      case '交通': return const Color(0xFFFFA726);
      case '娱乐': return const Color(0xFFAB47BC);
      case '居住': return const Color(0xFF26A69A);
      case '医疗': return const Color(0xFFEF5350);
      default:
        return _palette[_stableHash(key) % _palette.length];
    }
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

  int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  String _groupKeyFor(JiveTransaction tx) {
    if (_isDateGrouping()) {
      return DateFormat('MM-dd').format(tx.timestamp);
    }
    if (widget.filterCategoryKey != null && widget.filterCategoryKey!.isNotEmpty) {
      final subKey = tx.subCategoryKey;
      if (subKey != null && subKey.isNotEmpty) return subKey;
      final sub = tx.subCategory;
      if (sub == null || sub.isEmpty) return "未分类";
      return sub;
    }
    final parentKey = tx.categoryKey;
    if (parentKey != null && parentKey.isNotEmpty) return parentKey;
    return tx.category ?? "其他";
  }

  String _titleText() {
    final suffix = _showIncomeStats ? "收入" : "支出";
    if (widget.filterSubCategoryKey != null && widget.filterSubCategoryKey!.isNotEmpty) {
      return "${_nameForKey(widget.filterSubCategoryKey)} · 本月$suffix";
    }
    if (widget.filterCategoryKey != null && widget.filterCategoryKey!.isNotEmpty) {
      return "${_nameForKey(widget.filterCategoryKey)} · 本月$suffix";
    }
    return _showIncomeStats ? "本月收入" : "本月支出";
  }

  String _emptyText() {
    if (widget.filterCategoryKey != null || widget.filterSubCategoryKey != null) {
      return _showIncomeStats ? "本月暂无该分类收入" : "本月暂无该分类支出";
    }
    return _showIncomeStats ? "本月暂无收入" : "本月暂无支出";
  }

  bool _isDateGrouping() {
    return widget.filterSubCategoryKey != null && widget.filterSubCategoryKey!.isNotEmpty;
  }

  String _displayNameForGroupKey(String key, Map<String, JiveCategory> categoryMap) {
    if (_isDateGrouping()) return key;
    final cat = categoryMap[key];
    return cat?.name ?? key;
  }

  String _nameForKey(String? key) {
    if (key == null || key.isEmpty) return "";
    final cat = _categoryByKey[key];
    return cat?.name ?? key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titleText(), style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出报表',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportExportScreen()),
              );
            },
          ),
          if (_availableCurrencies.length > 1)
            _buildCurrencySelector(),
        ],
      ),
      body: _categoryStats.isEmpty
          ? _buildEmptyState()
          : (isLandscape ? _buildLandscapeBody() : _buildPortraitBody()),
    );
  }

  Widget _buildCurrencySelector() {
    final currencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == _displayCurrency,
      orElse: () => {'code': _displayCurrency, 'symbol': _displayCurrency, 'flag': null},
    );
    final flag = currencyData['flag'] as String?;
    final symbol = currencyData['symbol'] as String;

    return PopupMenuButton<String>(
      initialValue: _displayCurrency,
      tooltip: '切换货币',
      onSelected: (currency) {
        if (currency != _displayCurrency) {
          setState(() {
            _displayCurrency = currency;
            _isLoading = true;
          });
          _loadStats();
        }
      },
      itemBuilder: (context) => _availableCurrencies.map((code) {
        final data = CurrencyDefaults.getAllCurrencies().firstWhere(
          (c) => c['code'] == code,
          orElse: () => {'code': code, 'nameZh': code, 'symbol': code, 'flag': null},
        );
        final itemFlag = data['flag'] as String?;
        final itemSymbol = data['symbol'] as String;
        final nameZh = data['nameZh'] as String;

        return PopupMenuItem<String>(
          value: code,
          child: Row(
            children: [
              Text(itemFlag ?? itemSymbol, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(code),
              const SizedBox(width: 4),
              Text(
                nameZh,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (code == _displayCurrency) ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: Colors.green),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag ?? symbol, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              _displayCurrency,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitBody() {
    final chartHeight = _creditLimit > 0 ? 260.0 : 300.0;
    return Column(
      children: [
        if (_creditLimit > 0) _buildCreditSummary(),
        SizedBox(height: chartHeight, child: _buildPieChart()),
        Expanded(child: _buildStatsList(const EdgeInsets.symmetric(horizontal: 20))),
      ],
    );
  }

  Widget _buildLandscapeBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = (constraints.maxHeight - 16).clamp(180.0, 260.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: chartSize,
                height: chartSize,
                child: _buildPieChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    if (_creditLimit > 0)
                      _buildCreditSummary(
                        margin: const EdgeInsets.only(bottom: 12),
                        dense: true,
                      ),
                    Expanded(child: _buildStatsList(const EdgeInsets.only(right: 4))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart() {
    final currencySymbol = CurrencyDefaults.getSymbol(_displayCurrency);
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 60, // 空心半径
            sections: _buildPieSections(),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _touchedIndex == -1
                  ? (_showIncomeStats ? "总收入" : "总支出")
                  : _categoryStats[_touchedIndex].name,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "$currencySymbol${NumberFormat.compact().format(
                _touchedIndex == -1 ? _totalExpense : _categoryStats[_touchedIndex].amount,
              )}",
              style: GoogleFonts.rubik(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsList(EdgeInsets padding) {
    final currencySymbol = CurrencyDefaults.getSymbol(_displayCurrency);
    return ListView.builder(
      padding: padding,
      itemCount: _categoryStats.length,
      itemBuilder: (context, index) {
        final stat = _categoryStats[index];
        final percent = stat.amount / _totalExpense;
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
                    "$currencySymbol${stat.amount.toStringAsFixed(1)}",
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
    );
  }

  Widget _buildCreditSummary({EdgeInsets? margin, bool dense = false}) {
    final currencySymbol = CurrencyDefaults.getSymbol(_displayCurrency);
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "信用卡概览",
            style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildCreditMeta("额度", _creditLimit, currencySymbol),
              _buildCreditMeta("已用", _creditUsed, currencySymbol),
              _buildCreditMeta("可用", _creditAvailable, currencySymbol),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditMeta(String label, double value, String symbol) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(width: 4),
        Text(
          NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 0).format(value),
          style: GoogleFonts.lato(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<_CreditSummary> _computeCreditSummary(
    List<JiveAccount> accounts,
    Map<int, double> balances,
    String baseCurrency,
  ) async {
    double limit = 0;
    double used = 0;
    double available = 0;

    for (final account in accounts) {
      if (!AccountService.isCreditAccount(account)) continue;
      final accountLimit = account.creditLimit;
      if (accountLimit == null || accountLimit <= 0) continue;
      final balance = balances[account.id] ?? account.openingBalance;
      final usedForAccount = balance < 0 ? -balance : 0.0;

      // 转换为基础货币
      final accountCurrency = account.currency;
      double convertedLimit = accountLimit;
      double convertedUsed = usedForAccount;

      if (accountCurrency != baseCurrency && _currencyService != null) {
        convertedLimit =
            await _currencyService!.convert(accountLimit, accountCurrency, baseCurrency) ??
                accountLimit;
        convertedUsed =
            await _currencyService!.convert(usedForAccount, accountCurrency, baseCurrency) ??
                usedForAccount;
      }

      limit += convertedLimit;
      used += convertedUsed;
      final availableForAccount = convertedLimit - convertedUsed;
      if (availableForAccount > 0) {
        available += availableForAccount;
      }
    }

    return _CreditSummary(limit: limit, used: used, available: available);
  }

  List<PieChartSectionData> _buildPieSections() {
    return List.generate(_categoryStats.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0; // 选中变大
      final stat = _categoryStats[i];

      return PieChartSectionData(
        color: stat.color,
        value: stat.amount,
        title: '${(stat.amount / _totalExpense * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_emptyText(), style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class CategoryStat {
  final String name;
  final double amount;
  final Color color;

  CategoryStat({required this.name, required this.amount, required this.color});
}

class _CreditSummary {
  final double limit;
  final double used;
  final double available;

  const _CreditSummary({
    required this.limit,
    required this.used,
    required this.available,
  });
}
