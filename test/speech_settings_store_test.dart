import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/speech_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SpeechSettingsStore persists round-trip values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const expected = SpeechSettings(
      enabled: false,
      onlineEnhance: false,
      locale: 'yue',
    );

    await SpeechSettingsStore.save(expected);
    final loaded = await SpeechSettingsStore.load();

    expect(loaded.enabled, isFalse);
    expect(loaded.onlineEnhance, isFalse);
    expect(loaded.locale, equals('yue'));
  });

  test('SpeechSettingsStore loads defaults when preferences are empty', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final loaded = await SpeechSettingsStore.load();

    expect(loaded.enabled, equals(SpeechSettingsStore.defaults.enabled));
    expect(
      loaded.onlineEnhance,
      equals(SpeechSettingsStore.defaults.onlineEnhance),
    );
    expect(loaded.locale, isNotEmpty);
  });
}
