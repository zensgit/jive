import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/model/quick_action.dart';
import 'package:jive/core/service/quick_action_service.dart';
import 'package:jive/feature/quick_entry/quick_action_executor.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';

void main() {
  group('QuickActionExecutor.paramsFor', () {
    test('preserves quick action editor prefill fields', () {
      final action = QuickAction(
        id: 'template:42',
        name: '午餐',
        transactionType: 'expense',
        bookId: 7,
        accountId: 3,
        categoryKey: 'food',
        subCategoryKey: 'lunch',
        tagKeys: const ['tag_workday', 'tag_lunch'],
        defaultAmount: 35,
        defaultNote: '公司楼下',
        mode: QuickActionMode.edit,
      );

      final params = QuickActionExecutor.paramsFor(action);

      expect(params.source, TransactionEntrySource.quickAction);
      expect(params.sourceBannerText, '来自快速动作「午餐」');
      expect(params.quickActionId, 'template:42');
      expect(params.prefillAmount, 35);
      expect(params.prefillType, 'expense');
      expect(params.prefillBookId, 7);
      expect(params.prefillAccountId, 3);
      expect(params.prefillCategoryKey, 'food');
      expect(params.prefillSubCategoryKey, 'lunch');
      expect(params.prefillTagKeys, ['tag_workday', 'tag_lunch']);
      expect(params.prefillNote, '公司楼下');
      expect(params.highlightFields, isEmpty);
    });

    test('highlights missing transfer target account for edit fallback', () {
      final action = QuickAction(
        id: 'template:99',
        name: '信用卡还款',
        transactionType: 'transfer',
        bookId: 8,
        accountId: 1,
        toAccountId: null,
        defaultAmount: 1000,
        defaultNote: '还款',
        mode: QuickActionMode.edit,
      );

      final params = QuickActionExecutor.paramsFor(action);

      expect(params.prefillBookId, 8);
      expect(params.prefillType, 'transfer');
      expect(params.prefillAccountId, 1);
      expect(params.prefillToAccountId, isNull);
      expect(
        params.highlightFields,
        contains(QuickActionService.fieldTransferAccount),
      );
      expect(
        params.shouldHighlight(TransactionHighlightField.transferAccount),
        isTrue,
      );
      expect(params.shouldHighlight(TransactionHighlightField.amount), isFalse);
    });

    test(
      'highlights missing amount account and category for incomplete actions',
      () {
        final action = QuickAction(
          id: 'template:100',
          name: '待补充',
          transactionType: 'expense',
          mode: QuickActionMode.edit,
        );

        final params = QuickActionExecutor.paramsFor(action);

        expect(params.prefillType, 'expense');
        expect(
          params.highlightFields,
          containsAll([
            QuickActionService.fieldAmount,
            QuickActionService.fieldAccount,
            QuickActionService.fieldCategory,
          ]),
        );
        expect(
          params.shouldHighlight(TransactionHighlightField.amount),
          isTrue,
        );
        expect(
          params.shouldHighlight(TransactionHighlightField.account),
          isTrue,
        );
        expect(
          params.shouldHighlight(TransactionHighlightField.category),
          isTrue,
        );
      },
    );
  });
}
