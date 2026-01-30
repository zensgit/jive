import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/rate_widget_service.dart';

/// 汇率小组件配置界面
class RateWidgetConfigScreen extends StatefulWidget {
  const RateWidgetConfigScreen({super.key});

  @override
  State<RateWidgetConfigScreen> createState() => _RateWidgetConfigScreenState();
}

class _RateWidgetConfigScreenState extends State<RateWidgetConfigScreen> {
  bool _isLoading = true;
  RateWidgetConfig? _config;
  late Isar _isar;
  late CurrencyService _currencyService;
  late RateWidgetService _widgetService;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    _widgetService = RateWidgetService(_currencyService);

    final config = await RateWidgetService.getConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    await RateWidgetService.saveConfig(_config!);
    await _widgetService.updateWidgetData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('小组件配置已保存'),
          backgroundColor: JiveTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _addCurrencyPair() async {
    String? fromCurrency;
    String? toCurrency;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '添加货币对',
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
                  _buildCurrencySelector(
                    label: '源货币',
                    value: fromCurrency,
                    onChanged: (v) => setSheetState(() => fromCurrency = v),
                  ),
                  const SizedBox(height: 12),
                  // 目标货币
                  _buildCurrencySelector(
                    label: '目标货币',
                    value: toCurrency,
                    onChanged: (v) => setSheetState(() => toCurrency = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: fromCurrency != null && toCurrency != null
                          ? () => Navigator.pop(ctx, '$fromCurrency/$toCurrency')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JiveTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null && _config != null) {
      if (!_config!.currencyPairs.contains(result)) {
        setState(() {
          _config = _config!.copyWith(
            currencyPairs: [..._config!.currencyPairs, result],
          );
        });
        await _saveConfig();
      }
    }
  }

  Widget _buildCurrencySelector({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final currencies = CurrencyDefaults.getAllCurrencies();

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: currencies.map((c) {
        final code = c['code'] as String;
        final nameZh = c['nameZh'] as String;
        final flag = c['flag'] as String?;
        return DropdownMenuItem(
          value: code,
          child: Row(
            children: [
              Text(flag ?? code, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('$code - $nameZh'),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('汇率小组件')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('汇率小组件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
            onPressed: () async {
              await _widgetService.updateWidgetData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('小组件数据已更新')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 说明卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '配置桌面小组件显示的汇率信息，添加后长按桌面添加小组件',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 货币对列表
          Row(
            children: [
              Text(
                '显示的货币对',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addCurrencyPair,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_config!.currencyPairs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.currency_exchange, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('暂无货币对', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _addCurrencyPair,
                      child: const Text('添加货币对'),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _config!.currencyPairs.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final pairs = List<String>.from(_config!.currencyPairs);
                final item = pairs.removeAt(oldIndex);
                pairs.insert(newIndex, item);
                setState(() {
                  _config = _config!.copyWith(currencyPairs: pairs);
                });
                _saveConfig();
              },
              itemBuilder: (context, index) {
                final pair = _config!.currencyPairs[index];
                final parts = pair.split('/');
                final from = parts[0];
                final to = parts[1];

                final fromData = CurrencyDefaults.getAllCurrencies()
                    .firstWhere((c) => c['code'] == from, orElse: () => {'flag': from});
                final toData = CurrencyDefaults.getAllCurrencies()
                    .firstWhere((c) => c['code'] == to, orElse: () => {'flag': to});

                return Card(
                  key: ValueKey(pair),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fromData['flag'] as String? ?? from, style: const TextStyle(fontSize: 20)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, size: 16),
                        ),
                        Text(toData['flag'] as String? ?? to, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    title: Text('$from / $to'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _config = _config!.copyWith(
                                currencyPairs: _config!.currencyPairs
                                    .where((p) => p != pair)
                                    .toList(),
                              );
                            });
                            _saveConfig();
                          },
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // 显示选项
          Text(
            '显示选项',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('显示涨跌趋势'),
                  subtitle: const Text('在汇率旁边显示涨跌箭头和百分比'),
                  value: _config!.showTrend,
                  onChanged: (v) {
                    setState(() {
                      _config = _config!.copyWith(showTrend: v);
                    });
                    _saveConfig();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('显示国旗'),
                  subtitle: const Text('用国旗图标代替货币代码'),
                  value: _config!.showFlag,
                  onChanged: (v) {
                    setState(() {
                      _config = _config!.copyWith(showFlag: v);
                    });
                    _saveConfig();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 刷新间隔
          Card(
            child: ListTile(
              title: const Text('刷新间隔'),
              subtitle: Text('每 ${_config!.refreshInterval} 分钟自动更新'),
              trailing: DropdownButton<int>(
                value: _config!.refreshInterval,
                underline: const SizedBox(),
                items: [15, 30, 60, 120, 240].map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text(v < 60 ? '$v 分钟' : '${v ~/ 60} 小时'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _config = _config!.copyWith(refreshInterval: v);
                    });
                    _saveConfig();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 主题
          Card(
            child: ListTile(
              title: const Text('小组件主题'),
              trailing: DropdownButton<String>(
                value: _config!.theme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('跟随系统')),
                  DropdownMenuItem(value: 'light', child: Text('浅色')),
                  DropdownMenuItem(value: 'dark', child: Text('深色')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _config = _config!.copyWith(theme: v);
                    });
                    _saveConfig();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 预览
          Text(
            '预览',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildWidgetPreview(),
        ],
      ),
    );
  }

  Widget _buildWidgetPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _config!.theme == 'dark' ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: _config!.theme == 'dark' ? Colors.white70 : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '汇率',
                style: TextStyle(
                  fontSize: 12,
                  color: _config!.theme == 'dark' ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._config!.currencyPairs.take(3).map((pair) {
            final parts = pair.split('/');
            final from = parts[0];
            final to = parts[1];
            final fromData = CurrencyDefaults.getAllCurrencies()
                .firstWhere((c) => c['code'] == from, orElse: () => {'flag': from, 'symbol': from});
            final toData = CurrencyDefaults.getAllCurrencies()
                .firstWhere((c) => c['code'] == to, orElse: () => {'flag': to, 'symbol': to});

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (_config!.showFlag) ...[
                    Text(fromData['flag'] as String? ?? from),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '$from/$to',
                    style: TextStyle(
                      fontSize: 13,
                      color: _config!.theme == 'dark' ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '7.2500',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _config!.theme == 'dark' ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_config!.showTrend) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '↑ 0.12%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
