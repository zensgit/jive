import 'package:flutter/foundation.dart';

import 'alipay_payment_service.dart';
import '../entitlement/entitlement_service.dart';
import 'app_store_payment_service.dart';
import 'domestic_payment_order_client.dart';
import 'payment_provider_resolver.dart';
import 'payment_service.dart';
import 'play_store_payment_service.dart';
import 'subscription_truth_repository.dart';
import 'wechat_pay_payment_service.dart';

PaymentService createPlatformPaymentService({
  required EntitlementService entitlementService,
  SubscriptionTruthRepository? truthRepository,
  String? Function()? applicationUserNameProvider,
  TargetPlatform? platformOverride,
  bool isWeb = kIsWeb,
  PaymentChannel paymentChannel = PaymentChannel.auto,
  bool enableWechatPay = false,
  bool enableAlipay = false,
  PaymentService Function()? appStoreBuilder,
  PaymentService Function()? playStoreBuilder,
  PaymentService Function()? wechatPayBuilder,
  PaymentService Function()? alipayBuilder,
  DomesticPaymentOrderClient? domesticOrderClient,
}) {
  final platform = platformOverride ?? defaultTargetPlatform;
  final providers = resolveAvailablePaymentProviders(
    platform: platform,
    isWeb: isWeb,
    channel: paymentChannel,
    enableStoreBilling: true,
    enableWechatPay: enableWechatPay,
    enableAlipay: enableAlipay,
  );

  if (providers.isNotEmpty) {
    switch (providers.first) {
      case PaymentProvider.appleAppStore:
        return appStoreBuilder?.call() ??
            AppStorePaymentService(
              entitlement: entitlementService,
              truthRepository: truthRepository,
              applicationUserNameProvider: applicationUserNameProvider,
            );
      case PaymentProvider.googlePlay:
        return playStoreBuilder?.call() ??
            PlayStorePaymentService(
              entitlement: entitlementService,
              truthRepository: truthRepository,
            );
      case PaymentProvider.wechatPay:
        return wechatPayBuilder?.call() ??
            WechatPayPaymentService(
              orderClient:
                  domesticOrderClient ?? SupabaseDomesticPaymentOrderClient(),
              channel: paymentChannel,
            );
      case PaymentProvider.alipay:
        return alipayBuilder?.call() ??
            AlipayPaymentService(
              orderClient:
                  domesticOrderClient ?? SupabaseDomesticPaymentOrderClient(),
              channel: paymentChannel,
            );
    }
  }

  if (usesAppStorePaymentService(platform: platform, isWeb: isWeb)) {
    return appStoreBuilder?.call() ??
        AppStorePaymentService(
          entitlement: entitlementService,
          truthRepository: truthRepository,
          applicationUserNameProvider: applicationUserNameProvider,
        );
  }

  return playStoreBuilder?.call() ??
      PlayStorePaymentService(
        entitlement: entitlementService,
        truthRepository: truthRepository,
      );
}

bool usesAppStorePaymentService({
  required TargetPlatform platform,
  required bool isWeb,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}
