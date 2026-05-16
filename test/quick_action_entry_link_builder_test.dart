import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/quick_entry/quick_action_deep_link_service.dart';
import 'package:jive/feature/quick_entry/quick_action_entry_link_builder.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';

void main() {
  group('QuickActionEntryLinkBuilder', () {
    test('builds encoded template quick action links', () {
      final uri = QuickActionEntryLinkBuilder.templateQuickAction(42);
      final request = QuickActionDeepLinkService.parse(uri);

      expect(uri.toString(), 'jive://quick-action?id=template%3A42');
      expect(request?.isQuickAction, isTrue);
      expect(request?.quickActionId, 'template:42');
      expect(QuickActionDeepLinkService.legacyTemplateId('template:42'), 42);
    });

    test(
      'round-trips transaction params without hand-written query strings',
      () {
        final date = DateTime(2026, 5, 12, 9, 30);
        final uri = QuickActionEntryLinkBuilder.transaction(
          TransactionEntryParams(
            source: TransactionEntrySource.deepLink,
            prefillType: 'expense',
            prefillAmount: 12.5,
            prefillAccountId: 7,
            prefillBookId: 3,
            prefillCategoryKey: 'food',
            prefillSubCategoryKey: 'coffee',
            prefillNote: '拿铁',
            prefillRawText: '星巴克 拿铁 12.5',
            prefillTagKeys: const ['work', 'coffee'],
            prefillDate: date,
            sourceLabel: '外部快捷入口',
          ),
        );

        final params = QuickActionDeepLinkService.parse(uri)?.transactionParams;

        expect(uri.host, 'transaction');
        expect(uri.path, '/new');
        expect(params?.source, TransactionEntrySource.deepLink);
        expect(params?.sourceLabel, '外部快捷入口');
        expect(params?.prefillType, 'expense');
        expect(params?.prefillAmount, 12.5);
        expect(params?.prefillAccountId, 7);
        expect(params?.prefillBookId, 3);
        expect(params?.prefillCategoryKey, 'food');
        expect(params?.prefillSubCategoryKey, 'coffee');
        expect(params?.prefillNote, '拿铁');
        expect(params?.prefillRawText, '星巴克 拿铁 12.5');
        expect(params?.prefillTagKeys, ['work', 'coffee']);
        expect(params?.prefillDate, date);
        expect(params?.highlightFields, isEmpty);
      },
    );

    test('keeps share receive raw text encoded and parseable', () {
      final uri = QuickActionEntryLinkBuilder.transaction(
        const TransactionEntryParams(
          source: TransactionEntrySource.shareReceive,
          sourceLabel: '系统分享',
          prefillRawText: '微信支付：咖啡 18 元',
        ),
      );

      final params = QuickActionDeepLinkService.parse(uri)?.transactionParams;

      expect(uri.queryParameters['entrySource'], 'shareReceive');
      expect(uri.queryParameters['rawText'], '微信支付：咖啡 18 元');
      expect(params?.source, TransactionEntrySource.shareReceive);
      expect(params?.sourceLabel, '系统分享');
      expect(params?.prefillRawText, '微信支付：咖啡 18 元');
      expect(params?.prefillNote, '微信支付：咖啡');
      expect(params?.prefillAmount, 18);
      expect(
        params?.highlightFields,
        containsAll([
          TransactionHighlightField.account,
          TransactionHighlightField.category,
        ]),
      );
    });

    test(
      'omits empty optional fields instead of generating blank query values',
      () {
        final uri = QuickActionEntryLinkBuilder.transaction(
          const TransactionEntryParams(
            prefillType: 'expense',
            prefillAmount: 0,
            prefillNote: '  ',
            prefillRawText: '',
            prefillTagKeys: ['', '  '],
          ),
        );

        expect(uri.queryParameters.containsKey('note'), isFalse);
        expect(uri.queryParameters.containsKey('rawText'), isFalse);
        expect(uri.queryParameters.containsKey('tagKeys'), isFalse);
        expect(uri.queryParameters['type'], 'expense');
        expect(uri.queryParameters['amount'], '0');
      },
    );

    test('builds parseable scene switch links', () {
      final byId = QuickActionEntryLinkBuilder.sceneSwitch(bookId: 7);
      final byKey = QuickActionEntryLinkBuilder.sceneSwitch(
        bookKey: 'travel_book',
      );
      final byName = QuickActionEntryLinkBuilder.sceneSwitch(sceneName: '旅行');
      final allScenes = QuickActionEntryLinkBuilder.sceneSwitch();

      expect(byId.toString(), 'jive://scene/switch?bookId=7');
      expect(QuickActionDeepLinkService.parse(byId)?.sceneBookId, 7);
      expect(
        QuickActionDeepLinkService.parse(byKey)?.sceneBookKey,
        'travel_book',
      );
      expect(QuickActionDeepLinkService.parse(byName)?.sceneName, '旅行');
      expect(
        QuickActionDeepLinkService.parse(allScenes)?.switchToAllScenes,
        isTrue,
      );
    });
  });
}
