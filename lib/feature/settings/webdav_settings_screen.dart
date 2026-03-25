import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/service/database_service.dart';
import '../../core/service/webdav_sync_service.dart';

class WebDavSettingsScreen extends StatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  State<WebDavSettingsScreen> createState() => _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends State<WebDavSettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: '/Jive/');

  bool _autoBackup = false;
  String _frequency = 'daily';
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isBackingUp = false;
  bool _obscurePassword = true;
  WebDavSyncService? _service;
  DateTime? _lastBackup;
  List<WebDavBackupEntry> _remoteBackups = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final isar = await DatabaseService.getInstance();
    _service = WebDavSyncService(DataBackupService(isar));
    final config = await _service!.loadConfig();
    _lastBackup = await _service!.getLastBackupTime();
    if (config != null) {
      _urlCtrl.text = config.url;
      _userCtrl.text = config.username;
      _passCtrl.text = config.password;
      _pathCtrl.text = config.remotePath;
      _autoBackup = config.autoBackup;
      _frequency = config.autoBackupFrequency;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  WebDavConfig get _currentConfig => WebDavConfig(
        url: _urlCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        remotePath: _pathCtrl.text.trim().isEmpty ? '/Jive/' : _pathCtrl.text.trim(),
        autoBackup: _autoBackup,
        autoBackupFrequency: _frequency,
      );

  Future<void> _saveConfig() async {
    await _service!.saveConfig(_currentConfig);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  Future<void> _testConnection() async {
    final config = _currentConfig;
    if (!config.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写服务器地址、用户名和密码')),
      );
      return;
    }
    setState(() => _isTesting = true);
    final result = await _service!.testConnection(config);
    if (!mounted) return;
    setState(() => _isTesting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? '连接成功' : '连接失败: ${result.error}'),
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
    if (result.success) {
      await _saveConfig();
      _loadRemoteBackups();
    }
  }

  Future<void> _uploadBackup() async {
    final config = _currentConfig;
    if (!config.isConfigured) return;
    setState(() => _isBackingUp = true);
    try {
      await _service!.uploadBackup(config);
      _lastBackup = DateTime.now();
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份上传成功'), backgroundColor: Color(0xFF2E7D32)),
        );
        _loadRemoteBackups();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadRemoteBackups() async {
    final config = _currentConfig;
    if (!config.isConfigured) return;
    try {
      final backups = await _service!.listBackups(config);
      if (mounted) setState(() => _remoteBackups = backups);
    } catch (_) {}
  }

  Future<void> _restoreBackup(WebDavBackupEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复备份'),
        content: Text('确定从 "${entry.name}" 恢复？\n当前数据将被覆盖。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在恢复...')),
    );
    final result = await _service!.downloadAndRestore(_currentConfig, entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '恢复成功，共 ${result.restoredCount} 条交易'
            : '恢复失败: ${result.error}'),
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('WebDAV 同步')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('WebDAV 同步', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server config
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('服务器配置', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'https://dav.example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pathCtrl,
                    decoration: const InputDecoration(
                      labelText: '远程目录',
                      hintText: '/Jive/',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_find),
                          label: Text(_isTesting ? '测试中...' : '测试连接'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveConfig,
                          icon: const Icon(Icons.save),
                          label: const Text('保存配置'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto backup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('自动备份', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('启用自动备份'),
                    subtitle: Text(_autoBackup ? '已启用 ($_frequency)' : '关闭'),
                    value: _autoBackup,
                    onChanged: (v) => setState(() => _autoBackup = v),
                  ),
                  if (_autoBackup)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'daily', label: Text('每日')),
                        ButtonSegment(value: 'weekly', label: Text('每周')),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (s) => setState(() => _frequency = s.first),
                    ),
                  if (_lastBackup != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '上次备份: ${_lastBackup!.toLocal().toString().substring(0, 19)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Manual backup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('手动操作', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBackingUp ? null : _uploadBackup,
                      icon: _isBackingUp
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isBackingUp ? '正在备份...' : '立即备份'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remote backups list
          if (_remoteBackups.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('远程备份', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...(_remoteBackups.take(10).map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.archive_outlined),
                          title: Text(entry.name, style: const TextStyle(fontSize: 13)),
                          subtitle: entry.modified != null
                              ? Text(entry.modified!.toLocal().toString().substring(0, 16),
                                  style: const TextStyle(fontSize: 11))
                              : null,
                          trailing: TextButton(
                            onPressed: () => _restoreBackup(entry),
                            child: const Text('恢复'),
                          ),
                        ))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
