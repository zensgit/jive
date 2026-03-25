import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JiveTheme {
  static const Color primaryGreen = Color(0xFF2E7D32); // 森林绿
  static const Color accentLime = Color(0xFFDCE775);   // 嫩芽黄
  static const Color surfaceWhite = Color(0xFFF5F7FA); // 灰白背景
  static const Color cardWhite = Colors.white;
  static const Color categoryIconInactive = Color(0xFF202020);
  static const Color categoryLabelInactive = Color(0xFF8E8E8E);
  static const Color categoryIconInactiveBackground = Color(0xFFF5F5F5);
  static const Color categoryIconInactiveBorder = Color(0xFFBDBDBD);

  // 深色模式专用颜色
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkDivider = Color(0xFF2D2D2D);

  static ThemeData get lightTheme {
    return buildTheme(
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      accentColor: accentLime,
      seedColor: primaryGreen,
    );
  }

  static ThemeData get darkTheme {
    return buildTheme(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      accentColor: accentLime,
      seedColor: primaryGreen,
    );
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color accentColor,
    required Color seedColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? darkSurface : surfaceWhite;
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: baseColorScheme.copyWith(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
      ),
      textTheme: isDark
          ? GoogleFonts.latoTextTheme(ThemeData.dark().textTheme)
          : GoogleFonts.latoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkCard : cardWhite,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? darkDivider : Colors.grey.shade200,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkCard : cardWhite,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkCard : cardWhite,
      ),
    );
  }

  /// 获取适合当前主题的卡片背景色
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : cardWhite;
  }

  /// 获取适合当前主题的表面颜色
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surfaceWhite;
  }

  /// 获取适合当前主题的文本颜色
  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// 获取适合当前主题的次要文本颜色
  static Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade600;
  }

  /// 获取适合当前主题的分割线颜色
  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : Colors.grey.shade200;
  }

  /// 检查当前是否为深色模式
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
