import 'package:flutter/foundation.dart';

import 'payment_provider_resolver.dart';

class PaymentRuntimeConfig {
  const PaymentRuntimeConfig({
    required this.channel,
    required this.enableStoreBilling,
    required this.enableWechatPay,
    required this.enableAlipay,
  });

  final PaymentChannel channel;
  final bool enableStoreBilling;
  final bool enableWechatPay;
  final bool enableAlipay;

  static const String _rawChannel = String.fromEnvironment(
    'PAYMENT_CHANNEL',
    defaultValue: '',
  );
  static const String _rawEnableStoreBilling = String.fromEnvironment(
    'ENABLE_STORE_BILLING',
    defaultValue: '',
  );
  static const String _rawEnableWechatPay = String.fromEnvironment(
    'ENABLE_WECHAT_PAY',
    defaultValue: '',
  );
  static const String _rawEnableAlipay = String.fromEnvironment(
    'ENABLE_ALIPAY',
    defaultValue: '',
  );

  static PaymentRuntimeConfig current({
    TargetPlatform? platformOverride,
    bool isWeb = kIsWeb,
  }) {
    return resolvePaymentRuntimeConfig(
      rawChannel: _rawChannel,
      rawEnableStoreBilling: _rawEnableStoreBilling,
      rawEnableWechatPay: _rawEnableWechatPay,
      rawEnableAlipay: _rawEnableAlipay,
      platformOverride: platformOverride,
      isWeb: isWeb,
    );
  }
}

PaymentRuntimeConfig resolvePaymentRuntimeConfig({
  required String rawChannel,
  required String rawEnableStoreBilling,
  required String rawEnableWechatPay,
  required String rawEnableAlipay,
  TargetPlatform? platformOverride,
  bool isWeb = kIsWeb,
}) {
  final platform = platformOverride ?? defaultTargetPlatform;
  final channel =
      parsePaymentChannel(rawChannel) ??
      inferDefaultPaymentChannel(platform: platform, isWeb: isWeb);

  final defaultsToDomestic = channel.defaultsToDomesticProviders;

  return PaymentRuntimeConfig(
    channel: channel,
    enableStoreBilling:
        parseOptionalBool(rawEnableStoreBilling) ??
        channel.defaultsToStoreBilling,
    enableWechatPay:
        parseOptionalBool(rawEnableWechatPay) ?? defaultsToDomestic,
    enableAlipay: parseOptionalBool(rawEnableAlipay) ?? defaultsToDomestic,
  );
}

PaymentChannel inferDefaultPaymentChannel({
  required TargetPlatform platform,
  required bool isWeb,
}) {
  if (isWeb) return PaymentChannel.selfHostedWeb;
  switch (platform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return PaymentChannel.desktopWeb;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return PaymentChannel.auto;
  }
}

PaymentChannel? parsePaymentChannel(String raw) {
  switch (raw.trim().toLowerCase()) {
    case '':
    case 'auto':
      return null;
    case 'appstore':
    case 'app_store':
      return PaymentChannel.appStore;
    case 'googleplay':
    case 'google_play':
      return PaymentChannel.googlePlay;
    case 'selfhostedweb':
    case 'self_hosted_web':
      return PaymentChannel.selfHostedWeb;
    case 'directandroid':
    case 'direct_android':
      return PaymentChannel.directAndroid;
    case 'desktopweb':
    case 'desktop_web':
      return PaymentChannel.desktopWeb;
    default:
      return null;
  }
}

bool? parseOptionalBool(String raw) {
  switch (raw.trim().toLowerCase()) {
    case '':
      return null;
    case '1':
    case 'true':
    case 'yes':
    case 'on':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'off':
      return false;
    default:
      return null;
  }
}

extension PaymentChannelRuntimeDefaults on PaymentChannel {
  bool get defaultsToDomesticProviders =>
      this == PaymentChannel.selfHostedWeb ||
      this == PaymentChannel.directAndroid ||
      this == PaymentChannel.desktopWeb;

  bool get defaultsToStoreBilling =>
      this == PaymentChannel.auto ||
      this == PaymentChannel.appStore ||
      this == PaymentChannel.googlePlay;
}
