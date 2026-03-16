import '../repository/sync_checkpoint_snapshot.dart';
import '../repository/sync_cursor.dart';
import '../repository/sync_cursor_store.dart';
import '../repository/sync_lease_store.dart';
import '../repository/sync_runtime_identity_store.dart';
import 'sync_session_service.dart';

enum SyncRuntimeOpenDisposition { issued, resumed, renewed, rebound }

typedef SyncRuntimeOpenStatus = SyncRuntimeOpenDisposition;

class SyncRuntimeIdentity {
  const SyncRuntimeIdentity({
    required this.deviceId,
    required this.deviceCreatedAt,
    required this.appInstanceId,
  });

  final String deviceId;
  final DateTime deviceCreatedAt;
  final String appInstanceId;
}

class SyncRuntimeState {
  const SyncRuntimeState({required this.identity, required this.session});

  final SyncRuntimeIdentity identity;
  final SyncSessionState session;
}

class SyncRuntimeOpenResult {
  const SyncRuntimeOpenResult({
    required this.disposition,
    required this.state,
    required this.reason,
  });

  final SyncRuntimeOpenDisposition disposition;
  final SyncRuntimeState state;
  final String reason;

  SyncRuntimeOpenStatus get status => disposition;
  SyncRuntimeIdentity get identity => state.identity;
  SyncSessionState get session => state.session;
}

class SyncRuntimeService {
  SyncRuntimeService({
    SyncSessionService? sessionService,
    SyncRuntimeIdentityStore? identityStore,
    String? appInstanceId,
    String Function()? appInstanceIdFactory,
  }) : _sessionService = sessionService ?? SyncSessionService(),
       _identityStore = identityStore ?? SyncRuntimeIdentityStore(),
       _appInstanceId = (appInstanceId?.trim().isNotEmpty ?? false)
           ? appInstanceId!.trim()
           : (appInstanceIdFactory ?? SyncSessionService.buildRuntimeToken)(
               'runtime',
               DateTime.now().toUtc(),
             );

  final SyncSessionService _sessionService;
  final SyncRuntimeIdentityStore _identityStore;
  final String _appInstanceId;

  Future<SyncRuntimeIdentity> ensureIdentity({
    DateTime? now,
    String? deviceId,
  }) async {
    final deviceIdentity = await _identityStore.ensure(
      now: now,
      deviceId: deviceId,
    );
    return SyncRuntimeIdentity(
      deviceId: deviceIdentity.deviceId,
      deviceCreatedAt: deviceIdentity.createdAt,
      appInstanceId: _appInstanceId,
    );
  }

  Future<SyncRuntimeOpenResult> openRuntime({
    required String scope,
    required String ownerId,
    DateTime? now,
    Duration leaseDuration = SyncSessionService.defaultLeaseDuration,
    SyncCheckpointSnapshot? snapshot,
  }) async {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final identity = await ensureIdentity(now: currentTime);
    final existingLease = await SyncLeaseStore.load();
    final resumed = await _sessionService.resumeSession(
      ownerId: ownerId,
      deviceId: identity.deviceId,
      now: currentTime,
    );

    if (resumed.status == SyncSessionResumeStatus.ready &&
        resumed.state != null &&
        existingLease != null &&
        existingLease.scope == scope) {
      return SyncRuntimeOpenResult(
        disposition: SyncRuntimeOpenDisposition.resumed,
        state: SyncRuntimeState(identity: identity, session: resumed.state!),
        reason: 'active sync runtime resumed',
      );
    }

    if (existingLease != null &&
        existingLease.scope == scope &&
        existingLease.ownerId == ownerId &&
        existingLease.deviceId == identity.deviceId &&
        resumed.status == SyncSessionResumeStatus.expired) {
      final renewed = await _sessionService.renewSession(
        lease: existingLease,
        now: currentTime,
        leaseDuration: leaseDuration,
        snapshot: snapshot,
      );
      return SyncRuntimeOpenResult(
        disposition: SyncRuntimeOpenDisposition.renewed,
        state: SyncRuntimeState(identity: identity, session: renewed),
        reason: 'expired sync lease renewed for same owner/device',
      );
    }

    final previousVersion = existingLease?.version ?? 0;
    if (existingLease != null) {
      await _sessionService.clearSession(clearCheckpoint: false);
    }

    final issued = await _sessionService.issueSession(
      scope: scope,
      ownerId: ownerId,
      deviceId: identity.deviceId,
      version: previousVersion > 0 ? previousVersion + 1 : 1,
      now: currentTime,
      leaseDuration: leaseDuration,
      snapshot: snapshot,
    );

    return SyncRuntimeOpenResult(
      disposition: existingLease == null
          ? SyncRuntimeOpenDisposition.issued
          : SyncRuntimeOpenDisposition.rebound,
      state: SyncRuntimeState(identity: identity, session: issued),
      reason: existingLease == null
          ? 'new sync runtime issued'
          : 'sync runtime rotated for new owner/scope/lease state',
    );
  }

  Future<SyncCheckpointSnapshot> advanceCursor(SyncCursor cursor) {
    return persistCursor(cursor);
  }

  Future<SyncCheckpointSnapshot> persistCursor(SyncCursor cursor) async {
    await SyncCursorStore.save(cursor);
    return SyncCursorStore.loadSnapshot();
  }

  Future<SyncCheckpointSnapshot> persistSnapshot(
    SyncCheckpointSnapshot snapshot,
  ) async {
    await _sessionService.persistCheckpoint(snapshot);
    return SyncCursorStore.loadSnapshot();
  }

  Future<SyncRuntimeState?> currentState({
    required String ownerId,
    DateTime? now,
  }) async {
    final identity = await ensureIdentity(now: now);
    final resumed = await _sessionService.resumeSession(
      ownerId: ownerId,
      deviceId: identity.deviceId,
      now: now,
    );
    if (resumed.status != SyncSessionResumeStatus.ready ||
        resumed.state == null) {
      return null;
    }
    return SyncRuntimeState(identity: identity, session: resumed.state!);
  }

  Future<bool> canCurrentRuntimeWrite({
    required String leaseId,
    required String ownerId,
    DateTime? now,
  }) async {
    final identity = await ensureIdentity(now: now);
    return _sessionService.canWrite(
      leaseId: leaseId,
      ownerId: ownerId,
      deviceId: identity.deviceId,
      now: now,
    );
  }

  Future<void> clearRuntime({
    bool clearCheckpoint = false,
    bool clearIdentity = false,
  }) async {
    await _sessionService.clearSession(clearCheckpoint: clearCheckpoint);
    if (clearIdentity) {
      await _identityStore.clear();
    }
  }
}
