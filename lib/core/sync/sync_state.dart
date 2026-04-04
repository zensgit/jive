/// Sync engine state.
enum SyncStatus {
  /// Sync not configured or disabled.
  disabled,

  /// Idle, waiting for next sync.
  idle,

  /// Currently syncing.
  syncing,

  /// Last sync failed.
  error,
}

/// Snapshot of sync state for UI display.
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final int pendingUploadCount;
  final int pendingDownloadCount;
  final int conflictCount;

  const SyncState({
    this.status = SyncStatus.disabled,
    this.lastSyncAt,
    this.errorMessage,
    this.pendingUploadCount = 0,
    this.pendingDownloadCount = 0,
    this.conflictCount = 0,
  });

  const SyncState.disabled() : this();

  const SyncState.idle({DateTime? lastSyncAt, int conflictCount = 0})
      : this(status: SyncStatus.idle, lastSyncAt: lastSyncAt, conflictCount: conflictCount);

  const SyncState.syncing()
      : this(status: SyncStatus.syncing);

  SyncState.error(String message)
      : this(status: SyncStatus.error, errorMessage: message);

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isEnabled => status != SyncStatus.disabled;
  bool get hasConflicts => conflictCount > 0;
}
