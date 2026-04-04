import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/account_model.dart';
import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/shared_ledger_model.dart';
import '../database/transaction_model.dart';
import '../entitlement/entitlement_service.dart';
import 'sync_config.dart';
import 'sync_conflict_service.dart';
import 'sync_state.dart';

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
    'transactions',
    'accounts',
    'categories',
    'tags',
    'budgets',
    'shared_ledgers',
    'shared_ledger_members',
  ];

  final Isar _isar;
  final EntitlementService _entitlement;
  late final SyncConflictService _conflictService;

  SyncState _state = const SyncState.disabled();
  Timer? _debounceTimer;

  SyncEngine({
    required Isar isar,
    required EntitlementService entitlement,
  })  : _isar = isar,
        _entitlement = entitlement {
    _conflictService = SyncConflictService(isar);
  }

  SyncState get state => _state;
  SyncConflictService get conflictService => _conflictService;

  bool get isAvailable =>
      SyncConfig.isConfigured && _entitlement.tier.hasCloud;

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

      // Clean up old resolved conflicts periodically
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
    // Only sync if last sync was more than 5 minutes ago
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

    final rows = await _getLocalChanges(table, cursor);
    if (rows.isEmpty) return;

    final mapped = rows.map((r) => {'user_id': userId, ...r}).toList();
    await client.from(table).upsert(mapped, onConflict: 'user_id,local_id');
    debugPrint('SyncEngine: pushed ${rows.length} rows to $table');
  }

  Future<void> _pullTable(String table, DateTime cursor) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await client
        .from(table)
        .select()
        .eq('user_id', userId)
        .gt('updated_at', cursor.toIso8601String())
        .order('updated_at', ascending: true);

    final remoteRows = response as List<dynamic>;
    if (remoteRows.isEmpty) return;

    await _applyRemoteChanges(table, remoteRows);
    debugPrint('SyncEngine: pulled ${remoteRows.length} rows from $table');
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

  Future<List<Map<String, dynamic>>> _getTransactionChanges(DateTime cursor) async {
    final items = await _isar.jiveTransactions
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    return items.map((tx) => {
      'local_id': tx.id,
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
      'raw_text': tx.rawText,
      'updated_at': tx.updatedAt.toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getAccountChanges(DateTime cursor) async {
    final items = await _isar.jiveAccounts.where().findAll();
    return items.map((a) => {
      'local_id': a.id,
      'name': a.name,
      'type': a.type,
      'sub_type': a.subType,
      'opening_balance': a.openingBalance,
      'credit_limit': a.creditLimit,
      'currency': a.currency,
      'is_archived': a.isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getCategoryChanges(DateTime cursor) async {
    final items = await _isar.jiveCategorys.where().findAll();
    return items.map((c) => {
      'local_id': c.id,
      'key': c.key,
      'name': c.name,
      'parent_key': c.parentKey,
      'icon_name': c.iconName,
      'is_income': c.isIncome,
      'is_system': c.isSystem,
      'is_hidden': c.isHidden,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getTagChanges(DateTime cursor) async {
    final items = await _isar.jiveTags.where().findAll();
    return items.map((t) => {
      'local_id': t.id,
      'key': t.key,
      'name': t.name,
      'group_key': t.groupKey,
      'color_hex': t.colorHex,
      'is_archived': t.isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getBudgetChanges(DateTime cursor) async {
    final items = await _isar.jiveBudgets.where().findAll();
    return items.map((b) => {
      'local_id': b.id,
      'name': b.name,
      'amount': b.amount,
      'period': b.period,
      'start_date': b.startDate.toIso8601String(),
      'end_date': b.endDate.toIso8601String(),
      'category_keys': b.categoryKey ?? '',
      'is_active': b.isActive,
      'carry_over': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getSharedLedgerChanges(DateTime cursor) async {
    final items = await _isar.jiveSharedLedgers
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();
    return items.map((l) => {
      'local_id': l.id,
      'key': l.key,
      'name': l.name,
      'owner_user_id': l.ownerUserId,
      'currency': l.currency,
      'invite_code': l.inviteCode,
      'member_count': l.memberCount,
      'updated_at': l.updatedAt.toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getSharedLedgerMemberChanges(DateTime cursor) async {
    final items = await _isar.jiveSharedLedgerMembers.where().findAll();
    return items.map((m) => {
      'local_id': m.id,
      'ledger_key': m.ledgerKey,
      'user_id': m.userId,
      'display_name': m.displayName,
      'role': m.role,
      'joined_at': m.joinedAt.toIso8601String(),
    }).toList();
  }

  // ── Remote change application with conflict detection ──

  Future<void> _applyRemoteChanges(String table, List<dynamic> rows) async {
    switch (table) {
      case 'transactions':
        await _applyTransactionChanges(rows);
        break;
      case 'accounts':
        await _applyAccountChanges(rows);
        break;
      case 'categories':
        await _applyCategoryChanges(rows);
        break;
      case 'tags':
        await _applyTagChanges(rows);
        break;
      case 'budgets':
        await _applyBudgetChanges(rows);
        break;
      case 'shared_ledgers':
        await _applySharedLedgerChanges(rows);
        break;
      case 'shared_ledger_members':
        await _applySharedLedgerMemberChanges(rows);
        break;
    }
  }

  /// Check if both local and remote changed recently (true conflict).
  /// Returns true if it's a real conflict that needs user attention.
  bool _isRealConflict(DateTime localUpdatedAt, DateTime remoteUpdatedAt, DateTime cursor) {
    // Both changed since last sync
    final localChangedSinceCursor = localUpdatedAt.isAfter(cursor);
    final remoteChangedSinceCursor = remoteUpdatedAt.isAfter(cursor);
    if (!localChangedSinceCursor || !remoteChangedSinceCursor) return false;

    // Both changed within a short window of each other
    final diff = localUpdatedAt.difference(remoteUpdatedAt).abs();
    return diff < _conflictThreshold;
  }

  Future<void> _applyTransactionChanges(List<dynamic> rows) async {
    final cursor = await _getCursor('transactions');
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveTransactions.get(localId);
        final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

        if (existing != null) {
          // Detect conflict: both sides changed since last sync
          if (_isRealConflict(existing.updatedAt, remoteUpdatedAt, cursor)) {
            await _conflictService.recordConflict(
              table: 'transactions',
              localId: localId,
              localData: _transactionToMap(existing),
              remoteData: Map<String, dynamic>.from(row as Map),
              localUpdatedAt: existing.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            continue; // Skip update, let user resolve
          }

          // No conflict — last-write-wins
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;
        }

        final tx = existing ?? JiveTransaction();
        tx.id = localId;
        tx.amount = (row['amount'] as num).toDouble();
        tx.source = row['source'] as String? ?? '';
        tx.type = row['type'] as String?;
        tx.timestamp = DateTime.parse(row['timestamp'] as String);
        tx.categoryKey = row['category_key'] as String?;
        tx.subCategoryKey = row['sub_category_key'] as String?;
        tx.category = row['category'] as String?;
        tx.subCategory = row['sub_category'] as String?;
        tx.note = row['note'] as String?;
        tx.accountId = row['account_id'] as int?;
        tx.rawText = row['raw_text'] as String?;
        tx.updatedAt = remoteUpdatedAt;
        await _isar.jiveTransactions.put(tx);
      }
    });
  }

  Map<String, dynamic> _transactionToMap(JiveTransaction tx) => {
    'local_id': tx.id,
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
    'raw_text': tx.rawText,
    'updated_at': tx.updatedAt.toIso8601String(),
  };

  Future<void> _applyAccountChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveAccounts.get(localId);
        final a = existing ?? JiveAccount();
        a.id = localId;
        a.name = row['name'] as String? ?? '';
        a.type = row['type'] as String? ?? 'asset';
        a.subType = row['sub_type'] as String?;
        a.openingBalance = (row['opening_balance'] as num?)?.toDouble() ?? 0;
        a.creditLimit = (row['credit_limit'] as num?)?.toDouble();
        a.currency = row['currency'] as String? ?? 'CNY';
        a.isArchived = row['is_archived'] as bool? ?? false;
        await _isar.jiveAccounts.put(a);
      }
    });
  }

  Future<void> _applyCategoryChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveCategorys.get(localId);
        final c = existing ?? JiveCategory();
        c.id = localId;
        c.key = row['key'] as String? ?? '';
        c.name = row['name'] as String? ?? '';
        c.parentKey = row['parent_key'] as String?;
        c.iconName = row['icon_name'] as String? ?? 'category';
        c.isIncome = row['is_income'] as bool? ?? false;
        c.isSystem = row['is_system'] as bool? ?? false;
        c.isHidden = row['is_hidden'] as bool? ?? false;
        await _isar.jiveCategorys.put(c);
      }
    });
  }

  Future<void> _applyTagChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveTags.get(localId);
        final t = existing ?? JiveTag();
        t.id = localId;
        t.key = row['key'] as String? ?? '';
        t.name = row['name'] as String? ?? '';
        t.groupKey = row['group_key'] as String?;
        t.colorHex = row['color_hex'] as String?;
        t.isArchived = row['is_archived'] as bool? ?? false;
        await _isar.jiveTags.put(t);
      }
    });
  }

  Future<void> _applyBudgetChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveBudgets.get(localId);
        final b = existing ?? JiveBudget();
        b.id = localId;
        b.name = row['name'] as String? ?? '';
        b.amount = (row['amount'] as num?)?.toDouble() ?? 0;
        b.period = row['period'] as String? ?? 'monthly';
        b.startDate = DateTime.parse(row['start_date'] as String);
        b.endDate = DateTime.parse(row['end_date'] as String);
        final catKey = row['category_keys'];
        if (catKey is String && catKey.isNotEmpty) {
          b.categoryKey = catKey;
        }
        b.isActive = row['is_active'] as bool? ?? true;
        await _isar.jiveBudgets.put(b);
      }
    });
  }

  Future<void> _applySharedLedgerChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveSharedLedgers.get(localId);
        final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

        if (existing != null) {
          if (existing.updatedAt.isAfter(remoteUpdatedAt)) continue;
        }

        final l = existing ?? JiveSharedLedger();
        l.id = localId;
        l.key = row['key'] as String? ?? '';
        l.name = row['name'] as String? ?? '';
        l.ownerUserId = row['owner_user_id'] as String? ?? '';
        l.currency = row['currency'] as String? ?? 'CNY';
        l.inviteCode = row['invite_code'] as String?;
        l.memberCount = row['member_count'] as int? ?? 1;
        l.updatedAt = remoteUpdatedAt;
        await _isar.jiveSharedLedgers.put(l);
      }
    });
  }

  Future<void> _applySharedLedgerMemberChanges(List<dynamic> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;
        final existing = await _isar.jiveSharedLedgerMembers.get(localId);
        final m = existing ?? JiveSharedLedgerMember();
        m.id = localId;
        m.ledgerKey = row['ledger_key'] as String? ?? '';
        m.userId = row['user_id'] as String? ?? '';
        m.displayName = row['display_name'] as String? ?? '';
        m.role = row['role'] as String? ?? 'member';
        m.joinedAt = DateTime.parse(row['joined_at'] as String);
        await _isar.jiveSharedLedgerMembers.put(m);
      }
    });
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
}
