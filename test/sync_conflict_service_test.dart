import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/sync_conflict_model.dart';

void main() {
  group('JiveSyncConflict', () {
    test('default values are set correctly', () {
      final conflict = JiveSyncConflict();

      expect(conflict.table, '');
      expect(conflict.localId, 0);
      expect(conflict.localJson, '');
      expect(conflict.remoteJson, '');
      expect(conflict.status, 'pending');
      expect(conflict.resolvedAt, isNull);
    });

    test('fields can be set correctly', () {
      final now = DateTime.now();
      final conflict = JiveSyncConflict()
        ..table = 'transactions'
        ..localId = 42
        ..localJson = '{"amount": 100}'
        ..remoteJson = '{"amount": 200}'
        ..localUpdatedAt = now
        ..remoteUpdatedAt = now
        ..status = 'keepLocal'
        ..detectedAt = now
        ..resolvedAt = now;

      expect(conflict.table, 'transactions');
      expect(conflict.localId, 42);
      expect(conflict.localJson, '{"amount": 100}');
      expect(conflict.remoteJson, '{"amount": 200}');
      expect(conflict.localUpdatedAt, now);
      expect(conflict.remoteUpdatedAt, now);
      expect(conflict.status, 'keepLocal');
      expect(conflict.detectedAt, now);
      expect(conflict.resolvedAt, now);
    });

    test('status can be set to keepRemote', () {
      final conflict = JiveSyncConflict()..status = 'keepRemote';
      expect(conflict.status, 'keepRemote');
    });

    test('table can be set to various collection names', () {
      for (final tableName in [
        'transactions',
        'accounts',
        'categories',
        'tags',
        'budgets',
      ]) {
        final conflict = JiveSyncConflict()..table = tableName;
        expect(conflict.table, tableName);
      }
    });

    test('resolvedAt is null by default for pending conflicts', () {
      final conflict = JiveSyncConflict();
      expect(conflict.status, 'pending');
      expect(conflict.resolvedAt, isNull);
    });

    test('detectedAt defaults to approximately now', () {
      final before = DateTime.now();
      final conflict = JiveSyncConflict();
      final after = DateTime.now();

      expect(conflict.detectedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(conflict.detectedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
