import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/service/locale_service.dart';
import 'package:jive/feature/settings/settings_screen.dart';
import 'package:jive/feature/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('free tier settings screen locks speech settings entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final entitlement = EntitlementService();
    await entitlement.init();
    await entitlement.setTier(UserTier.free);

    final themeProvider = ThemeProvider();
    final localeService = LocaleService();
    await localeService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleService>.value(value: localeService),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('语音设置'), 200);
    await tester.tap(find.text('语音设置'));
    await tester.pumpAndSettle();

    expect(find.text('此功能需要订阅版'), findsOneWidget);
  });
}
