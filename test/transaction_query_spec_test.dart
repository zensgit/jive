import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/transaction_model.dart';
import 'package:jive/core/model/transaction_query_spec.dart';

void main() {
  test('normalizedKeyword trims and empty becomes null', () {
    const empty = TransactionQuerySpec(keyword: '   ');
    expect(empty.normalizedKeyword, isNull);

    const filled = TransactionQuerySpec(keyword: '  coffee  ');
    expect(filled.normalizedKeyword, 'coffee');
  });

  test('cursor can be created from transaction', () {
    final tx = JiveTransaction()
      ..id = 42
      ..amount = 12.5
      ..source = 'wechat'
      ..timestamp = DateTime(2026, 2, 19, 8, 30);

    final cursor = TransactionQueryCursor.fromTransaction(tx);
    expect(cursor.id, 42);
    expect(cursor.timestamp, DateTime(2026, 2, 19, 8, 30));
  });

  test('result page stores hasMore and nextCursor as provided', () {
    final cursor = TransactionQueryCursor(
      id: 7,
      timestamp: DateTime(2026, 2, 19),
    );
    const page = TransactionQueryResultPage(
      items: [],
      nextCursor: null,
      hasMore: false,
    );
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);

    final page2 = TransactionQueryResultPage(
      items: const [],
      nextCursor: cursor,
      hasMore: true,
    );
    expect(page2.hasMore, isTrue);
    expect(page2.nextCursor, isNotNull);
    expect(page2.nextCursor!.id, 7);
  });
}
