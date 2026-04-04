import 'dart:math';

import 'package:isar/isar.dart';

import '../database/shared_ledger_model.dart';

/// Manages shared family ledgers locally.
/// Supabase sync for multi-user collaboration is handled separately.
class SharedLedgerService {
  final Isar _isar;

  SharedLedgerService(this._isar);

  /// Create a new shared ledger.
  Future<JiveSharedLedger> createLedger({
    required String name,
    required String ownerUserId,
    String currency = 'CNY',
  }) async {
    final key = 'shared_${DateTime.now().millisecondsSinceEpoch}';
    final inviteCode = _generateInviteCode();

    final ledger = JiveSharedLedger()
      ..key = key
      ..name = name
      ..ownerUserId = ownerUserId
      ..currency = currency
      ..inviteCode = inviteCode
      ..isOwner = true
      ..role = 'owner'
      ..memberCount = 1
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final member = JiveSharedLedgerMember()
      ..ledgerKey = key
      ..userId = ownerUserId
      ..displayName = '我'
      ..role = 'owner'
      ..joinedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveSharedLedgers.put(ledger);
      await _isar.jiveSharedLedgerMembers.put(member);
    });

    return ledger;
  }

  /// Get all shared ledgers the user is part of.
  Future<List<JiveSharedLedger>> getLedgers() async {
    return _isar.jiveSharedLedgers.where().sortByUpdatedAtDesc().findAll();
  }

  /// Get members of a ledger.
  Future<List<JiveSharedLedgerMember>> getMembers(String ledgerKey) async {
    return _isar.jiveSharedLedgerMembers
        .filter()
        .ledgerKeyEqualTo(ledgerKey)
        .sortByJoinedAt()
        .findAll();
  }

  /// Add a member to a ledger (by invite code).
  Future<bool> joinByInviteCode({
    required String inviteCode,
    required String userId,
    required String displayName,
  }) async {
    final ledger = await _isar.jiveSharedLedgers
        .filter()
        .inviteCodeEqualTo(inviteCode)
        .findFirst();

    if (ledger == null) return false;

    // Check if already a member
    final existing = await _isar.jiveSharedLedgerMembers
        .filter()
        .ledgerKeyEqualTo(ledger.key)
        .and()
        .userIdEqualTo(userId)
        .findFirst();
    if (existing != null) return true;

    final member = JiveSharedLedgerMember()
      ..ledgerKey = ledger.key
      ..userId = userId
      ..displayName = displayName
      ..role = 'member'
      ..joinedAt = DateTime.now();

    await _isar.writeTxn(() async {
      ledger.memberCount += 1;
      ledger.updatedAt = DateTime.now();
      await _isar.jiveSharedLedgers.put(ledger);
      await _isar.jiveSharedLedgerMembers.put(member);
    });

    return true;
  }

  /// Update a member's role.
  Future<void> updateMemberRole(int memberId, String role) async {
    await _isar.writeTxn(() async {
      final member = await _isar.jiveSharedLedgerMembers.get(memberId);
      if (member == null) return;
      member.role = role;
      await _isar.jiveSharedLedgerMembers.put(member);
    });
  }

  /// Remove a member from a ledger.
  Future<void> removeMember(int memberId, String ledgerKey) async {
    await _isar.writeTxn(() async {
      await _isar.jiveSharedLedgerMembers.delete(memberId);
      final ledger = await _isar.jiveSharedLedgers
          .filter()
          .keyEqualTo(ledgerKey)
          .findFirst();
      if (ledger != null) {
        ledger.memberCount = (ledger.memberCount - 1).clamp(1, 999);
        ledger.updatedAt = DateTime.now();
        await _isar.jiveSharedLedgers.put(ledger);
      }
    });
  }

  /// Regenerate invite code for a ledger.
  Future<String> regenerateInviteCode(String ledgerKey) async {
    final code = _generateInviteCode();
    await _isar.writeTxn(() async {
      final ledger = await _isar.jiveSharedLedgers
          .filter()
          .keyEqualTo(ledgerKey)
          .findFirst();
      if (ledger != null) {
        ledger.inviteCode = code;
        ledger.updatedAt = DateTime.now();
        await _isar.jiveSharedLedgers.put(ledger);
      }
    });
    return code;
  }

  /// Delete a shared ledger (owner only).
  Future<void> deleteLedger(String ledgerKey) async {
    await _isar.writeTxn(() async {
      final members = await _isar.jiveSharedLedgerMembers
          .filter()
          .ledgerKeyEqualTo(ledgerKey)
          .findAll();
      await _isar.jiveSharedLedgerMembers.deleteAll(members.map((m) => m.id).toList());

      final ledger = await _isar.jiveSharedLedgers
          .filter()
          .keyEqualTo(ledgerKey)
          .findFirst();
      if (ledger != null) {
        await _isar.jiveSharedLedgers.delete(ledger.id);
      }
    });
  }

  /// Generate a 6-character invite code.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
