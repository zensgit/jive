import 'subscription_truth_model.dart';

abstract class SubscriptionTruthRepository {
  Future<SubscriptionTruthFetchResult> fetchCurrentSubscription();

  Future<SubscriptionTruthFetchResult> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDateMs,
  });

  Future<SubscriptionTruthFetchResult> verifyAppleAppStorePurchase({
    required String productId,
    required String receiptData,
    String? orderId,
  });
}
