import 'package:flutter_test/flutter_test.dart';

import 'package:jive/feature/quick_entry/quick_action_deep_link_service.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';

void main() {
  group('QuickActionDeepLinkService entry contracts', () {
    test('parses quick action ids from query or path', () {
      final queryRequest = QuickActionDeepLinkService.parse(
        Uri.parse('jive://quick-action?id=template:42'),
      );
      final pathRequest = QuickActionDeepLinkService.parse(
        Uri.parse('jive://quick-action/template%3A99'),
      );

      expect(queryRequest?.isQuickAction, isTrue);
      expect(queryRequest?.quickActionId, 'template:42');
      expect(pathRequest?.isQuickAction, isTrue);
      expect(pathRequest?.quickActionId, 'template:99');
      expect(QuickActionDeepLinkService.legacyTemplateId('template:42'), 42);
    });

    test('keeps complete expense links free of missing-field highlights', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?type=expense&amount=28.5'
          '&accountId=3&bookId=7&categoryKey=food&subCategoryKey=lunch'
          '&tags=work, lunch&date=2026-05-10T12:30:00&note=Client%20meal',
        ),
      );
      final params = request?.transactionParams;

      expect(request?.isTransaction, isTrue);
      expect(params?.source, TransactionEntrySource.deepLink);
      expect(params?.sourceBannerText, '来自外部链接');
      expect(params?.submitButtonLabel, '确认入账');
      expect(params?.prefillAmount, 28.5);
      expect(params?.prefillType, 'expense');
      expect(params?.prefillAccountId, 3);
      expect(params?.prefillBookId, 7);
      expect(params?.prefillCategoryKey, 'food');
      expect(params?.prefillSubCategoryKey, 'lunch');
      expect(params?.prefillTagKeys, ['work', 'lunch']);
      expect(params?.prefillDate, DateTime(2026, 5, 10, 12, 30));
      expect(params?.prefillNote, 'Client meal');
      expect(params?.highlightFields, isEmpty);
    });

    test(
      'routes incomplete transfer links to editor with target highlight',
      () {
        final request = QuickActionDeepLinkService.parse(
          Uri.parse(
            'jive://transaction/new?type=transfer&amount=500&accountId=1'
            '&categoryKey=ignored',
          ),
        );
        final params = request?.transactionParams;

        expect(params?.prefillType, 'transfer');
        expect(params?.prefillAmount, 500);
        expect(params?.prefillAccountId, 1);
        expect(params?.prefillToAccountId, isNull);
        expect(
          params?.highlightFields,
          contains(TransactionHighlightField.transferAccount),
        );
        expect(
          params?.highlightFields,
          isNot(contains(TransactionHighlightField.category)),
        );
        expect(
          params?.highlightFields,
          isNot(contains(TransactionHighlightField.amount)),
        );
        expect(
          params?.highlightFields,
          isNot(contains(TransactionHighlightField.account)),
        );
      },
    );

    test('keeps raw share text as note when parsing is incomplete', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?entrySource=shareReceive'
          '&rawText=%E5%8D%88%E9%A4%90%E5%BE%85%E8%A1%A5%E5%85%85',
        ),
      );
      final params = request?.transactionParams;

      expect(params?.source, TransactionEntrySource.shareReceive);
      expect(params?.sourceBannerText, '来自分享接收');
      expect(params?.prefillAmount, isNull);
      expect(params?.prefillNote, '午餐待补充');
      expect(params?.prefillRawText, '午餐待补充');
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.amount),
      );
    });

    test(
      'parses scene switch links by id, key, name, or all-scenes target',
      () {
        final byId = QuickActionDeepLinkService.parse(
          Uri.parse('jive://scene/switch?bookId=7'),
        );
        final byKey = QuickActionDeepLinkService.parse(
          Uri.parse('jive://scene/switch?bookKey=travel_book'),
        );
        final byName = QuickActionDeepLinkService.parse(
          Uri.parse('jive://scene/switch?name=%E6%97%85%E8%A1%8C'),
        );
        final allScenes = QuickActionDeepLinkService.parse(
          Uri.parse('jive://scene/switch?all=true'),
        );

        expect(byId?.isSceneSwitch, isTrue);
        expect(byId?.sceneBookId, 7);
        expect(byKey?.isSceneSwitch, isTrue);
        expect(byKey?.sceneBookKey, 'travel_book');
        expect(byName?.isSceneSwitch, isTrue);
        expect(byName?.sceneName, '旅行');
        expect(allScenes?.isSceneSwitch, isTrue);
        expect(allScenes?.switchToAllScenes, isTrue);
      },
    );

    test('ignores incomplete scene switch links without a target', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse('jive://scene/switch'),
      );

      expect(request, isNull);
    });
  });
}
