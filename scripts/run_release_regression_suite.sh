#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

flutter analyze \
  lib/core/repository/sync_cursor.dart \
  lib/core/repository/sync_checkpoint_snapshot.dart \
  lib/core/repository/sync_cursor_store.dart \
  lib/core/repository/sync_lease.dart \
  lib/core/repository/sync_lease_store.dart \
  lib/core/repository/sync_runtime_identity.dart \
  lib/core/repository/sync_runtime_identity_store.dart \
  lib/core/repository/account_sync_repository.dart \
  lib/core/repository/category_sync_repository.dart \
  lib/core/repository/transaction_sync_repository.dart \
  lib/core/repository/tag_sync_repository.dart \
  lib/core/repository/project_sync_repository.dart \
  lib/core/service/data_backup_service.dart \
  lib/core/service/sync_session_service.dart \
  lib/core/service/sync_runtime_service.dart \
  lib/core/service/sync_runtime_telemetry_report_service.dart \
  lib/core/service/account_book_switch_sync_governance_service.dart \
  lib/core/service/account_book_delete_transfer_policy_service.dart \
  lib/core/service/import_edit_reconciliation_governance_service.dart \
  lib/core/service/account_book_import_sync_conflict_report_service.dart \
  lib/core/service/import_column_mapping_failfast_service.dart \
  test/account_category_sync_repository_test.dart \
  test/account_book_import_sync_conflict_report_service_test.dart \
  test/backup_restore_stale_session_regression_test.dart \
  test/import_column_mapping_failfast_service_test.dart \
  test/sync_runtime_backup_restore_rebind_regression_test.dart \
  test/sync_runtime_telemetry_report_service_test.dart \
  test/transaction_tag_project_sync_repository_test.dart \
  test/sync_cursor_store_and_lease_store_test.dart \
  test/sync_session_service_test.dart \
  test/sync_runtime_service_test.dart \
  test/data_backup_service_roundtrip_test.dart \
  test/data_backup_service_migration_regression_test.dart \
  test/auth_stale_session_release_gate_test.dart

flutter test \
  test/account_category_sync_repository_test.dart \
  test/account_book_import_sync_conflict_report_service_test.dart \
  test/backup_restore_stale_session_regression_test.dart \
  test/import_column_mapping_failfast_service_test.dart \
  test/sync_runtime_backup_restore_rebind_regression_test.dart \
  test/sync_runtime_telemetry_report_service_test.dart \
  test/transaction_tag_project_sync_repository_test.dart \
  test/sync_cursor_store_and_lease_store_test.dart \
  test/sync_session_service_test.dart \
  test/sync_runtime_service_test.dart \
  test/data_backup_service_roundtrip_test.dart \
  test/data_backup_service_migration_regression_test.dart \
  test/auth_stale_session_release_gate_test.dart
