import 'package:flutter/material.dart';

import 'strings_en.dart';
import 'strings_zh_cn.dart';
import 'strings_zh_tw.dart';

/// Manual localization class for the Jive app.
///
/// Supports zh_CN (Simplified Chinese), zh_TW (Traditional Chinese), and
/// en (English). Simplified Chinese is the default fallback.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// Convenience accessor from any widget tree.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// All supported locales.
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _localizedStrings = {
    'zh_CN': stringsZhCN,
    'zh_TW': stringsZhTW,
    'en': stringsEn,
  };

  /// Returns the resolved string map key for the current [locale].
  String get _mapKey {
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'TW') return 'zh_TW';
      return 'zh_CN'; // default for zh, zh_CN, zh_Hans, etc.
    }
    if (_localizedStrings.containsKey(locale.languageCode)) {
      return locale.languageCode;
    }
    return 'zh_CN'; // ultimate fallback
  }

  /// Look up a translated string by [key].
  ///
  /// Falls back to Simplified Chinese if the key is missing in the current
  /// locale, and returns the raw key if it is missing everywhere.
  String translate(String key) {
    final map = _localizedStrings[_mapKey];
    return map?[key] ?? stringsZhCN[key] ?? key;
  }

  /// Shorthand alias for [translate].
  String tr(String key) => translate(key);
}

/// Delegate that loads [AppLocalizations] for the resolved locale.
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
