import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/settings/speech_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _todayKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

Map<String, Object> _seedValues() => <String, Object>{
      'speech_enabled': true,
      'speech_online_enhance': true,
      'speech_locale': 'zh-CN',
      'voice_quota_date': _todayKey(),
      'voice_quota_online': 3,
      'voice_quota_offline': 1,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings page opens with correct sections', (tester) async {
    SharedPreferences.setMockInitialValues(_seedValues());
    await tester.pumpWidget(const MaterialApp(home: SpeechSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('语音设置'), findsOneWidget);
    expect(find.text('启用语音记账'), findsOneWidget);
    expect(find.text('引擎现状'), findsOneWidget);
    expect(find.text('讯飞增强'), findsOneWidget);
  });

  testWidgets('Enabled toggle persists to SharedPreferences', (tester) async {
    SharedPreferences.setMockInitialValues(_seedValues());
    await tester.pumpWidget(const MaterialApp(home: SpeechSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    await tester.tap(find.text('启用语音记账'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('speech_enabled'), isFalse);
  });

  testWidgets('Locale switch persists to SharedPreferences', (tester) async {
    SharedPreferences.setMockInitialValues(_seedValues());
    await tester.pumpWidget(const MaterialApp(home: SpeechSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    await tester.tap(find.text('粤语'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('speech_locale'), equals('yue'));
  });

  testWidgets('Quota section visible after scroll', (tester) async {
    SharedPreferences.setMockInitialValues(_seedValues());
    await tester.pumpWidget(const MaterialApp(home: SpeechSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Scroll down to reveal quota section below the fold
    await tester.scrollUntilVisible(
      find.textContaining('今日线上识别'),
      200,
    );
    expect(find.textContaining('今日线上识别'), findsOneWidget);
  });
}
