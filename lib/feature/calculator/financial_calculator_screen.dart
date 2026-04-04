import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/service/financial_calculator_service.dart';

class FinancialCalculatorScreen extends StatefulWidget {
  const FinancialCalculatorScreen({super.key});

  @override
  State<FinancialCalculatorScreen> createState() =>
      _FinancialCalculatorScreenState();
}

class _FinancialCalculatorScreenState extends State<FinancialCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = FinancialCalculatorService();

  // ---- Deposit tab ----
  final _dPrincipalCtrl = TextEditingController();
  final _dRateCtrl = TextEditingController();
  final _dMonthsCtrl = TextEditingController();
  DepositResult? _depositResult;

  // ---- Loan tab ----
  final _lPrincipalCtrl = TextEditingController();
  final _lRateCtrl = TextEditingController();
  final _lMonthsCtrl = TextEditingController();
  String _loanMethod = 'equal_installment'; // or 'equal_principal'
  LoanResult? _loanResult;

  // ---- Early-repayment tab ----
  final _ePrincipalCtrl = TextEditingController();
  final _eRateCtrl = TextEditingController();
  final _eMonthsCtrl = TextEditingController();
  final _eAmountCtrl = TextEditingController();
  double? _savedInterest;

  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dPrincipalCtrl.dispose();
    _dRateCtrl.dispose();
    _dMonthsCtrl.dispose();
    _lPrincipalCtrl.dispose();
    _lRateCtrl.dispose();
    _lMonthsCtrl.dispose();
    _ePrincipalCtrl.dispose();
    _eRateCtrl.dispose();
    _eMonthsCtrl.dispose();
    _eAmountCtrl.dispose();
    super.dispose();
  }

  // --------------- helpers ---------------

  InputDecoration _inputDec(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static final _decimalFilter =
      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'));
  static final _intFilter = FilteringTextInputFormatter.digitsOnly;

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    String? prefix,
    bool decimal = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType:
            decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
        inputFormatters: [if (decimal) _decimalFilter else _intFilter],
        decoration: _inputDec(label, prefix: prefix),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000) {
      return '${(v / 10000).toStringAsFixed(2)}万';
    }
    return v.toStringAsFixed(2);
  }

  // --------------- Deposit ---------------

  void _calcDeposit() {
    final p = double.tryParse(_dPrincipalCtrl.text);
    final r = double.tryParse(_dRateCtrl.text);
    final m = int.tryParse(_dMonthsCtrl.text);
    if (p == null || r == null || m == null || p <= 0 || r <= 0 || m <= 0) {
      _showError('请输入有效的正数');
      return;
    }
    setState(() {
      _depositResult = _service.calculateFixedDeposit(
        principal: p,
        annualRate: r,
        months: m,
      );
    });
  }

  // --------------- Loan ---------------

  void _calcLoan() {
    final p = double.tryParse(_lPrincipalCtrl.text);
    final r = double.tryParse(_lRateCtrl.text);
    final m = int.tryParse(_lMonthsCtrl.text);
    if (p == null || r == null || m == null || p <= 0 || r <= 0 || m <= 0) {
      _showError('请输入有效的正数');
      return;
    }
    setState(() {
      if (_loanMethod == 'equal_principal') {
        _loanResult = _service.calculateLoanEqualPrincipal(
          principal: p,
          annualRate: r,
          months: m,
        );
      } else {
        _loanResult = _service.calculateLoanEqualInstallment(
          principal: p,
          annualRate: r,
          months: m,
        );
      }
    });
  }

  // --------------- Early Repayment ---------------

  void _calcEarly() {
    final p = double.tryParse(_ePrincipalCtrl.text);
    final r = double.tryParse(_eRateCtrl.text);
    final m = int.tryParse(_eMonthsCtrl.text);
    final a = double.tryParse(_eAmountCtrl.text);
    if (p == null ||
        r == null ||
        m == null ||
        a == null ||
        p <= 0 ||
        r <= 0 ||
        m <= 0 ||
        a <= 0) {
      _showError('请输入有效的正数');
      return;
    }
    if (a >= p) {
      _showError('提前还款金额需小于剩余本金');
      return;
    }
    setState(() {
      _savedInterest = _service.calculateEarlyRepayment(
        remainingPrincipal: p,
        annualRate: r,
        remainingMonths: m,
        earlyAmount: a,
      );
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // --------------- build ---------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '财务计算器',
          style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _green,
          indicatorColor: _green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '定存计算'),
            Tab(text: '贷款计算'),
            Tab(text: '提前还款'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepositTab(),
          _buildLoanTab(),
          _buildEarlyTab(),
        ],
      ),
    );
  }

  // ---------- Deposit Tab ----------

  Widget _buildDepositTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _numField(_dPrincipalCtrl, '本金', prefix: '¥ '),
        _numField(_dRateCtrl, '年利率 (%)'),
        _numField(_dMonthsCtrl, '存期 (月)', decimal: false),
        const SizedBox(height: 4),
        _calcButton('计算定存收益', _calcDeposit),
        if (_depositResult != null) ...[
          const SizedBox(height: 16),
          _resultCard(
            title: '定存结果',
            rows: [
              _resultRow('到期金额', '¥${_fmt(_depositResult!.maturityAmount)}'),
              _resultRow('利息收益', '¥${_fmt(_depositResult!.totalInterest)}'),
              _resultRow(
                '存期',
                '${_depositResult!.monthlyBreakdown.length}个月',
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------- Loan Tab ----------

  Widget _buildLoanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _numField(_lPrincipalCtrl, '贷款金额', prefix: '¥ '),
        _numField(_lRateCtrl, '年利率 (%)'),
        _numField(_lMonthsCtrl, '贷款期限 (月)', decimal: false),
        const SizedBox(height: 4),
        _methodSelector(),
        const SizedBox(height: 12),
        _calcButton('计算贷款', _calcLoan),
        if (_loanResult != null) ...[
          const SizedBox(height: 16),
          _resultCard(
            title: '贷款结果',
            rows: [
              if (_loanMethod == 'equal_installment')
                _resultRow(
                  '每月还款',
                  '¥${_fmt(_loanResult!.monthlyPayments.first.payment)}',
                ),
              _resultRow('总利息', '¥${_fmt(_loanResult!.totalInterest)}'),
              _resultRow('还款总额', '¥${_fmt(_loanResult!.totalPayment)}'),
            ],
          ),
          const SizedBox(height: 16),
          _amortizationTable(),
        ],
      ],
    );
  }

  Widget _methodSelector() {
    return Row(
      children: [
        Expanded(
          child: _methodChip('等额本息', 'equal_installment'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _methodChip('等额本金', 'equal_principal'),
        ),
      ],
    );
  }

  Widget _methodChip(String label, String value) {
    final selected = _loanMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _loanMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _amortizationTable() {
    final payments = _loanResult!.monthlyPayments;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '还款计划表',
              style: GoogleFonts.notoSansSc(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('月')),
                  DataColumn(label: Text('月供')),
                  DataColumn(label: Text('本金')),
                  DataColumn(label: Text('利息')),
                  DataColumn(label: Text('剩余')),
                ],
                rows: payments
                    .map(
                      (p) => DataRow(cells: [
                        DataCell(Text('${p.month}')),
                        DataCell(Text(p.payment.toStringAsFixed(2))),
                        DataCell(Text(p.principal.toStringAsFixed(2))),
                        DataCell(Text(p.interest.toStringAsFixed(2))),
                        DataCell(Text(_fmt(p.remainingBalance))),
                      ]),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Early-Repayment Tab ----------

  Widget _buildEarlyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _numField(_ePrincipalCtrl, '剩余本金', prefix: '¥ '),
        _numField(_eRateCtrl, '年利率 (%)'),
        _numField(_eMonthsCtrl, '剩余期限 (月)', decimal: false),
        _numField(_eAmountCtrl, '提前还款金额', prefix: '¥ '),
        const SizedBox(height: 4),
        _calcButton('计算节省利息', _calcEarly),
        if (_savedInterest != null) ...[
          const SizedBox(height: 16),
          _resultCard(
            title: '提前还款结果',
            rows: [
              _resultRow('可节省利息', '¥${_fmt(_savedInterest!)}'),
            ],
          ),
        ],
      ],
    );
  }

  // ---------- shared widgets ----------

  Widget _calcButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _resultCard({
    required String title,
    required List<Widget> rows,
  }) {
    return Card(
      color: _lightGreen,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.notoSansSc(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _green,
              ),
            ),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }
}
