import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily bookkeeping reminder preferences.
///
/// Does NOT use flutter_local_notifications (would require native setup).
/// Instead, checks on app open whether to show an in-app reminder.
class DailyReminderService {
  static const _prefKeyEnabled = 'daily_reminder_enabled';
  static const _prefKeyHour = 'daily_reminder_hour';
  static const _prefKeyLastShown = 'daily_reminder_last_shown';

  /// Default reminder hour (21 = 9 PM)
  static const int defaultHour = 21;

  /// Load current settings.
  static Future<DailyReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyReminderSettings(
      enabled: prefs.getBool(_prefKeyEnabled) ?? false,
      hour: prefs.getInt(_prefKeyHour) ?? defaultHour,
    );
  }

  /// Save settings.
  static Future<void> saveSettings(DailyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, settings.enabled);
    await prefs.setInt(_prefKeyHour, settings.hour);
  }

  /// Check if we should show a reminder right now.
  ///
  /// Returns true if:
  /// 1. Reminders are enabled
  /// 2. Current hour >= reminder hour
  /// 3. Haven't shown today yet
  static Future<bool> shouldShowReminder() async {
    final settings = await loadSettings();
    if (!settings.enabled) return false;

    final now = DateTime.now();
    if (now.hour < settings.hour) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefKeyLastShown);
    final today = now.toIso8601String().substring(0, 10);
    if (lastShown == today) return false;

    await prefs.setString(_prefKeyLastShown, today);
    return true;
  }

  /// Mark today's reminder as shown (for manual dismissal).
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_prefKeyLastShown, today);
  }
}

class DailyReminderSettings {
  final bool enabled;
  final int hour;

  const DailyReminderSettings({
    required this.enabled,
    required this.hour,
  });

  DailyReminderSettings copyWith({bool? enabled, int? hour}) {
    return DailyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
    );
  }

  String get hourLabel {
    final h = hour.toString().padLeft(2, '0');
    return '$h:00';
  }
}
