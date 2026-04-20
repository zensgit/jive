import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_runtime_config.dart';

void main() {
  group('inferDefaultPaymentChannel', () {
    test('defaults web to self-hosted web', () {
      expect(
        inferDefaultPaymentChannel(
          platform: TargetPlatform.android,
          isWeb: true,
        ),
        PaymentChannel.selfHostedWeb,
      );
    });

    test('defaults desktop to desktop web', () {
      expect(
        inferDefaultPaymentChannel(
          platform: TargetPlatform.macOS,
          isWeb: false,
        ),
        PaymentChannel.desktopWeb,
      );
      expect(
        inferDefaultPaymentChannel(
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
        PaymentChannel.desktopWeb,
      );
    });

    test('keeps mobile native on auto', () {
      expect(
        inferDefaultPaymentChannel(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        PaymentChannel.auto,
      );
      expect(
        inferDefaultPaymentChannel(platform: TargetPlatform.iOS, isWeb: false),
        PaymentChannel.auto,
      );
    });
  });

  group('resolvePaymentRuntimeConfig', () {
    test('web defaults to domestic providers without store billing', () {
      final config = resolvePaymentRuntimeConfig(
        rawChannel: '',
        rawEnableStoreBilling: '',
        rawEnableWechatPay: '',
        rawEnableAlipay: '',
        platformOverride: TargetPlatform.android,
        isWeb: true,
      );

      expect(config.channel, PaymentChannel.selfHostedWeb);
      expect(config.enableStoreBilling, isFalse);
      expect(config.enableWechatPay, isTrue);
      expect(config.enableAlipay, isTrue);
    });

    test('desktop defaults to desktop web and domestic providers', () {
      final config = resolvePaymentRuntimeConfig(
        rawChannel: '',
        rawEnableStoreBilling: '',
        rawEnableWechatPay: '',
        rawEnableAlipay: '',
        platformOverride: TargetPlatform.macOS,
        isWeb: false,
      );

      expect(config.channel, PaymentChannel.desktopWeb);
      expect(config.enableStoreBilling, isFalse);
      expect(config.enableWechatPay, isTrue);
      expect(config.enableAlipay, isTrue);
    });

    test('explicit google play channel preserves store billing defaults', () {
      final config = resolvePaymentRuntimeConfig(
        rawChannel: 'google_play',
        rawEnableStoreBilling: '',
        rawEnableWechatPay: '',
        rawEnableAlipay: '',
        platformOverride: TargetPlatform.android,
        isWeb: false,
      );

      expect(config.channel, PaymentChannel.googlePlay);
      expect(config.enableStoreBilling, isTrue);
      expect(config.enableWechatPay, isFalse);
      expect(config.enableAlipay, isFalse);
    });

    test('explicit booleans override channel defaults', () {
      final config = resolvePaymentRuntimeConfig(
        rawChannel: 'desktop_web',
        rawEnableStoreBilling: 'true',
        rawEnableWechatPay: 'off',
        rawEnableAlipay: '0',
        platformOverride: TargetPlatform.macOS,
        isWeb: false,
      );

      expect(config.channel, PaymentChannel.desktopWeb);
      expect(config.enableStoreBilling, isTrue);
      expect(config.enableWechatPay, isFalse);
      expect(config.enableAlipay, isFalse);
    });
  });
}
