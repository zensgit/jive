import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/sync/sync_tombstone_entry.dart';
import 'package:jive/core/sync/sync_tombstone_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SyncTombstoneStore.clear();
  });

  test('upsert replaces tombstone for same table and entity key', () async {
    final first = SyncTombstoneEntry(
      table: 'transactions',
      entityKey: 'local:1',
      deletedAt: DateTime(2026, 4, 5, 8, 0),
      payload: {'local_id': 1},
    );
    final second = SyncTombstoneEntry(
      table: 'transactions',
      entityKey: 'local:1',
      deletedAt: DateTime(2026, 4, 5, 9, 0),
      payload: {'local_id': 1, 'deleted_at': '2026-04-05T09:00:00.000'},
    );

    await SyncTombstoneStore.upsert(first);
    await SyncTombstoneStore.upsert(second);

    final entries = await SyncTombstoneStore.listForTable('transactions');
    expect(entries, hasLength(1));
    expect(entries.single.deletedAt, DateTime(2026, 4, 5, 9, 0));
  });

  test('mapForTable returns only requested table entries', () async {
    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'transactions',
        entityKey: 'local:2',
        deletedAt: DateTime(2026, 4, 5, 8, 0),
        payload: {'local_id': 2},
      ),
    );
    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'budgets',
        entityKey: 'local:3',
        deletedAt: DateTime(2026, 4, 5, 8, 30),
        payload: {'local_id': 3},
      ),
    );

    final transactionMap = await SyncTombstoneStore.mapForTable('transactions');
    expect(transactionMap.keys, ['local:2']);
  });

  test('removeEntries clears uploaded tombstones only', () async {
    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'transactions',
        entityKey: 'local:2',
        deletedAt: DateTime(2026, 4, 5, 8, 0),
        payload: {'local_id': 2},
      ),
    );
    await SyncTombstoneStore.upsert(
      SyncTombstoneEntry(
        table: 'transactions',
        entityKey: 'local:4',
        deletedAt: DateTime(2026, 4, 5, 8, 1),
        payload: {'local_id': 4},
      ),
    );

    await SyncTombstoneStore.removeEntries('transactions', ['local:2']);

    final entries = await SyncTombstoneStore.listForTable('transactions');
    expect(entries.map((entry) => entry.entityKey), ['local:4']);
  });
}
