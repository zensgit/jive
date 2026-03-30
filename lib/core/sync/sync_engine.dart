import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/transaction_model.dart';
import '../entitlement/entitlement_service.dart';
import 'sync_config.dart';
import 'sync_state.dart';

/// Incremental sync engine between local Isar and remote Supabase.
///
/// Strategy: cursor-based incremental sync using `updatedAt` timestamps.
/// Conflict resolution: last-write-wins (higher updatedAt wins).
///
/// Lifecycle:
///  1. [init] — check config, init Supabase if not already done
///  2. [sync] — push local changes, then pull remote changes
///  3. Called on app start (if subscriber) and on data change
class SyncEngine extends ChangeNotifier {
  static const _prefKeySyncCursor = 'sync_last_cursor';
  static const _prefKeySyncEnabled = 'sync_enabled';

  final Isar _isar;
  final EntitlementService _entitlement;

  SyncState _state = const SyncState.disabled();

  SyncEngine({
    required Isar isar,
    required EntitlementService entitlement,
  })  : _isar = isar,
        _entitlement = entitlement;

  /// Current sync state for UI.
  SyncState get state => _state;

  /// Whether sync is available (configured + subscriber tier).
  bool get isAvailable =>
      SyncConfig.isConfigured && _entitlement.tier.hasCloud;

  /// Initialize sync engine.
  Future<void> init() async {
    if (!SyncConfig.isConfigured) {
      _state = const SyncState.disabled();
      notifyListeners();
      return;
    }

    if (!_entitlement.tier.hasCloud) {
      _state = const SyncState.disabled();
      notifyListeners();
      return;
    }

    try {
      // Initialize Supabase if not already done
      if (Supabase.instance.client.auth.currentSession == null) {
        debugPrint('SyncEngine: no auth session, sync disabled');
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

      _state = const SyncState.idle();
      notifyListeners();
    } catch (e) {
      debugPrint('SyncEngine: init failed: $e');
      _state = SyncState.error('初始化失败: $e');
      notifyListeners();
    }
  }

  /// Enable or disable sync.
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

  /// Run a full sync cycle: push local → pull remote.
  Future<void> sync() async {
    if (!isAvailable || _state.isSyncing) return;

    _state = const SyncState.syncing();
    notifyListeners();

    try {
      final cursor = await _getSyncCursor();
      await _pushLocalChanges(cursor);
      await _pullRemoteChanges(cursor);
      await _updateSyncCursor();

      _state = SyncState.idle(lastSyncAt: DateTime.now());
    } catch (e) {
      debugPrint('SyncEngine: sync failed: $e');
      _state = SyncState.error('同步失败: $e');
    }
    notifyListeners();
  }

  /// Push local transactions modified after [cursor] to Supabase.
  Future<void> _pushLocalChanges(DateTime cursor) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final localChanges = await _isar.jiveTransactions
        .filter()
        .updatedAtGreaterThan(cursor)
        .findAll();

    if (localChanges.isEmpty) return;

    final rows = localChanges.map((tx) => {
      'local_id': tx.id,
      'user_id': userId,
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

    // Upsert by (user_id, local_id) — last-write-wins via updated_at
    await client
        .from('transactions')
        .upsert(rows, onConflict: 'user_id,local_id');

    debugPrint('SyncEngine: pushed ${rows.length} transactions');
  }

  /// Pull remote changes after [cursor] from Supabase into local Isar.
  Future<void> _pullRemoteChanges(DateTime cursor) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', cursor.toIso8601String())
        .order('updated_at', ascending: true);

    final remoteRows = response as List<dynamic>;
    if (remoteRows.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final row in remoteRows) {
        final localId = row['local_id'] as int?;
        if (localId == null) continue;

        final existing = await _isar.jiveTransactions.get(localId);
        final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

        // Last-write-wins: skip if local is newer
        if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
          continue;
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

    debugPrint('SyncEngine: pulled ${remoteRows.length} transactions');
  }

  Future<DateTime> _getSyncCursor() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKeySyncCursor);
    if (stored != null) {
      return DateTime.parse(stored);
    }
    // First sync: use epoch (sync everything)
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _updateSyncCursor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeySyncCursor,
      DateTime.now().toIso8601String(),
    );
  }
}
