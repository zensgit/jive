import 'package:flutter/foundation.dart';

import 'alipay_payment_service.dart';
import '../entitlement/entitlement_service.dart';
import 'app_store_payment_service.dart';
import 'domestic_payment_order_client.dart';
import 'domestic_payment_service_base.dart';
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
  bool enableStoreBilling = true,
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
    enableStoreBilling: enableStoreBilling,
    enableWechatPay: enableWechatPay,
    enableAlipay: enableAlipay,
  );

  if (providers.isNotEmpty) {
    final domesticProviders = providers.where((p) => p.isDomestic).toList();
    if (domesticProviders.length > 1) {
      return DomesticPaymentService(
        providers: domesticProviders,
        orderClient:
            domesticOrderClient ?? SupabaseDomesticPaymentOrderClient(),
        channel: paymentChannel,
      );
    }

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

  switch (paymentChannel) {
    case PaymentChannel.appStore:
      if (enableStoreBilling) {
        return appStoreBuilder?.call() ??
            AppStorePaymentService(
              entitlement: entitlementService,
              truthRepository: truthRepository,
              applicationUserNameProvider: applicationUserNameProvider,
            );
      }
      return _UnavailablePaymentService();
    case PaymentChannel.googlePlay:
      if (enableStoreBilling) {
        return playStoreBuilder?.call() ??
            PlayStorePaymentService(
              entitlement: entitlementService,
              truthRepository: truthRepository,
            );
      }
      return _UnavailablePaymentService();
    case PaymentChannel.selfHostedWeb:
    case PaymentChannel.directAndroid:
    case PaymentChannel.desktopWeb:
      return _UnavailablePaymentService();
    case PaymentChannel.auto:
      break;
  }

  if (!enableStoreBilling) {
    return _UnavailablePaymentService();
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

class _UnavailablePaymentService extends PaymentService {
  _UnavailablePaymentService();

  final String _message = '当前分发渠道未配置可用支付方式';

  @override
  bool get isAvailable => false;

  @override
  bool get isReady => true;

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<void> init() async {}

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async => PurchaseResult.error(_message, provider: provider);

  @override
  Future<PurchaseResult> restorePurchases() async =>
      PurchaseResult.error(_message);
}
