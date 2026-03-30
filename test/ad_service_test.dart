import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/ads/ad_config.dart';
import 'package:jive/core/ads/ad_service.dart';
import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdConfig', () {
    test('test IDs are non-empty', () {
      expect(AdConfig.testAppId.isNotEmpty, isTrue);
      expect(AdConfig.testBannerId.isNotEmpty, isTrue);
      expect(AdConfig.bannerUnitId.isNotEmpty, isTrue);
    });
  });

  group('AdService', () {
    late EntitlementService entitlement;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      entitlement = EntitlementService();
      await entitlement.init();
    });

    test('shouldShowAds false before init', () {
      final adService = AdService(entitlement);
      expect(adService.shouldShowAds, isFalse);
      expect(adService.isInitialized, isFalse);
    });

    test('shouldShowAds false for paid tier', () async {
      await entitlement.setTier(UserTier.paid);
      final adService = AdService(entitlement);
      expect(adService.shouldShowAds, isFalse);
      expect(entitlement.showAds, isFalse);
    });

    test('shouldShowAds false for subscriber tier', () async {
      await entitlement.setTier(UserTier.subscriber);
      final adService = AdService(entitlement);
      expect(adService.shouldShowAds, isFalse);
      expect(entitlement.showAds, isFalse);
    });

    test('free tier allows ads', () {
      expect(entitlement.tier, equals(UserTier.free));
      expect(entitlement.showAds, isTrue);
    });

    test('notifies on tier change', () async {
      final adService = AdService(entitlement);
      var notified = false;
      adService.addListener(() => notified = true);
      await entitlement.setTier(UserTier.paid);
      expect(notified, isTrue);
    });

    test('dispose removes listener', () {
      final adService = AdService(entitlement);
      adService.dispose();
      // Should not throw after dispose
      entitlement.notifyListeners();
    });
  });
}
