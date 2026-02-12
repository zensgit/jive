import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/currency_model.dart';
import '../design_system/theme.dart';
import '../service/currency_service.dart';
import '../service/database_service.dart';

/// 实时货币转换组件
/// 用户输入金额时实时显示转换后的金额
class CurrencyConverterWidget extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;
  final double? initialAmount;
  final ValueChanged<double>? onAmountChanged;
  final ValueChanged<double>? onConvertedChanged;
  final bool showSwapButton;
  final bool fetchLiveRate;

  const CurrencyConverterWidget({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    this.initialAmount,
    this.onAmountChanged,
    this.onConvertedChanged,
    this.showSwapButton = true,
    this.fetchLiveRate = true,
  });

  @override
  State<CurrencyConverterWidget> createState() => _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  final _amountController = TextEditingController();
  late String _fromCurrency;
  late String _toCurrency;
  double? _rate;
  double? _convertedAmount;
  bool _isLoadingRate = false;
  Timer? _debounceTimer;
  CurrencyService? _currencyService;

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.fromCurrency;
    _toCurrency = widget.toCurrency;
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toString();
    }
    _initService();
  }

  @override
  void didUpdateWidget(covariant CurrencyConverterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCurrency != widget.fromCurrency ||
        oldWidget.toCurrency != widget.toCurrency) {
      setState(() {
        _fromCurrency = widget.fromCurrency;
        _toCurrency = widget.toCurrency;
      });
      _loadRate();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _initService() async {
    final isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(isar);
    await _loadRate();
  }

  Future<void> _loadRate() async {
    if (_currencyService == null) return;
    if (_fromCurrency == _toCurrency) {
      setState(() {
        _rate = 1.0;
        _updateConversion();
      });
      return;
    }

    setState(() => _isLoadingRate = true);

    double? rate;
    if (widget.fetchLiveRate) {
      // 尝试在线获取
      final response = await _currencyService!.fetchLiveRate(
        _fromCurrency,
        _toCurrency,
      );
      rate = response?.rate;
    }

    // 如果在线获取失败，使用本地数据
    rate ??= await _currencyService!.getRate(_fromCurrency, _toCurrency);

    if (!mounted) return;
    setState(() {
      _rate = rate;
      _isLoadingRate = false;
      _updateConversion();
    });
  }

  void _updateConversion() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || _rate == null) {
      setState(() => _convertedAmount = null);
      return;
    }
    final converted = amount * _rate!;
    setState(() => _convertedAmount = converted);
    widget.onConvertedChanged?.call(converted);
  }

  void _onAmountChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final amount = double.tryParse(value.trim());
      if (amount != null) {
        widget.onAmountChanged?.call(amount);
      }
      _updateConversion();
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _loadRate();
  }

  String _formatAmount(double amount, String currency) {
    final decimals = CurrencyDefaults.getDecimalPlaces(currency);
    return amount.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final fromData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == _fromCurrency,
      orElse: () => {'code': _fromCurrency, 'symbol': _fromCurrency, 'flag': null, 'nameZh': _fromCurrency},
    );
    final toData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == _toCurrency,
      orElse: () => {'code': _toCurrency, 'symbol': _toCurrency, 'flag': null, 'nameZh': _toCurrency},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 源金额输入
        _buildCurrencyInput(
          label: '金额',
          currency: _fromCurrency,
          currencyData: fromData,
          controller: _amountController,
          onChanged: _onAmountChanged,
        ),
        const SizedBox(height: 12),
        // 汇率和交换按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoadingRate)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_rate != null)
              Text(
                '1 $_fromCurrency = ${_formatAmount(_rate!, _toCurrency)} $_toCurrency',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (widget.showSwapButton) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _swapCurrencies,
                icon: const Icon(Icons.swap_vert),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                  foregroundColor: JiveTheme.primaryGreen,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // 目标金额显示
        _buildConvertedDisplay(
          currency: _toCurrency,
          currencyData: toData,
          amount: _convertedAmount,
        ),
      ],
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required String currency,
    required Map<String, dynamic> currencyData,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final symbol = currencyData['symbol'] as String;
    final flag = currencyData['flag'] as String?;
    final decimals = CurrencyDefaults.getDecimalPlaces(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    flag ?? symbol,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currency,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
                textAlign: TextAlign.right,
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0${decimals > 0 ? '.${'0' * decimals}' : ''}',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConvertedDisplay({
    required String currency,
    required Map<String, dynamic> currencyData,
    required double? amount,
  }) {
    final symbol = currencyData['symbol'] as String;
    final flag = currencyData['flag'] as String?;
    final decimals = CurrencyDefaults.getDecimalPlaces(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '转换结果',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JiveTheme.primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JiveTheme.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Text(
                flag ?? symbol,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      amount != null
                          ? '$symbol ${amount.toStringAsFixed(decimals)}'
                          : '--',
                      style: GoogleFonts.rubik(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: JiveTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 简洁的实时汇率显示组件
class CurrencyRateDisplay extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final bool compact;

  const CurrencyRateDisplay({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    this.compact = false,
  });

  @override
  State<CurrencyRateDisplay> createState() => _CurrencyRateDisplayState();
}

class _CurrencyRateDisplayState extends State<CurrencyRateDisplay> {
  double? _convertedAmount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversion();
  }

  @override
  void didUpdateWidget(covariant CurrencyRateDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCurrency != widget.fromCurrency ||
        oldWidget.toCurrency != widget.toCurrency ||
        oldWidget.amount != widget.amount) {
      _loadConversion();
    }
  }

  Future<void> _loadConversion() async {
    if (widget.fromCurrency == widget.toCurrency) {
      setState(() {
        _convertedAmount = widget.amount;
        _isLoading = false;
      });
      return;
    }

    final isar = await DatabaseService.getInstance();
    final service = CurrencyService(isar);
    final converted = await service.convert(
      widget.amount,
      widget.fromCurrency,
      widget.toCurrency,
    );

    if (!mounted) return;
    setState(() {
      _convertedAmount = converted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1),
      );
    }

    if (_convertedAmount == null) {
      return const SizedBox.shrink();
    }

    final toSymbol = CurrencyDefaults.getSymbol(widget.toCurrency);
    final decimals = CurrencyDefaults.getDecimalPlaces(widget.toCurrency);

    if (widget.compact) {
      return Text(
        '$toSymbol${_convertedAmount!.toStringAsFixed(decimals)}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.swap_horiz,
          size: 14,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          '$toSymbol${_convertedAmount!.toStringAsFixed(decimals)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
