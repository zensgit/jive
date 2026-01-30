import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/currency_model.dart';

/// 汇率数据云备份服务
/// 提供汇率数据的导出和恢复功能
class RateCloudBackupService {
  static const String _lastBackupKey = 'rate_cloud_backup_last';
  static const String _backupEnabledKey = 'rate_cloud_backup_enabled';

  final Isar _isar;

  RateCloudBackupService(this._isar);

  /// 检查是否启用了云备份
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? false;
  }

  /// 启用/禁用云备份
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, enabled);
  }

  /// 获取最后备份时间
  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastBackupKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// 导出汇率数据为 JSON
  Future<Map<String, dynamic>> exportRateData() async {
    final rates = await _isar.jiveExchangeRates.where().findAll();
    final history = await _isar.jiveExchangeRateHistorys.where().findAll();
    final prefs = await _isar.jiveCurrencyPreferences.where().findAll();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'exchangeRates': rates.map((r) => {
        'fromCurrency': r.fromCurrency,
        'toCurrency': r.toCurrency,
        'rate': r.rate,
        'effectiveDate': r.effectiveDate.toIso8601String(),
        'source': r.source,
        'updatedAt': r.updatedAt?.toIso8601String(),
      }).toList(),
      'rateHistory': history.map((h) => {
        'fromCurrency': h.fromCurrency,
        'toCurrency': h.toCurrency,
        'rate': h.rate,
        'recordedAt': h.recordedAt.toIso8601String(),
        'source': h.source,
      }).toList(),
      'preferences': prefs.map((p) => {
        'baseCurrency': p.baseCurrency,
        'enabledCurrencies': p.enabledCurrencies,
        'favoritePairs': p.favoritePairs,
        'autoUpdateRates': p.autoUpdateRates,
        'rateChangeAlert': p.rateChangeAlert,
        'rateChangeThreshold': p.rateChangeThreshold,
        'preferredRateSource': p.preferredRateSource,
        'preferredCryptoSource': p.preferredCryptoSource,
      }).toList(),
    };
  }

  /// 导出到本地文件
  Future<File> exportToLocalFile() async {
    final data = await exportRateData();
    final json = jsonEncode(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/rate_backup_$timestamp.json');
    await file.writeAsString(json);

    // 更新最后备份时间
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

    return file;
  }

  /// 从 JSON 数据导入汇率
  Future<RateImportResult> importRateData(Map<String, dynamic> data) async {
    int ratesImported = 0;
    int historyImported = 0;
    int prefsImported = 0;

    await _isar.writeTxn(() async {
      // 导入汇率
      final ratesData = data['exchangeRates'] as List?;
      if (ratesData != null) {
        for (final rateJson in ratesData) {
          final rate = JiveExchangeRate()
            ..fromCurrency = rateJson['fromCurrency']
            ..toCurrency = rateJson['toCurrency']
            ..rate = (rateJson['rate'] as num).toDouble()
            ..effectiveDate = DateTime.parse(rateJson['effectiveDate'])
            ..source = rateJson['source'] ?? 'import';

          if (rateJson['updatedAt'] != null) {
            rate.updatedAt = DateTime.parse(rateJson['updatedAt']);
          }

          await _isar.jiveExchangeRates.put(rate);
          ratesImported++;
        }
      }

      // 导入历史记录
      final historyData = data['rateHistory'] as List?;
      if (historyData != null) {
        for (final histJson in historyData) {
          final history = JiveExchangeRateHistory()
            ..fromCurrency = histJson['fromCurrency']
            ..toCurrency = histJson['toCurrency']
            ..rate = (histJson['rate'] as num).toDouble()
            ..recordedAt = DateTime.parse(histJson['recordedAt'])
            ..source = histJson['source'] ?? 'import';

          await _isar.jiveExchangeRateHistorys.put(history);
          historyImported++;
        }
      }

      // 导入偏好设置（只导入第一个）
      final prefsData = data['preferences'] as List?;
      if (prefsData != null && prefsData.isNotEmpty) {
        final prefJson = prefsData.first;
        final existingPref = await _isar.jiveCurrencyPreferences.where().findFirst();

        final pref = existingPref ?? JiveCurrencyPreference();
        pref.baseCurrency = prefJson['baseCurrency'] ?? 'CNY';
        pref.enabledCurrencies = List<String>.from(prefJson['enabledCurrencies'] ?? []);
        pref.favoritePairs = List<String>.from(prefJson['favoritePairs'] ?? []);
        pref.autoUpdateRates = prefJson['autoUpdateRates'] ?? false;
        pref.rateChangeAlert = prefJson['rateChangeAlert'] ?? false;
        pref.rateChangeThreshold = (prefJson['rateChangeThreshold'] as num?)?.toDouble() ?? 1.0;
        pref.preferredRateSource = prefJson['preferredRateSource'] ?? 'frankfurter';
        pref.preferredCryptoSource = prefJson['preferredCryptoSource'] ?? 'coingecko';

        await _isar.jiveCurrencyPreferences.put(pref);
        prefsImported = 1;
      }
    });

    return RateImportResult(
      ratesImported: ratesImported,
      historyImported: historyImported,
      preferencesImported: prefsImported,
    );
  }

  /// 从本地文件导入
  Future<RateImportResult> importFromLocalFile(File file) async {
    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;
    return importRateData(data);
  }

  /// 获取备份文件列表
  static Future<List<File>> getLocalBackupFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync()
        .whereType<File>()
        .where((f) => f.path.contains('rate_backup_') && f.path.endsWith('.json'))
        .toList();

    // 按修改时间排序，最新的在前
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  /// 删除旧的备份文件，只保留最近的 N 个
  static Future<void> cleanupOldBackups({int keepCount = 5}) async {
    final files = await getLocalBackupFiles();
    if (files.length > keepCount) {
      for (int i = keepCount; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }
}

/// 汇率数据导入结果
class RateImportResult {
  final int ratesImported;
  final int historyImported;
  final int preferencesImported;

  RateImportResult({
    required this.ratesImported,
    required this.historyImported,
    required this.preferencesImported,
  });

  int get totalImported => ratesImported + historyImported + preferencesImported;
}
