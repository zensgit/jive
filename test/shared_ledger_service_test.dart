import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/shared_ledger_model.dart';

void main() {
  group('JiveSharedLedger', () {
    test('default values are set correctly', () {
      final ledger = JiveSharedLedger();

      expect(ledger.key, '');
      expect(ledger.name, '');
      expect(ledger.ownerUserId, '');
      expect(ledger.currency, 'CNY');
      expect(ledger.inviteCode, isNull);
      expect(ledger.isOwner, false);
      expect(ledger.role, 'member');
      expect(ledger.memberCount, 1);
    });

    test('fields can be set correctly', () {
      final now = DateTime.now();
      final ledger = JiveSharedLedger()
        ..key = 'ledger-abc-123'
        ..name = '家庭账本'
        ..ownerUserId = 'user-xyz'
        ..currency = 'USD'
        ..inviteCode = 'AB12CD'
        ..isOwner = true
        ..role = 'owner'
        ..memberCount = 4
        ..createdAt = now
        ..updatedAt = now;

      expect(ledger.key, 'ledger-abc-123');
      expect(ledger.name, '家庭账本');
      expect(ledger.ownerUserId, 'user-xyz');
      expect(ledger.currency, 'USD');
      expect(ledger.inviteCode, 'AB12CD');
      expect(ledger.isOwner, true);
      expect(ledger.role, 'owner');
      expect(ledger.memberCount, 4);
      expect(ledger.createdAt, now);
      expect(ledger.updatedAt, now);
    });

    test('role can be set to all valid values', () {
      for (final role in ['owner', 'admin', 'member', 'readonly']) {
        final ledger = JiveSharedLedger()..role = role;
        expect(ledger.role, role);
      }
    });

    test('inviteCode defaults to null', () {
      final ledger = JiveSharedLedger();
      expect(ledger.inviteCode, isNull);
    });
  });

  group('JiveSharedLedgerMember', () {
    test('default values are set correctly', () {
      final member = JiveSharedLedgerMember();

      expect(member.ledgerKey, '');
      expect(member.userId, '');
      expect(member.displayName, '');
      expect(member.role, 'member');
    });

    test('fields can be set correctly', () {
      final now = DateTime.now();
      final member = JiveSharedLedgerMember()
        ..ledgerKey = 'ledger-abc-123'
        ..userId = 'user-456'
        ..displayName = '小明'
        ..role = 'admin'
        ..joinedAt = now;

      expect(member.ledgerKey, 'ledger-abc-123');
      expect(member.userId, 'user-456');
      expect(member.displayName, '小明');
      expect(member.role, 'admin');
      expect(member.joinedAt, now);
    });

    test('role can be set to all valid values', () {
      for (final role in ['owner', 'admin', 'member', 'readonly']) {
        final member = JiveSharedLedgerMember()..role = role;
        expect(member.role, role);
      }
    });

    test('joinedAt defaults to approximately now', () {
      final before = DateTime.now();
      final member = JiveSharedLedgerMember();
      final after = DateTime.now();

      expect(member.joinedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(member.joinedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
