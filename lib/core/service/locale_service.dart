import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Service that manages the current app locale and persists the user's choice.
class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_locale';

  Locale _currentLocale = const Locale('zh', 'CN');

  /// The currently active locale.
  Locale get currentLocale => _currentLocale;

  /// Initialise the service by reading the persisted locale (if any).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null) {
      _currentLocale = _parseLocale(stored);
    }
  }

  /// Change the locale, persist it, and notify listeners.
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _localeToString(locale));
  }

  /// Returns all locales the app supports.
  List<Locale> getSupportedLocales() {
    return AppLocalizations.supportedLocales;
  }

  // -- helpers ---------------------------------------------------------------

  static String _localeToString(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  static Locale _parseLocale(String value) {
    final parts = value.split('_');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }
}
