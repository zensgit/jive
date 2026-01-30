import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';

/// 货币与汇率管理页面
class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  late Isar _isar;
  late CurrencyService _currencyService;
  bool _isLoading = true;
  JiveCurrencyPreference? _preference;
  List<JiveExchangeRate> _rates = [];
  bool _isUpdatingRates = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    await _loadData();
  }

  Future<void> _loadData() async {
    final pref = await _currencyService.getPreference();
    final rates = await _currencyService.getRatesFrom(pref?.baseCurrency ?? 'CNY');

    if (!mounted) return;
    setState(() {
      _preference = pref;
      _rates = rates;
      _isLoading = false;
    });
  }

  Future<void> _updateRatesOnline() async {
    if (_preference == null) return;
    setState(() => _isUpdatingRates = true);

    try {
      await _currencyService.fetchAndUpdateRates(
        _preference!.baseCurrency,
        _preference!.enabledCurrencies,
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('汇率更新成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRates = false);
      }
    }
  }

  Future<void> _changeBaseCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CurrencySelectSheet(
        title: '选择主币种',
        selectedCode: _preference?.baseCurrency,
      ),
    );

    if (selected != null && selected != _preference?.baseCurrency) {
      await _currencyService.setBaseCurrency(selected);
      await _loadData();
    }
  }

  Future<void> _editRate(JiveExchangeRate rate) async {
    final controller = TextEditingController(
      text: _currencyService.formatRate(rate.rate),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑汇率 ${rate.fromCurrency} → ${rate.toCurrency}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '汇率',
            hintText: '1 ${rate.fromCurrency} = ? ${rate.toCurrency}',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _currencyService.setManualRate(
        rate.fromCurrency,
        rate.toCurrency,
        result,
      );
      await _loadData();
    }
  }

  Future<void> _addRate() async {
    String? fromCurrency = _preference?.baseCurrency ?? 'CNY';
    String? toCurrency;
    final rateController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '添加汇率',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 源货币
                  InkWell(
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (c) => _CurrencySelectSheet(
                          title: '选择源货币',
                          selectedCode: fromCurrency,
                        ),
                      );
                      if (selected != null) {
                        setSheetState(() => fromCurrency = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '源货币',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.chevron_right),
                      ),
                      child: _buildCurrencyDisplay(fromCurrency!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 目标货币
                  InkWell(
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (c) => _CurrencySelectSheet(
                          title: '选择目标货币',
                          selectedCode: toCurrency,
                        ),
                      );
                      if (selected != null) {
                        setSheetState(() => toCurrency = selected);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '目标货币',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.chevron_right),
                      ),
                      child: toCurrency != null
                          ? _buildCurrencyDisplay(toCurrency!)
                          : Text(
                              '请选择',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 汇率
                  TextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '汇率',
                      hintText: fromCurrency != null && toCurrency != null
                          ? '1 $fromCurrency = ? $toCurrency'
                          : '请输入汇率',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 在线获取按钮
                  if (fromCurrency != null && toCurrency != null)
                    TextButton.icon(
                      onPressed: () async {
                        final response = await _currencyService.fetchLiveRate(
                          fromCurrency!,
                          toCurrency!,
                        );
                        if (response != null) {
                          rateController.text = _currencyService.formatRate(response.rate);
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('获取汇率失败')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_download, size: 18),
                      label: const Text('在线获取'),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (fromCurrency == null ||
                                toCurrency == null ||
                                fromCurrency == toCurrency) {
                              return;
                            }
                            final rate = double.tryParse(rateController.text.trim());
                            if (rate == null || rate <= 0) return;
                            Navigator.pop(ctx, {
                              'from': fromCurrency,
                              'to': toCurrency,
                              'rate': rate,
                            });
                          },
                          child: const Text('保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      await _currencyService.setManualRate(
        result['from'] as String,
        result['to'] as String,
        result['rate'] as double,
      );
      await _loadData();
    }
  }

  Widget _buildCurrencyDisplay(String code) {
    final currency = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'nameZh': code, 'flag': null, 'symbol': code},
    );
    final flag = currency['flag'] as String?;
    final symbol = currency['symbol'] as String;
    final nameZh = currency['nameZh'] as String;

    return Row(
      children: [
        Text(flag ?? symbol, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          '$code - $nameZh',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('货币与汇率')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final baseCurrency = _preference?.baseCurrency ?? 'CNY';
    final baseCurrencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
      (c) => c['code'] == baseCurrency,
      orElse: () => {'code': baseCurrency, 'nameZh': baseCurrency, 'flag': null, 'symbol': baseCurrency},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('货币与汇率'),
        actions: [
          IconButton(
            onPressed: _isUpdatingRates ? null : _updateRatesOnline,
            icon: _isUpdatingRates
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync),
            tooltip: '更新汇率',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主币种设置
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  baseCurrencyData['flag'] as String? ?? baseCurrencyData['symbol'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: const Text('主币种'),
              subtitle: Text('$baseCurrency - ${baseCurrencyData['nameZh']}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeBaseCurrency,
            ),
          ),
          const SizedBox(height: 8),
          // 自动更新汇率开关
          Card(
            child: SwitchListTile(
              title: const Text('自动更新汇率'),
              subtitle: Text(
                _preference?.autoUpdateRates == true
                    ? '启动时自动获取最新汇率'
                    : '手动更新汇率',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: _preference?.autoUpdateRates ?? false,
              onChanged: (value) async {
                if (_preference == null) return;
                _preference!.autoUpdateRates = value;
                await _currencyService.updatePreference(_preference!);
                setState(() {});
              },
              secondary: Icon(
                Icons.sync,
                color: _preference?.autoUpdateRates == true
                    ? JiveTheme.primaryGreen
                    : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 最后更新时间
          if (_preference?.lastRateUpdate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '最后更新：${_formatDateTime(_preference!.lastRateUpdate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          const SizedBox(height: 16),
          // 汇率列表标题
          Row(
            children: [
              Text(
                '汇率列表',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addRate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 汇率列表
          if (_rates.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无汇率数据',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _updateRatesOnline,
                      child: const Text('在线获取汇率'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rate = _rates[index];
                  final toCurrencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
                    (c) => c['code'] == rate.toCurrency,
                    orElse: () => {'code': rate.toCurrency, 'nameZh': rate.toCurrency, 'flag': null, 'symbol': rate.toCurrency},
                  );
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        toCurrencyData['flag'] as String? ?? toCurrencyData['symbol'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          rate.toCurrency,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          toCurrencyData['nameZh'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '1 $baseCurrency = ${_currencyService.formatRate(rate.rate)} ${rate.toCurrency}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSourceBadge(rate.source),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 18),
                      ],
                    ),
                    onTap: () => _editRate(rate),
                  );
                },
              ),
            ),
        ],
      ),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 货币选择底部弹窗
class _CurrencySelectSheet extends StatefulWidget {
  final String title;
  final String? selectedCode;

  const _CurrencySelectSheet({
    required this.title,
    this.selectedCode,
  });

  @override
  State<_CurrencySelectSheet> createState() => _CurrencySelectSheetState();
}

class _CurrencySelectSheetState extends State<_CurrencySelectSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredCurrencies {
    final all = CurrencyDefaults.fiatCurrencies;
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((c) {
      final code = (c['code'] as String).toLowerCase();
      final name = (c['name'] as String).toLowerCase();
      final nameZh = (c['nameZh'] as String).toLowerCase();
      return code.contains(query) ||
          name.contains(query) ||
          nameZh.contains(query);
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
                    title: Text(
                      '$code - $nameZh',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? JiveTheme.primaryGreen : null,
                      ),
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
