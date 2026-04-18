import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/sync/sync_account_scope.dart';

void main() {
  const scope = SyncAccountScope(
    accountKeyById: {
      7: 'acct_cash',
      9: 'acct_credit',
    },
    accountIdByKey: {
      'acct_cash': 7,
      'acct_credit': 9,
    },
  );

  group('SyncAccountScope', () {
    test('maps local IDs to stable account keys', () {
      expect(scope.accountKey(7), 'acct_cash');
      expect(scope.accountKey(null), isNull);
      expect(scope.accountKey(999), isNull);
    });

    test('resolves remote account keys back to local IDs', () {
      expect(scope.accountId('acct_credit'), 9);
      expect(scope.accountId(' acct_cash '), 7);
    });

    test('falls back to previous accountId when key is missing', () {
      expect(scope.accountId(null, fallbackAccountId: 12), 12);
      expect(scope.accountId('', fallbackAccountId: 13), 13);
      expect(scope.accountId('acct_missing', fallbackAccountId: 14), 14);
    });
  });
}
