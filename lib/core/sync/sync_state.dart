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

  const SyncState({
    this.status = SyncStatus.disabled,
    this.lastSyncAt,
    this.errorMessage,
    this.pendingUploadCount = 0,
    this.pendingDownloadCount = 0,
  });

  const SyncState.disabled() : this();

  const SyncState.idle({DateTime? lastSyncAt})
      : this(status: SyncStatus.idle, lastSyncAt: lastSyncAt);

  const SyncState.syncing()
      : this(status: SyncStatus.syncing);

  SyncState.error(String message)
      : this(status: SyncStatus.error, errorMessage: message);

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isEnabled => status != SyncStatus.disabled;
}
