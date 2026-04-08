import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/account_model.dart';
import '../database/book_model.dart';
import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/shared_ledger_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';
import '../entitlement/entitlement_service.dart';
import '../service/book_service.dart';
import 'sync_config.dart';
import 'sync_conflict_service.dart';
import 'sync_key_generator.dart';
import 'sync_state.dart';
import 'sync_tombstone_store.dart';

class _AccountSyncLookup {
  const _AccountSyncLookup({
    required this.localIds,
    required this.localIdBySyncKey,
  });

  final Set<int> localIds;
  final Map<String, int> localIdBySyncKey;
}

/// Incremental sync engine between local Isar and remote Supabase.
///
/// Syncs 5 tables: transactions, accounts, categories, tags, budgets.
/// Strategy: per-table cursor-based incremental sync using `updatedAt`.
/// Conflict resolution: detects conflicts and logs them for user resolution.
/// Falls back to last-write-wins when both sides changed within a threshold.
class SyncEngine extends ChangeNotifier {
  static const _prefKeyCursorPrefix = 'sync_cursor_';
  static const _prefKeySyncEnabled = 'sync_enabled';

  /// If both local and remote changed within this window, it's a conflict.
  static const _conflictThreshold = Duration(seconds: 60);

  static const _syncTables = [
    'accounts',
    'categories',
    'tags',
    'budgets',
    'transactions',
    'shared_ledgers',
    'shared_ledger_members',
  ];

  static const Map<String, String> _onConflictColumns = {
    'transactions': 'user_id,sync_key',
    'accounts': 'user_id,sync_key',
    'categories': 'user_id,key',
    'tags': 'user_id,key',
    'budgets': 'user_id,sync_key',
    'shared_ledgers': 'key',
    'shared_ledger_members': 'ledger_key,user_id',
  };

  static const _stableSyncKeyTables = {'transactions', 'accounts', 'budgets'};

  final Isar _isar;
  final EntitlementService _entitlement;
  late final SyncConflictService _conflictService;

  SyncState _state = const SyncState.disabled();
  Timer? _debounceTimer;

  SyncEngine({required Isar isar, required EntitlementService entitlement})
    : _isar = isar,
      _entitlement = entitlement {
    _conflictService = SyncConflictService(isar);
  }

  SyncState get state => _state;
  SyncConflictService get conflictService => _conflictService;

  bool get isAvailable => SyncConfig.isConfigured && _entitlement.tier.hasCloud;

  Future<void> init() async {
    if (!SyncConfig.isConfigured || !_entitlement.tier.hasCloud) {
      _state = const SyncState.disabled();
      notifyListeners();
      return;
    }

    try {
      if (Supabase.instance.client.auth.currentSession == null) {
        _state = const SyncState.disabled();
        notifyListeners();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefKeySyncEnabled) ?? true;
      if (!enabled) {
        _state = const SyncState.disabled();
        notifyListeners();
        return;
      }

      final conflictCount = await _conflictService.getPendingCount();
      _state = SyncState.idle(conflictCount: conflictCount);
      notifyListeners();
    } catch (e) {
      debugPrint('SyncEngine: init failed: $e');
      _state = SyncState.error('初始化失败: $e');
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeySyncEnabled, enabled);
    if (enabled && isAvailable) {
      _state = const SyncState.idle();
    } else {
      _state = const SyncState.disabled();
    }
    notifyListeners();
  }

  /// Run a full sync cycle across all tables.
  Future<void> sync() async {
    if (!isAvailable || _state.isSyncing) return;

    _state = const SyncState.syncing();
    notifyListeners();

    try {
      for (final table in _syncTables) {
        final cursor = await _getCursor(table);
        await _pushTable(table, cursor);
        await _pullTable(table, cursor);
        await _updateCursor(table);
      }

      await _conflictService.cleanupOldConflicts();
      final conflictCount = await _conflictService.getPendingCount();

      _state = SyncState.idle(
        lastSyncAt: DateTime.now(),
        conflictCount: conflictCount,
      );
    } catch (e) {
      debugPrint('SyncEngine: sync failed: $e');
      _state = SyncState.error('同步失败: $e');
    }
    notifyListeners();
  }

  /// Schedule a sync after a debounce period (30s).
  /// Call this after any local data change.
  void scheduleSync() {
    if (!isAvailable) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 30), () {
      sync();
    });
  }

  /// Called when app resumes from background.
  void onAppResumed() {
    if (!isAvailable) return;
    final lastSync = _state.lastSyncAt;
    if (lastSync == null ||
        DateTime.now().difference(lastSync).inMinutes >= 5) {
      sync();
    }
  }

  /// Cancel pending debounce timer.
  void cancelPendingSync() {
    _debounceTimer?.cancel();
  }

  /// Refresh conflict count and notify listeners.
  Future<void> refreshConflictCount() async {
    final count = await _conflictService.getPendingCount();
    if (_state.status == SyncStatus.idle) {
      _state = SyncState.idle(
        lastSyncAt: _state.lastSyncAt,
        conflictCount: count,
      );
      notifyListeners();
    }
  }

  // ── Per-table push/pull ──

  Future<void> _pushTable(String table, DateTime cursor) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final tombstones = await SyncTombstoneStore.listForTable(table);
    final onConflict = _onConflictColumns[table];
    if (tombstones.isNotEmpty && onConflict != null) {
      final uploadedEntityKeys = <String>[];
      final mappedTombstones = <Map<String, dynamic>>[];
      for (final entry in tombstones) {
        final prepared = _prepareTombstoneRow(
          table,
          userId,
          Map<String, dynamic>.from(entry.payload),
        );
        if (_stableSyncKeyTables.contains(table) &&
            _readString(prepared['sync_key']) == null) {
          continue;
        }
        mappedTombstones.add(prepared);
        uploadedEntityKeys.add(entry.entityKey);
      }

      if (mappedTombstones.isNotEmpty) {
        await client
            .from(table)
            .upsert(mappedTombstones, onConflict: onConflict);
        await SyncTombstoneStore.removeEntries(table, uploadedEntityKeys);
        debugPrint(
          'SyncEngine: pushed ${mappedTombstones.length} tombstones to $table',
        );
      }
    }

    final rows = await _getLocalChanges(table, cursor);
    if (rows.isEmpty) return;

    await _backfillLegacyRemoteRows(table, userId, rows);

    final mapped = rows
        .map((row) => _decoratePushRow(table, userId, row))
        .toList();
    if (onConflict == null) return;

    await client.from(table).upsert(mapped, onConflict: onConflict);
    debugPrint('SyncEngine: pushed ${rows.length} rows to $table');
  }

  Future<void> _pullTable(String table, DateTime cursor) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    dynamic query = client.from(table).select();
    switch (table) {
      case 'shared_ledgers':
        query = query
            .gt('updated_at', cursor.toIso8601String())
            .order('updated_at', ascending: true);
        break;
      case 'shared_ledger_members':
        query = query
            .gt('joined_at', cursor.toIso8601String())
            .order('joined_at', ascending: true);
        break;
      default:
        query = query
            .eq('user_id', userId)
            .gt('updated_at', cursor.toIso8601String())
            .order('updated_at', ascending: true);
        break;
    }

    final response = await query;
    final remoteRows = (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (remoteRows.isEmpty) return;

    await _applyRemoteChanges(table, remoteRows, userId);
    await _backfillPulledRemoteRows(table, userId, remoteRows);
    debugPrint('SyncEngine: pulled ${remoteRows.length} rows from $table');
  }

  Map<String, dynamic> _decoratePushRow(
    String table,
    String userId,
    Map<String, dynamic> row,
  ) {
    switch (table) {
      case 'shared_ledgers':
      case 'shared_ledger_members':
        return row;
      default:
        return {'user_id': userId, ...row};
    }
  }

  Map<String, dynamic> _prepareTombstoneRow(
    String table,
    String userId,
    Map<String, dynamic> row,
  ) {
    final prepared = Map<String, dynamic>.from(row);
    if (_stableSyncKeyTables.contains(table)) {
      final localId = _readInt(prepared['local_id']);
      if (_readString(prepared['sync_key']) == null && localId != null) {
        prepared['sync_key'] = _legacySyncKey(table, userId, localId);
      }
    }

    if (table == 'transactions') {
      final accountSyncKey =
          _readString(prepared['account_sync_key']) ??
          _legacyAccountSyncKey(userId, prepared['account_id']);
      final toAccountSyncKey =
          _readString(prepared['to_account_sync_key']) ??
          _legacyAccountSyncKey(userId, prepared['to_account_id']);
      if (accountSyncKey != null) {
        prepared['account_sync_key'] = accountSyncKey;
      }
      if (toAccountSyncKey != null) {
        prepared['to_account_sync_key'] = toAccountSyncKey;
      }
    }

    return _decoratePushRow(table, userId, prepared);
  }

  Future<void> _backfillLegacyRemoteRows(
    String table,
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    if (!_stableSyncKeyTables.contains(table)) return;

    final localIds = rows
        .map((row) => _readInt(row['local_id']))
        .whereType<int>()
        .toList();
    if (localIds.isEmpty) return;

    final selectColumns = switch (table) {
      'transactions' =>
        'id,local_id,sync_key,account_id,account_sync_key,to_account_id,to_account_sync_key',
      _ => 'id,local_id,sync_key',
    };

    final response = await Supabase.instance.client
        .from(table)
        .select(selectColumns)
        .eq('user_id', userId)
        .inFilter('local_id', localIds);

    final remoteRows = (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (remoteRows.isEmpty) return;

    final rowsByLocalId = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final localId = _readInt(row['local_id']);
      if (localId != null) {
        rowsByLocalId[localId] = row;
      }
    }

    for (final remoteRow in remoteRows) {
      final localId = _readInt(remoteRow['local_id']);
      if (localId == null) continue;
      final localRow = rowsByLocalId[localId];
      if (localRow == null) continue;

      final canonicalSyncKey =
          _resolveRemoteSyncKey(table, userId, remoteRow) ??
          _readString(localRow['sync_key']);
      if (canonicalSyncKey == null) continue;

      if (_readString(localRow['sync_key']) != canonicalSyncKey) {
        await _updateLocalSyncKey(table, localId, canonicalSyncKey);
        localRow['sync_key'] = canonicalSyncKey;
      }

      final patch = <String, dynamic>{};
      if (_readString(remoteRow['sync_key']) != canonicalSyncKey) {
        patch['sync_key'] = canonicalSyncKey;
      }

      if (table == 'transactions') {
        final accountSyncKey =
            _readString(remoteRow['account_sync_key']) ??
            _readString(localRow['account_sync_key']) ??
            _legacyAccountSyncKey(userId, remoteRow['account_id']);
        final toAccountSyncKey =
            _readString(remoteRow['to_account_sync_key']) ??
            _readString(localRow['to_account_sync_key']) ??
            _legacyAccountSyncKey(userId, remoteRow['to_account_id']);

        if (accountSyncKey != null &&
            _readString(remoteRow['account_sync_key']) != accountSyncKey) {
          patch['account_sync_key'] = accountSyncKey;
          localRow['account_sync_key'] = accountSyncKey;
        }

        if (toAccountSyncKey != null &&
            _readString(remoteRow['to_account_sync_key']) != toAccountSyncKey) {
          patch['to_account_sync_key'] = toAccountSyncKey;
          localRow['to_account_sync_key'] = toAccountSyncKey;
        }
      }

      if (patch.isNotEmpty) {
        await Supabase.instance.client
            .from(table)
            .update(patch)
            .eq('id', remoteRow['id'] as Object)
            .eq('user_id', userId);
      }
    }
  }

  Future<void> _backfillPulledRemoteRows(
    String table,
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    if (!_stableSyncKeyTables.contains(table)) return;

    for (final row in rows) {
      final patch = <String, dynamic>{};
      final syncKey = _resolveRemoteSyncKey(table, userId, row);
      if (syncKey != null && _readString(row['sync_key']) != syncKey) {
        patch['sync_key'] = syncKey;
      }

      if (table == 'transactions') {
        final accountSyncKey =
            _readString(row['account_sync_key']) ??
            _legacyAccountSyncKey(userId, row['account_id']);
        final toAccountSyncKey =
            _readString(row['to_account_sync_key']) ??
            _legacyAccountSyncKey(userId, row['to_account_id']);

        if (accountSyncKey != null &&
            _readString(row['account_sync_key']) != accountSyncKey) {
          patch['account_sync_key'] = accountSyncKey;
        }
        if (toAccountSyncKey != null &&
            _readString(row['to_account_sync_key']) != toAccountSyncKey) {
          patch['to_account_sync_key'] = toAccountSyncKey;
        }
      }

      if (patch.isEmpty) continue;

      await Supabase.instance.client
          .from(table)
          .update(patch)
          .eq('id', row['id'] as Object)
          .eq('user_id', userId);
    }
  }

  Future<void> _updateLocalSyncKey(
    String table,
    int localId,
    String syncKey,
  ) async {
    await _isar.writeTxn(() async {
      switch (table) {
        case 'transactions':
          final tx = await _isar.jiveTransactions.get(localId);
          if (tx == null || tx.syncKey == syncKey) return;
          tx.syncKey = syncKey;
          await _isar.jiveTransactions.put(tx);
          break;
        case 'accounts':
          final account = await _isar.jiveAccounts.get(localId);
          if (account == null || account.syncKey == syncKey) return;
          account.syncKey = syncKey;
          await _isar.jiveAccounts.put(account);
          break;
        case 'budgets':
          final budget = await _isar.jiveBudgets.get(localId);
          if (budget == null || budget.syncKey == syncKey) return;
          budget.syncKey = syncKey;
          await _isar.jiveBudgets.put(budget);
          break;
      }
    });
  }

  // ── Local change extraction ──

  Future<List<Map<String, dynamic>>> _getLocalChanges(
    String table,
    DateTime cursor,
  ) async {
    switch (table) {
      case 'transactions':
        return _getTransactionChanges(cursor);
      case 'accounts':
        return _getAccountChanges(cursor);
      case 'categories':
        return _getCategoryChanges(cursor);
      case 'tags':
        return _getTagChanges(cursor);
      case 'budgets':
        return _getBudgetChanges(cursor);
      case 'shared_ledgers':
        return _getSharedLedgerChanges(cursor);
      case 'shared_ledger_members':
        return _getSharedLedgerMemberChanges(cursor);
      default:
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getTransactionChanges(
    DateTime cursor,
  ) async {
    final items = await _isar.jiveTransactions
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    final accountSyncKeyById = await _loadAccountSyncKeyById();
    final bookKeyById = await _loadBookKeyById();

    return items
        .map(
          (tx) => {
            'local_id': tx.id,
            'sync_key': tx.syncKey,
            'book_key': _bookKeyFor(tx.bookId, bookKeyById),
            'amount': tx.amount,
            'source': tx.source,
            'type': tx.type,
            'timestamp': tx.timestamp.toIso8601String(),
            'category_key': tx.categoryKey,
            'sub_category_key': tx.subCategoryKey,
            'category': tx.category,
            'sub_category': tx.subCategory,
            'note': tx.note,
            'account_id': tx.accountId,
            'account_sync_key': _accountSyncKeyFor(
              tx.accountId,
              accountSyncKeyById,
            ),
            'to_account_id': tx.toAccountId,
            'to_account_sync_key': _accountSyncKeyFor(
              tx.toAccountId,
              accountSyncKeyById,
            ),
            'raw_text': tx.rawText,
            'deleted_at': null,
            'updated_at': tx.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getAccountChanges(DateTime cursor) async {
    final items = await _isar.jiveAccounts
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    final bookKeyById = await _loadBookKeyById();

    return items
        .map(
          (account) => {
            'local_id': account.id,
            'sync_key': account.syncKey,
            'book_key': _bookKeyFor(account.bookId, bookKeyById),
            'name': account.name,
            'type': account.type,
            'sub_type': account.subType,
            'opening_balance': account.openingBalance,
            'credit_limit': account.creditLimit,
            'currency': account.currency,
            'is_archived': account.isArchived,
            'updated_at': account.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getCategoryChanges(
    DateTime cursor,
  ) async {
    final items = await _isar.jiveCategorys
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    return items
        .map(
          (category) => {
            'local_id': category.id,
            'key': category.key,
            'name': category.name,
            'parent_key': category.parentKey,
            'icon_name': category.iconName,
            'is_income': category.isIncome,
            'is_system': category.isSystem,
            'is_hidden': category.isHidden,
            'sort_order': category.order,
            'updated_at': category.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getTagChanges(DateTime cursor) async {
    final items = await _isar.jiveTags
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    return items
        .map(
          (tag) => {
            'local_id': tag.id,
            'key': tag.key,
            'name': tag.name,
            'group_key': tag.groupKey,
            'color_hex': tag.colorHex,
            'is_archived': tag.isArchived,
            'sort_order': tag.order,
            'updated_at': tag.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getBudgetChanges(DateTime cursor) async {
    final items = await _isar.jiveBudgets
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    final bookKeyById = await _loadBookKeyById();

    return items
        .map(
          (budget) => {
            'local_id': budget.id,
            'sync_key': budget.syncKey,
            'book_key': _bookKeyFor(budget.bookId, bookKeyById),
            'name': budget.name,
            'amount': budget.amount,
            'period': budget.period,
            'start_date': budget.startDate.toIso8601String(),
            'end_date': budget.endDate.toIso8601String(),
            'category_keys': budget.categoryKey ?? '',
            'is_active': budget.isActive,
            'carry_over': budget.rollover,
            'deleted_at': null,
            'updated_at': budget.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getSharedLedgerChanges(
    DateTime cursor,
  ) async {
    final items = await _isar.jiveSharedLedgers
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    return items
        .map(
          (ledger) => {
            'local_id': ledger.id,
            'key': ledger.key,
            'name': ledger.name,
            'owner_user_id': ledger.ownerUserId,
            'currency': ledger.currency,
            'invite_code': ledger.inviteCode,
            'member_count': ledger.memberCount,
            'updated_at': ledger.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getSharedLedgerMemberChanges(
    DateTime cursor,
  ) async {
    final items = await _isar.jiveSharedLedgerMembers.where().findAll();
    return items
        .map(
          (member) => {
            'local_id': member.id,
            'ledger_key': member.ledgerKey,
            'user_id': member.userId,
            'display_name': member.displayName,
            'role': member.role,
            'joined_at': member.joinedAt.toIso8601String(),
          },
        )
        .toList();
  }

  // ── Remote change application with conflict detection ──

  Future<void> _applyRemoteChanges(
    String table,
    List<Map<String, dynamic>> rows,
    String userId,
  ) async {
    switch (table) {
      case 'transactions':
        await _applyTransactionChanges(rows, userId);
        break;
      case 'accounts':
        await _applyAccountChanges(rows, userId);
        break;
      case 'categories':
        await _applyCategoryChanges(rows);
        break;
      case 'tags':
        await _applyTagChanges(rows);
        break;
      case 'budgets':
        await _applyBudgetChanges(rows, userId);
        break;
      case 'shared_ledgers':
        await _applySharedLedgerChanges(rows);
        break;
      case 'shared_ledger_members':
        await _applySharedLedgerMemberChanges(rows);
        break;
    }
  }

  bool _isRealConflict(
    DateTime localUpdatedAt,
    DateTime remoteUpdatedAt,
    DateTime cursor,
  ) {
    final localChangedSinceCursor = localUpdatedAt.isAfter(cursor);
    final remoteChangedSinceCursor = remoteUpdatedAt.isAfter(cursor);
    if (!localChangedSinceCursor || !remoteChangedSinceCursor) return false;

    final diff = localUpdatedAt.difference(remoteUpdatedAt).abs();
    return diff < _conflictThreshold;
  }

  Future<void> _applyTransactionChanges(
    List<Map<String, dynamic>> rows,
    String userId,
  ) async {
    final cursor = await _getCursor('transactions');
    final accountLookup = await _loadAccountSyncLookup();
    final bookIdByKey = await _loadBookIdByKey();
    final pendingTombstones = await SyncTombstoneStore.mapForTable(
      'transactions',
    );
    final clearedTombstones = <String>{};

    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final syncKey = _resolveRemoteSyncKey('transactions', userId, row);
        if (localId == null && syncKey == null) continue;
        final tombstoneEntityKey = _pendingEntityKeyForRow(
          'transactions',
          userId,
          row,
        );
        final pendingTombstone = tombstoneEntityKey == null
            ? null
            : pendingTombstones[tombstoneEntityKey];

        JiveTransaction? existing;
        if (syncKey != null) {
          existing = await _isar.jiveTransactions
              .filter()
              .syncKeyEqualTo(syncKey)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveTransactions.get(localId);

        final remoteUpdatedAt =
            _parseDateTime(row['updated_at']) ?? DateTime.now();
        final remoteDeletedAt = _parseRemoteDate(row['deleted_at']);

        if (remoteDeletedAt != null) {
          if (pendingTombstone != null && tombstoneEntityKey != null) {
            clearedTombstones.add(tombstoneEntityKey);
          }

          if (existing == null) continue;

          if (_isRealConflict(existing.updatedAt, remoteUpdatedAt, cursor)) {
            await _conflictService.recordConflict(
              table: 'transactions',
              localId: existing.id,
              localData: _transactionToMap(existing),
              remoteData: row,
              localUpdatedAt: existing.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            continue;
          }
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;

          await _isar.jiveTransactions.delete(existing.id);
          continue;
        }

        if (pendingTombstone != null) {
          final pendingLocalId =
              existing?.id ??
              _readInt(pendingTombstone.payload['local_id']) ??
              localId;
          if (_isRealConflict(
            pendingTombstone.deletedAt,
            remoteUpdatedAt,
            cursor,
          )) {
            if (pendingLocalId != null) {
              await _conflictService.recordConflict(
                table: 'transactions',
                localId: pendingLocalId,
                localData: pendingTombstone.payload,
                remoteData: row,
                localUpdatedAt: pendingTombstone.deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
              );
            }
            continue;
          }

          if (pendingTombstone.deletedAt.isAfter(remoteUpdatedAt)) continue;
          if (tombstoneEntityKey != null) {
            clearedTombstones.add(tombstoneEntityKey);
          }
        }

        if (existing != null) {
          if (_isRealConflict(existing.updatedAt, remoteUpdatedAt, cursor)) {
            await _conflictService.recordConflict(
              table: 'transactions',
              localId: existing.id,
              localData: _transactionToMap(existing),
              remoteData: row,
              localUpdatedAt: existing.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            continue;
          }
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;
        }

        final tx = existing ?? JiveTransaction();
        if (syncKey != null) {
          tx.syncKey = syncKey;
        }
        tx.amount = _readDouble(row['amount']) ?? 0;
        tx.source = _readString(row['source']) ?? '';
        tx.type = _readString(row['type']);
        tx.timestamp = _parseDateTime(row['timestamp']) ?? remoteUpdatedAt;
        tx.categoryKey = _readString(row['category_key']);
        tx.subCategoryKey = _readString(row['sub_category_key']);
        tx.category = _readString(row['category']);
        tx.subCategory = _readString(row['sub_category']);
        tx.note = _readString(row['note']);
        tx.accountId = _resolveRemoteAccountId(row, userId, accountLookup);
        tx.toAccountId = _resolveRemoteTransferAccountId(
          row,
          userId,
          accountLookup,
        );
        tx.bookId = _resolveRemoteBookId(row, bookIdByKey);
        tx.rawText = _readString(row['raw_text']);
        tx.updatedAt = remoteUpdatedAt;
        await _isar.jiveTransactions.put(tx);
      }
    });

    if (clearedTombstones.isNotEmpty) {
      await SyncTombstoneStore.removeEntries('transactions', clearedTombstones);
    }
  }

  Map<String, dynamic> _transactionToMap(JiveTransaction tx) => {
    'local_id': tx.id,
    'sync_key': tx.syncKey,
    'amount': tx.amount,
    'source': tx.source,
    'type': tx.type,
    'timestamp': tx.timestamp.toIso8601String(),
    'category_key': tx.categoryKey,
    'sub_category_key': tx.subCategoryKey,
    'category': tx.category,
    'sub_category': tx.subCategory,
    'note': tx.note,
    'account_id': tx.accountId,
    'to_account_id': tx.toAccountId,
    'raw_text': tx.rawText,
    'deleted_at': null,
    'updated_at': tx.updatedAt.toIso8601String(),
  };

  Future<void> _applyAccountChanges(
    List<Map<String, dynamic>> rows,
    String userId,
  ) async {
    final bookIdByKey = await _loadBookIdByKey();

    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final syncKey = _resolveRemoteSyncKey('accounts', userId, row);
        if (localId == null && syncKey == null) continue;

        JiveAccount? existing;
        if (syncKey != null) {
          existing = await _isar.jiveAccounts
              .filter()
              .syncKeyEqualTo(syncKey)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveAccounts.get(localId);

        final remoteUpdatedAt =
            _parseDateTime(row['updated_at']) ?? DateTime.now();
        if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
          continue;
        }

        final account = existing ?? JiveAccount();
        if (syncKey != null) {
          account.syncKey = syncKey;
        }
        account.key = existing?.key ?? syncKey ?? account.key;
        account.name = _readString(row['name']) ?? existing?.name ?? '';
        account.type = _readString(row['type']) ?? existing?.type ?? 'asset';
        account.subType = _readString(row['sub_type']) ?? existing?.subType;
        account.openingBalance =
            _readDouble(row['opening_balance']) ??
            existing?.openingBalance ??
            0;
        account.creditLimit =
            _readDouble(row['credit_limit']) ?? existing?.creditLimit;
        account.currency =
            _readString(row['currency']) ?? existing?.currency ?? 'CNY';
        account.iconName = existing?.iconName ?? 'account_balance_wallet';
        account.groupName = existing?.groupName;
        account.order = _readInt(row['sort_order']) ?? existing?.order ?? 0;
        account.includeInBalance = existing?.includeInBalance ?? true;
        account.isHidden = existing?.isHidden ?? false;
        account.isArchived =
            row['is_archived'] as bool? ?? existing?.isArchived ?? false;
        account.bookId = _resolveRemoteBookId(row, bookIdByKey);
        account.updatedAt = remoteUpdatedAt;
        await _isar.jiveAccounts.put(account);
      }
    });
  }

  Future<void> _applyCategoryChanges(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final key = _readString(row['key']);
        if (localId == null && key == null) continue;

        JiveCategory? existing;
        if (key != null) {
          existing = await _isar.jiveCategorys
              .filter()
              .keyEqualTo(key)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveCategorys.get(localId);

        final category = existing ?? JiveCategory();
        category.key = key ?? existing?.key ?? '';
        category.name = _readString(row['name']) ?? existing?.name ?? '';
        category.parentKey =
            _readString(row['parent_key']) ?? existing?.parentKey;
        category.iconName =
            _readString(row['icon_name']) ?? existing?.iconName ?? 'category';
        category.isIncome =
            row['is_income'] as bool? ?? existing?.isIncome ?? false;
        category.isSystem =
            row['is_system'] as bool? ?? existing?.isSystem ?? false;
        category.isHidden =
            row['is_hidden'] as bool? ?? existing?.isHidden ?? false;
        category.order = _readInt(row['sort_order']) ?? existing?.order ?? 0;
        category.iconForceTinted = existing?.iconForceTinted ?? false;
        category.excludeFromBudget = existing?.excludeFromBudget ?? false;
        category.updatedAt =
            _parseDateTime(row['updated_at']) ??
            existing?.updatedAt ??
            DateTime.now();
        await _isar.jiveCategorys.put(category);
      }
    });
  }

  Future<void> _applyTagChanges(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final key = _readString(row['key']);
        if (localId == null && key == null) continue;

        JiveTag? existing;
        if (key != null) {
          existing = await _isar.jiveTags.filter().keyEqualTo(key).findFirst();
        }
        existing ??= localId == null ? null : await _isar.jiveTags.get(localId);

        final tag = existing ?? JiveTag();
        final remoteUpdatedAt =
            _parseDateTime(row['updated_at']) ?? DateTime.now();
        tag.key = key ?? existing?.key ?? '';
        tag.name = _readString(row['name']) ?? existing?.name ?? '';
        tag.groupKey = _readString(row['group_key']) ?? existing?.groupKey;
        tag.colorHex = _readString(row['color_hex']) ?? existing?.colorHex;
        tag.iconName = existing?.iconName;
        tag.iconText = existing?.iconText;
        tag.order = _readInt(row['sort_order']) ?? existing?.order ?? 0;
        tag.isArchived =
            row['is_archived'] as bool? ?? existing?.isArchived ?? false;
        tag.usageCount = existing?.usageCount ?? 0;
        tag.lastUsedAt = existing?.lastUsedAt;
        tag.createdAt = existing?.createdAt ?? remoteUpdatedAt;
        tag.updatedAt = remoteUpdatedAt;
        await _isar.jiveTags.put(tag);
      }
    });
  }

  Future<void> _applyBudgetChanges(
    List<Map<String, dynamic>> rows,
    String userId,
  ) async {
    final cursor = await _getCursor('budgets');
    final bookIdByKey = await _loadBookIdByKey();
    final pendingTombstones = await SyncTombstoneStore.mapForTable('budgets');
    final clearedTombstones = <String>{};

    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final syncKey = _resolveRemoteSyncKey('budgets', userId, row);
        if (localId == null && syncKey == null) continue;
        final tombstoneEntityKey = _pendingEntityKeyForRow(
          'budgets',
          userId,
          row,
        );
        final pendingTombstone = tombstoneEntityKey == null
            ? null
            : pendingTombstones[tombstoneEntityKey];

        JiveBudget? existing;
        if (syncKey != null) {
          existing = await _isar.jiveBudgets
              .filter()
              .syncKeyEqualTo(syncKey)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveBudgets.get(localId);

        final remoteUpdatedAt =
            _parseDateTime(row['updated_at']) ?? DateTime.now();
        final remoteDeletedAt = _parseRemoteDate(row['deleted_at']);

        if (remoteDeletedAt != null) {
          if (pendingTombstone != null && tombstoneEntityKey != null) {
            clearedTombstones.add(tombstoneEntityKey);
          }

          if (existing == null) continue;
          if (_isRealConflict(existing.updatedAt, remoteUpdatedAt, cursor)) {
            await _conflictService.recordConflict(
              table: 'budgets',
              localId: existing.id,
              localData: _budgetToMap(existing),
              remoteData: row,
              localUpdatedAt: existing.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            continue;
          }
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;

          await _isar.jiveBudgetUsages
              .filter()
              .budgetIdEqualTo(existing.id)
              .deleteAll();
          await _isar.jiveBudgets.delete(existing.id);
          continue;
        }

        if (pendingTombstone != null) {
          final pendingLocalId =
              existing?.id ??
              _readInt(pendingTombstone.payload['local_id']) ??
              localId;
          if (_isRealConflict(
            pendingTombstone.deletedAt,
            remoteUpdatedAt,
            cursor,
          )) {
            if (pendingLocalId != null) {
              await _conflictService.recordConflict(
                table: 'budgets',
                localId: pendingLocalId,
                localData: pendingTombstone.payload,
                remoteData: row,
                localUpdatedAt: pendingTombstone.deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
              );
            }
            continue;
          }

          if (pendingTombstone.deletedAt.isAfter(remoteUpdatedAt)) continue;
          if (tombstoneEntityKey != null) {
            clearedTombstones.add(tombstoneEntityKey);
          }
        }

        if (existing != null) {
          if (_isRealConflict(existing.updatedAt, remoteUpdatedAt, cursor)) {
            await _conflictService.recordConflict(
              table: 'budgets',
              localId: existing.id,
              localData: _budgetToMap(existing),
              remoteData: row,
              localUpdatedAt: existing.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            continue;
          }
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;
        }

        final budget = existing ?? JiveBudget();
        if (syncKey != null) {
          budget.syncKey = syncKey;
        }
        budget.name = _readString(row['name']) ?? existing?.name ?? '';
        budget.amount = _readDouble(row['amount']) ?? existing?.amount ?? 0;
        budget.period =
            _readString(row['period']) ?? existing?.period ?? 'monthly';
        budget.startDate =
            _parseDateTime(row['start_date']) ??
            existing?.startDate ??
            remoteUpdatedAt;
        budget.endDate =
            _parseDateTime(row['end_date']) ??
            existing?.endDate ??
            remoteUpdatedAt;
        final categoryKeys = row['category_keys'];
        if (categoryKeys is String) {
          budget.categoryKey = categoryKeys.trim().isEmpty
              ? null
              : categoryKeys;
        } else if (categoryKeys is List && categoryKeys.isNotEmpty) {
          budget.categoryKey = categoryKeys.first.toString();
        }
        budget.isActive =
            row['is_active'] as bool? ?? existing?.isActive ?? true;
        budget.rollover =
            row['carry_over'] as bool? ?? existing?.rollover ?? false;
        budget.currency = existing?.currency ?? 'CNY';
        budget.bookId = _resolveRemoteBookId(row, bookIdByKey);
        budget.createdAt = existing?.createdAt ?? remoteUpdatedAt;
        budget.updatedAt = remoteUpdatedAt;
        await _isar.jiveBudgets.put(budget);
      }
    });

    if (clearedTombstones.isNotEmpty) {
      await SyncTombstoneStore.removeEntries('budgets', clearedTombstones);
    }
  }

  Map<String, dynamic> _budgetToMap(JiveBudget budget) => {
    'local_id': budget.id,
    'sync_key': budget.syncKey,
    'name': budget.name,
    'amount': budget.amount,
    'period': budget.period,
    'start_date': budget.startDate.toIso8601String(),
    'end_date': budget.endDate.toIso8601String(),
    'category_keys': budget.categoryKey ?? '',
    'is_active': budget.isActive,
    'carry_over': budget.rollover,
    'deleted_at': null,
    'updated_at': budget.updatedAt.toIso8601String(),
  };

  Future<void> _applySharedLedgerChanges(
    List<Map<String, dynamic>> rows,
  ) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final key = _readString(row['key']);
        if (localId == null && key == null) continue;

        JiveSharedLedger? existing;
        if (key != null) {
          existing = await _isar.jiveSharedLedgers
              .filter()
              .keyEqualTo(key)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveSharedLedgers.get(localId);

        final remoteUpdatedAt =
            _parseDateTime(row['updated_at']) ?? DateTime.now();
        if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
          continue;
        }

        final ledger = existing ?? JiveSharedLedger();
        ledger.key = key ?? existing?.key ?? '';
        ledger.name = _readString(row['name']) ?? existing?.name ?? '';
        ledger.ownerUserId =
            _readString(row['owner_user_id']) ?? existing?.ownerUserId ?? '';
        ledger.currency =
            _readString(row['currency']) ?? existing?.currency ?? 'CNY';
        ledger.inviteCode =
            _readString(row['invite_code']) ?? existing?.inviteCode;
        ledger.memberCount =
            _readInt(row['member_count']) ?? existing?.memberCount ?? 1;
        ledger.createdAt = existing?.createdAt ?? remoteUpdatedAt;
        ledger.updatedAt = remoteUpdatedAt;
        await _isar.jiveSharedLedgers.put(ledger);
      }
    });
  }

  Future<void> _applySharedLedgerMemberChanges(
    List<Map<String, dynamic>> rows,
  ) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = _readInt(row['local_id']);
        final ledgerKey = _readString(row['ledger_key']);
        final userId = _readString(row['user_id']);
        if (ledgerKey == null || userId == null) {
          if (localId == null) continue;
        }

        JiveSharedLedgerMember? existing;
        if (ledgerKey != null && userId != null) {
          existing = await _isar.jiveSharedLedgerMembers
              .filter()
              .ledgerKeyEqualTo(ledgerKey)
              .and()
              .userIdEqualTo(userId)
              .findFirst();
        }
        existing ??= localId == null
            ? null
            : await _isar.jiveSharedLedgerMembers.get(localId);

        final member = existing ?? JiveSharedLedgerMember();
        member.ledgerKey = ledgerKey ?? existing?.ledgerKey ?? '';
        member.userId = userId ?? existing?.userId ?? '';
        member.displayName =
            _readString(row['display_name']) ?? existing?.displayName ?? '';
        member.role = _readString(row['role']) ?? existing?.role ?? 'member';
        member.joinedAt =
            _parseDateTime(row['joined_at']) ??
            existing?.joinedAt ??
            DateTime.now();
        await _isar.jiveSharedLedgerMembers.put(member);
      }
    });
  }

  // ── Helpers ──

  Future<Map<int, String>> _loadBookKeyById() async {
    final books = await _isar.jiveBooks.where().findAll();
    return {for (final book in books) book.id: book.key};
  }

  Future<Map<String, int>> _loadBookIdByKey() async {
    final books = await _isar.jiveBooks.where().findAll();
    return {for (final book in books) book.key: book.id};
  }

  Future<Map<int, String>> _loadAccountSyncKeyById() async {
    final accounts = await _isar.jiveAccounts.where().findAll();
    return {for (final account in accounts) account.id: account.syncKey};
  }

  Future<_AccountSyncLookup> _loadAccountSyncLookup() async {
    final accounts = await _isar.jiveAccounts.where().findAll();
    return _AccountSyncLookup(
      localIds: accounts.map((account) => account.id).toSet(),
      localIdBySyncKey: {
        for (final account in accounts)
          if (account.syncKey.trim().isNotEmpty) account.syncKey: account.id,
      },
    );
  }

  String _bookKeyFor(int? bookId, Map<int, String> bookKeyById) {
    if (bookId == null) return BookService.defaultBookKey;
    return bookKeyById[bookId] ?? BookService.defaultBookKey;
  }

  String? _accountSyncKeyFor(
    int? accountId,
    Map<int, String> accountSyncKeyById,
  ) {
    if (accountId == null) return null;
    return accountSyncKeyById[accountId];
  }

  int? _resolveRemoteBookId(
    Map<String, dynamic> row,
    Map<String, int> bookIdByKey,
  ) {
    final bookKey = _readString(row['book_key']) ?? BookService.defaultBookKey;
    return bookIdByKey[bookKey];
  }

  int? _resolveRemoteAccountId(
    Map<String, dynamic> row,
    String userId,
    _AccountSyncLookup lookup,
  ) {
    final accountSyncKey =
        _readString(row['account_sync_key']) ??
        _legacyAccountSyncKey(userId, row['account_id']);
    if (accountSyncKey != null) {
      final localId = lookup.localIdBySyncKey[accountSyncKey];
      if (localId != null) return localId;
    }

    final legacyLocalId = _readInt(row['account_id']);
    if (legacyLocalId != null && lookup.localIds.contains(legacyLocalId)) {
      return legacyLocalId;
    }
    return null;
  }

  int? _resolveRemoteTransferAccountId(
    Map<String, dynamic> row,
    String userId,
    _AccountSyncLookup lookup,
  ) {
    final accountSyncKey =
        _readString(row['to_account_sync_key']) ??
        _legacyAccountSyncKey(userId, row['to_account_id']);
    if (accountSyncKey != null) {
      final localId = lookup.localIdBySyncKey[accountSyncKey];
      if (localId != null) return localId;
    }

    final legacyLocalId = _readInt(row['to_account_id']);
    if (legacyLocalId != null && lookup.localIds.contains(legacyLocalId)) {
      return legacyLocalId;
    }
    return null;
  }

  String? _resolveRemoteSyncKey(
    String table,
    String userId,
    Map<String, dynamic> row,
  ) {
    final syncKey = _readString(row['sync_key']);
    if (syncKey != null) return syncKey;

    final localId = _readInt(row['local_id']);
    if (localId == null || !_stableSyncKeyTables.contains(table)) {
      return null;
    }
    return _legacySyncKey(table, userId, localId);
  }

  String _legacySyncKey(String table, String userId, int localId) {
    final prefix = switch (table) {
      'transactions' => 'tx',
      'accounts' => 'acct',
      'budgets' => 'budget',
      _ => table,
    };
    return SyncKeyGenerator.generateDeterministic(
      prefix,
      '$table:$userId:$localId',
    );
  }

  String? _legacyAccountSyncKey(String userId, dynamic localIdValue) {
    final localId = _readInt(localIdValue);
    if (localId == null) return null;
    return _legacySyncKey('accounts', userId, localId);
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  DateTime? _parseRemoteDate(dynamic value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // ── Cursor management (per-table) ──

  Future<DateTime> _getCursor(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefKeyCursorPrefix$table');
    if (stored != null) return DateTime.parse(stored);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _updateCursor(String table) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefKeyCursorPrefix$table',
      DateTime.now().toIso8601String(),
    );
  }

  String _syncEntityKey(String syncKey) => 'sync:$syncKey';

  String _localEntityKey(int localId) => 'local:$localId';

  String? _pendingEntityKeyForRow(
    String table,
    String userId,
    Map<String, dynamic> row,
  ) {
    final syncKey = _resolveRemoteSyncKey(table, userId, row);
    if (syncKey != null) return _syncEntityKey(syncKey);

    final localId = _readInt(row['local_id']);
    if (localId != null) return _localEntityKey(localId);
    return null;
  }
}
