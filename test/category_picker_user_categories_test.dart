import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/feature/category/category_picker_screen.dart';

void main() {
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
}
