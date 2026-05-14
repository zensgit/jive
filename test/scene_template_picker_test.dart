import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/data/scene_templates.dart';
import 'package:jive/feature/onboarding/scene_template_picker.dart';

void main() {
  testWidgets('enables apply after selecting a scene template', (tester) async {
    SceneTemplate? appliedTemplate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SceneTemplatePicker(
            onApply: (template) => appliedTemplate = template,
          ),
        ),
      ),
    );

    final applyButton = find.widgetWithText(FilledButton, '应用场景');
    expect(tester.widget<FilledButton>(applyButton).onPressed, isNull);

    await tester.tap(find.text('旅行出差'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(applyButton).onPressed, isNotNull);

    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(appliedTemplate?.id, 'travel');
    expect(appliedTemplate?.tagKeys, contains('旅行'));
  });
}
