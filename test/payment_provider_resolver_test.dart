import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/payment/payment_provider_resolver.dart';

void main() {
  group('resolveAvailablePaymentProviders', () {
    test('returns App Store for iOS auto channel', () {
      expect(
        resolveAvailablePaymentProviders(
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        equals(const [PaymentProvider.appleAppStore]),
      );
    });

    test('returns Google Play for Android auto channel', () {
      expect(
        resolveAvailablePaymentProviders(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        equals(const [PaymentProvider.googlePlay]),
      );
    });

    test('returns domestic providers for self-hosted web when enabled', () {
      expect(
        resolveAvailablePaymentProviders(
          platform: TargetPlatform.android,
          isWeb: true,
          channel: PaymentChannel.selfHostedWeb,
          enableWechatPay: true,
          enableAlipay: true,
        ),
        equals(const [PaymentProvider.wechatPay, PaymentProvider.alipay]),
      );
    });

    test('returns domestic providers for direct Android builds', () {
      expect(
        resolveAvailablePaymentProviders(
          platform: TargetPlatform.android,
          isWeb: false,
          channel: PaymentChannel.directAndroid,
          enableWechatPay: true,
        ),
        equals(const [PaymentProvider.wechatPay]),
      );
    });

    test(
      'returns empty list when a web channel has no enabled domestic pay',
      () {
        expect(
          resolveAvailablePaymentProviders(
            platform: TargetPlatform.android,
            isWeb: true,
            channel: PaymentChannel.selfHostedWeb,
          ),
          isEmpty,
        );
      },
    );

    test('honors disabled store billing', () {
      expect(
        resolveAvailablePaymentProviders(
          platform: TargetPlatform.iOS,
          isWeb: false,
          enableStoreBilling: false,
        ),
        isEmpty,
      );
    });
  });

  group('PaymentProviderX', () {
    test('exposes labels and category flags', () {
      expect(PaymentProvider.wechatPay.label, '微信支付');
      expect(PaymentProvider.wechatPay.isDomestic, isTrue);
      expect(PaymentProvider.wechatPay.isStoreManaged, isFalse);

      expect(PaymentProvider.appleAppStore.label, 'App Store');
      expect(PaymentProvider.appleAppStore.isDomestic, isFalse);
      expect(PaymentProvider.appleAppStore.isStoreManaged, isTrue);
    });
  });
}
