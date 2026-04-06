import 'package:flutter/material.dart';

import '../../core/service/screenshot_capture_service.dart';

class ScreenshotCaptureSettingsScreen extends StatefulWidget {
  const ScreenshotCaptureSettingsScreen({super.key});

  @override
  State<ScreenshotCaptureSettingsScreen> createState() =>
      _ScreenshotCaptureSettingsScreenState();
}

class _ScreenshotCaptureSettingsScreenState
    extends State<ScreenshotCaptureSettingsScreen> {
  final _service = ScreenshotCaptureService();

  bool _loading = true;
  bool _enabled = false;
  List<String> _recentPaths = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabled;
    final recent = await _service.getRecentPaths(count: 5);
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _recentPaths = recent;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    await _service.setEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  Future<void> _manualScan() async {
    setState(() => _scanning = true);
    try {
      final paths = await _service.checkForNewScreenshots();
      int processed = 0;
      for (final path in paths) {
        final result = await _service.processScreenshot(path);
        if (result != null) processed++;
      }
      final recent = await _service.getRecentPaths(count: 5);
      if (!mounted) return;
      setState(() {
        _recentPaths = recent;
        _scanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描完成，识别到 $processed 条支付记录'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('扫描失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('截图自动捕获')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildToggleCard(theme),
                const SizedBox(height: 16),
                _buildManualScanButton(theme),
                const SizedBox(height: 16),
                if (_recentPaths.isNotEmpty) _buildRecentList(theme),
              ],
            ),
    );
  }

  Widget _buildToggleCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '截图自动识别',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('开启后将自动识别截图中的支付信息'),
            value: _enabled,
            onChanged: _toggle,
          ),
        ],
      ),
    );
  }

  Widget _buildManualScanButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _scanning ? null : _manualScan,
        icon: _scanning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.document_scanner_outlined),
        label: Text(_scanning ? '扫描中...' : '手动扫描截图'),
      ),
    );
  }

  Widget _buildRecentList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近捕获',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_recentPaths.length, (i) {
          final path = _recentPaths[i];
          final fileName = path.split('/').last;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined, size: 28),
            title: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              path,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }),
      ],
    );
  }
}
