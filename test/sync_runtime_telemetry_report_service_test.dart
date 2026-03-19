import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/sync_runtime_service.dart';
import 'package:jive/core/service/sync_runtime_telemetry_report_service.dart';

void main() {
  const service = SyncRuntimeTelemetryReportService();

  test('evaluate returns ready for complete restore and rebind telemetry', () {
    final report = service.evaluate(
      const SyncRuntimeTelemetryInput(
        scope: 'cloud_sync',
        initialDisposition: SyncRuntimeOpenDisposition.issued,
        restoredDisposition: SyncRuntimeOpenDisposition.issued,
        reboundDisposition: SyncRuntimeOpenDisposition.rebound,
        importedSyncCursorCount: 4,
        restoredSnapshotValid: true,
        sameDeviceRetained: true,
        leaseClearedBeforeRestore: true,
        staleWriterBlocked: true,
        reboundWriterAllowed: true,
      ),
    );

    expect(report.status, SyncRuntimeTelemetryStatus.ready);
    expect(report.telemetryLevel, 'T1_READY');
    expect(report.exportJson(), contains('"status": "ready"'));
    expect(report.exportMarkdown(), contains('# Sync Runtime 遥测回归报告'));
    expect(report.exportCsv(), contains('status,ready'));
  });

  test('evaluate returns block when stale writer is not blocked', () {
    final report = service.evaluate(
      const SyncRuntimeTelemetryInput(
        scope: 'cloud_sync',
        initialDisposition: SyncRuntimeOpenDisposition.issued,
        restoredDisposition: SyncRuntimeOpenDisposition.issued,
        reboundDisposition: SyncRuntimeOpenDisposition.rebound,
        importedSyncCursorCount: 2,
        restoredSnapshotValid: true,
        sameDeviceRetained: true,
        leaseClearedBeforeRestore: true,
        staleWriterBlocked: false,
        reboundWriterAllowed: true,
      ),
    );

    expect(report.status, SyncRuntimeTelemetryStatus.block);
    expect(report.reason, contains('旧 lease 仍然可写'));
  });

  test(
    'evaluate returns review when restore does not clear lease explicitly',
    () {
      final report = service.evaluate(
        const SyncRuntimeTelemetryInput(
          scope: 'cloud_sync',
          initialDisposition: SyncRuntimeOpenDisposition.issued,
          restoredDisposition: SyncRuntimeOpenDisposition.issued,
          reboundDisposition: SyncRuntimeOpenDisposition.rebound,
          importedSyncCursorCount: 3,
          restoredSnapshotValid: true,
          sameDeviceRetained: true,
          leaseClearedBeforeRestore: false,
          staleWriterBlocked: true,
          reboundWriterAllowed: true,
        ),
      );

      expect(report.status, SyncRuntimeTelemetryStatus.review);
      expect(report.reason, contains('未确认清理旧 lease'));
    },
  );

  test(
    'evaluate returns review when restore incorrectly resumes previous lease',
    () {
      final report = service.evaluate(
        const SyncRuntimeTelemetryInput(
          scope: 'cloud_sync',
          initialDisposition: SyncRuntimeOpenDisposition.issued,
          restoredDisposition: SyncRuntimeOpenDisposition.resumed,
          reboundDisposition: SyncRuntimeOpenDisposition.rebound,
          importedSyncCursorCount: 3,
          restoredSnapshotValid: true,
          sameDeviceRetained: true,
          leaseClearedBeforeRestore: true,
          staleWriterBlocked: true,
          reboundWriterAllowed: true,
        ),
      );

      expect(report.status, SyncRuntimeTelemetryStatus.review);
      expect(report.reason, contains('restore 后 reopen 不是 issued'));
    },
  );
}
