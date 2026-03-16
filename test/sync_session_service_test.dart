import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/repository/sync_checkpoint_snapshot.dart';
import 'package:jive/core/repository/sync_cursor.dart';
import 'package:jive/core/repository/sync_cursor_store.dart';
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

  test('resume returns expired when lease is stale', () async {
    final service = SyncSessionService();
    await service.issueSession(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      deviceId: 'pixel_7',
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      leaseDuration: const Duration(minutes: 5),
      snapshot: SyncCheckpointSnapshot(
        cursors: {
          'account': SyncCursor(
            entityType: 'account',
            updatedAt: DateTime.utc(2026, 3, 13, 8, 0, 0),
            lastId: 10,
          ),
        },
      ),
    );

    final resumed = await service.resumeSession(
      ownerId: 'user_001',
      deviceId: 'pixel_7',
      now: DateTime.utc(2026, 3, 13, 9, 10, 0),
    );

    expect(resumed.status, SyncSessionResumeStatus.expired);
    expect(resumed.reason, contains('expired'));
  });

  test('renew increments version and keeps owner identity', () async {
    final service = SyncSessionService();
    final issued = await service.issueSession(
      scope: 'cloud_sync',
      ownerId: 'user_001',
      deviceId: 'pixel_7',
      version: 2,
      now: DateTime.utc(2026, 3, 13, 9, 0, 0),
      snapshot: SyncCheckpointSnapshot(),
    );

    final renewed = await service.renewSession(
      lease: issued.lease,
      now: DateTime.utc(2026, 3, 13, 9, 20, 0),
    );

    expect(renewed.lease.version, 3);
    expect(renewed.lease.ownerId, 'user_001');
    expect(renewed.lease.deviceId, 'pixel_7');
  });
}
