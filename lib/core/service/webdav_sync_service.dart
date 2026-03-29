import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:archive/archive.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'data_backup_service.dart';

/// WebDAV 备份恢复结果
class BackupRestoreResult {
  final bool success;
  final String? error;
  final int restoredCount;

  BackupRestoreResult({required this.success, this.error, this.restoredCount = 0});
}

/// 备份服务桥接 - 将 JiveDataBackupService 静态方法包装为 ZIP 导入导出
class DataBackupService {
  final Isar _isar;

  DataBackupService(this._isar);

  /// 导出备份为 ZIP（内含 JSON 数据文件）
  Future<File> exportToZip() async {
    final jsonFile = await JiveDataBackupService.exportToFile(_isar);
    final jsonBytes = await jsonFile.readAsBytes();

    final archive = Archive();
    archive.addFile(ArchiveFile('jive_backup.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final zipFile = File('${dir.path}/jive_backup_$timestamp.zip');
    await zipFile.writeAsBytes(zipBytes!);

    // 清理临时 JSON 文件
    if (jsonFile.existsSync()) await jsonFile.delete();

    return zipFile;
  }

  /// 从 ZIP 文件恢复备份
  Future<BackupRestoreResult> restoreFromZip(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? jsonEntry;
      for (final entry in archive) {
        if (entry.name.endsWith('.json')) {
          jsonEntry = entry;
          break;
        }
      }
      if (jsonEntry == null) {
        return BackupRestoreResult(success: false, error: 'ZIP 中未找到备份数据文件');
      }

      // 写入临时文件供 importFromFile 使用
      final tempDir = await Directory.systemTemp.createTemp('jive_restore_');
      final tempFile = File('${tempDir.path}/jive_backup.json');
      await tempFile.writeAsBytes(jsonEntry.content as List<int>);

      final summary = await JiveDataBackupService.importFromFile(_isar, tempFile);
      await tempDir.delete(recursive: true);

      return BackupRestoreResult(
        success: true,
        restoredCount: summary.transactions,
      );
    } catch (e) {
      return BackupRestoreResult(success: false, error: e.toString());
    }
  }

  /// 从 JSON Map 恢复备份
  Future<BackupRestoreResult> restoreFromJson(Map<String, dynamic> data) async {
    try {
      final tempDir = await Directory.systemTemp.createTemp('jive_restore_');
      final tempFile = File('${tempDir.path}/jive_backup.json');
      await tempFile.writeAsString(jsonEncode(data));

      final summary = await JiveDataBackupService.importFromFile(_isar, tempFile);
      await tempDir.delete(recursive: true);

      return BackupRestoreResult(
        success: true,
        restoredCount: summary.transactions,
      );
    } catch (e) {
      return BackupRestoreResult(success: false, error: e.toString());
    }
  }
}

/// WebDAV 配置
class WebDavConfig {
  final String url;
  final String username;
  final String password;
  final String remotePath;
  final bool autoBackup;
  final String autoBackupFrequency; // daily | weekly

  const WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
    this.remotePath = '/Jive/',
    this.autoBackup = false,
    this.autoBackupFrequency = 'daily',
  });

  WebDavConfig copyWith({
    String? url,
    String? username,
    String? password,
    String? remotePath,
    bool? autoBackup,
    String? autoBackupFrequency,
  }) {
    return WebDavConfig(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      autoBackup: autoBackup ?? this.autoBackup,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'username': username,
        'password': password,
        'remotePath': remotePath,
        'autoBackup': autoBackup,
        'autoBackupFrequency': autoBackupFrequency,
      };

  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      url: json['url'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      remotePath: json['remotePath'] as String? ?? '/Jive/',
      autoBackup: json['autoBackup'] as bool? ?? false,
      autoBackupFrequency: json['autoBackupFrequency'] as String? ?? 'daily',
    );
  }

  bool get isConfigured => url.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}

/// WebDAV 同步服务
class WebDavSyncService {
  static const _prefKeyWebDavConfig = 'webdav_config';
  static const _prefKeyLastBackupTime = 'webdav_last_backup';

  final DataBackupService _backupService;

  WebDavSyncService(this._backupService);

  /// 加载 WebDAV 配置
  Future<WebDavConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyWebDavConfig);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WebDavConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// 保存 WebDAV 配置
  Future<void> saveConfig(WebDavConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyWebDavConfig, jsonEncode(config.toJson()));
  }

  /// 测试 WebDAV 连接
  Future<WebDavTestResult> testConnection(WebDavConfig config) async {
    try {
      final client = _createClient(config);
      // 尝试确保远程目录存在
      try {
        await client.mkdir(config.remotePath);
      } catch (_) {
        // 目录可能已存在，忽略
      }
      // 尝试读取目录
      await client.readDir(config.remotePath);
      return WebDavTestResult(success: true);
    } catch (e) {
      return WebDavTestResult(success: false, error: e.toString());
    }
  }

  /// 上传备份到 WebDAV
  Future<void> uploadBackup(WebDavConfig config) async {
    final client = _createClient(config);

    // 确保远程目录存在
    try {
      await client.mkdir(config.remotePath);
    } catch (e) { debugPrint('Failed to create WebDAV remote directory: $e'); }

    // 导出为 ZIP
    final zipFile = await _backupService.exportToZip();
    final bytes = await zipFile.readAsBytes();

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final remoteName = '${config.remotePath}jive_backup_$timestamp.zip';

    await client.write(remoteName, bytes);

    // 记录备份时间
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastBackupTime, DateTime.now().toIso8601String());

    // 清理临时文件
    if (zipFile.existsSync()) {
      await zipFile.delete();
    }
  }

  /// 列出远程备份
  Future<List<WebDavBackupEntry>> listBackups(WebDavConfig config) async {
    final client = _createClient(config);
    final files = await client.readDir(config.remotePath);
    final backups = <WebDavBackupEntry>[];

    for (final file in files) {
      if (file.name == null) continue;
      if (!file.name!.endsWith('.zip') && !file.name!.endsWith('.json')) continue;
      backups.add(WebDavBackupEntry(
        name: file.name!,
        path: file.path ?? '${config.remotePath}${file.name}',
        size: file.size ?? 0,
        modified: file.mTime,
      ));
    }

    backups.sort((a, b) => (b.modified ?? DateTime(2000)).compareTo(a.modified ?? DateTime(2000)));
    return backups;
  }

  /// 从 WebDAV 下载并恢复
  Future<BackupRestoreResult> downloadAndRestore(
    WebDavConfig config,
    WebDavBackupEntry entry,
  ) async {
    final client = _createClient(config);
    final bytes = await client.read(entry.path);

    final tempDir = await Directory.systemTemp.createTemp('jive_restore_');
    final tempFile = File('${tempDir.path}/${entry.name}');
    await tempFile.writeAsBytes(bytes);

    BackupRestoreResult result;
    if (entry.name.endsWith('.zip')) {
      result = await _backupService.restoreFromZip(tempFile);
    } else {
      final jsonStr = utf8.decode(bytes);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      result = await _backupService.restoreFromJson(data);
    }

    // 清理
    await tempDir.delete(recursive: true);
    return result;
  }

  /// 获取上次备份时间
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKeyLastBackupTime);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// 检查是否需要自动备份
  Future<bool> shouldAutoBackup(WebDavConfig config) async {
    if (!config.autoBackup || !config.isConfigured) return false;

    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true;

    final now = DateTime.now();
    final diff = now.difference(lastBackup);

    switch (config.autoBackupFrequency) {
      case 'daily':
        return diff.inHours >= 24;
      case 'weekly':
        return diff.inDays >= 7;
      default:
        return diff.inHours >= 24;
    }
  }

  webdav.Client _createClient(WebDavConfig config) {
    return webdav.newClient(
      config.url,
      user: config.username,
      password: config.password,
    );
  }
}

class WebDavTestResult {
  final bool success;
  final String? error;

  WebDavTestResult({required this.success, this.error});
}

class WebDavBackupEntry {
  final String name;
  final String path;
  final int size;
  final DateTime? modified;

  WebDavBackupEntry({
    required this.name,
    required this.path,
    required this.size,
    this.modified,
  });
}
