// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import 'package:jive/core/design_system/theme.dart';

void main() {
  setUpAll(() async => setupGoogleFontsForTests());

  testWidgets('Jive theme smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Jive'),
      ),
    );
    expect(find.text('Jive'), findsOneWidget);
    expect(JiveTheme.lightTheme.brightness, equals(Brightness.light));
  });
}
