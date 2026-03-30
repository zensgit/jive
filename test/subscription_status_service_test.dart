import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/subscription_status_service.dart';

/// Minimal fake [PaymentService] for unit tests.
class FakePaymentService extends PaymentService {
  bool fakeAvailable;
  PurchaseResult fakeRestoreResult;

  FakePaymentService({
    this.fakeAvailable = true,
    PurchaseResult? restoreResult,
  }) : fakeRestoreResult =
            restoreResult ?? const PurchaseResult(success: true);

  @override
  bool get isAvailable => fakeAvailable;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => [];

  @override
  Future<PurchaseResult> purchase(String productId) async =>
      const PurchaseResult.error('not implemented');

  @override
  Future<PurchaseResult> restorePurchases() async => fakeRestoreResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EntitlementService entitlement;
  late FakePaymentService fakePayment;
  late SubscriptionStatusService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entitlement = EntitlementService();
    await entitlement.init();
    fakePayment = FakePaymentService();
    service = SubscriptionStatusService(
      paymentService: fakePayment,
      entitlementService: entitlement,
    );
  });

  group('SubscriptionStatusService', () {
    test('construction defaults', () {
      expect(service, isNotNull);
    });

    test('offline grace: keeps tier when service unavailable and within grace',
        () async {
      // Set subscriber tier and record a recent purchase.
      await entitlement.setTier(UserTier.subscriber);
      await service.recordPurchaseTimestamp('jive_subscriber_monthly');

      // Simulate offline.
      fakePayment.fakeAvailable = false;

      await service.checkAndSync();

      // Tier should be preserved (within 7-day grace).
      expect(entitlement.tier, equals(UserTier.subscriber));
    });

    test('offline grace: downgrades when grace period expired', () async {
      await entitlement.setTier(UserTier.subscriber);

      // Record a purchase timestamp 8 days ago.
      final prefs = await SharedPreferences.getInstance();
      final eightDaysAgo =
          DateTime.now().subtract(const Duration(days: 8));
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
      fakePayment.fakeRestoreResult =
          const PurchaseResult.error('no purchases');

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.paid));
    });

    test('downgrades subscriber when restore finds no active purchases',
        () async {
      await entitlement.setTier(UserTier.subscriber);

      fakePayment.fakeRestoreResult =
          const PurchaseResult.error('no active subscriptions');

      await service.checkAndSync();

      expect(entitlement.tier, equals(UserTier.free));
    });

    test('recordPurchaseTimestamp and getLastPurchaseTime round-trip',
        () async {
      await service.recordPurchaseTimestamp('jive_paid_unlock');
      final time = await service.getLastPurchaseTime();
      expect(time, isNotNull);
      expect(
        DateTime.now().difference(time!).inSeconds,
        lessThan(2),
      );
    });
  });
}
