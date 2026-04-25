import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/feature/category/category_picker_screen.dart';
import 'package:jive/feature/category/category_search_delegate.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupGoogleFontsForTests();
  });

  test(
    'user-only category picker keeps custom children under system parents',
    () {
      final now = DateTime(2026, 4, 22);
      final parent = JiveCategory()
        ..key = 'system_food'
        ..name = '餐饮'
        ..iconName = 'restaurant'
        ..order = 0
        ..isSystem = true
        ..isHidden = true
        ..isIncome = false
        ..updatedAt = now;
      final customChild = JiveCategory()
        ..key = 'custom_coffee'
        ..name = '自制咖啡'
        ..iconName = 'local_cafe'
        ..parentKey = parent.key
        ..order = 0
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = now;
      final systemChild = JiveCategory()
        ..key = 'system_lunch'
        ..name = '系统午餐'
        ..iconName = 'lunch_dining'
        ..parentKey = parent.key
        ..order = 1
        ..isSystem = true
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = now;

      final data = buildCategoryPickerData(
        [parent, customChild, systemChild],
        isIncome: false,
        onlyUserCategories: true,
      );

      expect(data.parents.map((cat) => cat.name), contains('餐饮'));
      expect(data.expandedParents, contains(parent.key));
      expect(data.items.map((item) => item.primaryName), contains('自制咖啡'));
      expect(data.items.map((item) => item.primaryName), isNot(contains('餐饮')));
      expect(
        data.items.map((item) => item.primaryName),
        isNot(contains('系统午餐')),
      );
    },
  );

  testWidgets(
    'user-only category picker treats hidden system parent as a group only',
    (tester) async {
      final now = DateTime(2026, 4, 22);
      final parent = JiveCategory()
        ..key = 'system_food'
        ..name = '餐饮'
        ..iconName = 'restaurant'
        ..order = 0
        ..isSystem = true
        ..isHidden = true
        ..isIncome = false
        ..updatedAt = now;
      final customChild = JiveCategory()
        ..key = 'custom_coffee'
        ..name = '自制咖啡'
        ..iconName = 'local_cafe'
        ..parentKey = parent.key
        ..order = 0
        ..isSystem = false
        ..isHidden = false
        ..isIncome = false
        ..updatedAt = now;
      final pickerData = buildCategoryPickerData(
        [parent, customChild],
        isIncome: false,
        onlyUserCategories: true,
      );

      CategorySearchResult? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await Navigator.push<CategorySearchResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryPickerScreen(
                      isIncome: false,
                      onlyUserCategories: true,
                      initialData: pickerData,
                    ),
                  ),
                );
              },
              child: const Text('open picker'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open picker'));
      await _pumpUntilFound(tester, find.text('自制咖啡'));
      expect(find.text('餐饮'), findsOneWidget);
      expect(picked, isNull);

      await tester.tap(find.text('餐饮'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('选择分类'), findsOneWidget);
      expect(find.text('自制咖啡'), findsNothing);
      expect(picked, isNull);

      await tester.tap(find.text('餐饮'));
      await _pumpUntilFound(tester, find.text('自制咖啡'));
      await tester.tap(find.text('自制咖啡'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(picked?.parent.name, '餐饮');
      expect(picked?.sub?.name, '自制咖啡');
      expect(find.text('open picker'), findsOneWidget);
    },
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
