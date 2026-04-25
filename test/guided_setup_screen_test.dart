import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/feature/onboarding/guided_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  late JiveCategory category;
  late List<JiveTransaction> savedTransactions;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupGoogleFontsForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    savedTransactions = [];
    category = JiveCategory()
      ..key = 'test-food'
      ..name = '餐饮'
      ..iconName = 'restaurant'
      ..order = 0
      ..isSystem = false
      ..isHidden = false
      ..isIncome = false
      ..updatedAt = DateTime(2026, 4, 22);
  });

  testWidgets(
    'guided setup advances after choosing a category and entering amount',
    (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: GuidedSetupScreen(
            initialParentCategories: [category],
            firstTransactionSaver: (transaction) async {
              savedTransactions.add(transaction);
            },
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('记一笔'), findsOneWidget);
      expect(find.text('选择分类'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '12.5');
      await tester.tap(find.text('餐饮'));
      await tester.pump(const Duration(milliseconds: 250));

      final nextButton = find.widgetWithText(ElevatedButton, '下一步');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('设分类'), findsOneWidget);
      expect(completed, isFalse);
      expect(savedTransactions, hasLength(1));
      expect(savedTransactions.single.amount, 12.5);
      expect(savedTransactions.single.category, '餐饮');
      expect(savedTransactions.single.categoryKey, 'test-food');
      expect(savedTransactions.single.type, 'expense');
    },
  );
}
