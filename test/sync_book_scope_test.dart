import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/sync/sync_book_scope.dart';

void main() {
  const scope = SyncBookScope(
    bookKeyById: {
      1: 'book_default',
      2: 'book_family',
    },
    bookIdByKey: {
      'book_default': 1,
      'book_family': 2,
    },
    defaultBookId: 1,
    defaultBookKey: 'book_default',
  );

  group('SyncBookScope', () {
    test('transactions and accounts fall back to default workspace key', () {
      expect(scope.transactionBookKey(null), 'book_default');
      expect(scope.accountBookKey(999), 'book_default');
    });

    test('budgets preserve global scope when no book is assigned', () {
      expect(scope.budgetBookKey(null), isNull);
      expect(scope.budgetBookId(null), isNull);
    });

    test('remote transaction and account rows resolve to default book', () {
      expect(scope.transactionBookId(null), 1);
      expect(scope.accountBookId(''), 1);
      expect(scope.transactionBookId('book_family'), 2);
    });

    test('budget rows keep existing scope when remote book key is missing', () {
      expect(scope.budgetBookId(null, fallbackBookId: 2), 2);
      expect(scope.budgetBookId('book_family'), 2);
    });

    test('shared ledger workspace falls back to default workspace', () {
      expect(scope.sharedLedgerWorkspaceKey(null), 'book_default');
      expect(scope.sharedLedgerWorkspaceKey(' book_family '), 'book_family');
    });
  });
}
