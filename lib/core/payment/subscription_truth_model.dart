import '../entitlement/user_tier.dart';

enum SubscriptionPlan {
  free,
  paid,
  subscriber;

  static SubscriptionPlan fromString(String? value) {
    switch (value) {
      case 'paid':
        return SubscriptionPlan.paid;
      case 'subscriber':
        return SubscriptionPlan.subscriber;
      default:
        return SubscriptionPlan.free;
    }
  }
}

enum SubscriptionStatusKind {
  active,
  grace,
  pending,
  canceled,
  expired,
  revoked;

  static SubscriptionStatusKind fromString(String? value) {
    switch (value) {
      case 'active':
        return SubscriptionStatusKind.active;
      case 'grace':
        return SubscriptionStatusKind.grace;
      case 'pending':
        return SubscriptionStatusKind.pending;
      case 'canceled':
        return SubscriptionStatusKind.canceled;
      case 'revoked':
        return SubscriptionStatusKind.revoked;
      default:
        return SubscriptionStatusKind.expired;
    }
  }
}

class TrustedSubscriptionSnapshot {
  final SubscriptionPlan plan;
  final SubscriptionStatusKind status;
  final String platform;
  final String? productId;
  final DateTime? expiresAt;
  final DateTime? lastVerifiedAt;
  final String? purchaseToken;
  final String? orderId;

  const TrustedSubscriptionSnapshot({
    required this.plan,
    required this.status,
    required this.platform,
    this.productId,
    this.expiresAt,
    this.lastVerifiedAt,
    this.purchaseToken,
    this.orderId,
  });

  bool get isEntitled =>
      status == SubscriptionStatusKind.active ||
      status == SubscriptionStatusKind.grace;

  UserTier get tier {
    if (!isEntitled) return UserTier.free;
    switch (plan) {
      case SubscriptionPlan.paid:
        return UserTier.paid;
      case SubscriptionPlan.subscriber:
        return UserTier.subscriber;
      case SubscriptionPlan.free:
        return UserTier.free;
    }
  }

  Map<String, String> toCacheMap() => {
    'plan': plan.name,
    'status': status.name,
    'platform': platform,
    if (productId != null) 'product_id': productId!,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    if (lastVerifiedAt != null)
      'last_verified_at': lastVerifiedAt!.toIso8601String(),
    if (purchaseToken != null) 'purchase_token': purchaseToken!,
    if (orderId != null) 'order_id': orderId!,
  };

  factory TrustedSubscriptionSnapshot.fromCacheMap(Map<String, String> cache) {
    return TrustedSubscriptionSnapshot(
      plan: SubscriptionPlan.fromString(cache['plan']),
      status: SubscriptionStatusKind.fromString(cache['status']),
      platform: cache['platform'] ?? 'unknown',
      productId: cache['product_id'],
      expiresAt: _parseDate(cache['expires_at']),
      lastVerifiedAt: _parseDate(cache['last_verified_at']),
      purchaseToken: cache['purchase_token'],
      orderId: cache['order_id'],
    );
  }

  factory TrustedSubscriptionSnapshot.fromRow(Map<String, dynamic> row) {
    return TrustedSubscriptionSnapshot(
      plan: SubscriptionPlan.fromString(row['plan'] as String?),
      status: SubscriptionStatusKind.fromString(row['status'] as String?),
      platform: row['platform'] as String? ?? 'unknown',
      productId: row['product_id'] as String?,
      expiresAt: _parseDate(row['expires_at']?.toString()),
      lastVerifiedAt: _parseDate(row['last_verified_at']?.toString()),
      purchaseToken: row['purchase_token'] as String?,
      orderId: row['order_id'] as String?,
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class SubscriptionTruthFetchResult {
  final bool isAuthoritative;
  final TrustedSubscriptionSnapshot? snapshot;
  final String? errorMessage;

  const SubscriptionTruthFetchResult({
    required this.isAuthoritative,
    this.snapshot,
    this.errorMessage,
  });

  const SubscriptionTruthFetchResult.authoritative({
    TrustedSubscriptionSnapshot? snapshot,
  }) : this(isAuthoritative: true, snapshot: snapshot);

  const SubscriptionTruthFetchResult.unavailable([String? errorMessage])
    : this(isAuthoritative: false, errorMessage: errorMessage);
}
