import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JiveTheme {
  static const Color primaryGreen = Color(0xFF2E7D32); // 森林绿
  static const Color accentLime = Color(0xFFDCE775);   // 嫩芽黄
  static const Color surfaceWhite = Color(0xFFF5F7FA); // 灰白背景
  static const Color cardWhite = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentLime,
        surface: surfaceWhite,
      ),
      textTheme: GoogleFonts.latoTextTheme(),
      // cardTheme removed to avoid version conflict
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(), // 圆形按钮
      ),
    );
  }
}
