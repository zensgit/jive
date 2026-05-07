import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/database/shared_ledger_model.dart';
import 'package:jive/core/service/object_share_policy_service.dart';

void main() {
  group('ObjectSharePolicyService', () {
    test('treats book shared ledger key as inherited shared scene', () {
      final book = _book(sharedLedgerKey: 'ledger_family', isShared: false);

      final policy = const ObjectSharePolicyService().evaluate(
        book: book,
        objectLabel: '账户',
      );

      expect(policy.visibility, ObjectShareVisibility.inheritedFromScene);
      expect(policy.label, '继承场景共享');
      expect(policy.warning, contains('账户'));
      expect(policy.warning, contains('场景成员'));
    });

    test(
      'explicitly shared object takes shared label outside shared scenes',
      () {
        final policy = const ObjectSharePolicyService().evaluate(
          book: _book(),
          objectLabel: '标签',
          explicitlyShared: true,
        );

        expect(policy.visibility, ObjectShareVisibility.shared);
        expect(policy.label, '共享');
        expect(policy.warning, contains('标签'));
        expect(policy.warning, contains('共享成员'));
      },
    );

    test('shared ledger instance marks object as inherited shared scene', () {
      final ledger = JiveSharedLedger()
        ..key = 'ledger_family'
        ..name = '家庭共享';

      final policy = const ObjectSharePolicyService().evaluate(
        book: null,
        sharedLedger: ledger,
        objectLabel: '分类',
      );

      expect(policy.visibility, ObjectShareVisibility.inheritedFromScene);
      expect(policy.label, '继承场景共享');
      expect(policy.warning, contains('分类'));
    });

    test('private object warning only appears inside shared scenes', () {
      final service = const ObjectSharePolicyService();

      expect(
        service.privateObjectInSharedSceneWarning(
          book: _book(sharedLedgerKey: 'ledger_family'),
          objectIsPrivate: true,
          objectLabel: '账户',
        ),
        contains('私有账户不能直接用于共享场景交易'),
      );
      expect(
        service.privateObjectInSharedSceneWarning(
          book: _book(sharedLedgerKey: 'ledger_family'),
          objectIsPrivate: false,
          objectLabel: '账户',
        ),
        isNull,
      );
      expect(
        service.privateObjectInSharedSceneWarning(
          book: _book(),
          objectIsPrivate: true,
          objectLabel: '账户',
        ),
        isNull,
      );
    });

    test('deletion warnings cover empty shared and local scopes', () {
      final service = const ObjectSharePolicyService();

      expect(
        service.deletionWarning(
          objectLabel: '差旅',
          affectedTransactionCount: 0,
          shared: true,
        ),
        '删除「差旅」后，将不再出现在共享成员的候选列表中。',
      );
      expect(
        service.deletionWarning(objectLabel: '差旅', affectedTransactionCount: 0),
        '删除「差旅」后，将不再出现在本地账本的候选列表中。',
      );
    });
  });
}

JiveBook _book({bool isShared = false, String? sharedLedgerKey}) {
  return JiveBook()
    ..key = 'book_daily'
    ..name = '日常'
    ..currency = 'CNY'
    ..order = 0
    ..isDefault = true
    ..isArchived = false
    ..isShared = isShared
    ..sharedLedgerKey = sharedLedgerKey
    ..memberCount = isShared || sharedLedgerKey != null ? 2 : 1
    ..createdAt = DateTime(2026)
    ..updatedAt = DateTime(2026);
}
