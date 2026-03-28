import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jive/feature/category/category_icon_picker_screen.dart';

Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 250),
  int maxSteps = 30,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Category icon picker returns selected icon after confirm', (
    tester,
  ) async {
    String? selectedIconValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  selectedIconValue = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const CategoryIconPickerScreen(
                        initialIcon: 'category',
                      ),
                    ),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilSettled(tester);

    await tester.tap(find.text('Open Picker'));
    await _pumpUntilSettled(tester);

    expect(find.text('选择图标'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    final gridView = find.byType(GridView);
    expect(gridView, findsOneWidget);

    await tester.enterText(searchField, 'movie');
    await _pumpUntilSettled(tester);

    final movieEntry = find.descendant(
      of: gridView,
      matching: find.text('movie'),
    );
    expect(movieEntry, findsOneWidget);
    await tester.tap(movieEntry);
    await _pumpUntilSettled(tester);

    await tester.tap(find.byIcon(Icons.close));
    await _pumpUntilSettled(tester);
    expect(tester.widget<TextField>(searchField).controller?.text ?? '', '');

    await tester.tap(find.text('确定'));
    await _pumpUntilSettled(tester);

    expect(find.byType(CategoryIconPickerScreen), findsNothing);
    expect(selectedIconValue, 'movie');
  });
}
