import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/database/auto_draft_model.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/category_model.dart';
import 'package:jive/core/database/template_model.dart';
import 'package:jive/core/model/quick_action.dart';
import 'package:jive/core/service/speech_intent_parser.dart';
import 'package:jive/core/service/account_group_service.dart';
import 'package:jive/core/service/category_path_service.dart';
import 'package:jive/core/service/conversational_parser.dart';
import 'package:jive/core/service/object_share_policy_service.dart';
import 'package:jive/core/service/quick_action_service.dart';
import 'package:jive/core/service/scene_candidate_service.dart';
import 'package:jive/core/data/scene_templates.dart';
import 'package:jive/feature/auto/auto_draft_entry_params_builder.dart';
import 'package:jive/feature/quick_entry/quick_action_deep_link_service.dart';
import 'package:jive/feature/transactions/speech_entry_params_builder.dart';
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

  group('AutoDraftEntryParamsBuilder', () {
    test('maps transfer drafts to editor params and preserves service fee', () {
      final draft = JiveAutoDraft()
        ..amount = 188.8
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 4, 26, 9)
        ..rawText = '微信零钱转到招商银行'
        ..type = 'transfer'
        ..category = '转账'
        ..subCategory = '转账'
        ..accountId = 1
        ..metadataJson = jsonEncode({'transferServiceCharge': 1.5})
        ..createdAt = DateTime(2026, 4, 26, 9, 1);

      final params = const AutoDraftEntryParamsBuilder().build(draft);

      expect(params.source, TransactionEntrySource.autoDraft);
      expect(params.sourceBannerText, '来自自动识别「WeChat」');
      expect(params.prefillType, 'transfer');
      expect(params.prefillAmount, 188.8);
      expect(params.prefillAccountId, 1);
      expect(params.prefillRawText, '微信零钱转到招商银行');
      expect(params.prefillExchangeFee, 1.5);
      expect(params.prefillExchangeFeeType, 'fixed');
      expect(
        params.highlightFields,
        contains(TransactionHighlightField.transferAccount),
      );
      expect(
        params.highlightFields,
        isNot(contains(TransactionHighlightField.category)),
      );
    });

    test('maps category names as fallback when category keys are missing', () {
      final draft = JiveAutoDraft()
        ..amount = 15
        ..source = 'Alipay'
        ..timestamp = DateTime(2026, 4, 26, 12)
        ..rawText = '午餐 15 元'
        ..type = 'expense'
        ..category = '餐饮'
        ..subCategory = '午餐'
        ..accountId = 2
        ..tagKeys = ['tag_lunch']
        ..createdAt = DateTime(2026, 4, 26, 12, 1);

      final params = const AutoDraftEntryParamsBuilder().build(draft);

      expect(params.prefillType, 'expense');
      expect(params.prefillCategoryKey, '餐饮');
      expect(params.prefillSubCategoryKey, '午餐');
      expect(params.prefillAccountId, 2);
      expect(params.prefillTagKeys, ['tag_lunch']);
      expect(params.highlightFields, isEmpty);
    });

    test('infers income drafts from shared auto draft type hints', () {
      final draft = JiveAutoDraft()
        ..amount = 88
        ..source = 'WeChat'
        ..timestamp = DateTime(2026, 4, 26, 18)
        ..rawText = '微信已收款 88 元'
        ..category = '收入'
        ..subCategory = '收款'
        ..accountId = 3
        ..createdAt = DateTime(2026, 4, 26, 18, 1);

      final params = const AutoDraftEntryParamsBuilder().build(draft);

      expect(params.prefillType, 'income');
      expect(params.prefillCategoryKey, '收入');
      expect(params.prefillSubCategoryKey, '收款');
      expect(params.prefillAccountId, 3);
      expect(params.highlightFields, isEmpty);
    });
  });

  group('SpeechEntryParamsBuilder', () {
    test('maps valid voice expense into editor params', () {
      final intent = SpeechIntent(
        rawText: '今天午餐花了 35 元 微信',
        cleanedText: '午餐 微信',
        amount: 35,
        timestamp: DateTime(2026, 4, 26, 12),
        type: 'expense',
        accountHint: '微信',
        toAccountHint: null,
      );

      final params = const SpeechEntryParamsBuilder().build(
        intent,
        accounts: [_account(id: 8, name: '微信零钱')],
      );

      expect(params.source, TransactionEntrySource.voice);
      expect(params.prefillAmount, 35);
      expect(params.prefillType, 'expense');
      expect(params.prefillAccountId, 8);
      expect(params.prefillNote, '午餐 微信');
      expect(params.prefillRawText, '今天午餐花了 35 元 微信');
      expect(
        params.highlightFields,
        contains(TransactionHighlightField.category),
      );
      expect(
        params.highlightFields,
        isNot(contains(TransactionHighlightField.account)),
      );
    });

    test('maps voice transfer target account highlight', () {
      final intent = SpeechIntent(
        rawText: '从微信零钱转到招商银行 500 元',
        cleanedText: '从微信零钱转到招商银行',
        amount: 500,
        timestamp: DateTime(2026, 4, 26, 12),
        type: 'transfer',
        accountHint: '微信',
        toAccountHint: '招商',
      );

      final params = const SpeechEntryParamsBuilder().build(
        intent,
        accounts: [
          _account(id: 1, name: '微信零钱'),
          _account(id: 2, name: '招商银行'),
        ],
      );

      expect(params.prefillType, 'transfer');
      expect(params.prefillAccountId, 1);
      expect(params.prefillToAccountId, 2);
      expect(
        params.highlightFields,
        isNot(contains(TransactionHighlightField.transferAccount)),
      );
      expect(
        params.highlightFields,
        isNot(contains(TransactionHighlightField.category)),
      );
    });

    test(
      'resolves compact account group path hints to concrete subaccounts',
      () {
        final intent = SpeechIntent(
          rawText: '从中国银行活期转到中国银行定期 500 元',
          cleanedText: '从中国银行活期转到中国银行定期',
          amount: 500,
          timestamp: DateTime(2026, 4, 26, 12),
          type: 'transfer',
          accountHint: '中国银行活期',
          toAccountHint: '中国银行定期',
        );

        final params = const SpeechEntryParamsBuilder().build(
          intent,
          accounts: [
            _account(id: 1, name: '活期', groupName: '中国银行', currency: 'CNY'),
            _account(id: 2, name: '定期', groupName: '中国银行', currency: 'USD'),
          ],
        );

        expect(params.prefillAccountId, 1);
        expect(params.prefillToAccountId, 2);
        expect(params.highlightFields, isEmpty);
      },
    );
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

    test('visible paths keep hidden parents for full leaf context', () {
      final categories = [
        _category(key: 'transport', name: '出行', isHidden: true, order: 2),
        _category(key: 'car', name: '私家车', parentKey: 'transport'),
        _category(key: 'fuel', name: '加油', parentKey: 'car'),
      ];

      final paths = const CategoryPathService().visiblePaths(
        categories,
        isIncome: false,
      );

      expect(
        paths.map((path) => path.displayName),
        contains('出行 / 私家车 / 加油'),
      );
    });

    test('treats two-level paths as default and third-level as optional', () {
      final categories = [
        _category(key: 'transport', name: '出行'),
        _category(key: 'car', name: '私家车', parentKey: 'transport'),
        _category(key: 'fuel', name: '加油', parentKey: 'car'),
      ];

      final service = const CategoryPathService();
      final defaultPaths = service.defaultInteractivePaths(
        categories,
        isIncome: false,
      );
      final optionalPaths = service.optionalExtendedPaths(
        categories,
        isIncome: false,
      );

      expect(
        defaultPaths.map((path) => path.displayName),
        containsAll(['出行', '出行 / 私家车']),
      );
      expect(
        defaultPaths.map((path) => path.displayName),
        isNot(contains('出行 / 私家车 / 加油')),
      );
      expect(optionalPaths.map((path) => path.displayName), ['出行 / 私家车 / 加油']);
    });
  });

  group('CategoryPathImportParser', () {
    test('keeps full three-level import segments', () {
      final names = CategoryPathImportParser.split('出行 / 私家车 / 加油');

      expect(names.parentName, '出行');
      expect(names.childName, '加油');
      expect(names.segments, ['出行', '私家车', '加油']);
    });

    test('keeps single category import segment compatible', () {
      final names = CategoryPathImportParser.split('餐饮');

      expect(names.parentName, '餐饮');
      expect(names.childName, isNull);
      expect(names.segments, ['餐饮']);
    });

    test('returns empty segments for blank input', () {
      final names = CategoryPathImportParser.split('  ');

      expect(names.parentName, isNull);
      expect(names.childName, isNull);
      expect(names.segments, isEmpty);
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

    test('parses quick action transaction links with executor metadata', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?entrySource=quickAction&quickActionId=template:42&mode=direct&type=expense&amount=15&categoryKey=food&accountId=8&sourceLabel=%E6%9D%A5%E8%87%AA%E5%BF%AB%E9%80%9F%E5%8A%A8%E4%BD%9C%E3%80%8C%E6%97%A9%E9%A4%90%E3%80%8D',
        ),
      );

      final params = request?.transactionParams;
      expect(params?.source, TransactionEntrySource.quickAction);
      expect(params?.sourceBannerText, '来自快速动作「早餐」');
      expect(params?.quickActionId, 'template:42');
      expect(params?.canDirectSubmit, isTrue);
      expect(params?.prefillAmount, 15);
      expect(params?.prefillAccountId, 8);
      expect(params?.prefillCategoryKey, 'food');
      expect(params?.highlightFields, isEmpty);
    });

    test('supports structured editor source aliases in transaction links', () {
      final cases = {
        'voice': TransactionEntrySource.voice,
        'conversation': TransactionEntrySource.conversation,
        'auto_draft': TransactionEntrySource.autoDraft,
        'ocr': TransactionEntrySource.ocrScreenshot,
      };

      for (final entry in cases.entries) {
        final request = QuickActionDeepLinkService.parse(
          Uri.parse('jive://transaction/new?entrySource=${entry.key}'),
        );

        expect(request?.transactionParams?.source, entry.value);
        expect(
          request?.transactionParams?.highlightFields,
          contains(TransactionHighlightField.amount),
        );
      }
    });

    test('parses Android share text links into share receive params', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?entrySource=shareReceive&rawText=%E4%BB%8A%E5%A4%A9%E5%8D%88%E9%A4%90%E8%8A%B1%E4%BA%86%2035%20%E5%85%83&sourceLabel=%E6%9D%A5%E8%87%AA%E7%B3%BB%E7%BB%9F%E5%88%86%E4%BA%AB',
        ),
      );

      final params = request?.transactionParams;
      expect(params?.source, TransactionEntrySource.shareReceive);
      expect(params?.sourceLabel, '来自系统分享');
      expect(params?.prefillAmount, 35);
      expect(params?.prefillType, 'expense');
      expect(params?.prefillRawText, '今天午餐花了 35 元');
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.account),
      );
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.category),
      );
    });

    test('keeps raw shared text as note when parsing is incomplete', () {
      final request = QuickActionDeepLinkService.parse(
        Uri.parse(
          'jive://transaction/new?entrySource=shareReceive&rawText=%E5%8D%88%E9%A4%90%E5%BE%85%E8%A1%A5%E5%85%85',
        ),
      );

      final params = request?.transactionParams;
      expect(params?.source, TransactionEntrySource.shareReceive);
      expect(params?.prefillAmount, isNull);
      expect(params?.prefillNote, '午餐待补充');
      expect(params?.prefillRawText, '午餐待补充');
      expect(
        params?.highlightFields,
        contains(TransactionHighlightField.amount),
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

    test('keeps custom account groups inside broad asset sections', () {
      final account = _account(
        id: 1,
        name: '活期',
        subType: 'bank',
        groupName: '中国银行',
      );

      expect(const AccountGroupService().sectionNameFor(account), '资金账户');
      expect(
        const AccountGroupService().displayPath(account),
        '中国银行 / 活期 / bank CNY',
      );
    });

    test('deduplicates repeated subtype and currency in display paths', () {
      final service = const AccountGroupService();

      expect(
        service.displayPath(
          _account(
            id: 1,
            name: '活期 CNY',
            groupName: '中国银行',
            subType: '活期',
            currency: 'CNY',
          ),
        ),
        '中国银行 / 活期 CNY',
      );
      expect(
        service.displayPath(
          _account(
            id: 2,
            name: '定期',
            groupName: '中国银行',
            subType: '定期',
            currency: 'USD',
          ),
        ),
        '中国银行 / 定期 / USD',
      );
    });
  });

  group('SceneCandidateService', () {
    test(
      'prioritizes template categories before generic category candidates',
      () {
        const service = SceneCandidateService();
        final categories = [
          _category(key: 'parking', name: '停车', order: 1),
          _category(key: 'food', name: '餐饮', order: 2),
          _category(key: 'traffic', name: '交通', order: 3),
          _category(key: 'salary', name: '收入', order: 4, isIncome: true),
          _category(key: 'shopping', name: '购物', order: 5)..isHidden = true,
        ];

        final candidates = service.categoryCandidates(
          template: kSceneTemplates.firstWhere((t) => t.id == 'travel'),
          categories: categories,
          isIncome: false,
        );

        expect(candidates.map((c) => c.name), ['交通', '餐饮', '停车']);
        expect(
          service
              .defaultCategoryCandidate(
                template: kSceneTemplates.firstWhere((t) => t.id == 'travel'),
                categories: categories,
                isIncome: false,
              )
              ?.name,
          '交通',
        );
      },
    );

    test('scopes account candidates to scene book with default fallback', () {
      const service = SceneCandidateService();
      final accounts = [
        _account(id: 1, name: '默认现金', order: 1),
        _account(id: 2, name: '旅行卡', order: 2, bookId: 7),
        _account(id: 3, name: '旅行信用卡', order: 3, bookId: 7)
          ..type = 'liability',
        _account(id: 4, name: '其他账本', order: 4, bookId: 8),
        _account(id: 5, name: '已隐藏', order: 5, bookId: 7)..isHidden = true,
      ];

      final candidates = service.accountCandidates(
        bookId: 7,
        accounts: accounts,
      );

      expect(candidates.map((a) => a.name), ['旅行卡', '旅行信用卡', '默认现金']);
      expect(
        service.defaultAccountCandidate(bookId: 7, accounts: accounts)?.name,
        '旅行卡',
      );
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
  int order = 0,
  bool isIncome = false,
  bool isHidden = false,
}) {
  return JiveCategory()
    ..key = key
    ..name = name
    ..iconName = 'category'
    ..parentKey = parentKey
    ..order = order
    ..isSystem = false
    ..isHidden = isHidden
    ..isIncome = isIncome
    ..updatedAt = DateTime(2026);
}

JiveAccount _account({
  required int id,
  required String name,
  String? subType,
  String? groupName,
  String currency = 'CNY',
  int? bookId,
  int? order,
}) {
  return JiveAccount()
    ..id = id
    ..key = 'account_$id'
    ..name = name
    ..type = 'asset'
    ..subType = subType
    ..groupName = groupName
    ..currency = currency
    ..iconName = 'wallet'
    ..order = order ?? id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..bookId = bookId
    ..updatedAt = DateTime(2026);
}
