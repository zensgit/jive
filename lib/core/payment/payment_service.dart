import 'package:flutter/foundation.dart';

import '../entitlement/user_tier.dart';
import 'product_ids.dart';

/// Result of a purchase attempt.
class PurchaseResult {
  final bool success;
  final String? errorMessage;
  final UserTier? grantedTier;

  const PurchaseResult({
    required this.success,
    this.errorMessage,
    this.grantedTier,
  });

  const PurchaseResult.success(UserTier tier)
      : success = true,
        errorMessage = null,
        grantedTier = tier;

  const PurchaseResult.error(String message)
      : success = false,
        errorMessage = message,
        grantedTier = null;
}

/// Product info returned from the store.
class StoreProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final bool isSubscription;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isSubscription,
  });
}

/// Abstract payment service.
///
/// Implementations:
///  - [PlayStorePaymentService]: Google Play Billing (S3)
///  - Future: WechatPaymentService, AppStorePaymentService
abstract class PaymentService extends ChangeNotifier {
  /// Whether the payment service is available on this device.
  bool get isAvailable;

  /// Whether product info has been loaded.
  bool get isReady;

  /// Initialize the service and query available products.
  Future<void> init();

  /// Available products from the store.
  List<StoreProduct> get products;

  /// Purchase a product by its [productId].
  Future<PurchaseResult> purchase(String productId);

  /// Restore previously purchased products.
  Future<PurchaseResult> restorePurchases();

  /// Dispose streams and connections.
  @override
  void dispose();

  /// Map a product ID to the tier it grants.
  static UserTier tierForProduct(String productId) {
    if (ProductIds.subscriptions.contains(productId)) {
      return UserTier.subscriber;
    }
    if (productId == ProductIds.paidUnlock) {
      return UserTier.paid;
    }
    return UserTier.free;
  }
}
