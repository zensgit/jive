import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import 'package:jive/feature/transactions/note_field_with_chips.dart';

void main() {
  setUpAll(() async => setupGoogleFontsForTests());

  testWidgets('note chips toggle text and selection state', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final selectedTags = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFieldWithChips(
            controller: controller,
            isLandscape: false,
            suggestions: const ['早餐', '午餐'],
            onTagSelected: selectedTags.add,
          ),
        ),
      ),
    );

    expect(controller.text, isEmpty);
    expect(selectedTags, isEmpty);

    await tester.tap(find.text('早餐'));
    await tester.pump();

    expect(controller.text, '早餐');
    expect(selectedTags, ['早餐']);
    var chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '早餐'));
    expect(chip.selected, isTrue);

    await tester.tap(find.text('午餐'));
    await tester.pump();

    expect(controller.text, '早餐 午餐');
    expect(selectedTags, ['早餐', '午餐']);
    chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '午餐'));
    expect(chip.selected, isTrue);

    await tester.tap(find.text('早餐'));
    await tester.pump();

    expect(controller.text, '午餐');
    expect(selectedTags, ['早餐', '午餐']);
    chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '早餐'));
    expect(chip.selected, isFalse);
  });
}
