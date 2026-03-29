import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app/jive_app.dart';
import 'core/service/category_icon_style.dart';
import 'core/utils/logger_util.dart';
import 'feature/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await JiveLogger.init();
  final iconStyle = await CategoryIconStyleStore.load();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  CategoryIconStyleConfig.current = iconStyle;
  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const JiveApp(),
    ),
  );
}
