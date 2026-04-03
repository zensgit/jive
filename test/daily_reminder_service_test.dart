import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/service/daily_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyReminderSettings', () {
    test('defaults to disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await DailyReminderService.loadSettings();
      expect(s.enabled, isFalse);
      expect(s.hour, equals(DailyReminderService.defaultHour));
    });

    test('persists round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      const settings = DailyReminderSettings(enabled: true, hour: 20);
      await DailyReminderService.saveSettings(settings);
      final loaded = await DailyReminderService.loadSettings();
      expect(loaded.enabled, isTrue);
      expect(loaded.hour, equals(20));
    });

    test('hourLabel formats correctly', () {
      const s = DailyReminderSettings(enabled: true, hour: 9);
      expect(s.hourLabel, equals('09:00'));
      const s2 = DailyReminderSettings(enabled: true, hour: 21);
      expect(s2.hourLabel, equals('21:00'));
    });
  });

  group('shouldShowReminder', () {
    test('returns false when disabled', () async {
      SharedPreferences.setMockInitialValues({
        'daily_reminder_enabled': false,
      });
      expect(await DailyReminderService.shouldShowReminder(), isFalse);
    });

    test('returns false when already shown today', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      SharedPreferences.setMockInitialValues({
        'daily_reminder_enabled': true,
        'daily_reminder_hour': 0, // always past
        'daily_reminder_last_shown': today,
      });
      expect(await DailyReminderService.shouldShowReminder(), isFalse);
    });

    test('returns true when enabled and not shown today', () async {
      SharedPreferences.setMockInitialValues({
        'daily_reminder_enabled': true,
        'daily_reminder_hour': 0, // hour 0 = always past the threshold
      });
      expect(await DailyReminderService.shouldShowReminder(), isTrue);
      // Second call same day should return false
      expect(await DailyReminderService.shouldShowReminder(), isFalse);
    });
  });
}
