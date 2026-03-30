/// User subscription tier.
///
/// Determines which features are available and whether ads are shown.
///  - [free]: ads + limited features
///  - [paid]: no ads + more features (one-time purchase)
///  - [subscriber]: no ads + all features (recurring subscription)
enum UserTier {
  free,
  paid,
  subscriber;

  bool get isFree => this == free;
  bool get isPaid => this == paid;
  bool get isSubscriber => this == subscriber;

  /// Whether ads should be shown for this tier.
  bool get showAds => this == free;

  /// Whether this tier has at least paid-level access.
  bool get hasFullOffline => this != free;

  /// Whether this tier has cloud/sync features.
  bool get hasCloud => this == subscriber;

  String get label {
    switch (this) {
      case free:
        return '免费版';
      case paid:
        return '专业版';
      case subscriber:
        return '订阅版';
    }
  }
}
