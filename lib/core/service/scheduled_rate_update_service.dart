import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';

/// 定时汇率更新服务
/// 提供自动更新汇率的功能
class ScheduledRateUpdateService {
  static const String _lastUpdateKey = 'scheduled_rate_last_update';
  static const String _updateIntervalKey = 'scheduled_rate_interval';
  static const String _autoUpdateEnabledKey = 'scheduled_rate_enabled';

  final CurrencyService _currencyService;
  Timer? _updateTimer;

  ScheduledRateUpdateService(this._currencyService);

  /// 检查是否启用了自动更新
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoUpdateEnabledKey) ?? false;
  }

  /// 启用/禁用自动更新
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateEnabledKey, enabled);
  }

  /// 获取更新间隔（分钟）
  static Future<int> getUpdateInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_updateIntervalKey) ?? 60; // 默认60分钟
  }

  /// 设置更新间隔（分钟）
  static Future<void> setUpdateInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_updateIntervalKey, minutes);
  }

  /// 获取最后更新时间
  static Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastUpdateKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// 记录最后更新时间
  static Future<void> _setLastUpdateTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUpdateKey, time.toIso8601String());
  }

  /// 检查是否需要更新
  static Future<bool> needsUpdate() async {
    final enabled = await isEnabled();
    if (!enabled) return false;

    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;

    final interval = await getUpdateInterval();
    final nextUpdate = lastUpdate.add(Duration(minutes: interval));
    return DateTime.now().isAfter(nextUpdate);
  }

  /// 启动定时更新
  Future<void> startScheduledUpdates() async {
    final enabled = await isEnabled();
    if (!enabled) return;

    // 取消现有定时器
    _updateTimer?.cancel();

    final interval = await getUpdateInterval();

    // 检查是否需要立即更新
    if (await needsUpdate()) {
      await performUpdate();
    }

    // 设置定时器
    _updateTimer = Timer.periodic(Duration(minutes: interval), (_) async {
      if (await isEnabled()) {
        await performUpdate();
      }
    });
  }

  /// 停止定时更新
  void stopScheduledUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// 执行汇率更新
  Future<RateUpdateResult> performUpdate() async {
    final pref = await _currencyService.getPreference();
    if (pref == null) {
      return RateUpdateResult(
        success: false,
        message: '无法获取货币偏好设置',
        updatedPairs: 0,
      );
    }

    final enabledCurrencies = pref.enabledCurrencies;
    final baseCurrency = pref.baseCurrency;
    int updatedCount = 0;
    final errors = <String>[];

    // 更新每个启用的货币与基础货币之间的汇率
    for (final currency in enabledCurrencies) {
      if (currency == baseCurrency) continue;

      try {
        // 获取最新汇率
        final response = await _currencyService.fetchLiveRate(currency, baseCurrency);
        if (response != null) {
          await _currencyService.setManualRate(currency, baseCurrency, response.rate);
          updatedCount++;
        }
      } catch (e) {
        errors.add('$currency: $e');
      }
    }

    // 更新收藏的货币对
    final favoritePairs = pref.favoritePairs;
    for (final pair in favoritePairs) {
      final parts = pair.split('/');
      if (parts.length != 2) continue;

      final from = parts[0];
      final to = parts[1];

      // 如果已经在启用货币中更新过，跳过
      if (enabledCurrencies.contains(from) && to == baseCurrency) continue;
      if (enabledCurrencies.contains(to) && from == baseCurrency) continue;

      try {
        final response = await _currencyService.fetchLiveRate(from, to);
        if (response != null) {
          await _currencyService.setManualRate(from, to, response.rate);
          updatedCount++;
        }
      } catch (e) {
        errors.add('$pair: $e');
      }
    }

    // 记录更新时间
    await _setLastUpdateTime(DateTime.now());

    // 清除缓存
    CurrencyService.clearCache();

    return RateUpdateResult(
      success: errors.isEmpty,
      message: errors.isEmpty
          ? '成功更新 $updatedCount 个货币对'
          : '更新完成，但有 ${errors.length} 个错误',
      updatedPairs: updatedCount,
      errors: errors.isEmpty ? null : errors,
    );
  }

  /// 获取下次更新时间
  static Future<DateTime?> getNextUpdateTime() async {
    final enabled = await isEnabled();
    if (!enabled) return null;

    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return DateTime.now();

    final interval = await getUpdateInterval();
    return lastUpdate.add(Duration(minutes: interval));
  }

  /// 释放资源
  void dispose() {
    stopScheduledUpdates();
  }
}

/// 汇率更新结果
class RateUpdateResult {
  final bool success;
  final String message;
  final int updatedPairs;
  final List<String>? errors;

  RateUpdateResult({
    required this.success,
    required this.message,
    required this.updatedPairs,
    this.errors,
  });
}

/// 汇率更新配置
class RateUpdateConfig {
  final bool enabled;
  final int intervalMinutes;
  final DateTime? lastUpdate;
  final DateTime? nextUpdate;

  RateUpdateConfig({
    required this.enabled,
    required this.intervalMinutes,
    this.lastUpdate,
    this.nextUpdate,
  });

  static Future<RateUpdateConfig> load() async {
    final enabled = await ScheduledRateUpdateService.isEnabled();
    final interval = await ScheduledRateUpdateService.getUpdateInterval();
    final lastUpdate = await ScheduledRateUpdateService.getLastUpdateTime();
    final nextUpdate = await ScheduledRateUpdateService.getNextUpdateTime();

    return RateUpdateConfig(
      enabled: enabled,
      intervalMinutes: interval,
      lastUpdate: lastUpdate,
      nextUpdate: nextUpdate,
    );
  }

  /// 预设的更新间隔选项
  static const List<int> intervalOptions = [15, 30, 60, 120, 240, 480, 1440];

  /// 获取间隔的显示文本
  static String getIntervalText(int minutes) {
    if (minutes < 60) {
      return '$minutes 分钟';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60} 小时';
    } else {
      return '${minutes ~/ 1440} 天';
    }
  }
}
