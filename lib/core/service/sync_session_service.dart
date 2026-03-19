import 'dart:math';

import '../repository/sync_checkpoint_snapshot.dart';
import '../repository/sync_cursor_store.dart';
import '../repository/sync_lease.dart';
import '../repository/sync_lease_store.dart';

enum SyncSessionResumeStatus { ready, expired, ownerMismatch, absent }

class SyncSessionState {
  const SyncSessionState({required this.lease, required this.snapshot});

  final SyncLease lease;
  final SyncCheckpointSnapshot snapshot;
}

class SyncSessionResumeResult {
  const SyncSessionResumeResult({
    required this.status,
    this.state,
    this.reason,
  });

  final SyncSessionResumeStatus status;
  final SyncSessionState? state;
  final String? reason;
}

class SyncSessionService {
  static const Duration defaultLeaseDuration = Duration(minutes: 30);
  static String buildRuntimeToken(String prefix, DateTime issuedAt) {
    final random = Random(issuedAt.microsecondsSinceEpoch ^ prefix.hashCode);
    final token = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${prefix}_${issuedAt.microsecondsSinceEpoch}_$token';
  }

  Future<SyncSessionState> issueSession({
    required String scope,
    required String ownerId,
    required String deviceId,
    int version = 1,
    DateTime? now,
    Duration leaseDuration = defaultLeaseDuration,
    SyncCheckpointSnapshot? snapshot,
  }) async {
    final issuedAt = (now ?? DateTime.now()).toUtc();
    final lease = SyncLease(
      leaseId: _buildLeaseId(scope: scope, issuedAt: issuedAt),
      scope: scope,
      ownerId: ownerId,
      deviceId: deviceId,
      version: version,
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(leaseDuration),
    );
    final checkpointSnapshot = snapshot ?? await SyncCursorStore.loadSnapshot();
    await SyncLeaseStore.save(lease);
    await SyncCursorStore.saveSnapshot(checkpointSnapshot);
    return SyncSessionState(lease: lease, snapshot: checkpointSnapshot);
  }

  Future<SyncSessionState> renewSession({
    required SyncLease lease,
    DateTime? now,
    Duration leaseDuration = defaultLeaseDuration,
    SyncCheckpointSnapshot? snapshot,
  }) async {
    return issueSession(
      scope: lease.scope,
      ownerId: lease.ownerId,
      deviceId: lease.deviceId,
      version: lease.version + 1,
      now: now,
      leaseDuration: leaseDuration,
      snapshot: snapshot,
    );
  }

  Future<SyncSessionResumeResult> resumeSession({
    required String ownerId,
    required String deviceId,
    DateTime? now,
  }) async {
    final lease = await SyncLeaseStore.load();
    if (lease == null) {
      return const SyncSessionResumeResult(
        status: SyncSessionResumeStatus.absent,
        reason: 'no sync lease',
      );
    }
    if (lease.ownerId != ownerId || lease.deviceId != deviceId) {
      return const SyncSessionResumeResult(
        status: SyncSessionResumeStatus.ownerMismatch,
        reason: 'owner/device mismatch',
      );
    }

    final currentTime = (now ?? DateTime.now()).toUtc();
    if (!lease.isActiveAt(currentTime)) {
      return const SyncSessionResumeResult(
        status: SyncSessionResumeStatus.expired,
        reason: 'sync lease expired',
      );
    }

    final snapshot = await SyncCursorStore.loadSnapshot();
    return SyncSessionResumeResult(
      status: SyncSessionResumeStatus.ready,
      state: SyncSessionState(lease: lease, snapshot: snapshot),
    );
  }

  Future<bool> canWrite({
    required String leaseId,
    required String ownerId,
    required String deviceId,
    DateTime? now,
  }) async {
    final lease = await SyncLeaseStore.load();
    if (lease == null) return false;
    if (lease.leaseId != leaseId) return false;
    if (lease.ownerId != ownerId || lease.deviceId != deviceId) return false;
    return lease.isActiveAt((now ?? DateTime.now()).toUtc());
  }

  Future<void> persistCheckpoint(SyncCheckpointSnapshot snapshot) async {
    await SyncCursorStore.saveSnapshot(snapshot);
  }

  Future<void> clearSession({bool clearCheckpoint = false}) async {
    await SyncLeaseStore.clear();
    if (clearCheckpoint) {
      await SyncCursorStore.clearAll();
    }
  }

  String _buildLeaseId({required String scope, required DateTime issuedAt}) {
    return buildRuntimeToken(scope, issuedAt);
  }
}
