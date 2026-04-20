import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/subscription_status_service.dart';
import 'package:jive/core/payment/subscription_truth_model.dart';
import 'package:jive/core/payment/subscription_truth_repository.dart';

/// Minimal fake [PaymentService] for unit tests.
class FakePaymentService extends PaymentService {
  bool fakeAvailable;
  PurchaseResult fakeRestoreResult;
  int restoreCallCount = 0;

  FakePaymentService({this.fakeAvailable = true, PurchaseResult? restoreResult})
    : fakeRestoreResult = restoreResult ?? const PurchaseResult(success: true);

  @override
  bool get isAvailable => fakeAvailable;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => [];

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async => const PurchaseResult.error('not implemented');

  @override
  Future<PurchaseResult> restorePurchases() async {
    restoreCallCount += 1;
    return fakeRestoreResult;
  }
}

class FakeSubscriptionTruthRepository implements SubscriptionTruthRepository {
  SubscriptionTruthFetchResult fetchResult;
  SubscriptionTruthFetchResult verifyResult;
  SubscriptionTruthFetchResult appleVerifyResult;
  int fetchCallCount = 0;

  FakeSubscriptionTruthRepository({
    SubscriptionTruthFetchResult? fetchResult,
    SubscriptionTruthFetchResult? verifyResult,
    SubscriptionTruthFetchResult? appleVerifyResult,
  }) : fetchResult =
           fetchResult ?? const SubscriptionTruthFetchResult.unavailable(),
       verifyResult =
           verifyResult ?? const SubscriptionTruthFetchResult.unavailable(),
       appleVerifyResult =
           appleVerifyResult ??
           const SubscriptionTruthFetchResult.unavailable();

  @override
  Future<SubscriptionTruthFetchResult> fetchCurrentSubscription() async {
    fetchCallCount += 1;
    return fetchResult;
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDateMs,
  }) async {
    return verifyResult;
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyAppleAppStorePurchase({
    required String productId,
    required String receiptData,
    String? orderId,
  }) async {
    return appleVerifyResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EntitlementService entitlement;
  late FakePaymentService fakePayment;
  late FakeSubscriptionTruthRepository fakeTruth;
  late SubscriptionStatusService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entitlement = EntitlementService();
    await entitlement.init();
    fakePayment = FakePaymentService();
    fakeTruth = FakeSubscriptionTruthRepository();
    service = SubscriptionStatusService(
      paymentService: fakePayment,
      entitlementService: entitlement,
      truthRepository: fakeTruth,
    );
  });

  group('SubscriptionStatusService', () {
    test('construction defaults', () {
      expect(service, isNotNull);
    });

    test(
      'offline grace: keeps tier when service unavailable and within grace',
      () async {
        // Set subscriber tier and record a recent purchase.
        await entitlement.setTier(UserTier.subscriber);
        await service.recordPurchaseTimestamp('jive_subscriber_monthly');

        // Simulate offline.
        fakePayment.fakeAvailable = false;

        await service.checkAndSync();

        // Tier should be preserved (within 7-day grace).
        expect(entitlement.tier, equals(UserTier.subscriber));
      },
    );

    test('uses authoritative trusted snapshot when available', () async {
      fakeTruth.fetchResult = SubscriptionTruthFetchResult.authoritative(
        snapshot: TrustedSubscriptionSnapshot(
          plan: SubscriptionPlan.subscriber,
          status: SubscriptionStatusKind.active,
          platform: 'google_play',
          productId: 'jive_subscriber_monthly',
          lastVerifiedAt: DateTime(2026, 4, 5, 10),
        ),
      );

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.subscriber));
    });

    test('authoritative empty snapshot downgrades subscriber tier', () async {
      await entitlement.setTier(UserTier.subscriber);
      fakeTruth.fetchResult =
          const SubscriptionTruthFetchResult.authoritative();

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.free));
    });

    test(
      'authoritative expired snapshot wins over local restore fallback',
      () async {
        await entitlement.setTier(UserTier.subscriber);
        fakeTruth.fetchResult = SubscriptionTruthFetchResult.authoritative(
          snapshot: TrustedSubscriptionSnapshot(
            plan: SubscriptionPlan.subscriber,
            status: SubscriptionStatusKind.expired,
            platform: 'google_play',
            productId: 'jive_subscriber_monthly',
            lastVerifiedAt: DateTime(2026, 4, 5, 10),
          ),
        );
        fakePayment.fakeRestoreResult = const PurchaseResult.success(
          UserTier.subscriber,
        );

        await service.checkAndSync();

        expect(entitlement.tier, equals(UserTier.free));
      },
    );

    test('offline grace: downgrades when grace period expired', () async {
      await entitlement.setTier(UserTier.subscriber);

      // Record a purchase timestamp 8 days ago.
      final prefs = await SharedPreferences.getInstance();
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      await prefs.setInt(
        'last_purchase_timestamp',
        eightDaysAgo.millisecondsSinceEpoch,
      );

      fakePayment.fakeAvailable = false;

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.free));
    });

    test('paid tier never expires', () async {
      await entitlement.setTier(UserTier.paid);

      // Even if restore would fail, paid stays paid.
      fakePayment.fakeRestoreResult = const PurchaseResult.error(
        'no purchases',
      );

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.paid));
    });

    test(
      'downgrades subscriber when restore finds no active purchases',
      () async {
        await entitlement.setTier(UserTier.subscriber);

        fakePayment.fakeRestoreResult = const PurchaseResult.error(
          'no active subscriptions',
        );

        await service.checkAndSync();

        expect(entitlement.tier, equals(UserTier.free));
      },
    );

    test(
      'recordPurchaseTimestamp and getLastPurchaseTime round-trip',
      () async {
        await service.recordPurchaseTimestamp('jive_paid_unlock');
        final time = await service.getLastPurchaseTime();
        expect(time, isNotNull);
        expect(DateTime.now().difference(time!).inSeconds, lessThan(2));
      },
    );

    test(
      'checkAndSyncIfStale skips repeated refreshes within interval',
      () async {
        fakeTruth.fetchResult = SubscriptionTruthFetchResult.authoritative(
          snapshot: TrustedSubscriptionSnapshot(
            plan: SubscriptionPlan.subscriber,
            status: SubscriptionStatusKind.active,
            platform: 'google_play',
            productId: 'jive_subscriber_monthly',
            lastVerifiedAt: DateTime(2026, 4, 5, 10),
          ),
        );

        await service.checkAndSyncIfStale();
        await service.checkAndSyncIfStale();

        expect(fakeTruth.fetchCallCount, equals(1));
        expect(fakePayment.restoreCallCount, equals(0));
      },
    );
  });
}
