import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/database_service.dart';
import '../../core/service/notification_service.dart';
import '../../core/service/rate_cloud_backup_service.dart';
import '../../core/service/scheduled_rate_update_service.dart';
import 'currency_converter_screen.dart';
import 'exchange_fee_tracking_screen.dart';
import 'exchange_rate_profit_screen.dart';
import 'foreign_currency_spending_screen.dart';
import 'multi_currency_overview_screen.dart';

/// 货币与汇率管理页面
class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  late Isar _isar;
  late CurrencyService _currencyService;
  late RateCloudBackupService _backupService;
  ScheduledRateUpdateService? _scheduledUpdateService;
  bool _isLoading = true;
  JiveCurrencyPreference? _preference;
  List<JiveExchangeRate> _rates = [];
  bool _isUpdatingRates = false;
  RateUpdateConfig? _updateConfig;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);
    _backupService = RateCloudBackupService(_isar);
    _scheduledUpdateService = ScheduledRateUpdateService(_currencyService);
    await _loadData();
  }

  Future<void> _loadData() async {
    final pref = await _currencyService.getPreference();
    final rates = await _currencyService.getRatesFrom(pref?.baseCurrency ?? 'CNY');
    final updateConfig = await RateUpdateConfig.load();

    if (!mounted) return;
    setState(() {
      _preference = pref;
      _rates = rates;
      _updateConfig = updateConfig;
      _isLoading = false;
    });
  }

  Future<void> _updateRatesOnline() async {
    if (_preference == null) return;
    setState(() => _isUpdatingRates = true);

    try {
      // 使用带变动检测的更新方法
      final result = await _currencyService.fetchAndUpdateRatesWithChangeDetection(
        _preference!.baseCurrency,
        _preference!.enabledCurrencies,
        changeThreshold: _preference!.rateChangeAlert ? _preference!.rateChangeThreshold : null,
      );
      await _loadData();
      if (!mounted) return;

      // 如果有显著变动且启用了提醒，显示变动详情
      if (_preference!.rateChangeAlert && result.hasSignificantChanges) {
        // 使用新的通知服务显示横幅通知
        final changes = result.significantChanges;
        if (changes.isNotEmpty) {
          final notifications = changes.map((c) => RateChangeNotification(
            fromCurrency: c.from,
            toCurrency: c.to,
            oldRate: c.oldRate,
            newRate: c.newRate,
            threshold: _preference!.rateChangeThreshold,
          )).toList();

          RateChangeNotificationManager.checkAndShowNotifications(context, notifications);
        }

        // 同时显示详细对话框
        _showRateChangeAlert(result.significantChanges);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('汇率更新成功')),
        );
      }
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

  void _showRateChangeAlert(List<RateChangeInfo> changes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('汇率变动提醒'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: changes.length,
            itemBuilder: (ctx, index) {
              final change = changes[index];
              final isUp = change.isIncrease;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.red : JiveTheme.primaryGreen,
                ),
                title: Text('${change.from} → ${change.to}'),
                subtitle: Text(
                  '${_currencyService.formatRate(change.oldRate)} → ${_currencyService.formatRate(change.newRate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? Colors.red : JiveTheme.primaryGreen).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change.changeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUp ? Colors.red : JiveTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
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

  String _getSourceDisplayName(String source) {
    switch (source) {
      case 'frankfurter':
        return 'Frankfurter API (免费，无限制)';
      case 'exchangerate.host':
        return 'ExchangeRate.host (免费，每日更新)';
      case 'openexchangerates':
        return 'Open Exchange Rates (需要API Key)';
      case 'coingecko':
        return 'CoinGecko (免费，实时价格)';
      case 'binance':
        return 'Binance API (实时交易价格)';
      default:
        return source;
    }
  }

  Future<void> _showSourceSelector(bool isCrypto) async {
    final sources = isCrypto
        ? [
            {'id': 'coingecko', 'name': 'CoinGecko', 'desc': '免费API，支持大多数加密货币，实时价格', 'icon': Icons.currency_bitcoin},
            {'id': 'binance', 'name': 'Binance', 'desc': '实时交易价格，需要网络良好', 'icon': Icons.trending_up},
          ]
        : [
            {'id': 'frankfurter', 'name': 'Frankfurter', 'desc': '欧洲央行数据，免费无限制，每日更新', 'icon': Icons.euro},
            {'id': 'exchangerate.host', 'name': 'ExchangeRate.host', 'desc': '备用数据源，免费，每日更新', 'icon': Icons.sync_alt},
          ];

    final currentSource = isCrypto
        ? (_preference?.preferredCryptoSource ?? 'coingecko')
        : (_preference?.preferredRateSource ?? 'frankfurter');

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    isCrypto ? '加密货币数据源' : '汇率数据源',
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
            ),
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              itemCount: sources.length,
              itemBuilder: (ctx, index) {
                final source = sources[index];
                final isSelected = source['id'] == currentSource;
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
                    child: Icon(
                      source['icon'] as IconData,
                      color: isSelected ? JiveTheme.primaryGreen : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(
                    source['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? JiveTheme.primaryGreen : null,
                    ),
                  ),
                  subtitle: Text(
                    source['desc'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: JiveTheme.primaryGreen)
                      : null,
                  onTap: () => Navigator.pop(ctx, source['id'] as String),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selected != null && _preference != null) {
      if (isCrypto) {
        _preference!.preferredCryptoSource = selected;
      } else {
        _preference!.preferredRateSource = selected;
      }
      await _currencyService.updatePreference(_preference!);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据源已切换为 ${_getSourceDisplayName(selected).split(' (').first}'),
            backgroundColor: JiveTheme.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _showOfflinePackageOptions() async {
    final info = CurrencyService.getOfflinePackageInfo();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    '离线汇率包',
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
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.offline_bolt, color: Colors.green.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '内置离线汇率包',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '在无网络时仍可进行货币换算',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem('版本', 'v${info['version']}'),
                      _buildInfoItem('日期', info['date'] ?? '-'),
                      _buildInfoItem('货币数', info['currencies'] ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('重置为离线汇率'),
              subtitle: const Text(
                '清除所有在线更新和手动设置的汇率，恢复为内置离线数据',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('确认重置'),
                    content: const Text('这将清除所有在线更新和手动设置的汇率，恢复为内置离线数据。确定要继续吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _currencyService.resetToOfflineRates();
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('汇率已重置为离线数据'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRateData() async {
    try {
      final file = await _backupService.exportToLocalFile();
      await RateCloudBackupService.cleanupOldBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出到: ${file.path.split('/').last}'),
          backgroundColor: JiveTheme.primaryGreen,
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () => _showBackupFiles(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importRateData() async {
    final files = await RateCloudBackupService.getLocalBackupFiles();
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有找到备份文件')),
      );
      return;
    }

    if (!mounted) return;
    final selectedFile = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    '选择备份文件',
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (ctx, index) {
                  final file = files[index];
                  final stat = file.statSync();
                  final name = file.path.split('/').last;
                  return ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: Text(name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${_formatDateTime(stat.modified)} · ${(stat.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    onTap: () => Navigator.pop(ctx, index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selectedFile == null) return;

    try {
      final result = await _backupService.importFromLocalFile(files[selectedFile]);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入 ${result.totalImported} 条记录'),
          backgroundColor: JiveTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showBackupFiles() async {
    final files = await RateCloudBackupService.getLocalBackupFiles();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    '备份文件 (${files.length})',
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (files.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.folder_off, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('暂无备份文件', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (ctx, index) {
                    final file = files[index];
                    final stat = file.statSync();
                    final name = file.path.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${_formatDateTime(stat.modified)} · ${(stat.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await file.delete();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showBackupFiles();
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurrencyConverterScreen()),
              );
            },
            icon: const Icon(Icons.calculate_outlined),
            tooltip: '货币换算',
          ),
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
          // 汇率变动提醒
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('汇率变动提醒'),
                  subtitle: Text(
                    _preference?.rateChangeAlert == true
                        ? '汇率波动超过阈值时提醒'
                        : '不提醒汇率变动',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _preference?.rateChangeAlert ?? false,
                  onChanged: (value) async {
                    if (_preference == null) return;
                    _preference!.rateChangeAlert = value;
                    await _currencyService.updatePreference(_preference!);
                    setState(() {});
                  },
                  secondary: Icon(
                    Icons.notifications_active,
                    color: _preference?.rateChangeAlert == true
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),
                if (_preference?.rateChangeAlert == true) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('变动阈值'),
                        const Spacer(),
                        ...([0.5, 1.0, 2.0, 5.0]).map((threshold) {
                          final isSelected = (_preference?.rateChangeThreshold ?? 1.0) == threshold;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('${threshold.toStringAsFixed(threshold == threshold.toInt() ? 0 : 1)}%'),
                              selected: isSelected,
                              onSelected: (selected) async {
                                if (!selected || _preference == null) return;
                                _preference!.rateChangeThreshold = threshold;
                                await _currencyService.updatePreference(_preference!);
                                setState(() {});
                              },
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : null,
                              ),
                              selectedColor: JiveTheme.primaryGreen,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 汇率数据源设置
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.api, color: Colors.blue),
                  title: const Text('汇率数据源'),
                  subtitle: Text(
                    _getSourceDisplayName(_preference?.preferredRateSource ?? 'frankfurter'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSourceSelector(false),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_bitcoin, color: Colors.orange),
                  title: const Text('加密货币数据源'),
                  subtitle: Text(
                    _getSourceDisplayName(_preference?.preferredCryptoSource ?? 'coingecko'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSourceSelector(true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.offline_bolt, color: Colors.green),
                  title: const Text('离线汇率包'),
                  subtitle: Builder(
                    builder: (context) {
                      final info = CurrencyService.getOfflinePackageInfo();
                      return Text(
                        '版本 ${info['version']} (${info['date']}) · ${info['currencies']} 种货币',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showOfflinePackageOptions,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 多币种功能
          Text(
            '多币种分析',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
                  ),
                  title: const Text('多币种资产总览'),
                  subtitle: const Text('查看所有币种资产统一换算', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MultiCurrencyOverviewScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.trending_up, color: Colors.green.shade600),
                  ),
                  title: const Text('汇率损益分析'),
                  subtitle: const Text('追踪汇率变动带来的盈亏', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExchangeRateProfitScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.pie_chart, color: Colors.purple.shade600),
                  ),
                  title: const Text('外币消费趋势'),
                  subtitle: const Text('按币种统计消费分布', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForeignCurrencySpendingScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: Colors.orange.shade600),
                  ),
                  title: const Text('换汇手续费'),
                  subtitle: const Text('查看跨币种转账费用记录', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExchangeFeeTrackingScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 数据同步
          Text(
            '数据同步',
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
                  title: const Text('定时汇率更新'),
                  subtitle: Text(
                    _updateConfig?.enabled == true
                        ? '每 ${RateUpdateConfig.getIntervalText(_updateConfig!.intervalMinutes)} 自动更新'
                        : '已关闭',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _updateConfig?.enabled ?? false,
                  onChanged: (value) async {
                    await ScheduledRateUpdateService.setEnabled(value);
                    if (value && _scheduledUpdateService != null) {
                      await _scheduledUpdateService!.startScheduledUpdates();
                    } else {
                      _scheduledUpdateService?.stopScheduledUpdates();
                    }
                    await _loadData();
                  },
                  secondary: Icon(
                    Icons.schedule,
                    color: _updateConfig?.enabled == true ? JiveTheme.primaryGreen : Colors.grey,
                  ),
                ),
                if (_updateConfig?.enabled == true) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('更新间隔'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _updateConfig?.intervalMinutes ?? 60,
                          underline: const SizedBox(),
                          items: RateUpdateConfig.intervalOptions.map((minutes) {
                            return DropdownMenuItem(
                              value: minutes,
                              child: Text(RateUpdateConfig.getIntervalText(minutes)),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              await ScheduledRateUpdateService.setUpdateInterval(value);
                              if (_scheduledUpdateService != null) {
                                await _scheduledUpdateService!.startScheduledUpdates();
                              }
                              await _loadData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_updateConfig?.lastUpdate != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '上次更新: ${_formatDateTime(_updateConfig!.lastUpdate!)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                  title: const Text('导出汇率数据'),
                  subtitle: const Text('备份到本地文件', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportRateData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download, color: Colors.teal),
                  title: const Text('导入汇率数据'),
                  subtitle: const Text('从备份文件恢复', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importRateData,
                ),
              ],
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 $baseCurrency = ${_currencyService.formatRate(rate.rate)} ${rate.toCurrency}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (rate.updatedAt != null)
                          Text(
                            '更新于 ${_formatDateTime(rate.updatedAt!)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSourceBadge(rate.source),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.history, size: 18),
                          onPressed: () => _showRateHistory(rate),
                          tooltip: '历史记录',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
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

  Future<void> _showRateHistory(JiveExchangeRate rate) async {
    final history = await _currencyService.getRateHistory(
      rate.fromCurrency,
      rate.toCurrency,
      limit: 50,
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
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
                    '${rate.fromCurrency} → ${rate.toCurrency} 历史',
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
            ),
            const Divider(height: 1),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '暂无历史记录',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 汇率趋势图
                        if (history.length >= 2) ...[
                          Text(
                            '汇率趋势',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRateChart(history),
                          const SizedBox(height: 24),
                        ],
                        // 历史记录列表
                        Text(
                          '历史记录',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final item = history[index];
                            final isFirst = index == 0;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? JiveTheme.primaryGreen.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isFirst ? Icons.check : Icons.history,
                                  size: 18,
                                  color: isFirst ? JiveTheme.primaryGreen : Colors.grey,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    _currencyService.formatRate(item.rate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFirst ? JiveTheme.primaryGreen : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSourceBadge(item.source),
                                ],
                              ),
                              subtitle: Text(
                                _formatDateTime(item.recordedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: isFirst
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '当前',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: JiveTheme.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChart(List<JiveExchangeRateHistory> history) {
    // 按时间顺序排列（旧的在前）
    final sortedHistory = history.reversed.toList();

    // 计算最大最小值，用于 Y 轴范围
    double minRate = double.infinity;
    double maxRate = double.negativeInfinity;
    for (final item in sortedHistory) {
      if (item.rate < minRate) minRate = item.rate;
      if (item.rate > maxRate) maxRate = item.rate;
    }

    // 添加一些边距
    final range = maxRate - minRate;
    final padding = range == 0 ? maxRate * 0.1 : range * 0.1;
    minRate = minRate - padding;
    maxRate = maxRate + padding;
    if (minRate < 0) minRate = 0;

    // 生成折线图数据点
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedHistory[i].rate));
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: minRate,
          maxY: maxRate,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxRate - minRate) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedHistory.length) {
                    return const SizedBox.shrink();
                  }
                  // 只显示首尾和中间的日期
                  if (index != 0 &&
                      index != sortedHistory.length - 1 &&
                      index != sortedHistory.length ~/ 2) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedHistory[index].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _currencyService.formatRate(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: JiveTheme.primaryGreen,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: index == spots.length - 1 ? 4 : 2,
                    color: JiveTheme.primaryGreen,
                    strokeWidth: index == spots.length - 1 ? 2 : 0,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= sortedHistory.length) {
                    return null;
                  }
                  final item = sortedHistory[index];
                  return LineTooltipItem(
                    '${_currencyService.formatRate(item.rate)}\n${_formatDateTime(item.recordedAt)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
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
  String _selectedGroup = '全部';

  List<String> get _groupNames => ['全部', ...CurrencyDefaults.currencyGroups.keys];

  List<Map<String, dynamic>> get _filteredCurrencies {
    List<Map<String, dynamic>> currencies;

    // 按分组筛选
    if (_selectedGroup == '全部') {
      currencies = CurrencyDefaults.getAllCurrencies();
    } else {
      final groupCodes = CurrencyDefaults.currencyGroups[_selectedGroup] ?? [];
      currencies = CurrencyDefaults.getAllCurrencies()
          .where((c) => groupCodes.contains(c['code']))
          .toList();
    }

    // 搜索筛选
    if (_searchQuery.isEmpty) return currencies;
    final query = _searchQuery.toLowerCase();
    return currencies.where((c) {
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
            // 分组选择器
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _groupNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = _groupNames[index];
                  final isSelected = group == _selectedGroup;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    selectedColor: JiveTheme.primaryGreen.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? JiveTheme.primaryGreen : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedGroup = group);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
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
