import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/category/category_create_screen.dart';

void main() {
  testWidgets(
    'third-level create stays opt-in and does not show batch defaults',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryCreateScreen(
            title: '添加下级分类 · 出行 / 私家车',
            parentName: '出行 / 私家车',
            initialIcon: 'directions_car',
            nameLabel: '下级分类名称',
            allowBatch: false,
            systemLibrary: {
              '出行': {
                'icon': 'directions_car',
                'children': [
                  {'name': '加油', 'icon': 'local_gas_station'},
                  {'name': '停车', 'icon': 'local_parking'},
                ],
              },
            },
          ),
        ),
      );

      expect(find.text('添加下级分类 · 出行 / 私家车'), findsOneWidget);
      expect(find.text('下级分类'), findsOneWidget);
      expect(find.text('二级分类'), findsNothing);
      expect(find.text('点击下方分类自动添加'), findsNothing);
      expect(find.text('批量添加'), findsNothing);
      expect(find.byType(TextField), findsWidgets);
    },
  );
}
