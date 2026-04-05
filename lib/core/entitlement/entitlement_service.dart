import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../payment/subscription_truth_model.dart';
import 'feature_id.dart';
import 'feature_registry.dart';
import 'user_tier.dart';

/// Manages the current user's entitlement (tier + feature access checks).
///
/// Currently persists tier locally via SharedPreferences.
/// Will be extended to verify against a remote backend in Phase S3.
class EntitlementService extends ChangeNotifier {
  static const _prefKeyTier = 'user_tier';
  static const _prefKeyTrustedPlan = 'trusted_subscription_plan';
  static const _prefKeyTrustedStatus = 'trusted_subscription_status';
  static const _prefKeyTrustedPlatform = 'trusted_subscription_platform';
  static const _prefKeyTrustedProductId = 'trusted_subscription_product_id';
  static const _prefKeyTrustedExpiresAt = 'trusted_subscription_expires_at';
  static const _prefKeyTrustedVerifiedAt = 'trusted_subscription_verified_at';
  static const _prefKeyTrustedPurchaseToken =
      'trusted_subscription_purchase_token';
  static const _prefKeyTrustedOrderId = 'trusted_subscription_order_id';

  UserTier _tier = UserTier.free;

  /// The current user tier.
  UserTier get tier => _tier;

  /// Load the persisted tier from local storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKeyTier);
    if (stored != null) {
      _tier = UserTier.values.asNameMap()[stored] ?? UserTier.free;
    }

    final trustedSnapshot = _loadTrustedSnapshotFromPrefs(prefs);
    if (trustedSnapshot != null) {
      _tier = trustedSnapshot.tier;
    }
    notifyListeners();
  }

  /// Update the user tier (called after purchase verification).
  Future<void> setTier(UserTier newTier) async {
    if (_tier == newTier) return;
    _tier = newTier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTier, newTier.name);
    notifyListeners();
  }

  Future<void> applyTrustedSnapshot(
    TrustedSubscriptionSnapshot snapshot,
  ) async {
    _tier = snapshot.tier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTier, _tier.name);
    await prefs.setString(_prefKeyTrustedPlan, snapshot.plan.name);
    await prefs.setString(_prefKeyTrustedStatus, snapshot.status.name);
    await prefs.setString(_prefKeyTrustedPlatform, snapshot.platform);

    if (snapshot.productId != null) {
      await prefs.setString(_prefKeyTrustedProductId, snapshot.productId!);
    } else {
      await prefs.remove(_prefKeyTrustedProductId);
    }

    if (snapshot.expiresAt != null) {
      await prefs.setString(
        _prefKeyTrustedExpiresAt,
        snapshot.expiresAt!.toIso8601String(),
      );
    } else {
      await prefs.remove(_prefKeyTrustedExpiresAt);
    }

    if (snapshot.lastVerifiedAt != null) {
      await prefs.setString(
        _prefKeyTrustedVerifiedAt,
        snapshot.lastVerifiedAt!.toIso8601String(),
      );
    } else {
      await prefs.remove(_prefKeyTrustedVerifiedAt);
    }

    if (snapshot.purchaseToken != null) {
      await prefs.setString(
        _prefKeyTrustedPurchaseToken,
        snapshot.purchaseToken!,
      );
    } else {
      await prefs.remove(_prefKeyTrustedPurchaseToken);
    }

    if (snapshot.orderId != null) {
      await prefs.setString(_prefKeyTrustedOrderId, snapshot.orderId!);
    } else {
      await prefs.remove(_prefKeyTrustedOrderId);
    }

    notifyListeners();
  }

  Future<void> clearTrustedSnapshot({bool downgradeSubscriber = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyTrustedPlan);
    await prefs.remove(_prefKeyTrustedStatus);
    await prefs.remove(_prefKeyTrustedPlatform);
    await prefs.remove(_prefKeyTrustedProductId);
    await prefs.remove(_prefKeyTrustedExpiresAt);
    await prefs.remove(_prefKeyTrustedVerifiedAt);
    await prefs.remove(_prefKeyTrustedPurchaseToken);
    await prefs.remove(_prefKeyTrustedOrderId);

    if (downgradeSubscriber && _tier == UserTier.subscriber) {
      _tier = UserTier.free;
      await prefs.setString(_prefKeyTier, _tier.name);
    }
    notifyListeners();
  }

  /// Whether the current tier can access [feature].
  bool canAccess(FeatureId feature) {
    return FeatureRegistry.canAccess(feature, _tier);
  }

  /// Whether ads should be shown.
  bool get showAds => _tier.showAds;

  /// Features that would unlock by upgrading to [target].
  List<FeatureId> upgradePreview(UserTier target) {
    return FeatureRegistry.unlockableFeatures(_tier, target);
  }

  TrustedSubscriptionSnapshot? _loadTrustedSnapshotFromPrefs(
    SharedPreferences prefs,
  ) {
    final plan = prefs.getString(_prefKeyTrustedPlan);
    final status = prefs.getString(_prefKeyTrustedStatus);
    final platform = prefs.getString(_prefKeyTrustedPlatform);
    if (plan == null || status == null || platform == null) {
      return null;
    }

    return TrustedSubscriptionSnapshot.fromCacheMap({
      'plan': plan,
      'status': status,
      'platform': platform,
      if (prefs.getString(_prefKeyTrustedProductId) != null)
        'product_id': prefs.getString(_prefKeyTrustedProductId)!,
      if (prefs.getString(_prefKeyTrustedExpiresAt) != null)
        'expires_at': prefs.getString(_prefKeyTrustedExpiresAt)!,
      if (prefs.getString(_prefKeyTrustedVerifiedAt) != null)
        'last_verified_at': prefs.getString(_prefKeyTrustedVerifiedAt)!,
      if (prefs.getString(_prefKeyTrustedPurchaseToken) != null)
        'purchase_token': prefs.getString(_prefKeyTrustedPurchaseToken)!,
      if (prefs.getString(_prefKeyTrustedOrderId) != null)
        'order_id': prefs.getString(_prefKeyTrustedOrderId)!,
    });
  }
}
