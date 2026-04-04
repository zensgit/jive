import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/account_model.dart';
import '../../core/database/currency_model.dart';
import '../../core/database/investment_model.dart';
import '../../core/service/account_service.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/investment_service.dart';
import 'portfolio_chart_widget.dart';

class InvestmentScreen extends StatefulWidget {
  final Isar? debugIsar;
  final PortfolioSummary? debugPortfolio;
  final List<JiveSecurity>? debugSecurities;
  final List<JiveCurrency>? debugCurrencies;
  final List<JiveAccount>? debugAccounts;
  final String? debugBaseCurrency;

  const InvestmentScreen({
    super.key,
    this.debugIsar,
    this.debugPortfolio,
    this.debugSecurities,
    this.debugCurrencies,
    this.debugAccounts,
    this.debugBaseCurrency,
  });

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  late Isar _isar;
  late InvestmentService _service;
  late CurrencyService _currencyService;

  bool _isLoading = true;
  PortfolioSummary? _portfolio;
  List<JiveSecurity> _securities = [];
  List<JiveCurrency> _currencies = [];
  List<JiveAccount> _accounts = [];
  Map<int, JiveAccount> _accountById = {};
  String _baseCurrency = 'CNY';
  bool _interactiveEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_usesDebugData) {
      _portfolio = widget.debugPortfolio;
      _securities = widget.debugSecurities ?? [];
      _currencies = widget.debugCurrencies ?? [];
      _accounts = widget.debugAccounts ?? [];
      _accountById = {for (final account in _accounts) account.id: account};
      _baseCurrency =
          widget.debugBaseCurrency ??
          widget.debugPortfolio?.baseCurrency ??
          'CNY';
      _isLoading = false;
      return;
    }

    _isar = widget.debugIsar ?? await DatabaseService.getInstance();
    _service = InvestmentService(_isar);
    _currencyService = CurrencyService(_isar);
    _interactiveEnabled = true;
    await _currencyService.initCurrencies();
    await _load();
  }

  Future<void> _load() async {
    final baseCurrency = await _currencyService.getBaseCurrency();
    final portfolio = await _service.getPortfolioSummary(
      currencyService: _currencyService,
      baseCurrency: baseCurrency,
    );
    final securities = await _service.getSecurities();
    final currencies = await _currencyService.getAllCurrencies();
    final accounts =
        (await AccountService(_isar).getActiveAccounts())
            .where((account) => account.type == AccountService.typeAsset)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    if (!mounted) return;
    setState(() {
      _portfolio = portfolio;
      _securities = securities;
      _currencies = currencies;
      _accounts = accounts;
      _accountById = {for (final account in accounts) account.id: account};
      _baseCurrency = baseCurrency;
      _isLoading = false;
    });
  }

  Future<void> _addSecurity() async {
    final tickerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedType = SecurityType.stock;
    String selectedCurrency = _baseCurrency;

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLS) => AlertDialog(
            title: const Text('添加证券'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: SecurityType.stock,
                        label: Text(SecurityType.label(SecurityType.stock)),
                      ),
                      ButtonSegment(
                        value: SecurityType.fund,
                        label: Text(SecurityType.label(SecurityType.fund)),
                      ),
                      ButtonSegment(
                        value: SecurityType.crypto,
                        label: Text(SecurityType.label(SecurityType.crypto)),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setLS(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tickerCtrl,
                    decoration: const InputDecoration(
                      labelText: '代码 *',
                      hintText: 'AAPL / 600519 / BTC-USD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '名称 *',
                      hintText: '苹果 / 贵州茅台 / 比特币',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: '价格币种',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies
                        .map(
                          (currency) => DropdownMenuItem<String>(
                            value: currency.code,
                            child: Text(_currencyCodeLabel(currency)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLS(() => selectedCurrency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '当前价格',
                      border: const OutlineInputBorder(),
                      prefixText:
                          '${CurrencyDefaults.getSymbol(selectedCurrency)} ',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('添加'),
              ),
            ],
          ),
        ),
      );

      if (ok != true || !mounted) return;

      await _service.addSecurity(
        ticker: tickerCtrl.text,
        name: nameCtrl.text,
        type: selectedType,
        currency: selectedCurrency,
        latestPrice: double.tryParse(priceCtrl.text),
      );
      if (mounted) {
        _showMessage('已添加 ${nameCtrl.text.trim()}');
      }
      await _load();
    } catch (error) {
      if (mounted) {
        _showMessage(_errorMessageFor(error));
      }
    } finally {
      tickerCtrl.dispose();
      nameCtrl.dispose();
      priceCtrl.dispose();
    }
  }

  Future<void> _recordTx(JiveSecurity security, {int? initialAccountId}) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: security.latestPrice?.toStringAsFixed(2) ?? '',
    );
    final feeCtrl = TextEditingController(text: '0');
    String action = 'buy';
    int? selectedAccountId = _defaultAccountForSecurity(
      security.id,
      initialAccountId,
    );

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLS) {
            final availableQuantity = _holdingQuantityFor(
              security.id,
              selectedAccountId,
            );

            return AlertDialog(
              title: Text('${security.name} (${security.ticker})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'buy', label: Text('买入')),
                        ButtonSegment(value: 'sell', label: Text('卖出')),
                      ],
                      selected: {action},
                      onSelectionChanged: (selection) {
                        setLS(() => action = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: '关联账户',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('未关联账户'),
                        ),
                        ..._accounts.map(
                          (account) => DropdownMenuItem<int?>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setLS(() => selectedAccountId = value);
                      },
                    ),
                    if (action == 'sell') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '当前可卖 ${availableQuantity.toStringAsFixed(4)} 份',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '数量 *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '单价 *',
                        border: const OutlineInputBorder(),
                        prefixText:
                            '${CurrencyDefaults.getSymbol(security.currency)} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: feeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '手续费',
                        border: const OutlineInputBorder(),
                        prefixText:
                            '${CurrencyDefaults.getSymbol(security.currency)} ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(action == 'buy' ? '确认买入' : '确认卖出'),
                ),
              ],
            );
          },
        ),
      );

      if (ok != true || !mounted) return;

      await _service.recordTransaction(
        securityId: security.id,
        action: action,
        quantity: double.tryParse(qtyCtrl.text) ?? 0,
        price: double.tryParse(priceCtrl.text) ?? 0,
        fee: double.tryParse(feeCtrl.text) ?? 0,
        accountId: selectedAccountId,
      );
      if (mounted) {
        final accountSuffix = selectedAccountId == null
            ? ''
            : ' · ${_accountLabel(selectedAccountId)}';
        _showMessage(
          '${action == "buy" ? "买入" : "卖出"} ${security.name} ${qtyCtrl.text.trim()} 份$accountSuffix',
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        _showMessage(_errorMessageFor(error));
      }
    } finally {
      qtyCtrl.dispose();
      priceCtrl.dispose();
      feeCtrl.dispose();
    }
  }

  Future<void> _updatePrice(JiveSecurity security) async {
    final ctrl = TextEditingController(
      text: security.latestPrice?.toStringAsFixed(2) ?? '',
    );
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('更新 ${security.name} 价格'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: '最新价格',
              border: const OutlineInputBorder(),
              prefixText: '${CurrencyDefaults.getSymbol(security.currency)} ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('更新'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await _service.updatePrice(security.id, double.tryParse(ctrl.text) ?? 0);
      _showMessage('已更新 ${security.name} 价格');
      await _load();
    } catch (error) {
      if (mounted) {
        _showMessage(_errorMessageFor(error));
      }
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final holdings = _portfolio?.holdings ?? const <HoldingValuation>[];
    final holdingSecurityIds = holdings
        .map((valuation) => valuation.security.id)
        .toSet();
    final unheldSecurities = _securities
        .where((security) => !holdingSecurityIds.contains(security.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '投资组合',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _interactiveEnabled ? _addSecurity : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _interactiveEnabled ? _load : () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_portfolio != null) _buildSummaryCard(),
                  const SizedBox(height: 16),
                  if (_portfolio != null && holdings.isNotEmpty)
                    PortfolioChartWidget(portfolio: _portfolio!),
                  if (_portfolio != null && holdings.isNotEmpty)
                    const SizedBox(height: 16),
                  if (holdings.isNotEmpty) ...[
                    Text(
                      '持仓明细',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...holdings.map(_buildHoldingTile),
                  ],
                  if (unheldSecurities.isNotEmpty) ...[
                    if (holdings.isNotEmpty) const SizedBox(height: 16),
                    Text(
                      holdings.isNotEmpty ? '未持有证券' : '已添加的证券',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...unheldSecurities.map(_buildSecurityTile),
                  ],
                  if (_securities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无投资记录',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击右上角 + 添加证券',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final portfolio = _portfolio!;
    final isProfit = portfolio.totalProfitLoss >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
              : [const Color(0xFFC62828), const Color(0xFFEF5350)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '总市值 (${portfolio.baseCurrency})',
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(portfolio.totalMarketValue, portfolio.baseCurrency),
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryPill(
                '成本',
                _formatAmount(portfolio.totalCost, portfolio.baseCurrency),
              ),
              _summaryPill(
                '盈亏',
                '${isProfit ? "+" : ""}${_formatAmount(portfolio.totalProfitLoss, portfolio.baseCurrency)}',
              ),
              _summaryPill(
                '收益率',
                '${isProfit ? "+" : ""}${portfolio.totalProfitLossPercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${portfolio.holdingCount} 只持仓',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingTile(HoldingValuation valuation) {
    final isProfit = valuation.profitLossInBase >= 0;
    final plColor = isProfit ? const Color(0xFF2E7D32) : Colors.red;
    final typeLabel = SecurityType.label(valuation.security.type);
    final accountLabel = _accountLabel(valuation.holding.accountId);
    final profitText = valuation.security.currency == valuation.baseCurrency
        ? '${isProfit ? "+" : ""}${_formatAmount(valuation.profitLoss, valuation.security.currency)} · ${isProfit ? "+" : ""}${valuation.profitLossPercent.toStringAsFixed(1)}%'
        : '≈ ${isProfit ? "+" : ""}${_formatAmount(valuation.profitLossInBase, valuation.baseCurrency)} · ${isProfit ? "+" : ""}${valuation.profitLossPercent.toStringAsFixed(1)}%';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: plColor.withValues(alpha: 0.1),
          child: Text(
            valuation.security.ticker.substring(
              0,
              valuation.security.ticker.length.clamp(0, 2),
            ),
            style: TextStyle(
              color: plColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          valuation.security.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$typeLabel · $accountLabel · ${valuation.holding.quantity.toStringAsFixed(4)}份',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                profitText,
                style: TextStyle(
                  fontSize: 12,
                  color: plColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(valuation.marketValue, valuation.security.currency),
              style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
            ),
            if (valuation.security.currency != valuation.baseCurrency)
              Text(
                '≈ ${_formatAmount(valuation.marketValueInBase, valuation.baseCurrency)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        onTap: _interactiveEnabled
            ? () => _showSecurityActions(
                valuation.security,
                preferredAccountId: valuation.holding.accountId,
              )
            : null,
      ),
    );
  }

  Widget _buildSecurityTile(JiveSecurity security) {
    final priceText = security.latestPrice != null
        ? _formatAmount(security.latestPrice!, security.currency)
        : '--';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${security.name} (${security.ticker})'),
        subtitle: Text(
          '${SecurityType.label(security.type)} · ${security.currency}',
        ),
        trailing: Text(
          priceText,
          style: GoogleFonts.rubik(fontWeight: FontWeight.w500),
        ),
        onTap: _interactiveEnabled
            ? () => _showSecurityActions(security)
            : null,
      ),
    );
  }

  void _showSecurityActions(JiveSecurity security, {int? preferredAccountId}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('买入/卖出'),
              onTap: () {
                Navigator.pop(ctx);
                _recordTx(security, initialAccountId: preferredAccountId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.price_change),
              title: const Text('更新价格'),
              onTap: () {
                Navigator.pop(ctx);
                _updatePrice(security);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除证券', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await _service.deleteSecurity(security.id);
                if (mounted) {
                  _showMessage('已删除 ${security.name}');
                  await _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int? _defaultAccountForSecurity(int securityId, int? preferredAccountId) {
    if (preferredAccountId != null) {
      return preferredAccountId;
    }
    final candidates = (_portfolio?.holdings ?? const <HoldingValuation>[])
        .where((valuation) => valuation.security.id == securityId)
        .map((valuation) => valuation.holding.accountId)
        .toSet()
        .toList();
    return candidates.length == 1 ? candidates.first : null;
  }

  double _holdingQuantityFor(int securityId, int? accountId) {
    return (_portfolio?.holdings ?? const <HoldingValuation>[])
        .where(
          (valuation) =>
              valuation.security.id == securityId &&
              valuation.holding.accountId == accountId,
        )
        .fold<double>(
          0,
          (total, valuation) => total + valuation.holding.quantity,
        );
  }

  String _accountLabel(int? accountId) {
    if (accountId == null) {
      return '未关联账户';
    }
    return _accountById[accountId]?.name ?? '账户 #$accountId';
  }

  String _currencyCodeLabel(JiveCurrency currency) {
    return '${currency.code} · ${currency.symbol} · ${currency.nameZh}';
  }

  String _formatAmount(double amount, String currencyCode) {
    final symbol = CurrencyDefaults.getSymbol(currencyCode);
    final decimals = CurrencyDefaults.getDecimalPlaces(currencyCode);
    final formatted = amount.toStringAsFixed(decimals);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final value = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    return '$symbol$value';
  }

  String _errorMessageFor(Object error) {
    if (error is InvestmentValidationException) {
      return error.message;
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? '输入有误，请检查后重试';
    }
    if (error is StateError && error.message == 'security_missing') {
      return '证券不存在，可能已被删除';
    }
    return '操作失败，请稍后重试';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _usesDebugData {
    return widget.debugPortfolio != null ||
        widget.debugSecurities != null ||
        widget.debugCurrencies != null ||
        widget.debugAccounts != null;
  }
}
