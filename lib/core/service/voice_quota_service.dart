import 'package:shared_preferences/shared_preferences.dart';

class VoiceQuota {
  final String dateKey;
  final int onlineCount;
  final int offlineCount;
  final int dailyLimit;

  VoiceQuota({
    required this.dateKey,
    required this.onlineCount,
    required this.offlineCount,
    required this.dailyLimit,
  });

  int get totalCount => onlineCount + offlineCount;
  int get remaining => (dailyLimit - onlineCount).clamp(0, dailyLimit);
  bool get isOnlineExceeded => onlineCount >= dailyLimit;

  double get usageRatio {
    if (dailyLimit <= 0) return 1.0;
    return onlineCount / dailyLimit;
  }

  VoiceQuotaWarningLevel get warningLevel {
    if (isOnlineExceeded) return VoiceQuotaWarningLevel.exceeded;
    if (usageRatio >= 0.9) return VoiceQuotaWarningLevel.high;
    if (usageRatio >= 0.7) return VoiceQuotaWarningLevel.medium;
    if (usageRatio >= 0.5) return VoiceQuotaWarningLevel.low;
    return VoiceQuotaWarningLevel.none;
  }
}

enum VoiceQuotaWarningLevel {
  none,
  low,
  medium,
  high,
  exceeded,
}

class VoiceQuotaStore {
  static const _keyDate = 'voice_quota_date';
  static const _keyOnline = 'voice_quota_online';
  static const _keyOffline = 'voice_quota_offline';
  static const int _dailyLimit = 50;

  static Future<VoiceQuota> load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_keyDate);
    if (storedDate != today) {
      await _resetForToday(prefs, today);
    }
    return VoiceQuota(
      dateKey: today,
      onlineCount: prefs.getInt(_keyOnline) ?? 0,
      offlineCount: prefs.getInt(_keyOffline) ?? 0,
      dailyLimit: _dailyLimit,
    );
  }

  static Future<VoiceQuota> increment({required bool online}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_keyDate);
    if (storedDate != today) {
      await _resetForToday(prefs, today);
    }
    if (online) {
      final current = prefs.getInt(_keyOnline) ?? 0;
      await prefs.setInt(_keyOnline, current + 1);
    } else {
      final current = prefs.getInt(_keyOffline) ?? 0;
      await prefs.setInt(_keyOffline, current + 1);
    }
    return load();
  }

  static Future<void> _resetForToday(SharedPreferences prefs, String today) async {
    await prefs.setString(_keyDate, today);
    await prefs.setInt(_keyOnline, 0);
    await prefs.setInt(_keyOffline, 0);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
