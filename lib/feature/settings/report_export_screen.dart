import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/currency_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/widgets/jive_calendar/jive_calendar.dart';
import '../../core/service/currency_service.dart';
import '../../core/service/data_backup_service.dart';
import '../../core/service/database_service.dart';

/// 报表导出界面
class ReportExportScreen extends StatefulWidget {
  const ReportExportScreen({super.key});

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  late Isar _isar;
  late CurrencyService _currencyService;
  bool _isLoading = true;
  bool _isExporting = false;

  // 导出选项
  String _targetCurrency = 'CNY';
  String _format = 'csv';
  DateTimeRange? _dateRange;
  List<String> _enabledCurrencies = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _isar = await DatabaseService.getInstance();
    _currencyService = CurrencyService(_isar);

    final pref = await _currencyService.getPreference();
    final baseCurrency = pref?.baseCurrency ?? 'CNY';
    final enabled =
        pref?.enabledCurrencies ?? ['CNY', 'USD', 'EUR', 'JPY', 'HKD'];

    // 默认导出本月
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    if (!mounted) return;
    setState(() {
      _targetCurrency = baseCurrency;
      _enabledCurrencies = enabled;
      _dateRange = DateTimeRange(start: monthStart, end: monthEnd);
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final previous = _dateRange;
    final result = await JiveDatePicker.pickDateRangeResult(
      context,
      initialRange: previous,
      firstDay: DateTime(2020),
      lastDay: now,
      minSelectableDay: DateTime(2020),
      maxSelectableDay: now,
      bottomLabel: '选择日期范围',
    );
    if (!mounted) return;
    final picked = result.value;
    if (!result.didChange || picked == null || picked == previous) return;
    setState(() => _dateRange = picked);
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      final file = await JiveDataBackupService.exportReport(
        _isar,
        targetCurrency: _targetCurrency,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        format: _format,
      );

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: '交易报表导出'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('报表已导出: ${file.path.split('/').last}'),
          backgroundColor: JiveTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('导出报表')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('导出报表')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: JiveTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '导出的报表将所有交易金额统一转换为选定的货币，方便统计和分析',
                      style: TextStyle(
                        fontSize: 13,
                        color: JiveTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 目标货币选择
            _buildSectionTitle('目标货币'),
            const SizedBox(height: 12),
            _buildCurrencySelector(),

            const SizedBox(height: 24),

            // 日期范围
            _buildSectionTitle('日期范围'),
            const SizedBox(height: 12),
            _buildDateRangeSelector(),

            const SizedBox(height: 24),

            // 导出格式
            _buildSectionTitle('导出格式'),
            const SizedBox(height: 12),
            _buildFormatSelector(),

            const SizedBox(height: 32),

            // 导出按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download),
                label: Text(_isExporting ? '正在导出...' : '导出报表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 快捷导出
            _buildSectionTitle('快捷导出'),
            const SizedBox(height: 12),
            _buildQuickExportOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _enabledCurrencies.map((code) {
        final data = CurrencyDefaults.getAllCurrencies().firstWhere(
          (c) => c['code'] == code,
          orElse: () => {
            'code': code,
            'symbol': code,
            'flag': null,
            'nameZh': code,
          },
        );
        final flag = data['flag'] as String?;
        final symbol = data['symbol'] as String;
        final nameZh = data['nameZh'] as String;
        final isSelected = code == _targetCurrency;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag ?? symbol, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$code ($nameZh)'),
            ],
          ),
          selected: isSelected,
          selectedColor: JiveTheme.primaryGreen.withValues(alpha: 0.2),
          checkmarkColor: JiveTheme.primaryGreen,
          onSelected: (selected) {
            if (selected) {
              setState(() => _targetCurrency = code);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final rangeText = _dateRange != null
        ? '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}'
        : '选择日期范围';

    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(rangeText, style: GoogleFonts.lato(fontSize: 15)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFormatOption(
            'csv',
            'CSV',
            '表格软件可直接打开',
            Icons.table_chart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFormatOption('json', 'JSON', '适合程序处理', Icons.code),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _format == value;
    return InkWell(
      onTap: () => setState(() => _format = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? JiveTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? JiveTheme.primaryGreen.withValues(alpha: 0.05)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? JiveTheme.primaryGreen : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? JiveTheme.primaryGreen : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportOptions() {
    final now = DateTime.now();

    return Column(
      children: [
        _buildQuickExportItem('本月报表', Icons.calendar_month, () async {
          setState(() {
            _dateRange = DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month + 1, 0),
            );
          });
          await _export();
        }),
        _buildQuickExportItem('本季度报表', Icons.calendar_view_month, () async {
          final quarter = ((now.month - 1) ~/ 3);
          final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
          final quarterEnd = DateTime(now.year, (quarter + 1) * 3 + 1, 0);
          setState(() {
            _dateRange = DateTimeRange(start: quarterStart, end: quarterEnd);
          });
          await _export();
        }),
        _buildQuickExportItem('本年报表', Icons.calendar_today, () async {
          setState(() {
            _dateRange = DateTimeRange(
              start: DateTime(now.year, 1, 1),
              end: DateTime(now.year, 12, 31),
            );
          });
          await _export();
        }),
        _buildQuickExportItem('全部数据', Icons.all_inclusive, () async {
          setState(() => _dateRange = null);
          await _export();
        }),
      ],
    );
  }

  Widget _buildQuickExportItem(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: _isExporting ? null : onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
