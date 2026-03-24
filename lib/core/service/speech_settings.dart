import 'dart:ui' as ui;

import 'package:shared_preferences/shared_preferences.dart';

class SpeechSettings {
  final bool enabled;
  final bool onlineEnhance;
  final String locale;

  const SpeechSettings({
    required this.enabled,
    required this.onlineEnhance,
    required this.locale,
  });

  SpeechSettings copyWith({
    bool? enabled,
    bool? onlineEnhance,
    String? locale,
  }) {
    return SpeechSettings(
      enabled: enabled ?? this.enabled,
      onlineEnhance: onlineEnhance ?? this.onlineEnhance,
      locale: locale ?? this.locale,
    );
  }
}

class SpeechSettingsStore {
  static const _prefKeyEnabled = 'speech_enabled';
  static const _prefKeyOnlineEnhance = 'speech_online_enhance';
  static const _prefKeyLocale = 'speech_locale';

  static const defaults = SpeechSettings(
    enabled: true,
    onlineEnhance: true,
    locale: 'zh-CN',
  );

  static Future<SpeechSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    var locale = prefs.getString(_prefKeyLocale);
    if (locale == null || locale.trim().isEmpty) {
      locale = _inferLocale();
      await prefs.setString(_prefKeyLocale, locale);
    }
    return SpeechSettings(
      enabled: prefs.getBool(_prefKeyEnabled) ?? defaults.enabled,
      onlineEnhance: prefs.getBool(_prefKeyOnlineEnhance) ?? defaults.onlineEnhance,
      locale: locale,
    );
  }

  static Future<void> save(SpeechSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, settings.enabled);
    await prefs.setBool(_prefKeyOnlineEnhance, settings.onlineEnhance);
    await prefs.setString(_prefKeyLocale, settings.locale);
  }

  static String _inferLocale() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final language = locale.languageCode.toLowerCase();
    if (language == 'yue') return 'yue';
    if (language == 'zh') {
      final script = locale.scriptCode?.toLowerCase();
      final country = locale.countryCode?.toUpperCase();
      if (script == 'hant' || country == 'TW' || country == 'HK' || country == 'MO') {
        return 'zh-TW';
      }
      return 'zh-CN';
    }
    return defaults.locale;
  }
}
