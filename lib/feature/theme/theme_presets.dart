import 'package:flutter/material.dart';

import '../../core/design_system/theme.dart';

class ThemePreset {
  const ThemePreset({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.seedColor,
  });

  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color seedColor;
}

abstract final class ThemePresets {
  static const ThemePreset forestGreen = ThemePreset(
    name: '森林绿',
    primaryColor: JiveTheme.primaryGreen,
    accentColor: JiveTheme.accentLime,
    seedColor: JiveTheme.primaryGreen,
  );

  static const ThemePreset oceanBlue = ThemePreset(
    name: '海洋蓝',
    primaryColor: Color(0xFF1565C0),
    accentColor: Color(0xFF80DEEA),
    seedColor: Color(0xFF0288D1),
  );

  static const ThemePreset sakuraPink = ThemePreset(
    name: '樱花粉',
    primaryColor: Color(0xFFD81B60),
    accentColor: Color(0xFFF8BBD0),
    seedColor: Color(0xFFEC407A),
  );

  static const ThemePreset twilightPurple = ThemePreset(
    name: '暮光紫',
    primaryColor: Color(0xFF6A1B9A),
    accentColor: Color(0xFFD1C4E9),
    seedColor: Color(0xFF7E57C2),
  );

  static const ThemePreset sunriseOrange = ThemePreset(
    name: '日出橙',
    primaryColor: Color(0xFFEF6C00),
    accentColor: Color(0xFFFFCC80),
    seedColor: Color(0xFFFF8F00),
  );

  static const ThemePreset minimalistGray = ThemePreset(
    name: '极简灰',
    primaryColor: Color(0xFF546E7A),
    accentColor: Color(0xFFCFD8DC),
    seedColor: Color(0xFF607D8B),
  );

  static const List<ThemePreset> all = [
    forestGreen,
    oceanBlue,
    sakuraPink,
    twilightPurple,
    sunriseOrange,
    minimalistGray,
  ];

  static const ThemePreset defaultPreset = forestGreen;

  static ThemePreset byName(String? name) {
    for (final preset in all) {
      if (preset.name == name) {
        return preset;
      }
    }
    return defaultPreset;
  }
}
