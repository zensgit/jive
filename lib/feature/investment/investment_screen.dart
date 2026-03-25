import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../core/database/investment_model.dart';
import '../../core/service/database_service.dart';
import '../../core/service/investment_service.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  late Isar _isar;
  late InvestmentService _service;
  bool _isLoading = true;
  PortfolioSummary? _portfolio;
  List<JiveSecurity> _securities = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = await DatabaseService.getInstance();
    _service = InvestmentService(_isar);
    await _load();
  }

  Future<void> _load() async {
    final portfolio = await _service.getPortfolioSummary();
    final securities = await _service.getSecurities();
    if (!mounted) return;
    setState(() {
      _portfolio = portfolio;
      _securities = securities;
      _isLoading = false;
    });
  }

  final _fmt = NumberFormat('#,##0.00');

  // ── Add Security ──

  Future<void> _addSecurity() async {
    final tickerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedType = SecurityType.stock;

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
                    ButtonSegment(value: SecurityType.stock, label: Text(SecurityType.label(SecurityType.stock))),
                    ButtonSegment(value: SecurityType.fund, label: Text(SecurityType.label(SecurityType.fund))),
                    ButtonSegment(value: SecurityType.crypto, label: Text(SecurityType.label(SecurityType.crypto))),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setLS(() => selectedType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tickerCtrl,
                  decoration: const InputDecoration(
                    labelText: '代码 *',
                    hintText: 'AAPL / 600519',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '名称 *',
                    hintText: '苹果 / 贵州茅台',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '当前价格',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    if (tickerCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;

    await _service.addSecurity(
      ticker: tickerCtrl.text,
      name: nameCtrl.text,
      type: selectedType,
      latestPrice: double.tryParse(priceCtrl.text),
    );
    tickerCtrl.dispose();
    nameCtrl.dispose();
    priceCtrl.dispose();
    await _load();
  }

  // ── Record Transaction (Buy/Sell) ──

  Future<void> _recordTx(JiveSecurity security) async {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
        text: security.latestPrice?.toStringAsFixed(2) ?? '');
    final feeCtrl = TextEditingController(text: '0');
    String action = 'buy';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLS) => AlertDialog(
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
                  onSelectionChanged: (s) => setLS(() => action = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '数量 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '单价 *',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '手续费',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action == 'buy' ? '确认买入' : '确认卖出'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    final fee = double.tryParse(feeCtrl.text) ?? 0;
    qtyCtrl.dispose();
    priceCtrl.dispose();
    feeCtrl.dispose();
    if (qty <= 0 || price <= 0) return;

    await _service.recordTransaction(
      securityId: security.id,
      action: action,
      quantity: qty,
      price: price,
      fee: fee,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action == "buy" ? "买入" : "卖出"} ${security.name} $qty 份')),
      );
    }
    await _load();
  }

  // ── Update Price ──

  Future<void> _updatePrice(JiveSecurity security) async {
    final ctrl = TextEditingController(
        text: security.latestPrice?.toStringAsFixed(2) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更新 ${security.name} 价格'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '最新价格',
            border: OutlineInputBorder(),
            prefixText: '¥ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('更新')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final price = double.tryParse(ctrl.text) ?? 0;
    ctrl.dispose();
    if (price <= 0) return;
    await _service.updatePrice(security.id, price);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('投资组合', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addSecurity),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_portfolio != null) _buildSummaryCard(),
                  const SizedBox(height: 16),
                  if (_portfolio != null && _portfolio!.holdings.isNotEmpty) ...[
                    Text('持仓明细',
                        style: GoogleFonts.lato(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._portfolio!.holdings.map(_buildHoldingTile),
                  ],
                  if (_securities.isNotEmpty &&
                      (_portfolio == null || _portfolio!.holdings.isEmpty)) ...[
                    Text('已添加的证券',
                        style: GoogleFonts.lato(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._securities.map(_buildSecurityTile),
                  ],
                  if (_securities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(Icons.trending_up,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('暂无投资记录',
                                style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            Text('点击右上角 + 添加证券',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12)),
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
    final p = _portfolio!;
    final isProfit = p.totalProfitLoss >= 0;
    final plColor = isProfit ? const Color(0xFF2E7D32) : Colors.red;

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
          Text('总市值',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('¥${_fmt.format(p.totalMarketValue)}',
              style: GoogleFonts.rubik(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryPill('成本', '¥${_fmt.format(p.totalCost)}'),
              const SizedBox(width: 8),
              _summaryPill(
                '盈亏',
                '${isProfit ? "+" : ""}¥${_fmt.format(p.totalProfitLoss)}',
              ),
              const SizedBox(width: 8),
              _summaryPill(
                '收益率',
                '${isProfit ? "+" : ""}${p.totalProfitLossPercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${p.holdingCount} 只持仓',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
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
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          Text(value,
              style: GoogleFonts.rubik(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHoldingTile(HoldingValuation v) {
    final isProfit = v.profitLoss >= 0;
    final plColor = isProfit ? const Color(0xFF2E7D32) : Colors.red;
    final typeLabel = SecurityType.label(v.security.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: plColor.withValues(alpha: 0.1),
          child: Text(v.security.ticker.substring(0, v.security.ticker.length.clamp(0, 2)),
              style: TextStyle(
                  color: plColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(v.security.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('¥${_fmt.format(v.marketValue)}',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
          ],
        ),
        subtitle: Row(
          children: [
            Text('$typeLabel · ${v.holding.quantity.toStringAsFixed(2)}份',
                style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Text(
              '${isProfit ? "+" : ""}${v.profitLossPercent.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: plColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: () => _showSecurityActions(v.security),
      ),
    );
  }

  Widget _buildSecurityTile(JiveSecurity security) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${security.name} (${security.ticker})'),
        subtitle: Text(SecurityType.label(security.type)),
        trailing: security.latestPrice != null
            ? Text('¥${_fmt.format(security.latestPrice!)}',
                style: GoogleFonts.rubik(fontWeight: FontWeight.w500))
            : null,
        onTap: () => _showSecurityActions(security),
      ),
    );
  }

  void _showSecurityActions(JiveSecurity security) {
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
                _recordTx(security);
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
                if (mounted) await _load();
              },
            ),
          ],
        ),
      ),
    );
  }
}
