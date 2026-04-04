import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/category_share_service.dart';
import '../../core/service/database_service.dart';

class CategoryShareScreen extends StatefulWidget {
  final Isar? isar;

  const CategoryShareScreen({super.key, this.isar});

  @override
  State<CategoryShareScreen> createState() => _CategoryShareScreenState();
}

class _CategoryShareScreenState extends State<CategoryShareScreen> {
  CategoryShareService? _service;
  bool _isInitialized = false;

  // Export state
  bool _isExporting = false;
  CategoryExport? _exportResult;

  // Import state
  final TextEditingController _importController = TextEditingController();
  bool _isImporting = false;
  List<String>? _previewNames;
  String? _decodedJson;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final isar = widget.isar ?? await DatabaseService.getInstance();
    if (!mounted) return;
    setState(() {
      _service = CategoryShareService(isar);
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final result = await _service!.exportToClipboard();
      if (!mounted) return;
      setState(() {
        _exportResult = result;
        _isExporting = false;
      });
      _showSnack('已导出 ${result.categoryCount} 个分类并复制到剪贴板');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showSnack('导出失败: $e', isError: true);
    }
  }

  Future<void> _copyCode() async {
    if (_exportResult == null) return;
    final encoded = base64Encode(utf8.encode(_exportResult!.jsonData));
    final payload = '${_exportResult!.shareCode}:$encoded';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    _showSnack('分享码已复制到剪贴板');
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  void _handlePreview() {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showSnack('请粘贴分享码', isError: true);
      return;
    }

    final json = _service!.decodePayload(text);
    if (json == null) {
      _showSnack('分享码格式无效', isError: true);
      return;
    }

    final names = _service!.previewNames(json);
    if (names.isEmpty) {
      _showSnack('未找到可导入的分类', isError: true);
      return;
    }

    setState(() {
      _decodedJson = json;
      _previewNames = names;
    });
  }

  Future<void> _handleImport() async {
    if (_decodedJson == null) return;
    setState(() => _isImporting = true);
    try {
      final count = await _service!.importCategories(_decodedJson!);
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _previewNames = null;
        _decodedJson = null;
        _importController.clear();
      });
      if (count > 0) {
        _showSnack('成功导入 $count 个新分类');
      } else {
        _showSnack('所有分类已存在，无需导入');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      _showSnack('导入失败: $e', isError: true);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _importController.text = data.text!;
      _handlePreview();
    } else {
      _showSnack('剪贴板为空', isError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(title: const Text('分类分享')),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('分享我的分类', Icons.upload_rounded, theme),
          const SizedBox(height: 8),
          _buildExportSection(theme),
          const SizedBox(height: 32),
          _buildSectionHeader('导入分类', Icons.download_rounded, theme),
          const SizedBox(height: 8),
          _buildImportSection(theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: JiveTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildExportSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '将你的自定义分类导出为分享码，发送给好友即可一键导入。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (_isExporting || !_isInitialized) ? null : _handleExport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_rounded),
              label: const Text('导出'),
            ),
            if (_exportResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '分享码',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _exportResult!.shareCode,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.copy_rounded),
                          tooltip: '复制',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${_exportResult!.categoryCount} 个分类',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '粘贴好友分享的分享码，预览后确认导入。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _importController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '在此粘贴分享码…',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded),
                  tooltip: '从剪贴板粘贴',
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handlePreview,
              icon: const Icon(Icons.preview_rounded),
              label: const Text('预览'),
            ),
            if (_previewNames != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '即将导入 ${_previewNames!.length} 个分类:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _previewNames!.map((name) {
                        return Chip(
                          label: Text(name),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isImporting ? null : _handleImport,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_done_rounded),
                label: const Text('确认导入'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
