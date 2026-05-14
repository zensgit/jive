import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/design_system/category_grid_picker.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupGoogleFontsForTests();
  });

  testWidgets(
    'grid picker exposes three-level descendants and saves top plus leaf keys',
    (tester) async {
      String? pickedCategoryKey;
      String? pickedSubCategoryKey;

      await tester.pumpWidget(
        _wrapPicker(
          categories: _threeLevelCategories(),
          onCategorySelected: (categoryKey, subCategoryKey) {
            pickedCategoryKey = categoryKey;
            pickedSubCategoryKey = subCategoryKey;
          },
        ),
      );

      expect(find.text('出行'), findsOneWidget);
      expect(find.text('私家车'), findsOneWidget);
      expect(find.text('私家车 / 加油'), findsOneWidget);
      expect(find.text('属于出行'), findsOneWidget);

      await tester.tap(find.text('私家车 / 加油'));
      await tester.pump();

      expect(pickedCategoryKey, 'transport');
      expect(pickedSubCategoryKey, 'fuel');
    },
  );

  testWidgets(
    'list mode keeps middle-level categories selectable without migrations',
    (tester) async {
      String? pickedCategoryKey;
      String? pickedSubCategoryKey;

      await tester.pumpWidget(
        _wrapPicker(
          categories: _threeLevelCategories(),
          initialGridMode: false,
          onCategorySelected: (categoryKey, subCategoryKey) {
            pickedCategoryKey = categoryKey;
            pickedSubCategoryKey = subCategoryKey;
          },
        ),
      );

      await tester.tap(find.text('私家车'));
      await tester.pump();

      expect(pickedCategoryKey, 'transport');
      expect(pickedSubCategoryKey, 'car');
    },
  );
}

Widget _wrapPicker({
  required List<JiveCategory> categories,
  required void Function(String categoryKey, String? subCategoryKey)
  onCategorySelected,
  bool initialGridMode = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 520,
        child: CategoryGridPicker(
          categories: categories,
          initialGridMode: initialGridMode,
          onCategorySelected: onCategorySelected,
        ),
      ),
    ),
  );
}

List<JiveCategory> _threeLevelCategories() {
  final now = DateTime(2026, 5, 11);
  return [
    _category(
      key: 'transport',
      name: '出行',
      iconName: 'directions_car',
      order: 0,
      updatedAt: now,
    ),
    _category(
      key: 'car',
      name: '私家车',
      iconName: 'directions_car_filled',
      parentKey: 'transport',
      order: 0,
      updatedAt: now,
    ),
    _category(
      key: 'fuel',
      name: '加油',
      iconName: 'local_gas_station',
      parentKey: 'car',
      order: 0,
      updatedAt: now,
    ),
  ];
}

JiveCategory _category({
  required String key,
  required String name,
  required String iconName,
  required int order,
  required DateTime updatedAt,
  String? parentKey,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..iconName = iconName
    ..parentKey = parentKey
    ..order = order
    ..isIncome = false
    ..isSystem = false
    ..isHidden = false
    ..updatedAt = updatedAt;
}
