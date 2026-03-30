import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feature_id.dart';
import 'feature_registry.dart';
import 'user_tier.dart';

/// Manages the current user's entitlement (tier + feature access checks).
///
/// Currently persists tier locally via SharedPreferences.
/// Will be extended to verify against a remote backend in Phase S3.
class EntitlementService extends ChangeNotifier {
  static const _prefKeyTier = 'user_tier';

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
}
