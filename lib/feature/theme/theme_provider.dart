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

  // 0=system, 1=light, 2=dark
  int _themeModeIndex = 0;
  static const String _themeModeKey = 'theme_mode_index';

  ThemeMode get themeMode {
    switch (_themeModeIndex) {
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  bool get isSystemMode => _themeModeIndex == 0;

  Future<void> init() async {
    final preferences = await _prefs;
    _currentPreset = ThemePresets.byName(preferences.getString(_presetKey));
    _isDarkMode = preferences.getBool(_darkModeKey) ?? false;
    _themeModeIndex = preferences.getInt(_themeModeKey) ?? 0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final index = mode == ThemeMode.light ? 1 : mode == ThemeMode.dark ? 2 : 0;
    if (_themeModeIndex == index) return;
    _themeModeIndex = index;
    _isDarkMode = mode == ThemeMode.dark;
    final preferences = await _prefs;
    await preferences.setInt(_themeModeKey, index);
    await preferences.setBool(_darkModeKey, _isDarkMode);
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
