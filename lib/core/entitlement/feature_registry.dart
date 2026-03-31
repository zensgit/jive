import 'feature_id.dart';
import 'user_tier.dart';

/// Maps each [FeatureId] to its minimum required [UserTier].
///
/// This is the single source of truth for feature gating decisions.
/// To change which tier a feature requires, update this map.
class FeatureRegistry {
  FeatureRegistry._();

  static const Map<FeatureId, UserTier> _requirements = {
    // Free tier — always available
    FeatureId.manualTransaction: UserTier.free,
    FeatureId.categoryManagement: UserTier.free,
    FeatureId.basicStats: UserTier.free,
    FeatureId.tagManagement: UserTier.free,
    FeatureId.autoBookkeeping: UserTier.free,
    FeatureId.csvExport: UserTier.free,

    // Paid tier
    FeatureId.multiCurrency: UserTier.paid,
    FeatureId.budgetUnlimited: UserTier.paid,
    FeatureId.recurringRules: UserTier.paid,
    FeatureId.projectTracking: UserTier.paid,
    FeatureId.billSplit: UserTier.paid,
    FeatureId.debtManagement: UserTier.paid,
    FeatureId.merchantMemory: UserTier.paid,
    FeatureId.cloudSync: UserTier.paid,
    FeatureId.multiDevice: UserTier.paid,

    // Subscriber tier
    FeatureId.investmentTracking: UserTier.subscriber,
    FeatureId.advancedAnalytics: UserTier.subscriber,
    FeatureId.savingsGoals: UserTier.subscriber,
    FeatureId.pdfReport: UserTier.subscriber,
    FeatureId.voiceBookkeeping: UserTier.subscriber,
  };

  /// Returns the minimum tier required to access [feature].
  static UserTier requiredTier(FeatureId feature) {
    return _requirements[feature] ?? UserTier.free;
  }

  /// Whether [tier] can access [feature].
  static bool canAccess(FeatureId feature, UserTier tier) {
    final required = requiredTier(feature);
    return tier.index >= required.index;
  }

  /// Returns all features available at [tier].
  static List<FeatureId> availableFeatures(UserTier tier) {
    return FeatureId.values
        .where((f) => canAccess(f, tier))
        .toList();
  }

  /// Returns features that would be unlocked by upgrading from [current] to [target].
  static List<FeatureId> unlockableFeatures(UserTier current, UserTier target) {
    if (target.index <= current.index) return const [];
    return FeatureId.values
        .where((f) => !canAccess(f, current) && canAccess(f, target))
        .toList();
  }
}
