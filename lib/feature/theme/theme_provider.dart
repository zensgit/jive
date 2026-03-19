import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design_system/theme.dart';
import 'theme_presets.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _presetKey = 'selected_theme_preset_name';
  static const String _darkModeKey = 'theme_dark_mode_enabled';

  SharedPreferences? _preferences;
  ThemePreset _currentPreset = ThemePresets.defaultPreset;
  bool _isDarkMode = false;

  String get selectedPresetName => _currentPreset.name;
  ThemePreset get selectedPreset => _currentPreset;
  bool get isDarkMode => _isDarkMode;
  List<ThemePreset> get presets => ThemePresets.all;

  ThemeData get lightTheme => JiveTheme.buildTheme(
        brightness: Brightness.light,
        primaryColor: _currentPreset.primaryColor,
        accentColor: _currentPreset.accentColor,
        seedColor: _currentPreset.seedColor,
      );

  ThemeData get darkTheme => JiveTheme.buildTheme(
        brightness: Brightness.dark,
        primaryColor: _currentPreset.primaryColor,
        accentColor: _currentPreset.accentColor,
        seedColor: _currentPreset.seedColor,
      );

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final preferences = await _prefs;
    _currentPreset = ThemePresets.byName(preferences.getString(_presetKey));
    _isDarkMode = preferences.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setTheme(String presetName) async {
    final preset = ThemePresets.byName(presetName);
    if (preset.name == _currentPreset.name) {
      return;
    }

    _currentPreset = preset;
    final preferences = await _prefs;
    await preferences.setString(_presetKey, preset.name);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final preferences = await _prefs;
    await preferences.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<SharedPreferences> get _prefs async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }
}
