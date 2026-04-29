import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/template_model.dart';
import 'package:jive/core/model/quick_action.dart';
import 'package:jive/core/service/account_group_service.dart';
import 'package:jive/core/service/category_path_service.dart';
import 'package:jive/core/service/conversational_parser.dart';
import 'package:jive/core/service/object_share_policy_service.dart';
import 'package:jive/core/service/quick_action_service.dart';
import 'package:jive/feature/quick_entry/quick_action_deep_link_service.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';

void main() {
  group('QuickActionService', () {
    test('infers direct action when amount, account, and category exist', () {
      final template = _template(amount: 15, accountId: 1, categoryKey: 'food');

      final action = QuickActionService.toQuickAction(template);

      expect(action.mode, QuickActionMode.direct);
      expect(action.defaultAmount, 15);
      expect(action.accountId, 1);
      expect(action.categoryKey, 'food');
    });

    test('infers confirm when only amount is missing', () {
      final template = _template(accountId: 1, categoryKey: 'food');

      final action = QuickActionService.toQuickAction(template);

      expect(action.mode, QuickActionMode.confirm);
      expect(QuickActionService.missingFields(action), contains('amount'));
    });

    test('keeps transfer actions in edit mode for safer completion', () {
      final template = _template(
        type: 'transfer',
        amount: 100,
        accountId: 1,
        toAccountId: 2,
      );

      final action = QuickActionService.toQuickAction(template);

      expect(action.mode, QuickActionMode.edit);
    });
  });

  group('TransactionEntryParams', () {
    test('tracks source banner and missing-field highlights', () {
      const params = TransactionEntryParams(
        source: TransactionEntrySource.quickAction,
        sourceLabel: '来自快速动作「午餐」',
        highlightFields: [
          TransactionHighlightField.amount,
          TransactionHighlightField.category,
        ],
      );

      expect(params.sourceBannerText, '来自快速动作「午餐」');
      expect(params.shouldHighlight(TransactionHighlightField.amount), isTrue);
      expect(
        params.shouldHighlight(TransactionHighlightField.account),
        isFalse,
      );
    });
  });

  group('CategoryPathService', () {
    test('resolves three-level category paths and compatible tx keys', () {
      final categories = [
        _category(key: 'transport', name: '出行'),
        _category(key: 'car', name: '私家车', parentKey: 'transport'),
        _category(key: 'fuel', name: '加油', parentKey: 'car'),
      ];

      final service = const CategoryPathService();
      final path = service.resolve(categories, subCategoryKey: 'fuel');
      final txKeys = service.toTransactionKeys(categories, categories.last);

      expect(path.displayName, '出行 / 私家车 / 加油');
      expect(txKeys.categoryKey, 'transport');
      expect(txKeys.subCategoryKey, 'fuel');
      expect(txKeys.categoryName, '出行');
      expect(txKeys.subCategoryName, '加油');
    });

    test('keeps two-level legacy categories working', () {
      final categories = [
        _category(key: 'food', name: '餐饮'),
        _category(key: 'lunch', name: '午餐', parentKey: 'food'),
      ];

      final path = const CategoryPathService().resolve(
        categories,
        categoryKey: 'food',
        subCategoryKey: 'lunch',
      );

      expect(path.displayName, '餐饮 / 午餐');
    });
  });

  group('QuickActionDeepLinkService', () {
    test('parses template quick action links', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse('jive://quick-action?id=template:42'),
      );

      expect(request?.isQuickAction, isTrue);
      expect(request?.quickActionId, 'template:42');
      expect(QuickActionDeepLinkService.legacyTemplateId('template:42'), 42);
    });

    test('parses transaction links and highlights missing fields', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?type=expense&amount=12.5&note=Coffee&bookId=7&raw=Coffee%20receipt',
        ),
      );

      final params = request?.transactionParams;
      expect(params?.source, TransactionEntrySource.deepLink);
      expect(params?.prefillAmount, 12.5);
      expect(params?.prefillNote, 'Coffee');
      expect(params?.prefillBookId, 7);
      expect(params?.prefillRawText, 'Coffee receipt');
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.account),
      );
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.category),
      );
      expect(
        params?.highlightFields,
        isNot(contains(TransactionHighlightField.amount)),
      );
    });
  });

  group('ConversationalParser', () {
    test('keeps item-level raw text for multi-transaction input', () {
      final result = ConversationalParser().parseConversation(
        '买了咖啡30和面包15',
        now: DateTime(2026, 4, 26, 12),
      );

      expect(result.transactions, hasLength(2));
      expect(result.transactions[0].rawText, contains('咖啡30'));
      expect(result.transactions[1].rawText, contains('面包15'));
      expect(result.transactions[0].rawText, isNot(result.rawText));
      expect(result.transactions[1].rawText, isNot(result.rawText));
    });
  });

  group('AccountGroupService', () {
    test(
      'groups subaccounts by groupName without changing account identity',
      () {
        final accounts = [
          _account(id: 1, name: '活期', groupName: '中国银行', currency: 'CNY'),
          _account(id: 2, name: '定期', groupName: '中国银行', currency: 'USD'),
          _account(id: 3, name: '微信钱包', currency: 'CNY'),
        ];

        final groups = const AccountGroupService().groupAccounts(accounts);

        expect(groups.map((g) => g.name), ['中国银行', '微信钱包']);
        expect(groups.first.accounts.map((a) => a.id), [1, 2]);
        expect(groups.first.currencies, {'CNY', 'USD'});
      },
    );

    test('does not treat broad legacy group names as subaccount groups', () {
      final accounts = [
        _account(id: 1, name: '现金', groupName: '资金账户'),
        _account(id: 2, name: '微信钱包', groupName: '资金账户'),
      ];

      final groups = const AccountGroupService().groupAccounts(accounts);

      expect(groups.map((g) => g.name), ['现金', '微信钱包']);
      expect(groups.every((g) => g.isSingleAccount), isTrue);
    });
  });

  group('ObjectSharePolicyService', () {
    test('labels objects in shared books as inherited from scene', () {
      final book = JiveBook()
        ..key = 'book_family'
        ..name = '家庭'
        ..currency = 'CNY'
        ..order = 0
        ..isDefault = false
        ..isArchived = false
        ..isShared = true
        ..memberCount = 2
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026);

      final policy = const ObjectSharePolicyService().evaluate(
        book: book,
        objectLabel: '分类',
      );

      expect(policy.visibility, ObjectShareVisibility.inheritedFromScene);
      expect(policy.label, '继承场景共享');
      expect(policy.warning, contains('同步给场景成员'));
    });

    test('uses shared scope in deletion warnings', () {
      final warning = const ObjectSharePolicyService().deletionWarning(
        objectLabel: '加油',
        affectedTransactionCount: 3,
        shared: true,
      );

      expect(warning, contains('共享成员'));
      expect(warning, contains('3 笔交易'));
    });
  });
}

JiveTemplate _template({
  String type = 'expense',
  double amount = 0,
  int? accountId,
  int? toAccountId,
  String? categoryKey,
}) {
  return JiveTemplate()
    ..name = '午餐'
    ..type = type
    ..amount = amount
    ..accountId = accountId
    ..toAccountId = toAccountId
    ..categoryKey = categoryKey
    ..category = categoryKey
    ..createdAt = DateTime(2026);
}

JiveCategory _category({
  required String key,
  required String name,
  String? parentKey,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..iconName = 'category'
    ..parentKey = parentKey
    ..order = 0
    ..isSystem = false
    ..isHidden = false
    ..isIncome = false
    ..updatedAt = DateTime(2026);
}

JiveAccount _account({
  required int id,
  required String name,
  String? groupName,
  String currency = 'CNY',
}) {
  return JiveAccount()
    ..id = id
    ..key = 'account_$id'
    ..name = name
    ..type = 'asset'
    ..groupName = groupName
    ..currency = currency
    ..iconName = 'wallet'
    ..order = id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..updatedAt = DateTime(2026);
}
