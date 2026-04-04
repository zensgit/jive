import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design_system/theme.dart';
import '../../core/service/database_service.dart';
import '../../core/service/encrypted_backup_service.dart';
import '../../core/service/excel_report_service.dart';

/// Unified export screen: annual Excel report, encrypted backup, and restore.
class ExportCenterScreen extends StatefulWidget {
  const ExportCenterScreen({super.key});

  @override
  State<ExportCenterScreen> createState() => _ExportCenterScreenState();
}

class _ExportCenterScreenState extends State<ExportCenterScreen> {
  // Year picker
  int _selectedYear = DateTime.now().year;

  // Backup password
  final _backupPasswordController = TextEditingController();
  bool _backupPasswordVisible = false;

  // Restore
  final _restorePasswordController = TextEditingController();
  bool _restorePasswordVisible = false;
  String? _restoreFilePath;
  String? _restoreFileName;

  // Loading states
  bool _isExportingExcel = false;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _backupPasswordController.dispose();
    _restorePasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _exportExcel() async {
    setState(() => _isExportingExcel = true);
    try {
      final isar = await DatabaseService.getInstance();
      final service = ExcelReportService(isar);
      final bytes = await service.generateAnnualExcel(_selectedYear);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'jive_annual_report_$_selectedYear.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Jive $_selectedYear 年度报告',
          text: '$_selectedYear 年度财务报告已生成。',
        ),
      );

      if (!mounted) return;
      _showSnackBar('$_selectedYear 年度报告导出成功');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('导出失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _createBackup() async {
    final password = _backupPasswordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar('请输入备份密码', isError: true);
      return;
    }
    if (password.length < 4) {
      _showSnackBar('密码至少需要 4 位', isError: true);
      return;
    }

    setState(() => _isCreatingBackup = true);
    try {
      final isar = await DatabaseService.getInstance();
      final service = EncryptedBackupService(isar);
      final result = await service.createEncryptedBackup(password);

      if (!mounted) return;

      final sizeKb = (result.fileSize / 1024).toStringAsFixed(1);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.filePath)],
          subject: 'Jive 加密备份',
          text: '加密备份已创建，共 ${result.recordCount} 条记录。',
        ),
      );

      if (!mounted) return;
      _showSnackBar('备份成功：${result.recordCount} 条记录，${sizeKb}KB');
      _backupPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('备份失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _pickRestoreFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    setState(() {
      _restoreFilePath = file.path;
      _restoreFileName = file.name;
    });
  }

  Future<void> _restoreBackup() async {
    if (_restoreFilePath == null) {
      _showSnackBar('请先选择备份文件', isError: true);
      return;
    }
    final password = _restorePasswordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar('请输入备份密码', isError: true);
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final isar = await DatabaseService.getInstance();
      final service = EncryptedBackupService(isar);
      final result =
          await service.restoreEncryptedBackup(_restoreFilePath!, password);

      if (!mounted) return;

      if (result.success) {
        _showSnackBar('恢复成功：${result.recordCount} 条记录');
        _restorePasswordController.clear();
        setState(() {
          _restoreFilePath = null;
          _restoreFileName = null;
        });
      } else {
        _showSnackBar(result.error ?? '恢复失败', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('恢复失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
      appBar: AppBar(title: const Text('导出中心')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildExcelCard(theme),
          const SizedBox(height: 16),
          _buildBackupCard(theme),
          const SizedBox(height: 16),
          _buildRestoreCard(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 1: Excel Annual Report
  // ---------------------------------------------------------------------------

  Widget _buildExcelCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: JiveTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_chart_outlined,
                    color: JiveTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Excel 年度报告',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '生成包含年度总览、月度明细、分类排行和交易明细的多 Sheet Excel 报告。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            // Year picker row
            Row(
              children: [
                Text('年份：', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                _YearDropdown(
                  value: _selectedYear,
                  onChanged: (v) => setState(() => _selectedYear = v),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isExportingExcel ? null : _exportExcel,
                  icon: _isExportingExcel
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(_isExportingExcel ? '生成中...' : '导出'),
                  style: FilledButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // ---------------------------------------------------------------------------
  // Card 2: Encrypted Backup
  // ---------------------------------------------------------------------------

  Widget _buildBackupCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '加密备份',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '将所有数据加密压缩为备份文件，可安全保存到云盘或其他设备。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _backupPasswordController,
              obscureText: !_backupPasswordVisible,
              decoration: _inputDecoration(
                label: '备份密码',
                prefixIcon: Icons.vpn_key_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _backupPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _backupPasswordVisible = !_backupPasswordVisible,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreatingBackup ? null : _createBackup,
                icon: _isCreatingBackup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.backup_outlined),
                label: Text(_isCreatingBackup ? '备份中...' : '创建备份'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 3: Restore Backup
  // ---------------------------------------------------------------------------

  Widget _buildRestoreCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: JiveTheme.cardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restore, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '恢复备份',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '从加密备份文件中恢复数据，需要输入创建备份时设定的密码。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: JiveTheme.secondaryTextColor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            // File picker
            OutlinedButton.icon(
              onPressed: _isRestoring ? null : _pickRestoreFile,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(_restoreFileName ?? '选择备份文件'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restorePasswordController,
              obscureText: !_restorePasswordVisible,
              decoration: _inputDecoration(
                label: '备份密码',
                prefixIcon: Icons.vpn_key_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _restorePasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () =>
                        _restorePasswordVisible = !_restorePasswordVisible,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRestoring ? null : _restoreBackup,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(_isRestoring ? '恢复中...' : '恢复'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: JiveTheme.dividerColor(context)),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide:
            const BorderSide(color: JiveTheme.primaryGreen, width: 1.4),
      ),
      filled: true,
      fillColor: JiveTheme.cardColor(context),
    );
  }
}

// ---------------------------------------------------------------------------
// Year dropdown helper
// ---------------------------------------------------------------------------

class _YearDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _YearDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox.shrink(),
      items: years.map((y) {
        return DropdownMenuItem<int>(value: y, child: Text('$y'));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
