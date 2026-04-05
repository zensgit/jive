import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/transaction_model.dart';
import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/export_template_service.dart';

/// Screen for managing and using custom export templates.
class ExportTemplateScreen extends StatefulWidget {
  const ExportTemplateScreen({super.key});

  @override
  State<ExportTemplateScreen> createState() => _ExportTemplateScreenState();
}

class _ExportTemplateScreenState extends State<ExportTemplateScreen> {
  final ExportTemplateService _service = ExportTemplateService();
  List<ExportTemplate> _userTemplates = [];
  late List<ExportTemplate> _defaultTemplates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _defaultTemplates = _service.getDefaultTemplates();
    unawaited(_loadTemplates());
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      _userTemplates = await _service.getTemplates();
    } catch (_) {
      // Silently handle – defaults are still available.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _createOrEditTemplate({ExportTemplate? existing}) async {
    final result = await showDialog<ExportTemplate>(
      context: context,
      builder: (_) => _TemplateEditorDialog(existing: existing),
    );
    if (result == null) return;
    await _service.saveTemplate(result);
    await _loadTemplates();
  }

  Future<void> _deleteTemplate(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定删除模板「$name」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteTemplate(name);
    await _loadTemplates();
  }

  Future<void> _previewTemplate(ExportTemplate template) async {
    try {
      final isar = await DatabaseService.getInstance();
      final transactions = await isar.jiveTransactions
          .where()
          .sortByTimestampDesc()
          .limit(5)
          .findAll();

      if (!mounted) return;

      final csv = _service.exportWithTemplate(template, transactions);

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('预览: ${template.name}'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('预览失败: $e', isError: true);
    }
  }

  Future<void> _exportWithTemplate(ExportTemplate template) async {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择导出日期范围',
      confirmText: '确定',
      cancelText: '取消',
      builder: (_, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: JiveTheme.primaryGreen,
            secondary: JiveTheme.accentLime,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;

    try {
      final isar = await DatabaseService.getInstance();
      final startAt = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      final endAt = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
        999,
      );
      final transactions = await isar.jiveTransactions
          .where()
          .timestampBetween(startAt, endAt)
          .findAll();

      if (transactions.isEmpty) {
        if (!mounted) return;
        _showSnackBar('该日期范围内没有交易记录', isError: true);
        return;
      }

      final csv = _service.exportWithTemplate(template, transactions);

      // Write to temp file and share
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safeName = template.name.replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '_');
      final file = File('${exportDir.path}/jive_${safeName}_$timestamp.csv');
      await file.writeAsString(csv, flush: true);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Jive 交易导出 - ${template.name}',
          text: '使用模板「${template.name}」导出了 ${transactions.length} 条交易记录。',
        ),
      );

      if (!mounted) return;
      _showSnackBar('导出成功: ${transactions.length} 条记录');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('导出失败: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : JiveTheme.primaryGreen,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: JiveTheme.surfaceColor(context),
      appBar: AppBar(title: const Text('导出模板')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: JiveTheme.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _createOrEditTemplate(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                _buildSectionHeader(theme, '默认模板'),
                ..._defaultTemplates.map(
                  (t) => _buildTemplateCard(theme, t, isDefault: true),
                ),
                if (_userTemplates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader(theme, '自定义模板'),
                  ..._userTemplates.map(
                    (t) => _buildTemplateCard(theme, t, isDefault: false),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: JiveTheme.secondaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    ThemeData theme,
    ExportTemplate template, {
    required bool isDefault,
  }) {
    final fieldSummary = template.fields.map((f) => f.label).join(', ');
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDefault
                        ? Icons.description_outlined
                        : Icons.edit_note_rounded,
                    color: JiveTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    template.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isDefault)
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _createOrEditTemplate(existing: template);
                        case 'delete':
                          _deleteTemplate(template.name);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '字段: $fieldSummary',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '排序: ${template.sortBy.label} (${template.ascending ? "升序" : "降序"}) '
              '| 日期格式: ${template.dateFormat} '
              '| 表头: ${template.includeHeader ? "是" : "否"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewTemplate(template),
                    icon: const Icon(Icons.preview_outlined, size: 18),
                    label: const Text('预览'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JiveTheme.primaryGreen,
                      side: BorderSide(
                        color: JiveTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _exportWithTemplate(template),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('导出'),
                    style: FilledButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Template editor dialog
// =============================================================================

class _TemplateEditorDialog extends StatefulWidget {
  final ExportTemplate? existing;

  const _TemplateEditorDialog({this.existing});

  @override
  State<_TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<_TemplateEditorDialog> {
  late final TextEditingController _nameController;
  late List<ExportField> _selectedFields;
  late String _dateFormat;
  late ExportField _sortBy;
  late bool _ascending;
  late bool _includeHeader;

  static const _dateFormats = [
    'yyyy-MM-dd',
    'MM/dd/yyyy',
    'dd.MM.yyyy',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameController = TextEditingController(text: t?.name ?? '');
    _selectedFields = List<ExportField>.of(
      t?.fields ?? ExportField.values,
    );
    _dateFormat = t?.dateFormat ?? 'yyyy-MM-dd';
    _sortBy = t?.sortBy ?? ExportField.date;
    _ascending = t?.ascending ?? true;
    _includeHeader = t?.includeHeader ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }
    if (_selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个导出字段')),
      );
      return;
    }
    Navigator.pop(
      context,
      ExportTemplate(
        name: name,
        fields: _selectedFields,
        dateFormat: _dateFormat,
        sortBy: _sortBy,
        ascending: _ascending,
        includeHeader: _includeHeader,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing != null ? '编辑模板' : '新建模板',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '模板名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Fields – reorderable checkboxes
              Text(
                '导出字段（长按拖动排序）',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: ExportField.values.length,
                  onReorder: _onReorder,
                  proxyDecorator: (child, _, __) => Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  ),
                  itemBuilder: (_, index) {
                    final field = _orderedFields[index];
                    final isSelected = _selectedFields.contains(field);
                    return ReorderableDragStartListener(
                      key: ValueKey(field.key),
                      index: index,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(field.label),
                        secondary: const Icon(Icons.drag_handle, size: 20),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedFields.add(field);
                            } else {
                              _selectedFields.remove(field);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Date format
              Row(
                children: [
                  Text('日期格式: ', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _dateFormat,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _dateFormats.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _dateFormat = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Sort
              Row(
                children: [
                  Text('排序: ', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<ExportField>(
                      value: _sortBy,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: ExportField.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sortBy = v);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _ascending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                    ),
                    tooltip: _ascending ? '升序' : '降序',
                    onPressed: () =>
                        setState(() => _ascending = !_ascending),
                  ),
                ],
              ),
              // Include header
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('包含表头行'),
                value: _includeHeader,
                onChanged: (v) => setState(() => _includeHeader = v),
              ),
              const SizedBox(height: 8),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: JiveTheme.primaryGreen,
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The ordering: selected fields first (in their current order), then
  // unselected fields in their enum order.
  List<ExportField> get _orderedFields {
    final unselected = ExportField.values
        .where((f) => !_selectedFields.contains(f))
        .toList();
    return [..._selectedFields, ...unselected];
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final ordered = _orderedFields;
      if (newIndex > oldIndex) newIndex--;
      final item = ordered.removeAt(oldIndex);
      ordered.insert(newIndex, item);
      // Re-derive the selected fields preserving the new order.
      _selectedFields = ordered
          .where((f) => _selectedFields.contains(f) || f == item)
          .toList();
      // If the item was not previously selected, keep it that way.
      if (!_selectedFields.contains(item)) {
        _selectedFields.remove(item);
      }
    });
  }
}
