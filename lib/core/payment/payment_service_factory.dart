import 'package:flutter/foundation.dart';

import '../entitlement/entitlement_service.dart';
import 'app_store_payment_service.dart';
import 'payment_service.dart';
import 'play_store_payment_service.dart';
import 'subscription_truth_repository.dart';

PaymentService createPlatformPaymentService({
  required EntitlementService entitlementService,
  SubscriptionTruthRepository? truthRepository,
  String? Function()? applicationUserNameProvider,
  TargetPlatform? platformOverride,
  bool isWeb = kIsWeb,
  PaymentService Function()? appStoreBuilder,
  PaymentService Function()? playStoreBuilder,
}) {
  final platform = platformOverride ?? defaultTargetPlatform;
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
