import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../entitlement/entitlement_service.dart';
import 'ad_config.dart';

/// Manages ad loading and visibility based on user entitlement.
///
/// Ads are only shown for [UserTier.free] users.
/// Call [init] once at app startup, then use [BannerAdWidget] in the UI.
class AdService extends ChangeNotifier {
  final EntitlementService _entitlement;

  bool _initialized = false;
  bool _isAvailable = false;

  AdService(this._entitlement) {
    _entitlement.addListener(_onTierChanged);
  }

  /// Whether ads should be displayed right now.
  bool get shouldShowAds => _initialized && _isAvailable && _entitlement.showAds;

  /// Whether the SDK has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize the Mobile Ads SDK.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _isAvailable = true;
      _initialized = true;
      debugPrint('AdService: initialized');
    } catch (e) {
      debugPrint('AdService: init failed: $e');
      _isAvailable = false;
      _initialized = true;
    }
    notifyListeners();
  }

  void _onTierChanged() {
    notifyListeners();
  }

  /// Create a banner ad with standard config.
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    void Function(Ad)? onLoaded,
    void Function(Ad, LoadAdError)? onFailed,
  }) {
    return BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded ?? (_) {},
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: banner load failed: ${error.message}');
          ad.dispose();
          onFailed?.call(ad, error);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entitlement.removeListener(_onTierChanged);
    super.dispose();
  }
}
