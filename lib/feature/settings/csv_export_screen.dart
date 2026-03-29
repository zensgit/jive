import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/category_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/csv_export_service.dart';
import '../../core/service/database_service.dart';
import '../../core/widgets/jive_calendar/jive_calendar.dart';

enum _CsvExportDatePreset {
  currentMonth,
  previousMonth,
  lastThreeMonths,
  custom,
}

class CsvExportScreen extends StatefulWidget {
  const CsvExportScreen({super.key});

  @override
  State<CsvExportScreen> createState() => _CsvExportScreenState();
}

class _CsvExportScreenState extends State<CsvExportScreen> {
  late DateTimeRange _dateRange;
  late CsvExportService _csvExportService;

  final DateFormat _rangeLabelFormat = DateFormat('yyyy-MM-dd');
  final Map<String, JiveCategory> _categoryByKey = {};

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isRefreshingPreview = false;
  int _previewCount = 0;
  int _previewRequestId = 0;
  String? _selectedCategoryKey;
  _CsvExportDatePreset _selectedPreset = _CsvExportDatePreset.currentMonth;
  List<JiveCategory> _rootCategories = [];

  @override
  void initState() {
    super.initState();
    _dateRange = _rangeForPreset(_selectedPreset, DateTime.now());
    _initData();
  }

  Future<void> _initData() async {
    final isar = await DatabaseService.getInstance();
    final csvExportService = CsvExportService(isar);
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final rootCategories = categories.where((category) {
      return category.parentKey == null;
    }).toList()..sort(_compareCategory);

    if (!mounted) return;
    setState(() {
      _csvExportService = csvExportService;
      _rootCategories = rootCategories;
      _categoryByKey
        ..clear()
        ..addEntries(
          categories.map((category) {
            return MapEntry(category.key, category);
          }),
        );
      _isLoading = false;
    });
    await _refreshPreview();
  }

  Future<void> _refreshPreview({bool showLoading = true}) async {
    if (_isLoading) return;

    final requestId = ++_previewRequestId;
    if (showLoading && mounted) {
      setState(() => _isRefreshingPreview = true);
    }

    try {
      final count = await _csvExportService.previewTransactionCount(
        _dateRange.start,
        _dateRange.end,
        categoryKey: _selectedCategoryKey,
      );
      if (!mounted || requestId != _previewRequestId) return;
      setState(() {
        _previewCount = count;
        _isRefreshingPreview = false;
      });
    } catch (e) {
      if (!mounted || requestId != _previewRequestId) return;
      setState(() => _isRefreshingPreview = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('预览失败: $e')));
    }
  }

  Future<void> _selectPreset(_CsvExportDatePreset preset) async {
    if (preset == _CsvExportDatePreset.custom) {
      await _pickCustomRange();
      return;
    }

    setState(() {
      _selectedPreset = preset;
      _dateRange = _rangeForPreset(preset, DateTime.now());
    });
    await _refreshPreview();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final result = await JiveDatePicker.pickDateRangeResult(
      context,
      initialRange: _dateRange,
      firstDay: DateTime(2020),
      lastDay: now,
      minSelectableDay: DateTime(2020),
      maxSelectableDay: now,
      bottomLabel: '选择导出时间范围',
    );
    if (!mounted) return;
    final pickedRange = result.value;
    if (!result.didChange || pickedRange == null) return;

    setState(() {
      _selectedPreset = _CsvExportDatePreset.custom;
      _dateRange = pickedRange;
    });
    await _refreshPreview();
  }

  Future<void> _exportCsv() async {
    if (_previewCount <= 0) return;

    setState(() => _isExporting = true);
    try {
      final file = await _csvExportService.exportTransactionsCsv(
        _dateRange.start,
        _dateRange.end,
        categoryKey: _selectedCategoryKey,
      );
      final fileName = file.uri.pathSegments.last;

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Jive 交易 CSV 导出',
          text: 'Jive 交易 CSV 导出',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV 已生成: $fileName'),
          backgroundColor: JiveTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  DateTimeRange _rangeForPreset(_CsvExportDatePreset preset, DateTime now) {
    switch (preset) {
      case _CsvExportDatePreset.currentMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _CsvExportDatePreset.previousMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
      case _CsvExportDatePreset.lastThreeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case _CsvExportDatePreset.custom:
        return _dateRange;
    }
  }

  int _compareCategory(JiveCategory left, JiveCategory right) {
    final byIncome = left.isIncome == right.isIncome
        ? 0
        : (left.isIncome ? 1 : -1);
    if (byIncome != 0) {
      return byIncome;
    }
    final byOrder = left.order.compareTo(right.order);
    if (byOrder != 0) {
      return byOrder;
    }
    return left.name.compareTo(right.name);
  }

  String _formatRange(DateTimeRange range) {
    return '${_rangeLabelFormat.format(range.start)} 至 ${_rangeLabelFormat.format(range.end)}';
  }

  String _presetLabel(_CsvExportDatePreset preset) {
    switch (preset) {
      case _CsvExportDatePreset.currentMonth:
        return '本月';
      case _CsvExportDatePreset.previousMonth:
        return '上月';
      case _CsvExportDatePreset.lastThreeMonths:
        return '最近3个月';
      case _CsvExportDatePreset.custom:
        return '自定义';
    }
  }

  String _categoryFilterSummary() {
    if (_selectedCategoryKey == null) {
      return '全部分类';
    }
    final category = _categoryByKey[_selectedCategoryKey!];
    if (category == null) {
      return _selectedCategoryKey!;
    }
    final typeLabel = category.isIncome ? '收入' : '支出';
    return '$typeLabel · ${category.name}';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('导出 CSV')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('导出 CSV'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.table_view_outlined, color: JiveTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '导出交易明细为 UTF-8 BOM 编码的 CSV，兼容 Excel 打开，并支持按时间和一级分类筛选。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: JiveTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('时间范围'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _CsvExportDatePreset.values.map((preset) {
                    return ChoiceChip(
                      label: Text(_presetLabel(preset)),
                      selected: _selectedPreset == preset,
                      selectedColor: JiveTheme.primaryGreen.withValues(
                        alpha: 0.16,
                      ),
                      checkmarkColor: JiveTheme.primaryGreen,
                      onSelected: (selected) {
                        if (!selected) return;
                        _selectPreset(preset);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickCustomRange,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '当前范围',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatRange(_dateRange),
                            style: GoogleFonts.lato(fontSize: 13),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('分类筛选'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  key: ValueKey(_selectedCategoryKey),
                  initialValue: _selectedCategoryKey,
                  decoration: InputDecoration(
                    labelText: '一级分类',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('全部分类'),
                    ),
                    ..._rootCategories.map((category) {
                      final typeLabel = category.isIncome ? '收入' : '支出';
                      return DropdownMenuItem<String?>(
                        value: category.key,
                        child: Text('$typeLabel · ${category.name}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryKey = value);
                    _refreshPreview();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '留空则导出当前时间范围内的全部交易。',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('导出预览'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '预计导出 $_previewCount 条交易',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_isRefreshingPreview)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '范围：${_formatRange(_dateRange)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '分类：${_categoryFilterSummary()}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isExporting || _previewCount == 0 ? null : _exportCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_outlined),
              label: Text(_isExporting ? '正在生成 CSV...' : '导出并分享'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JiveTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
