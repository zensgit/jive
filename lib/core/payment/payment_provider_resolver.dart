import 'package:flutter/foundation.dart';

enum PaymentChannel {
  auto,
  appStore,
  googlePlay,
  selfHostedWeb,
  directAndroid,
  desktopWeb,
}

enum PaymentProvider { googlePlay, appleAppStore, wechatPay, alipay }

extension PaymentProviderX on PaymentProvider {
  String get label {
    switch (this) {
      case PaymentProvider.googlePlay:
        return 'Google Play';
      case PaymentProvider.appleAppStore:
        return 'App Store';
      case PaymentProvider.wechatPay:
        return '微信支付';
      case PaymentProvider.alipay:
        return '支付宝';
    }
  }

  bool get isDomestic =>
      this == PaymentProvider.wechatPay || this == PaymentProvider.alipay;

  bool get isStoreManaged =>
      this == PaymentProvider.googlePlay ||
      this == PaymentProvider.appleAppStore;
}

List<PaymentProvider> resolveAvailablePaymentProviders({
  required TargetPlatform platform,
  required bool isWeb,
  PaymentChannel channel = PaymentChannel.auto,
  bool enableStoreBilling = true,
  bool enableWechatPay = false,
  bool enableAlipay = false,
}) {
  switch (channel) {
    case PaymentChannel.appStore:
      return enableStoreBilling
          ? const [PaymentProvider.appleAppStore]
          : const [];
    case PaymentChannel.googlePlay:
      return enableStoreBilling ? const [PaymentProvider.googlePlay] : const [];
    case PaymentChannel.selfHostedWeb:
    case PaymentChannel.desktopWeb:
    case PaymentChannel.directAndroid:
      return _domesticProviders(
        enableWechatPay: enableWechatPay,
        enableAlipay: enableAlipay,
      );
    case PaymentChannel.auto:
      if (isWeb) {
        return _domesticProviders(
          enableWechatPay: enableWechatPay,
          enableAlipay: enableAlipay,
        );
      }
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        return enableStoreBilling
            ? const [PaymentProvider.appleAppStore]
            : const [];
      }
      if (platform == TargetPlatform.android) {
        return enableStoreBilling
            ? const [PaymentProvider.googlePlay]
            : const [];
      }
      return _domesticProviders(
        enableWechatPay: enableWechatPay,
        enableAlipay: enableAlipay,
      );
  }
}

List<PaymentProvider> _domesticProviders({
  required bool enableWechatPay,
  required bool enableAlipay,
}) {
  return [
    if (enableWechatPay) PaymentProvider.wechatPay,
    if (enableAlipay) PaymentProvider.alipay,
  ];
}
