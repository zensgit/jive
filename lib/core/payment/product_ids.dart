/// In-app purchase product identifiers.
///
/// These must match the product IDs configured in:
/// - Google Play Console → In-app products / Subscriptions
/// - App Store Connect → In-App Purchases (future)
class ProductIds {
  ProductIds._();

  /// One-time purchase: unlock paid tier (专业版).
  static const String paidUnlock = 'jive_paid_unlock';

  /// Subscription: monthly subscriber tier (订阅版月付).
  static const String subscriberMonthly = 'jive_subscriber_monthly';

  /// Subscription: yearly subscriber tier (订阅版年付).
  static const String subscriberYearly = 'jive_subscriber_yearly';

  /// All product IDs to query from the store.
  static const Set<String> all = {
    paidUnlock,
    subscriberMonthly,
    subscriberYearly,
  };

  /// IDs that represent subscriptions (auto-renewing).
  static const Set<String> subscriptions = {
    subscriberMonthly,
    subscriberYearly,
  };

  /// Whether the given [productId] is a subscription.
  static bool isSubscription(String productId) =>
      subscriptions.contains(productId);
}
