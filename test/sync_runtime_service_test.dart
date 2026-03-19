import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/repository/sync_checkpoint_snapshot.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
import 'package:jive/core/repository/sync_lease_store.dart';
import 'package:jive/core/repository/sync_runtime_identity_store.dart';
import 'package:jive/core/service/sync_runtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SyncCursorStore.clearAll();
    await SyncLeaseStore.clear();
    await SyncRuntimeIdentityStore().clear();
  });

  test('openRuntime issues then resumes with stable device identity', () async {
    final service = SyncRuntimeService(appInstanceId: 'app_host_a');
    final snapshot = SyncCheckpointSnapshot(
      cursors: {
        'account': SyncCursor(
          entityType: 'account',
          updatedAt: DateTime.utc(2026, 3, 13, 8, 0, 0),
          lastId: 10,
        ),
      },
      capturedAt: DateTime.utc(2026, 3, 13, 8, 5, 0),
    );

    final issued = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      snapshot: snapshot,
    );
    final resumed = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 10, 0),
    );

    expect(issued.disposition, SyncRuntimeOpenDisposition.issued);
    expect(resumed.disposition, SyncRuntimeOpenDisposition.resumed);
    expect(resumed.identity.deviceId, issued.identity.deviceId);
    expect(resumed.identity.appInstanceId, 'app_host_a');
    expect(resumed.session.lease.leaseId, issued.session.lease.leaseId);
    expect(resumed.session.snapshot.cursors['account']?.lastId, 10);
  });

  test('openRuntime renews expired lease for same owner and device', () async {
    final service = SyncRuntimeService(appInstanceId: 'app_host_b');

    final issued = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      leaseDuration: const Duration(minutes: 5),
      snapshot: SyncCheckpointSnapshot(),
    );
    final renewed = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 10, 0),
      leaseDuration: const Duration(minutes: 5),
    );

    expect(renewed.disposition, SyncRuntimeOpenDisposition.renewed);
    expect(renewed.identity.deviceId, issued.identity.deviceId);
    expect(renewed.session.lease.version, issued.session.lease.version + 1);
    expect(renewed.session.lease.leaseId, isNot(issued.session.lease.leaseId));
  });

  test('openRuntime rebounds when owner changes on same device', () async {
    final service = SyncRuntimeService(appInstanceId: 'app_host_c');

    final first = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      snapshot: SyncCheckpointSnapshot(),
    );
    final rebound = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_002',
      now: DateTime.utc(2026, 3, 13, 9, 1, 0),
    );

    expect(rebound.disposition, SyncRuntimeOpenDisposition.rebound);
    expect(rebound.identity.deviceId, first.identity.deviceId);
    expect(rebound.session.lease.ownerId, 'user_002');
    expect(rebound.session.lease.leaseId, isNot(first.session.lease.leaseId));
  });

  test('advanceCursor persists checkpoint for later resume', () async {
    final service = SyncRuntimeService(appInstanceId: 'app_host_d');
    await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      snapshot: SyncCheckpointSnapshot(),
    );

    final updated = await service.advanceCursor(
      SyncCursor(
        entityType: 'transaction',
        updatedAt: DateTime.utc(2026, 3, 13, 9, 2, 0),
        lastId: 44,
      ),
    );
    final resumed = await service.openRuntime(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      now: DateTime.utc(2026, 3, 13, 9, 3, 0),
    );

    expect(updated.cursors['transaction']?.lastId, 44);
    expect(resumed.session.snapshot.cursors['transaction']?.lastId, 44);
    expect(
      await service.canCurrentRuntimeWrite(
        leaseId: resumed.session.lease.leaseId,
        ownerId: 'user_001',
        now: DateTime.utc(2026, 3, 13, 9, 4, 0),
      ),
      isTrue,
    );
  });
}
