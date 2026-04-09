import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../sync/sync_config.dart';
import 'subscription_truth_model.dart';
import 'subscription_truth_repository.dart';

class SupabaseSubscriptionTruthRepository
    implements SubscriptionTruthRepository {
  SupabaseSubscriptionTruthRepository({SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  @override
  Future<SubscriptionTruthFetchResult> fetchCurrentSubscription() async {
    if (!SyncConfig.isConfigured) {
      return const SubscriptionTruthFetchResult.unavailable(
        'supabase_not_configured',
      );
    }

    final userId = _resolvedClient.auth.currentUser?.id;
    if (userId == null) {
      return const SubscriptionTruthFetchResult.unavailable('auth_required');
    }

    try {
      final rows = await _resolvedClient
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1);

      final list = rows as List<dynamic>;
      if (list.isEmpty) {
        return const SubscriptionTruthFetchResult.authoritative();
      }

      final row = Map<String, dynamic>.from(list.first as Map);
      return SubscriptionTruthFetchResult.authoritative(
        snapshot: TrustedSubscriptionSnapshot.fromRow(row),
      );
    } catch (e) {
      debugPrint('SupabaseSubscriptionTruthRepository.fetch failed: $e');
      return SubscriptionTruthFetchResult.unavailable(e.toString());
    }
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDateMs,
  }) async {
    if (!SyncConfig.isConfigured) {
      return const SubscriptionTruthFetchResult.unavailable(
        'supabase_not_configured',
      );
    }

    final userId = _resolvedClient.auth.currentUser?.id;
    if (userId == null) {
      return const SubscriptionTruthFetchResult.unavailable('auth_required');
    }

    try {
      final response = await _invokeVerifySubscription({
        'platform': 'google_play',
        'product_id': productId,
        'purchase_token': purchaseToken,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        if (transactionDateMs != null && transactionDateMs.isNotEmpty)
          'transaction_date_ms': transactionDateMs,
      });

      return _parseVerifyResponse(response.data);
    } catch (e) {
      debugPrint('SupabaseSubscriptionTruthRepository.verify failed: $e');
      return SubscriptionTruthFetchResult.unavailable(e.toString());
    }
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyAppleAppStorePurchase({
    required String productId,
    required String receiptData,
    String? orderId,
  }) async {
    if (!SyncConfig.isConfigured) {
      return const SubscriptionTruthFetchResult.unavailable(
        'supabase_not_configured',
      );
    }

    final userId = _resolvedClient.auth.currentUser?.id;
    if (userId == null) {
      return const SubscriptionTruthFetchResult.unavailable('auth_required');
    }

    try {
      final response = await _invokeVerifySubscription({
        'platform': 'apple_app_store',
        'product_id': productId,
        'receipt_data': receiptData,
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      });

      return _parseVerifyResponse(response.data);
    } catch (e) {
      debugPrint('SupabaseSubscriptionTruthRepository.verify failed: $e');
      return SubscriptionTruthFetchResult.unavailable(e.toString());
    }
  }

  Future<FunctionResponse> _invokeVerifySubscription(
    Map<String, Object?> body,
  ) {
    return _resolvedClient.functions.invoke('verify-subscription', body: body);
  }

  SubscriptionTruthFetchResult _parseVerifyResponse(dynamic data) {
    if (data is! Map) {
      return const SubscriptionTruthFetchResult.unavailable(
        'invalid_verify_response',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final subscription = map['subscription'];
    if (subscription is Map) {
      return SubscriptionTruthFetchResult.authoritative(
        snapshot: TrustedSubscriptionSnapshot.fromRow(
          Map<String, dynamic>.from(subscription),
        ),
      );
    }

    return SubscriptionTruthFetchResult.unavailable(
      map['error']?.toString() ?? 'verification_failed',
    );
  }
}
