import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/payment/app_store_payment_service.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/payment_service_factory.dart';

class _FakePaymentService extends PaymentService {
  @override
  bool get isAvailable => true;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<PurchaseResult> purchase(String productId) async =>
      const PurchaseResult.error('not implemented');

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult.error('not implemented');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('usesAppStorePaymentService', () {
    test('returns true for iOS and macOS when not on web', () {
      expect(
        usesAppStorePaymentService(platform: TargetPlatform.iOS, isWeb: false),
        isTrue,
      );
      expect(
        usesAppStorePaymentService(
          platform: TargetPlatform.macOS,
          isWeb: false,
        ),
        isTrue,
      );
    });

    test('returns false for Android and web', () {
      expect(
        usesAppStorePaymentService(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        isFalse,
      );
      expect(
        usesAppStorePaymentService(platform: TargetPlatform.iOS, isWeb: true),
        isFalse,
      );
    });
  });

  group('createPlatformPaymentService', () {
    test('creates AppStorePaymentService for iOS platforms', () {
      final entitlement = EntitlementService();
      final fakeService = _FakePaymentService();

      final service = createPlatformPaymentService(
        entitlementService: entitlement,
        platformOverride: TargetPlatform.iOS,
        isWeb: false,
        appStoreBuilder: () => fakeService,
      );

      expect(identical(service, fakeService), isTrue);
    });

    test('creates PlayStorePaymentService for Android', () {
      final entitlement = EntitlementService();
      final fakeService = _FakePaymentService();

      final service = createPlatformPaymentService(
        entitlementService: entitlement,
        platformOverride: TargetPlatform.android,
        isWeb: false,
        playStoreBuilder: () => fakeService,
      );

      expect(identical(service, fakeService), isTrue);
    });

    test(
      'creates WeChat Pay service for direct Android channel when enabled',
      () {
        final entitlement = EntitlementService();
        final fakeService = _FakePaymentService();

        final service = createPlatformPaymentService(
          entitlementService: entitlement,
          platformOverride: TargetPlatform.android,
          isWeb: false,
          paymentChannel: PaymentChannel.directAndroid,
          enableWechatPay: true,
          wechatPayBuilder: () => fakeService,
        );

        expect(identical(service, fakeService), isTrue);
      },
    );

    test(
      'returns unavailable service for desktop channel without providers',
      () {
        final entitlement = EntitlementService();

        final service = createPlatformPaymentService(
          entitlementService: entitlement,
          platformOverride: TargetPlatform.macOS,
          isWeb: false,
          paymentChannel: PaymentChannel.desktopWeb,
          enableStoreBilling: false,
          enableWechatPay: false,
          enableAlipay: false,
        );

        expect(service.isAvailable, isFalse);
      },
    );
  });

  group('AppStorePaymentService.appStoreAccountTokenForUser', () {
    test('keeps valid UUIDs and normalizes casing', () {
      expect(
        AppStorePaymentService.appStoreAccountTokenForUser(
          '8F39C97D-5FD3-4422-9478-95F74D715967',
        ),
        '8f39c97d-5fd3-4422-9478-95f74d715967',
      );
    });

    test('rejects null and non UUID identifiers', () {
      expect(AppStorePaymentService.appStoreAccountTokenForUser(null), isNull);
      expect(
        AppStorePaymentService.appStoreAccountTokenForUser('user@example.com'),
        isNull,
      );
    });
  });
}
