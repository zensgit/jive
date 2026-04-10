import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entitlement/entitlement_service.dart';
import '../entitlement/user_tier.dart';
import 'payment_service.dart';
import 'subscription_truth_model.dart';
import 'subscription_truth_repository.dart';

/// Checks subscription validity on app startup and handles expiry/downgrade.
///
/// Responsibilities:
///  - Restore purchases via [PaymentService] on launch
///  - Downgrade subscriber → free when subscription has expired
///  - Never expire one-time (paid) purchases
///  - Grace period: keep tier for 7 days when offline
class SubscriptionStatusService {
  static const _prefKeyLastPurchase = 'last_purchase_timestamp';
  static const _gracePeriod = Duration(days: 7);
  static const _resumeRecheckInterval = Duration(minutes: 5);

  final PaymentService _paymentService;
  final EntitlementService _entitlementService;
  final SubscriptionTruthRepository? _truthRepository;
  Future<void>? _inFlightCheck;
  DateTime? _lastCheckedAt;

  SubscriptionStatusService({
    required PaymentService paymentService,
    required EntitlementService entitlementService,
    SubscriptionTruthRepository? truthRepository,
  }) : _paymentService = paymentService,
       _entitlementService = entitlementService,
       _truthRepository = truthRepository;

  /// Check and sync subscription state on app start.
  ///
  /// Flow:
  ///  1. If payment service unavailable → offline grace logic
  ///  2. Restore purchases (triggers purchase stream → tier update)
  ///  3. If restore finds nothing and user is subscriber → downgrade to free
  Future<void> checkAndSync({bool force = true}) {
    if (!force &&
        _lastCheckedAt != null &&
        DateTime.now().difference(_lastCheckedAt!) < _resumeRecheckInterval) {
      return Future.value();
    }

    final inFlight = _inFlightCheck;
    if (inFlight != null) return inFlight;

    final future = _runCheckAndSync().whenComplete(() {
      _lastCheckedAt = DateTime.now();
      _inFlightCheck = null;
    });
    _inFlightCheck = future;
    return future;
  }

  Future<void> checkAndSyncIfStale() {
    return checkAndSync(force: false);
  }

  Future<void> _runCheckAndSync() async {
    final currentTier = _entitlementService.tier;

    final truthResult =
        await _truthRepository?.fetchCurrentSubscription() ??
        const SubscriptionTruthFetchResult.unavailable();

    if (truthResult.isAuthoritative) {
      final snapshot = truthResult.snapshot;
      if (snapshot != null) {
        await _entitlementService.applyTrustedSnapshot(snapshot);
        if (snapshot.isEntitled || snapshot.tier == UserTier.paid) {
          debugPrint(
            'SubscriptionStatusService: loaded trusted tier ${snapshot.tier.name}',
          );
        }
        return;
      } else if (currentTier == UserTier.subscriber) {
        debugPrint(
          'SubscriptionStatusService: trusted source reports no subscription',
        );
        await _entitlementService.clearTrustedSnapshot(
          downgradeSubscriber: true,
        );
        return;
      }
    }

    // Paid (one-time) purchases never expire.
    if (currentTier == UserTier.paid) {
      debugPrint('SubscriptionStatusService: paid tier — no expiry check');
      return;
    }

    // If payment service is not available, apply offline grace period.
    if (!_paymentService.isAvailable) {
      debugPrint(
        'SubscriptionStatusService: service unavailable — offline grace',
      );
      await _applyOfflineGrace(currentTier);
      return;
    }

    // Attempt to restore purchases from the store.
    final result = await _paymentService.restorePurchases();

    // restorePurchases triggers the purchase stream in PlayStorePaymentService,
    // which updates the entitlement on success. If restore did not surface an
    // active entitlement and user was subscriber, clear the trusted cache and
    // downgrade locally.
    if (!result.success && currentTier == UserTier.subscriber) {
      debugPrint(
        'SubscriptionStatusService: no active subscription — downgrading',
      );
      await _entitlementService.clearTrustedSnapshot(downgradeSubscriber: true);
    }
  }

  /// Record the timestamp of a successful purchase.
  Future<void> recordPurchaseTimestamp(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefKeyLastPurchase,
      DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint(
      'SubscriptionStatusService: recorded purchase time for $productId',
    );
  }

  /// Read the last purchase timestamp, if any.
  Future<DateTime?> getLastPurchaseTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefKeyLastPurchase);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// When offline, keep tier if last purchase was within [_gracePeriod].
  Future<void> _applyOfflineGrace(UserTier currentTier) async {
    if (currentTier == UserTier.free) return;

    final lastPurchase = await getLastPurchaseTime();
    if (lastPurchase == null) {
      // No record — cannot verify, keep current tier as a courtesy.
      debugPrint(
        'SubscriptionStatusService: no purchase record — keeping tier',
      );
      return;
    }

    final elapsed = DateTime.now().difference(lastPurchase);
    if (elapsed > _gracePeriod) {
      debugPrint(
        'SubscriptionStatusService: grace period expired — downgrading',
      );
      await _entitlementService.setTier(UserTier.free);
    } else {
      debugPrint(
        'SubscriptionStatusService: within grace period '
        '(${elapsed.inDays}d / ${_gracePeriod.inDays}d)',
      );
    }
  }
}
