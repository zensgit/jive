import '../database/shared_ledger_model.dart';
import '../entitlement/user_tier.dart';

class SharedLedgerTierLimit {
  final UserTier tier;
  final String planLabel;
  final int maxLedgers;
  final int maxMembersPerLedger;
  final String upgradeHint;

  const SharedLedgerTierLimit({
    required this.tier,
    required this.planLabel,
    required this.maxLedgers,
    required this.maxMembersPerLedger,
    required this.upgradeHint,
  });

  bool get canUseSharedLedgers => maxLedgers > 0 && maxMembersPerLedger > 0;

  String get summary {
    if (!canUseSharedLedgers) return '当前版本暂不支持共享账本';
    return '$planLabel 可创建 $maxLedgers 个共享账本，每本最多 $maxMembersPerLedger 人';
  }
}

class SharedLedgerLimitDecision {
  final bool allowed;
  final String title;
  final String message;

  const SharedLedgerLimitDecision.allowed({this.title = '', this.message = ''})
    : allowed = true;

  const SharedLedgerLimitDecision.blocked({
    required this.title,
    required this.message,
  }) : allowed = false;
}

/// Client-side presentation policy for shared-ledger SaaS entry limits.
///
/// This does not replace server-side subscription truth. It only keeps local
/// entry states and copy aligned with the Free / Pro / Family product promise.
class SharedLedgerLimitPolicy {
  const SharedLedgerLimitPolicy();

  SharedLedgerTierLimit limitsFor(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return const SharedLedgerTierLimit(
          tier: UserTier.free,
          planLabel: 'Free',
          maxLedgers: 0,
          maxMembersPerLedger: 0,
          upgradeHint: '升级到 Pro 可创建 1 个 2 人共享账本，Family 可创建 5 个共享账本。',
        );
      case UserTier.paid:
        return const SharedLedgerTierLimit(
          tier: UserTier.paid,
          planLabel: 'Pro',
          maxLedgers: 1,
          maxMembersPerLedger: 2,
          upgradeHint: '升级到 Family 可创建 5 个共享账本，每本最多 10 人。',
        );
      case UserTier.subscriber:
        return const SharedLedgerTierLimit(
          tier: UserTier.subscriber,
          planLabel: 'Family',
          maxLedgers: 5,
          maxMembersPerLedger: 10,
          upgradeHint: 'Family 已包含当前阶段的完整共享账本额度。',
        );
    }
  }

  SharedLedgerLimitDecision canCreateLedger({
    required UserTier tier,
    required List<JiveSharedLedger> existingLedgers,
  }) {
    final limit = limitsFor(tier);
    if (!limit.canUseSharedLedgers) {
      return SharedLedgerLimitDecision.blocked(
        title: '共享账本需要升级',
        message: limit.upgradeHint,
      );
    }
    if (existingLedgers.length >= limit.maxLedgers) {
      return SharedLedgerLimitDecision.blocked(
        title: '${limit.planLabel} 共享账本数量已达上限',
        message: '当前最多可拥有 ${limit.maxLedgers} 个共享账本。${limit.upgradeHint}',
      );
    }
    return const SharedLedgerLimitDecision.allowed();
  }

  SharedLedgerLimitDecision canJoinLedger({
    required UserTier tier,
    required List<JiveSharedLedger> existingLedgers,
  }) {
    final limit = limitsFor(tier);
    if (!limit.canUseSharedLedgers) {
      return SharedLedgerLimitDecision.blocked(
        title: '加入共享账本需要升级',
        message: limit.upgradeHint,
      );
    }
    if (existingLedgers.length >= limit.maxLedgers) {
      return SharedLedgerLimitDecision.blocked(
        title: '${limit.planLabel} 共享账本数量已达上限',
        message: '加入新账本后会超过 ${limit.maxLedgers} 个共享账本额度。${limit.upgradeHint}',
      );
    }
    return const SharedLedgerLimitDecision.allowed();
  }

  SharedLedgerLimitDecision canInviteMember({
    required UserTier tier,
    required JiveSharedLedger ledger,
  }) {
    final limit = limitsFor(tier);
    if (!limit.canUseSharedLedgers) {
      return SharedLedgerLimitDecision.blocked(
        title: '邀请成员需要升级',
        message: limit.upgradeHint,
      );
    }
    if (ledger.memberCount >= limit.maxMembersPerLedger) {
      return SharedLedgerLimitDecision.blocked(
        title: '${limit.planLabel} 成员数已达上限',
        message:
            '「${ledger.name}」当前最多支持 ${limit.maxMembersPerLedger} 人。${limit.upgradeHint}',
      );
    }
    return const SharedLedgerLimitDecision.allowed();
  }
}
