import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/database/budget_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/category_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/widgets/date_range_picker_sheet.dart';
import 'budget_exclude_screen.dart';
import '../category/category_picker_screen.dart';
import '../category/category_search_delegate.dart';
import '../category/category_transactions_screen.dart';

/// 预算管理界面
class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  static const Duration _loadTimeout = Duration(seconds: 12);
  bool _isLoading = true;
  List<BudgetSummary> _summaries = [];
  Map<String, JiveCategory> _categoryByKey = {};
  String? _loadErrorMessage;
  BudgetService? _budgetService;
  CurrencyService? _currencyService;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
      });
    }

    try {
      final loaded = await _loadDataInternal().timeout(
        _loadTimeout,
        onTimeout: () => throw TimeoutException('预算数据加载超时'),
      );

      if (!mounted) return;
      setState(() {
        _currencyService = loaded.currencyService;
        _budgetService = loaded.budgetService;
        _summaries = loaded.summaries;
        _categoryByKey = loaded.categoryByKey;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _summaries = [];
        _loadErrorMessage = '预算加载超时，请稍后重试或清理测试数据';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaries = [];
        _loadErrorMessage = '加载预算失败：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<_BudgetLoadResult> _loadDataInternal() async {
    final isar = await DatabaseService.getInstance();
    final currencyService = CurrencyService(isar);
    final budgetService = BudgetService(isar, currencyService);
    final summaries = await budgetService.getAllBudgetSummaries();
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryByKey = {for (final c in categories) c.key: c};
    return _BudgetLoadResult(
      currencyService: currencyService,
      budgetService: budgetService,
      summaries: summaries,
      categoryByKey: categoryByKey,
    );
  }

  Future<void> _createBudget() async {
    await _openBudgetEditor();
  }

  Future<void> _openBudgetEditor({JiveBudget? budget}) async {
    if (_currencyService == null || _budgetService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('预算服务尚未准备好，请稍后重试')));
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BudgetEditorSheet(
        currencyService: _currencyService!,
        budgetService: _budgetService!,
        categories: _categoryByKey.values.toList(),
        initialBudget: budget,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openBudgetExclude() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const BudgetExcludeScreen()),
    );
    _loadData();
  }

  Future<void> _pullToOpenBudgetExclude() async {
    // Keep the refresh indicator short; open the screen without waiting.
    unawaited(_openBudgetExclude());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '预算排除',
            onPressed: _openBudgetExclude,
            icon: const Icon(Icons.block),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadErrorMessage != null
          ? _buildLoadErrorState()
          : RefreshIndicator(
              onRefresh: _pullToOpenBudgetExclude,
              child: _summaries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _summaries.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildPullHintCard();
                        }
                        return _buildBudgetCard(_summaries[index - 1]);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _currencyService == null || _budgetService == null
            ? null
            : _createBudget,
        tooltip: '创建预算',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              '预算加载失败',
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadErrorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildPullHintCard(),
        const SizedBox(height: 24),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                '暂无预算',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: JiveTheme.secondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '创建预算来追踪您的支出',
                style: TextStyle(color: JiveTheme.secondaryTextColor(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createBudget,
                icon: const Icon(Icons.add),
                label: const Text('创建预算'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPullHintCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.swipe_down, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '下拉设置不计入预算的分类',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: _openBudgetExclude,
            child: const Text('打开'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetSummary summary) {
    final budget = summary.budget;
    final currencyData = _getCurrencyData(budget.currency);
    final symbol = currencyData['symbol'] as String;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (summary.status) {
      case BudgetStatus.exceeded:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = '已超支';
        break;
      case BudgetStatus.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.error_outline;
        statusText = '接近预算';
        break;
      default:
        statusColor = JiveTheme.primaryGreen;
        statusIcon = Icons.check_circle_outline;
        statusText = '正常';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBudgetDetail(summary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_getPeriodText(budget.period)} • ${_budgetScopeText(budget)} • 剩余${summary.daysRemaining}天',
                          style: TextStyle(
                            fontSize: 12,
                            color: JiveTheme.secondaryTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (summary.usedPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '剩余 $symbol ${_formatAmount(summary.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: summary.remainingAmount < 0
                          ? Colors.red
                          : JiveTheme.secondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (summary.daysRemaining > 0)
                    Text(
                      '日均可用 $symbol ${_formatAmount(summary.remainingAmount / summary.daysRemaining)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: summary.remainingAmount < 0
                            ? Colors.red
                            : JiveTheme.secondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已使用',
                        style: TextStyle(
                          fontSize: 11,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                      Text(
                        '$symbol ${_formatAmount(summary.usedAmount)}',
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '使用率',
                        style: TextStyle(
                          fontSize: 11,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                      Text(
                        '${summary.usedPercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '预算金额',
                        style: TextStyle(
                          fontSize: 11,
                          color: JiveTheme.secondaryTextColor(context),
                        ),
                      ),
                      Text(
                        '$symbol ${_formatAmount(budget.amount)}',
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetDetail(BudgetSummary summary) {
    if (_currencyService == null || _budgetService == null) {
      _loadData();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: JiveTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BudgetDetailSheet(
        summary: summary,
        currencyService: _currencyService!,
        categoryByKey: _categoryByKey,
        onEdit: () {
          Navigator.of(ctx).pop();
          unawaited(
            Future<void>.delayed(
              const Duration(milliseconds: 150),
              () => _openBudgetEditor(budget: summary.budget),
            ),
          );
        },
        onDelete: () async {
          try {
            await _budgetService!.deleteBudget(summary.budget.id);
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
            _loadData();
          } catch (e) {
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
          }
        },
      ),
    );
  }

  Map<String, dynamic> _getCurrencyData(String code) {
    return CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'symbol': code},
    );
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return '自定义';
    }
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
  }

  String _budgetScopeText(JiveBudget budget) {
    final key = budget.categoryKey;
    if (key == null || key.isEmpty) return '全部分类';
    final category = _categoryByKey[key];
    if (category == null) return key;
    final parentKey = category.parentKey;
    if (parentKey != null && parentKey.isNotEmpty) {
      final parent = _categoryByKey[parentKey];
      if (parent != null) return '${parent.name} · ${category.name}';
    }
    return category.name;
  }
}

class _BudgetLoadResult {
  final CurrencyService currencyService;
  final BudgetService budgetService;
  final List<BudgetSummary> summaries;
  final Map<String, JiveCategory> categoryByKey;

  const _BudgetLoadResult({
    required this.currencyService,
    required this.budgetService,
    required this.summaries,
    required this.categoryByKey,
  });
}

/// 创建预算底部弹窗
class _BudgetEditorSheet extends StatefulWidget {
  final CurrencyService currencyService;
  final BudgetService budgetService;
  final List<JiveCategory> categories;
  final JiveBudget? initialBudget;

  const _BudgetEditorSheet({
    required this.currencyService,
    required this.budgetService,
    required this.categories,
    this.initialBudget,
  });

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _currency = 'CNY';
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _alertEnabled = true;
  double _alertThreshold = 80;
  String? _categoryKey;
  DateTimeRange? _customRange;
  late final Map<String, JiveCategory> _categoryByKey;
  late final bool _preferUserCategories;
  late final BudgetPeriod? _initialPeriod;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoryByKey = {for (final c in widget.categories) c.key: c};
    _preferUserCategories = widget.categories.any((c) => !c.isIncome && !c.isSystem);
    final budget = widget.initialBudget;
    if (budget == null) {
      _loadCurrency();
      return;
    }
    _initialPeriod = BudgetPeriod.fromValue(budget.period);
    _period = _initialPeriod!;
    _currency = budget.currency;
    _categoryKey = budget.categoryKey?.isNotEmpty == true ? budget.categoryKey : null;
    _alertEnabled = budget.alertEnabled;
    _alertThreshold = budget.alertThreshold ?? _alertThreshold;
    _nameController.text = budget.name;
    _amountController.text = _formatAmountForInput(budget.amount);
    if (_period == BudgetPeriod.custom) {
      _customRange = DateTimeRange(
        start: DateTime(budget.startDate.year, budget.startDate.month, budget.startDate.day),
        end: DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day),
      );
    }
  }

  Future<void> _loadCurrency() async {
    final base = await widget.currencyService.getBaseCurrency();
    setState(() => _currency = base);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入预算名称')));
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }

    if (_period == BudgetPeriod.custom && _customRange == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择预算日期范围')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final (startDate, endDate) = _resolveBudgetDateRange();
      final alertThreshold = _alertEnabled ? _alertThreshold : null;

      final budget = widget.initialBudget;
      if (budget == null) {
        await widget.budgetService.createBudget(
          name: name,
          amount: amount,
          currency: _currency,
          categoryKey: _categoryKey,
          startDate: startDate,
          endDate: endDate,
          period: _period.value,
          alertEnabled: _alertEnabled,
          alertThreshold: alertThreshold,
        );
      } else {
        budget
          ..name = name
          ..amount = amount
          ..currency = _currency
          ..categoryKey = _categoryKey
          ..startDate = startDate
          ..endDate = endDate
          ..period = _period.value
          ..alertEnabled = _alertEnabled
          ..alertThreshold = alertThreshold;
        await widget.budgetService.updateBudget(budget);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      return;
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialBudget != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart, color: JiveTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? '编辑预算' : '创建预算',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // 预算名称
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '预算名称',
                  hintText: '如：日常开销、餐饮预算',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 分类范围
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickCategory,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '预算分类',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCategoryLeading(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _categoryKey == null ? '全部分类' : _categoryLabel(_categoryKey!),
                          style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_categoryKey != null)
                        IconButton(
                          tooltip: '清除',
                          onPressed: () => setState(() => _categoryKey = null),
                          icon: Icon(Icons.close, size: 16, color: Colors.grey.shade700),
                          padding: EdgeInsets.zero,
                          splashRadius: 16,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 金额和货币
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '预算金额',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: '货币',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['CNY', 'USD', 'EUR', 'JPY', 'HKD'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 周期选择
              Text(
                '预算周期',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BudgetPeriod.values
                    .map((p) {
                      final isSelected = _period == p;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => _period = p);
                        },
                        selectedColor: JiveTheme.primaryGreen.withValues(
                          alpha: 0.2,
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 12),

              // 日期范围（自定义预算可选）
              _buildDateRangePicker(context),
              const SizedBox(height: 16),

              // 预警设置
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用预算预警'),
                subtitle: Text('当使用率达到 ${_alertThreshold.toInt()}% 时提醒'),
                value: _alertEnabled,
                onChanged: (v) => setState(() => _alertEnabled = v),
              ),
              if (_alertEnabled)
                Slider(
                  value: _alertThreshold,
                  min: 50,
                  max: 95,
                  divisions: 9,
                  label: '${_alertThreshold.toInt()}%',
                  onChanged: (v) => setState(() => _alertThreshold = v),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? '保存' : '创建预算'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (DateTime, DateTime) _resolveBudgetDateRange() {
    if (_period == BudgetPeriod.custom) {
      final range = _customRange!;
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
      return (start, end);
    }

    final budget = widget.initialBudget;
    if (budget != null) {
      final initial = _initialPeriod ?? BudgetPeriod.fromValue(budget.period);
      if (initial == _period) return (budget.startDate, budget.endDate);
      return BudgetService.getPeriodDateRange(_period);
    }

    return BudgetService.getPeriodDateRange(_period);
  }

  Widget _buildDateRangePicker(BuildContext context) {
    final isCustom = _period == BudgetPeriod.custom;
    final range = _previewDateRange();
    final rangeText = range == null
        ? '请选择日期范围'
        : '${_formatYmd(range.$1)} - ${_formatYmd(range.$2)}';

    final decorator = InputDecorator(
      decoration: InputDecoration(
        labelText: '预算范围',
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rangeText,
              style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCustom && _customRange != null)
            IconButton(
              tooltip: '清除',
              onPressed: () => setState(() => _customRange = null),
              icon: Icon(Icons.close, size: 16, color: Colors.grey.shade700),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          if (isCustom) Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
        ],
      ),
    );

    if (!isCustom) return decorator;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickCustomDateRange,
      child: decorator,
    );
  }

  (DateTime, DateTime)? _previewDateRange() {
    if (_period == BudgetPeriod.custom) {
      final range = _customRange;
      if (range == null) return null;
      return (range.start, range.end);
    }

    final (start, end) = _resolveBudgetDateRange();
    return (start, end);
  }

  String _formatYmd(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatAmountForInput(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initial = _customRange;
    final viewStart = DateTime((initial?.start.year ?? now.year) - 1, 1, 1);
    final viewEnd = DateTime((initial?.end.year ?? now.year) + 1, 12, 31);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DateRangePickerSheet(
          initialRange: initial,
          firstDay: viewStart,
          lastDay: viewEnd,
          onChanged: (range) => setState(() => _customRange = range),
        );
      },
    );
  }

  Widget _buildCategoryLeading() {
    if (_categoryKey == null) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.all_inclusive, size: 16, color: Colors.grey.shade700),
      );
    }
    final category = _categoryByKey[_categoryKey!];
    if (category == null) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.category, size: 16, color: Colors.grey.shade700),
      );
    }
    final color = CategoryService.parseColorHex(category.colorHex) ?? JiveTheme.categoryIconInactive;
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.12),
      child: CategoryService.buildIcon(
        category.iconName,
        size: 14,
        color: color,
        isSystemCategory: category.isSystem,
        forceTinted: category.iconForceTinted,
      ),
    );
  }

  String _categoryLabel(String key) {
    final category = _categoryByKey[key];
    if (category == null) return key;
    final parentKey = category.parentKey;
    if (parentKey != null && parentKey.isNotEmpty) {
      final parent = _categoryByKey[parentKey];
      if (parent != null) return '${parent.name} · ${category.name}';
    }
    return category.name;
  }

  Future<void> _pickCategory() async {
    final isar = await DatabaseService.getInstance();
    if (!mounted) return;
    final picked = await Navigator.push<CategorySearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(
          isIncome: false,
          onlyUserCategories: _preferUserCategories,
          isar: isar,
          title: '选择预算分类',
        ),
      ),
    );
    if (picked == null) return;
    final key = picked.sub?.key ?? picked.parent.key;
    setState(() => _categoryKey = key);

    // If user didn't name the budget, help them generate a good default.
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = '${picked.primaryName}预算';
    }
  }
}

/// 预算详情底部弹窗
class _BudgetDetailSheet extends StatelessWidget {
  final BudgetSummary summary;
  final CurrencyService currencyService;
  final Map<String, JiveCategory> categoryByKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetDetailSheet({
    required this.summary,
    required this.currencyService,
    required this.categoryByKey,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final budget = summary.budget;
    final currencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == budget.currency,
      orElse: () => {'symbol': budget.currency},
    );
    final symbol = currencyData['symbol'] as String;
    final scope = _budgetScopeText(budget);
    final totalDays = _totalDaysInclusive(budget.startDate, budget.endDate);
    final dailyBudget = budget.amount / totalDays;
    final dailyRemaining = summary.daysRemaining > 0
        ? summary.remainingAmount / summary.daysRemaining
        : summary.remainingAmount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  budget.name,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '编辑',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除预算'),
                        content: Text('确定要删除"${budget.name}"预算吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                            child: const Text(
                              '删除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            if (summary.status != BudgetStatus.normal) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (summary.status == BudgetStatus.exceeded
                          ? Colors.red
                          : Colors.orange)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (summary.status == BudgetStatus.exceeded
                            ? Colors.red
                            : Colors.orange)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  summary.status == BudgetStatus.exceeded
                      ? '已超支 $symbol ${_formatAmount((summary.usedAmount - budget.amount).abs())}'
                      : '已达到预警阈值 ${budget.alertThreshold?.toStringAsFixed(0) ?? '--'}%',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: summary.status == BudgetStatus.exceeded
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 进度圆环
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (summary.usedPercent / 100).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        summary.status == BudgetStatus.exceeded
                            ? Colors.red
                            : summary.status == BudgetStatus.warning
                            ? Colors.orange
                            : JiveTheme.primaryGreen,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${summary.usedPercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.rubik(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('已使用', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 详细信息
            _buildDetailRow('预算分类', scope),
            _buildDetailRow('预算金额', '$symbol ${_formatAmount(budget.amount)}'),
            _buildDetailRow(
              '已使用',
              '$symbol ${_formatAmount(summary.usedAmount)}',
            ),
            _buildDetailRow(
              '剩余',
              '$symbol ${_formatAmount(summary.remainingAmount)}',
              valueColor: summary.remainingAmount < 0 ? Colors.red : null,
            ),
            _buildDetailRow(
              '日均预算',
              '$symbol ${_formatAmount(dailyBudget)}',
            ),
            _buildDetailRow(
              '剩余日预算',
              '$symbol ${_formatAmount(dailyRemaining)}',
              valueColor: dailyRemaining < 0 ? Colors.red : null,
            ),
            _buildDetailRow(
              '开始日期',
              DateFormat('yyyy-MM-dd').format(budget.startDate),
            ),
            _buildDetailRow(
              '结束日期',
              DateFormat('yyyy-MM-dd').format(budget.endDate),
            ),
            _buildDetailRow('剩余天数', '${summary.daysRemaining} 天'),
            _buildDetailRow(
              '预算预警',
              budget.alertEnabled && budget.alertThreshold != null
                  ? '已启用（${budget.alertThreshold!.toStringAsFixed(0)}%）'
                  : '未启用',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openTransactions(context),
                icon: const Icon(Icons.receipt_long),
                label: const Text('查看账单'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTransactions(BuildContext context) {
    final budget = summary.budget;
    String? filterCategoryKey;
    String? filterSubCategoryKey;
    if (budget.categoryKey != null && budget.categoryKey!.isNotEmpty) {
      final selected = categoryByKey[budget.categoryKey!];
      if (selected != null && selected.parentKey != null && selected.parentKey!.isNotEmpty) {
        filterSubCategoryKey = selected.key;
      } else {
        filterCategoryKey = budget.categoryKey;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTransactionsScreen(
          title: '账单 · ${budget.name}',
          filterCategoryKey: filterCategoryKey,
          filterSubCategoryKey: filterSubCategoryKey,
          includeSubCategories: true,
        ),
      ),
    );
  }

  String _budgetScopeText(JiveBudget budget) {
    final key = budget.categoryKey;
    if (key == null || key.isEmpty) return '全部分类';
    final category = categoryByKey[key];
    if (category == null) return key;
    final parentKey = category.parentKey;
    if (parentKey != null && parentKey.isNotEmpty) {
      final parent = categoryByKey[parentKey];
      if (parent != null) return '${parent.name} · ${category.name}';
    }
    return category.name;
  }

  int _totalDaysInclusive(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final diff = endDay.difference(startDay).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
  }
}
