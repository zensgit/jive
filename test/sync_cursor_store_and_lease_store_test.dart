import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/repository/sync_checkpoint_snapshot.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
import 'package:jive/core/repository/sync_lease.dart';
import 'package:jive/core/repository/sync_lease_store.dart';
import 'package:jive/core/service/sync_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SyncCursorStore.clearAll();
    await SyncLeaseStore.clear();
  });

  test(
    'sync cursor store persists snapshot and supports selective clear',
    () async {
      final accountCursor = SyncCursor(
        entityType: 'account',
        updatedAt: DateTime.utc(2026, 3, 13, 9, 0, 0),
        lastId: 10,
      );
      final transactionCursor = SyncCursor(
        entityType: 'transaction',
        updatedAt: DateTime.utc(2026, 3, 13, 10, 0, 0),
        lastId: 30,
      );

      await SyncCursorStore.saveSnapshot(
        SyncCheckpointSnapshot(
          cursors: {
            accountCursor.entityType: accountCursor,
            transactionCursor.entityType: transactionCursor,
          },
        ),
      );

      final restored = await SyncCursorStore.loadSnapshot();
      expect(restored.count, 2);
      expect(restored.cursors['account']?.lastId, 10);
      expect(restored.cursors['transaction']?.lastId, 30);

      await SyncCursorStore.clear('account');
      final afterClear = await SyncCursorStore.loadSnapshot();
      expect(afterClear.count, 1);
      expect(afterClear.cursors.containsKey('account'), isFalse);
      expect(afterClear.cursors['transaction']?.lastId, 30);
    },
  );

  test('sync lease store persists active lease and clears cleanly', () async {
    final lease = SyncLease(
      leaseId: 'lease_auth_001',
      scope: 'auth_sync',
      ownerId: 'user_001',
      deviceId: 'android_emulator',
      version: 3,
      issuedAt: DateTime.utc(2026, 3, 13, 9, 0, 0),
      expiresAt: DateTime.utc(2026, 3, 13, 9, 30, 0),
    );

    await SyncLeaseStore.save(lease);

    final restored = await SyncLeaseStore.load();
    expect(restored?.leaseId, 'lease_auth_001');
    expect(
      await SyncLeaseStore.hasActiveLease(
        now: DateTime.utc(2026, 3, 13, 9, 15, 0),
      ),
      isTrue,
    );
    expect(
      await SyncLeaseStore.hasActiveLease(
        now: DateTime.utc(2026, 3, 13, 9, 45, 0),
      ),
      isFalse,
    );

    await SyncLeaseStore.clear();
    expect(await SyncLeaseStore.load(), isNull);
  });

  test('sync checkpoint snapshot detects checksum mismatch', () async {
    final snapshot = SyncCheckpointSnapshot(
      cursors: {
        'account': SyncCursor(
          entityType: 'account',
          updatedAt: DateTime.utc(2026, 3, 13, 9, 0, 0),
          lastId: 10,
        ),
      },
      capturedAt: DateTime.utc(2026, 3, 13, 9, 5, 0),
    );

    final tampered = Map<String, dynamic>.from(snapshot.toJson());
    tampered['checksum'] = 'deadbeef';

    final restored = SyncCheckpointSnapshot.fromJson(tampered);
    expect(restored.checksumValid, isFalse);
    expect(restored.isRestorable, isFalse);
  });

  test(
    'sync session service issues resumes and invalidates writes by owner',
    () async {
      final service = SyncSessionService();
      final snapshot = SyncCheckpointSnapshot(
        cursors: {
          'transaction': SyncCursor(
            entityType: 'transaction',
            updatedAt: DateTime.utc(2026, 3, 13, 10, 0, 0),
            lastId: 30,
          ),
        },
        capturedAt: DateTime.utc(2026, 3, 13, 10, 1, 0),
      );

      final state = await service.issueSession(
        scope: 'cloud_sync',
        ownerId: 'user_001',
        deviceId: 'android_emulator',
        version: 5,
        now: DateTime.utc(2026, 3, 13, 10, 2, 0),
        snapshot: snapshot,
      );

      final resumed = await service.resumeSession(
        ownerId: 'user_001',
        deviceId: 'android_emulator',
        now: DateTime.utc(2026, 3, 13, 10, 10, 0),
      );
      expect(resumed.status, SyncSessionResumeStatus.ready);
      expect(resumed.state?.snapshot.cursors['transaction']?.lastId, 30);

      expect(
        await service.canWrite(
          leaseId: state.lease.leaseId,
          ownerId: 'user_001',
          deviceId: 'android_emulator',
          now: DateTime.utc(2026, 3, 13, 10, 15, 0),
        ),
        isTrue,
      );
      expect(
        await service.canWrite(
          leaseId: state.lease.leaseId,
          ownerId: 'user_002',
          deviceId: 'android_emulator',
          now: DateTime.utc(2026, 3, 13, 10, 15, 0),
        ),
        isFalse,
      );
    },
  );
}
