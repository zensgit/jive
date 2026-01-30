import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// 货币转换计算器
class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  late Isar _isar;
  late CurrencyService _currencyService;
  bool _isLoading = true;

  String _fromCurrency = 'CNY';
  String _toCurrency = 'USD';
  final _amountController = TextEditingController(text: '100');
  double _convertedAmount = 0;
  double? _rate;
  String? _rateSource;
  DateTime? _rateUpdatedAt;
  RateTrendStats? _trendStats;

  List<String> _enabledCurrencies = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);

    final pref = await _currencyService.getPreference();
    final baseCurrency = pref?.baseCurrency ?? 'CNY';
    final enabled = pref?.enabledCurrencies ?? ['CNY', 'USD', 'EUR', 'JPY', 'HKD'];

    setState(() {
      _fromCurrency = baseCurrency;
      _toCurrency = enabled.firstWhere((c) => c != baseCurrency, orElse: () => 'USD');
      _enabledCurrencies = enabled;
      _isLoading = false;
    });

    _convert();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() {
        _convertedAmount = 0;
        _rate = null;
        _trendStats = null;
      });
      return;
    }

    final rate = await _currencyService.getRate(_fromCurrency, _toCurrency);
    final rateRecord = await _currencyService.getRateRecord(_fromCurrency, _toCurrency);
    final trendStats = await _currencyService.getRateTrendStats(_fromCurrency, _toCurrency, days: 30);

    if (rate != null) {
      setState(() {
        _rate = rate;
        _convertedAmount = amount * rate;
        _rateSource = rateRecord?.source;
        _rateUpdatedAt = rateRecord?.updatedAt;
        _trendStats = trendStats;
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
  }

  Future<void> _selectCurrency(bool isFrom) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CurrencySelectSheet(
        title: isFrom ? '选择源货币' : '选择目标货币',
        selectedCode: isFrom ? _fromCurrency : _toCurrency,
        enabledCurrencies: _enabledCurrencies,
      ),
    );

    if (selected != null) {
      setState(() {
        if (isFrom) {
          _fromCurrency = selected;
        } else {
          _toCurrency = selected;
        }
      });
      _convert();
    }
  }

  Future<void> _refreshRate() async {
    final response = await _currencyService.fetchLiveRate(_fromCurrency, _toCurrency);
    if (response != null) {
      // 保存到数据库
      await _currencyService.setManualRate(_fromCurrency, _toCurrency, response.rate);
      CurrencyService.clearCache();
      _convert();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('汇率已更新: 1 $_fromCurrency = ${_currencyService.formatRate(response.rate)} $_toCurrency'),
            backgroundColor: JiveTheme.primaryGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取汇率失败，请稍后重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('货币换算')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fromData = _getCurrencyData(_fromCurrency);
    final toData = _getCurrencyData(_toCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('货币换算'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRate,
            tooltip: '刷新汇率',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 源货币输入
            _buildCurrencyCard(
              currency: _fromCurrency,
              data: fromData,
              isFrom: true,
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: GoogleFonts.rubik(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade300,
                  ),
                  prefixText: '${fromData['symbol']} ',
                  prefixStyle: GoogleFonts.rubik(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (_) => _convert(),
              ),
            ),

            // 交换按钮
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: IconButton.filled(
                  onPressed: _swapCurrencies,
                  icon: const Icon(Icons.swap_vert),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),

            // 目标货币显示
            _buildCurrencyCard(
              currency: _toCurrency,
              data: toData,
              isFrom: false,
              child: Text(
                '${toData['symbol']} ${_currencyService.formatAmount(_convertedAmount, _toCurrency).replaceAll(toData['symbol'] as String, '').trim()}',
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: JiveTheme.primaryGreen,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 汇率信息
            if (_rate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '1 $_fromCurrency = ${_currencyService.formatRate(_rate!)} $_toCurrency',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '1 $_toCurrency = ${_currencyService.formatRate(1 / _rate!)} $_fromCurrency',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (_rateSource != null || _rateUpdatedAt != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_rateSource != null)
                            _buildSourceBadge(_rateSource!),
                          if (_rateUpdatedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '更新于 ${_formatDateTime(_rateUpdatedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // 趋势统计（如果有数据）
            if (_trendStats != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 18,
                          color: _trendStats!.isUp ? Colors.red : JiveTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '30天趋势',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_trendStats!.isUp ? Colors.red : JiveTheme.primaryGreen).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_trendStats!.trendIcon} ${_trendStats!.changeText}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _trendStats!.isUp ? Colors.red : JiveTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTrendItem('最低', _currencyService.formatRate(_trendStats!.min)),
                        _buildTrendItem('平均', _currencyService.formatRate(_trendStats!.avg)),
                        _buildTrendItem('最高', _currencyService.formatRate(_trendStats!.max)),
                      ],
                    ),
                    if (_trendStats!.dataPoints > 0) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '基于 ${_trendStats!.dataPoints} 个数据点',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 快捷金额按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [100, 500, 1000, 5000, 10000].map((amount) {
                return ActionChip(
                  label: Text('${fromData['symbol']}$amount'),
                  onPressed: () {
                    _amountController.text = amount.toString();
                    _convert();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard({
    required String currency,
    required Map<String, dynamic> data,
    required bool isFrom,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectCurrency(isFrom),
            child: Row(
              children: [
                Text(
                  data['flag'] as String? ?? data['symbol'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  currency,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' - ${data['nameZh']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    String label;
    switch (source) {
      case 'frankfurter':
      case 'exchangerate.host':
        color = JiveTheme.primaryGreen;
        label = '在线';
        break;
      case 'coingecko':
        color = Colors.purple;
        label = '加密';
        break;
      case 'manual':
        color = Colors.orange;
        label = '手动';
        break;
      default:
        color = Colors.grey;
        label = '默认';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCurrencyData(String code) {
    return CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {
        'code': code,
        'nameZh': code,
        'symbol': code,
        'flag': null,
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 货币选择底部弹窗
class _CurrencySelectSheet extends StatefulWidget {
  final String title;
  final String? selectedCode;
  final List<String> enabledCurrencies;

  const _CurrencySelectSheet({
    required this.title,
    this.selectedCode,
    required this.enabledCurrencies,
  });

  @override
  State<_CurrencySelectSheet> createState() => _CurrencySelectSheetState();
}

class _CurrencySelectSheetState extends State<_CurrencySelectSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredCurrencies {
    final all = CurrencyDefaults.getAllCurrencies();
    // 优先显示启用的货币
    final enabled = all.where((c) => widget.enabledCurrencies.contains(c['code'])).toList();
    final others = all.where((c) => !widget.enabledCurrencies.contains(c['code'])).toList();
    final sorted = [...enabled, ...others];

    if (_searchQuery.isEmpty) return sorted;
    final query = _searchQuery.toLowerCase();
    return sorted.where((c) {
      final code = (c['code'] as String).toLowerCase();
      final name = (c['name'] as String).toLowerCase();
      final nameZh = (c['nameZh'] as String).toLowerCase();
      return code.contains(query) || name.contains(query) || nameZh.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.title,
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索货币',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final code = currency['code'] as String;
                  final nameZh = currency['nameZh'] as String;
                  final symbol = currency['symbol'] as String;
                  final flag = currency['flag'] as String?;
                  final isSelected = code == widget.selectedCode;
                  final isEnabled = widget.enabledCurrencies.contains(code);

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? JiveTheme.primaryGreen.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        flag ?? symbol,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          '$code - $nameZh',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? JiveTheme.primaryGreen : null,
                          ),
                        ),
                        if (isEnabled && !isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '常用',
                              style: TextStyle(fontSize: 9, color: Colors.blue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: JiveTheme.primaryGreen)
                        : null,
                    onTap: () => Navigator.pop(context, code),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
