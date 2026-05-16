import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/shared_ledger_model.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/service/shared_ledger_limit_policy.dart';

void main() {
  group('SharedLedgerLimitPolicy', () {
    const policy = SharedLedgerLimitPolicy();

    test('free users cannot create or join shared ledgers', () {
      final create = policy.canCreateLedger(
        tier: UserTier.free,
        existingLedgers: const [],
      );
      final join = policy.canJoinLedger(
        tier: UserTier.free,
        existingLedgers: const [],
      );

      expect(create.allowed, isFalse);
      expect(create.message, contains('升级到 Pro'));
      expect(join.allowed, isFalse);
      expect(join.title, contains('加入共享账本需要升级'));
    });

    test('pro users can own one two-person shared ledger', () {
      final empty = policy.canCreateLedger(
        tier: UserTier.paid,
        existingLedgers: const [],
      );
      final fullLedgerList = policy.canCreateLedger(
        tier: UserTier.paid,
        existingLedgers: [_ledger(memberCount: 1)],
      );
      final inviteSecondMember = policy.canInviteMember(
        tier: UserTier.paid,
        ledger: _ledger(memberCount: 1),
      );
      final inviteThirdMember = policy.canInviteMember(
        tier: UserTier.paid,
        ledger: _ledger(memberCount: 2),
      );

      expect(empty.allowed, isTrue);
      expect(fullLedgerList.allowed, isFalse);
      expect(fullLedgerList.message, contains('1 个共享账本'));
      expect(inviteSecondMember.allowed, isTrue);
      expect(inviteThirdMember.allowed, isFalse);
      expect(inviteThirdMember.message, contains('最多支持 2 人'));
    });

    test('family users can own five ledgers with ten members each', () {
      final ledgers = List.generate(4, (_) => _ledger(memberCount: 1));
      final canCreateFifth = policy.canCreateLedger(
        tier: UserTier.subscriber,
        existingLedgers: ledgers,
      );
      final cannotCreateSixth = policy.canCreateLedger(
        tier: UserTier.subscriber,
        existingLedgers: [...ledgers, _ledger(memberCount: 1)],
      );
      final canInviteTenth = policy.canInviteMember(
        tier: UserTier.subscriber,
        ledger: _ledger(memberCount: 9),
      );
      final cannotInviteEleventh = policy.canInviteMember(
        tier: UserTier.subscriber,
        ledger: _ledger(memberCount: 10),
      );

      expect(canCreateFifth.allowed, isTrue);
      expect(cannotCreateSixth.allowed, isFalse);
      expect(cannotCreateSixth.message, contains('5 个共享账本'));
      expect(canInviteTenth.allowed, isTrue);
      expect(cannotInviteEleventh.allowed, isFalse);
      expect(cannotInviteEleventh.message, contains('最多支持 10 人'));
    });
  });
}

JiveSharedLedger _ledger({required int memberCount}) {
  return JiveSharedLedger()
    ..key = 'family'
    ..name = '家庭账本'
    ..memberCount = memberCount;
}
