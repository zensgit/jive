import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/settings/speech_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Speech settings screen loads and persists user preferences', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'speech_enabled': true,
      'speech_online_enhance': true,
      'speech_locale': 'zh-CN',
    });

    await tester.pumpWidget(
      const MaterialApp(home: SpeechSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('语音设置'), findsOneWidget);
    expect(find.text('启用语音记账'), findsOneWidget);
    expect(find.text('讯飞增强'), findsOneWidget);
    expect(find.textContaining('今日线上识别'), findsOneWidget);

    await tester.tap(find.text('启用语音记账'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('粤语'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('speech_enabled'), isFalse);
    expect(prefs.getString('speech_locale'), equals('yue'));
  });
}
