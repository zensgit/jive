import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/quick_action_model.dart';
import 'package:jive/core/service/quick_action_filter_service.dart';

void main() {
  group('QuickActionFilterService', () {
    test('empty query returns original order', () {
      final actions = [
        _action(id: 'template:1', name: '早餐'),
        _action(id: 'template:2', name: '午餐'),
        _action(id: 'template:3', name: '咖啡'),
      ];

      final filtered = QuickActionFilterService.filterRecords(actions, '  ');

      expect(filtered.map((action) => action.stableId), [
        'template:1',
        'template:2',
        'template:3',
      ]);
    });

    test('matches name with trimmed case-insensitive query', () {
      final actions = [
        _action(id: 'manual:1', name: 'Coffee Run'),
        _action(id: 'template:2', name: '午餐'),
      ];

      final filtered = QuickActionFilterService.filterRecords(
        actions,
        '  coffee  ',
      );

      expect(filtered.map((action) => action.stableId), ['manual:1']);
    });

    test('matches category path and note', () {
      final actions = [
        _action(
          id: 'template:1',
          name: '通勤',
          categoryName: '出行',
          subCategoryName: '地铁',
          note: '早高峰',
        ),
        _action(id: 'template:2', name: '咖啡', categoryName: '餐饮'),
      ];

      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '地铁',
        ).map((action) => action.stableId),
        ['template:1'],
      );
      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '早高峰',
        ).map((action) => action.stableId),
        ['template:1'],
      );
    });

    test('matches amount aliases', () {
      final actions = [
        _action(id: 'template:1', name: '早餐', amount: 15),
        _action(id: 'template:2', name: '晚餐', amount: 58.5),
      ];

      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '15.00',
        ).map((action) => action.stableId),
        ['template:1'],
      );
      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '58.50',
        ).map((action) => action.stableId),
        ['template:2'],
      );
    });

    test('matches Chinese type, mode, and visibility labels', () {
      final actions = [
        _action(id: 'template:1', name: '工资', type: 'income', mode: 'direct'),
        _action(
          id: 'template:2',
          name: '午餐',
          mode: 'confirm',
          showOnHome: false,
        ),
        _action(
          id: 'template:3',
          name: '信用卡还款',
          type: 'transfer',
          mode: 'edit',
          isPinned: true,
        ),
      ];

      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '收入',
        ).map((action) => action.stableId),
        ['template:1'],
      );
      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '轻确认 隐藏',
        ).map((action) => action.stableId),
        ['template:2'],
      );
      expect(
        QuickActionFilterService.filterRecords(
          actions,
          '转账 编辑器 置顶',
        ).map((action) => action.stableId),
        ['template:3'],
      );
    });

    test('uses multi-token AND matching', () {
      final actions = [
        _action(
          id: 'template:1',
          name: '拿铁',
          categoryName: '餐饮',
          subCategoryName: '咖啡',
        ),
        _action(id: 'template:2', name: '午餐', categoryName: '餐饮'),
        _action(id: 'template:3', name: '咖啡豆', categoryName: '购物'),
      ];

      final filtered = QuickActionFilterService.filterRecords(actions, '咖啡 餐饮');

      expect(filtered.map((action) => action.stableId), ['template:1']);
    });
  });
}

JiveQuickAction _action({
  required String id,
  required String name,
  String source = 'template',
  String type = 'expense',
  String mode = 'direct',
  String? categoryName,
  String? subCategoryName,
  String? note,
  double? amount,
  bool showOnHome = true,
  bool isPinned = false,
}) {
  return JiveQuickAction()
    ..stableId = id
    ..source = source
    ..name = name
    ..transactionType = type
    ..mode = mode
    ..categoryName = categoryName
    ..subCategoryName = subCategoryName
    ..defaultNote = note
    ..defaultAmount = amount
    ..showOnHome = showOnHome
    ..isPinned = isPinned
    ..sortOrder = 0
    ..usageCount = 0
    ..createdAt = DateTime(2026, 5, 6)
    ..updatedAt = DateTime(2026, 5, 6);
}
