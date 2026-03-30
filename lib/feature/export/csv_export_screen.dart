import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:isar/isar.dart';

import '../../core/database/category_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/csv_export_service.dart';
import '../../core/service/database_service.dart';

class CsvExportScreen extends StatelessWidget {
  const CsvExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CsvExportController>(
      create: (_) => CsvExportController()..initialize(),
      child: const _CsvExportView(),
    );
  }
}

class _CsvExportView extends StatelessWidget {
  const _CsvExportView();

  static final DateFormat _dateFormat = DateFormat('yyyy年M月d日');

  Future<void> _pickDateRange(
    BuildContext context,
    CsvExportController controller,
  ) async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDateRange: controller.dateRange,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择导出日期',
      confirmText: '确定',
      cancelText: '取消',
      builder: (_, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: JiveTheme.primaryGreen,
              secondary: JiveTheme.accentLime,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    controller.setDateRange(picked);
  }

  Future<void> _shareCsv(
    BuildContext context,
    CsvExportController controller,
  ) async {
    if (controller.previewCount == 0) {
      _showSnackBar(context, message: '没有匹配的交易可导出', isError: true);
      return;
    }

    try {
      final file = await controller.exportCsv();
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Jive 交易数据导出',
          text: '交易数据已导出为 CSV，可直接在 Excel 中打开。',
        ),
      );
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: '导出成功，已打开分享面板',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: '导出失败：$error',
        isError: true,
      );
    }
  }

  Future<void> _saveCsv(
    BuildContext context,
    CsvExportController controller,
  ) async {
    if (controller.previewCount == 0) {
      _showSnackBar(context, message: '没有匹配的交易可导出', isError: true);
      return;
    }

    try {
      final file = await controller.exportCsv();
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: '已保存到设备：${file.path}',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: '保存失败：$error',
        isError: true,
      );
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : JiveTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CsvExportController>();
    final theme = Theme.of(context);

    if (controller.isInitialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('导出数据')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('导出数据')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.loadError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: JiveTheme.surfaceColor(context),
      appBar: AppBar(title: const Text('导出数据')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildIntroCard(context),
          const SizedBox(height: 16),
          _buildFilterCard(context, controller),
          const SizedBox(height: 16),
          _buildPreviewCard(context, controller),
          const SizedBox(height: 16),
          _buildActionCard(context, controller),
        ],
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      surfaceTintColor: JiveTheme.primaryGreen.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.table_view_rounded,
                color: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '导出 CSV，Excel 可直接打开',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '支持按日期、分类和交易类型筛选，文件会保存到本机文稿目录的 exports 文件夹。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: JiveTheme.secondaryTextColor(context),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    CsvExportController controller,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '筛选条件',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: controller.isBusy
                  ? null
                  : () => _pickDateRange(context, controller),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JiveTheme.dividerColor(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: JiveTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.date_range_outlined,
                        color: JiveTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '日期范围',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dateFormat.format(controller.dateRange.start)} 至 ${_dateFormat.format(controller.dateRange.end)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: JiveTheme.secondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: JiveTheme.secondaryTextColor(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: controller.selectedCategoryKey ?? '',
              isExpanded: true,
              decoration: _inputDecoration(
                context,
                label: '分类筛选（可选）',
                prefixIcon: Icons.category_outlined,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('全部分类'),
                ),
                ...controller.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.key,
                    child: Text(
                      category.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: controller.isBusy
                  ? null
                  : (value) => controller.setCategoryKey(value),
            ),
            const SizedBox(height: 16),
            Text(
              '交易类型',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<String>(
                    value: 'all',
                    label: Text('全部'),
                    icon: Icon(Icons.grid_view_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'expense',
                    label: Text('支出'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'income',
                    label: Text('收入'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'transfer',
                    label: Text('转账'),
                    icon: Icon(Icons.swap_horiz_rounded),
                  ),
                ],
                selected: <String>{controller.selectedType},
                onSelectionChanged: controller.isBusy
                    ? null
                    : (selection) {
                        if (selection.isEmpty) return;
                        controller.setType(selection.first);
                      },
                style: SegmentedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: JiveTheme.primaryGreen,
                  side: BorderSide(color: JiveTheme.dividerColor(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    CsvExportController controller,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: JiveTheme.accentLime.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预览结果',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.previewError ??
                        '当前筛选条件下匹配的交易笔数',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: controller.previewError == null
                          ? JiveTheme.secondaryTextColor(context)
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: controller.isCounting
                  ? const SizedBox(
                      key: ValueKey('counting'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(
                      '${controller.previewCount} 笔',
                      key: const ValueKey('count'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: JiveTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    CsvExportController controller,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导出操作',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '导出文件为 UTF-8 编码 CSV，适合直接分享或在 Excel 中查看。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
            if (controller.isExporting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.canExport
                    ? () => _shareCsv(context, controller)
                    : null,
                icon: controller.isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(controller.isExporting ? '处理中...' : '导出并分享'),
                style: FilledButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.canExport
                    ? () => _saveCsv(context, controller)
                    : null,
                icon: const Icon(Icons.download_rounded),
                label: const Text('保存到设备'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JiveTheme.primaryGreen,
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(
                    color: JiveTheme.primaryGreen.withValues(alpha: 0.28),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.previewCount == 0
                  ? '当前没有可导出的交易，请调整筛选条件。'
                  : '文件将保存在 App 文稿目录的 exports 文件夹中。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData prefixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: JiveTheme.dividerColor(context)),
    );

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: JiveTheme.primaryGreen, width: 1.4),
      ),
      filled: true,
      fillColor: JiveTheme.cardColor(context),
    );
  }
}

class CsvExportController extends ChangeNotifier {
  CsvExportController() : _dateRange = _defaultDateRange();

  DateTimeRange _dateRange;
  final List<CsvExportCategoryOption> _categories = <CsvExportCategoryOption>[];

  CsvExportService? _csvExportService;
  bool _isDisposed = false;
  bool _isInitialLoading = true;
  bool _isCounting = false;
  bool _isExporting = false;
  int _previewCount = 0;
  int _previewRequestId = 0;
  String? _selectedCategoryKey;
  String _selectedType = CsvExportTransactionType.all.rawValue;
  String? _loadError;
  String? _previewError;

  DateTimeRange get dateRange => _dateRange;
  List<CsvExportCategoryOption> get categories =>
      List<CsvExportCategoryOption>.unmodifiable(_categories);
  bool get isInitialLoading => _isInitialLoading;
  bool get isCounting => _isCounting;
  bool get isExporting => _isExporting;
  bool get isBusy => _isCounting || _isExporting;
  bool get canExport => !_isCounting && !_isExporting && _previewCount > 0;
  int get previewCount => _previewCount;
  String? get selectedCategoryKey => _selectedCategoryKey;
  String get selectedType => _selectedType;
  String? get loadError => _loadError;
  String? get previewError => _previewError;

  static DateTimeRange _defaultDateRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> initialize() async {
    _isInitialLoading = true;
    _loadError = null;
    _safeNotifyListeners();

    try {
      final isar = await DatabaseService.getInstance();
      _csvExportService = CsvExportService(isar);

      final allCategories = await isar
          .collection<JiveCategory>()
          .where()
          .findAll();
      final loadedCategories =
          allCategories.where((c) => !c.isHidden).toList();
      loadedCategories.sort(_sortCategories);

      _categories
        ..clear()
        ..addAll(_buildCategoryOptions(loadedCategories));

      _isInitialLoading = false;
      _safeNotifyListeners();
      await _refreshPreviewCount();
    } catch (error) {
      _isInitialLoading = false;
      _loadError = '加载导出数据失败：$error';
      _safeNotifyListeners();
    }
  }

  void retry() {
    unawaited(initialize());
  }

  void setDateRange(DateTimeRange value) {
    if (_dateRange.start == value.start && _dateRange.end == value.end) {
      return;
    }
    _dateRange = value;
    _safeNotifyListeners();
    unawaited(_refreshPreviewCount());
  }

  void setCategoryKey(String? value) {
    final normalized = (value == null || value.isEmpty) ? null : value;
    if (_selectedCategoryKey == normalized) return;
    _selectedCategoryKey = normalized;
    _safeNotifyListeners();
    unawaited(_refreshPreviewCount());
  }

  void setType(String value) {
    if (_selectedType == value) return;
    _selectedType = value;
    _safeNotifyListeners();
    unawaited(_refreshPreviewCount());
  }

  Future<File> exportCsv() async {
    final service = _csvExportService;
    if (service == null) {
      throw StateError('导出服务尚未初始化');
    }

    _isExporting = true;
    _safeNotifyListeners();
    try {
      return await service.exportTransactionsCsv(
        _dateRange.start,
        _dateRange.end,
        categoryKey: _selectedCategoryKey,
        type: _selectedType,
      );
    } finally {
      _isExporting = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _refreshPreviewCount() async {
    final service = _csvExportService;
    if (service == null) return;

    final requestId = ++_previewRequestId;
    _isCounting = true;
    _previewError = null;
    _safeNotifyListeners();

    try {
      final count = await service.countTransactions(
        start: _dateRange.start,
        end: _dateRange.end,
        categoryKey: _selectedCategoryKey,
        type: _selectedType,
      );
      if (_isDisposed || requestId != _previewRequestId) return;
      _previewCount = count;
    } catch (error) {
      if (_isDisposed || requestId != _previewRequestId) return;
      _previewCount = 0;
      _previewError = '预览笔数加载失败：$error';
    } finally {
      if (!_isDisposed && requestId == _previewRequestId) {
        _isCounting = false;
        _safeNotifyListeners();
      }
    }
  }

  List<CsvExportCategoryOption> _buildCategoryOptions(
    List<JiveCategory> categories,
  ) {
    final categoryByKey = <String, JiveCategory>{
      for (final category in categories) category.key: category,
    };
    return categories.map((category) {
      final parent = category.parentKey == null
          ? null
          : categoryByKey[category.parentKey];
      final path = parent == null
          ? category.name
          : '${parent.name} / ${category.name}';
      final typeLabel = category.isIncome ? '收入' : '支出';
      return CsvExportCategoryOption(
        key: category.key,
        label: '$typeLabel · $path',
      );
    }).toList();
  }

  int _sortCategories(JiveCategory a, JiveCategory b) {
    if (a.isIncome != b.isIncome) {
      return a.isIncome ? -1 : 1;
    }
    final parentCompare =
        (a.parentKey == null ? 0 : 1).compareTo(b.parentKey == null ? 0 : 1);
    if (parentCompare != 0) return parentCompare;
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) return orderCompare;
    return a.name.compareTo(b.name);
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class CsvExportCategoryOption {
  final String key;
  final String label;

  const CsvExportCategoryOption({
    required this.key,
    required this.label,
  });
}
