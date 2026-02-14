import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/budget_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/budget_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import 'budget_exclude_screen.dart';

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
    return _BudgetLoadResult(
      currencyService: currencyService,
      budgetService: budgetService,
      summaries: summaries,
    );
  }

  Future<void> _createBudget() async {
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
      builder: (ctx) => _CreateBudgetSheet(
        currencyService: _currencyService!,
        budgetService: _budgetService!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: [
          IconButton(
            tooltip: '预算排除',
            onPressed: _openBudgetExclude,
            icon: const Icon(Icons.block),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _createBudget),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadErrorMessage != null
          ? _buildLoadErrorState()
          : _summaries.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _summaries.length,
                itemBuilder: (context, index) {
                  return _buildBudgetCard(_summaries[index]);
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
    return Center(
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
                          '${_getPeriodText(budget.period)} • 剩余${summary.daysRemaining}天',
                          style: TextStyle(
                            fontSize: 12,
                            color: JiveTheme.secondaryTextColor(context),
                          ),
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
}

class _BudgetLoadResult {
  final CurrencyService currencyService;
  final BudgetService budgetService;
  final List<BudgetSummary> summaries;

  const _BudgetLoadResult({
    required this.currencyService,
    required this.budgetService,
    required this.summaries,
  });
}

/// 创建预算底部弹窗
class _CreateBudgetSheet extends StatefulWidget {
  final CurrencyService currencyService;
  final BudgetService budgetService;

  const _CreateBudgetSheet({
    required this.currencyService,
    required this.budgetService,
  });

  @override
  State<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends State<_CreateBudgetSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _currency = 'CNY';
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _alertEnabled = true;
  double _alertThreshold = 80;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
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

  Future<void> _create() async {
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

    setState(() => _isCreating = true);

    final (startDate, endDate) = BudgetService.getPeriodDateRange(_period);

    await widget.budgetService.createBudget(
      name: name,
      amount: amount,
      currency: _currency,
      startDate: startDate,
      endDate: endDate,
      period: _period.value,
      alertEnabled: _alertEnabled,
      alertThreshold: _alertThreshold,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    '创建预算',
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
                    .where((p) => p != BudgetPeriod.custom)
                    .map((p) {
                      final isSelected = _period == p;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _period = p);
                        },
                        selectedColor: JiveTheme.primaryGreen.withValues(
                          alpha: 0.2,
                        ),
                      );
                    })
                    .toList(),
              ),
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
                  onPressed: _isCreating ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('创建预算'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 预算详情底部弹窗
class _BudgetDetailSheet extends StatelessWidget {
  final BudgetSummary summary;
  final CurrencyService currencyService;
  final VoidCallback onDelete;

  const _BudgetDetailSheet({
    required this.summary,
    required this.currencyService,
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
              '开始日期',
              DateFormat('yyyy-MM-dd').format(budget.startDate),
            ),
            _buildDetailRow(
              '结束日期',
              DateFormat('yyyy-MM-dd').format(budget.endDate),
            ),
            _buildDetailRow('剩余天数', '${summary.daysRemaining} 天'),
          ],
        ),
      ),
    );
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
