import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/feature_id.dart';
import 'package:jive/core/entitlement/feature_registry.dart';
import 'package:jive/core/entitlement/user_tier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserTier', () {
    test('free tier shows ads', () {
      expect(UserTier.free.showAds, isTrue);
      expect(UserTier.paid.showAds, isFalse);
      expect(UserTier.subscriber.showAds, isFalse);
    });

    test('cloud access only for subscriber', () {
      expect(UserTier.free.hasCloud, isFalse);
      expect(UserTier.paid.hasCloud, isFalse);
      expect(UserTier.subscriber.hasCloud, isTrue);
    });

    test('labels are non-empty', () {
      for (final tier in UserTier.values) {
        expect(tier.label.isNotEmpty, isTrue);
      }
    });
  });

  group('FeatureRegistry', () {
    test('free features accessible by all tiers', () {
      for (final tier in UserTier.values) {
        expect(
          FeatureRegistry.canAccess(FeatureId.manualTransaction, tier),
          isTrue,
        );
        expect(
          FeatureRegistry.canAccess(FeatureId.basicStats, tier),
          isTrue,
        );
      }
    });

    test('paid features blocked for free tier', () {
      expect(
        FeatureRegistry.canAccess(FeatureId.multiCurrency, UserTier.free),
        isFalse,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.multiCurrency, UserTier.paid),
        isTrue,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.multiCurrency, UserTier.subscriber),
        isTrue,
      );
    });

    test('free tier includes autoBookkeeping and csvExport', () {
      expect(
        FeatureRegistry.canAccess(FeatureId.autoBookkeeping, UserTier.free),
        isTrue,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.csvExport, UserTier.free),
        isTrue,
      );
    });

    test('cloudSync and multiDevice are paid tier', () {
      expect(
        FeatureRegistry.canAccess(FeatureId.cloudSync, UserTier.free),
        isFalse,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.cloudSync, UserTier.paid),
        isTrue,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.multiDevice, UserTier.paid),
        isTrue,
      );
    });

    test('subscriber features blocked for paid tier', () {
      expect(
        FeatureRegistry.canAccess(FeatureId.investmentTracking, UserTier.paid),
        isFalse,
      );
      expect(
        FeatureRegistry.canAccess(FeatureId.investmentTracking, UserTier.subscriber),
        isTrue,
      );
    });

    test('all FeatureIds are registered', () {
      for (final feature in FeatureId.values) {
        // Should not throw — every feature has a tier
        FeatureRegistry.requiredTier(feature);
      }
    });

    test('availableFeatures count increases with tier', () {
      final freeCount = FeatureRegistry.availableFeatures(UserTier.free).length;
      final paidCount = FeatureRegistry.availableFeatures(UserTier.paid).length;
      final subCount = FeatureRegistry.availableFeatures(UserTier.subscriber).length;
      expect(paidCount, greaterThan(freeCount));
      expect(subCount, greaterThan(paidCount));
      expect(subCount, equals(FeatureId.values.length));
    });

    test('unlockableFeatures returns diff between tiers', () {
      final paidUnlocks = FeatureRegistry.unlockableFeatures(
        UserTier.free,
        UserTier.paid,
      );
      expect(paidUnlocks, contains(FeatureId.multiCurrency));
      expect(paidUnlocks, contains(FeatureId.cloudSync));
      expect(paidUnlocks, isNot(contains(FeatureId.manualTransaction)));
      expect(paidUnlocks, isNot(contains(FeatureId.autoBookkeeping)));
    });
  });

  group('EntitlementService', () {
    test('defaults to free tier', () async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();
      expect(service.tier, equals(UserTier.free));
      expect(service.showAds, isTrue);
    });

    test('persists tier change', () async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await service.setTier(UserTier.paid);
      expect(service.tier, equals(UserTier.paid));
      expect(service.showAds, isFalse);

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_tier'), equals('paid'));
    });

    test('loads persisted tier on init', () async {
      SharedPreferences.setMockInitialValues({'user_tier': 'subscriber'});
      final service = EntitlementService();
      await service.init();
      expect(service.tier, equals(UserTier.subscriber));
    });

    test('canAccess reflects current tier', () async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      expect(service.canAccess(FeatureId.manualTransaction), isTrue);
      expect(service.canAccess(FeatureId.autoBookkeeping), isTrue); // free tier
      expect(service.canAccess(FeatureId.multiCurrency), isFalse); // paid tier

      await service.setTier(UserTier.paid);
      expect(service.canAccess(FeatureId.multiCurrency), isTrue);
      expect(service.canAccess(FeatureId.investmentTracking), isFalse); // subscriber
    });

    test('notifies listeners on tier change', () async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      var notified = false;
      service.addListener(() => notified = true);
      await service.setTier(UserTier.subscriber);
      expect(notified, isTrue);
    });
  });
}
