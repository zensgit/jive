import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entitlement/entitlement_service.dart';
import '../entitlement/user_tier.dart';
import 'payment_service.dart';
import 'product_ids.dart';
import 'subscription_truth_repository.dart';

/// Google Play Billing implementation of [PaymentService].
///
/// Lifecycle:
///  1. [init] checks store availability and queries products
///  2. Listens to the purchase stream for updates
///  3. [purchase] initiates a buy flow
///  4. Completed purchases update [EntitlementService] tier
class PlayStorePaymentService extends PaymentService {
  static const _prefKeyLastPurchase = 'last_purchase_timestamp';

  final InAppPurchase _iap;
  final EntitlementService _entitlement;
  final SubscriptionTruthRepository? _truthRepository;

  bool _isAvailable = false;
  bool _isReady = false;
  List<StoreProduct> _products = [];
  Map<String, ProductDetails> _productDetailsById = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Completer for the currently pending purchase, if any.
  Completer<PurchaseResult>? _pendingPurchase;

  PlayStorePaymentService({
    required EntitlementService entitlement,
    SubscriptionTruthRepository? truthRepository,
    InAppPurchase? iap,
  }) : _entitlement = entitlement,
       _truthRepository = truthRepository,
       _iap = iap ?? InAppPurchase.instance;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isReady => _isReady;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  Future<void> init() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('PlayStorePaymentService: store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('PlayStorePaymentService: purchase stream error: $error');
      },
    );

    // Query products
    final response = await _iap.queryProductDetails(ProductIds.all);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'PlayStorePaymentService: products not found: ${response.notFoundIDs}',
      );
    }

    _productDetailsById = {for (final pd in response.productDetails) pd.id: pd};
    _products = response.productDetails.map((pd) {
      return StoreProduct(
        id: pd.id,
        title: pd.title,
        description: pd.description,
        price: pd.price,
        isSubscription: ProductIds.isSubscription(pd.id),
      );
    }).toList();

    _isReady = true;
    notifyListeners();
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    if (!_isAvailable || !_isReady) {
      return const PurchaseResult.error('支付服务不可用');
    }

    final product = _findProductDetails(productId);
    if (product == null) {
      return PurchaseResult.error('未找到商品: $productId');
    }

    _pendingPurchase = Completer<PurchaseResult>();

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _pendingPurchase?.complete(PurchaseResult.error('购买发起失败: $e'));
      _pendingPurchase = null;
    }

    // If buyNonConsumable didn't throw but also didn't trigger stream yet,
    // wait for the stream to resolve it.
    return _pendingPurchase?.future ?? const PurchaseResult.error('购买状态未知');
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      return const PurchaseResult.error('支付服务不可用');
    }
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidAddition = _iap
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final response = await androidAddition.queryPastPurchases();
        if (response.error != null) {
          return PurchaseResult.error('恢复购买失败: ${response.error!.message}');
        }

        final restoredPurchases = response.pastPurchases.map<PurchaseDetails>((
          purchase,
        ) {
          purchase.status = PurchaseStatus.restored;
          return purchase;
        }).toList();
        if (restoredPurchases.isEmpty) {
          return const PurchaseResult.error('没有可恢复的有效购买');
        }

        return _processRestoredPurchases(restoredPurchases);
      }

      await _iap.restorePurchases();
      return const PurchaseResult(success: true);
    } catch (e) {
      return PurchaseResult.error('恢复购买失败: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    unawaited(_processPurchaseUpdates(purchases));
  }

  Future<void> _processPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in _sortPurchasesForEntitlement(purchases)) {
      await _handlePurchase(purchase);
    }
  }

  Future<PurchaseResult> _processRestoredPurchases(
    List<PurchaseDetails> purchases,
  ) async {
    PurchaseResult? bestRestore;
    for (final purchase in _sortPurchasesForEntitlement(purchases)) {
      final result = await _handlePurchase(purchase);
      final grantedTier = result?.grantedTier;
      if (result == null || !result.success || grantedTier == null) {
        continue;
      }
      if (bestRestore == null ||
          _tierRank(grantedTier) > _tierRank(bestRestore.grantedTier!)) {
        bestRestore = result;
      }
    }

    return bestRestore ?? const PurchaseResult.error('没有可恢复的有效购买');
  }

  List<PurchaseDetails> _sortPurchasesForEntitlement(
    List<PurchaseDetails> purchases,
  ) {
    final ordered = List<PurchaseDetails>.from(purchases);
    ordered.sort((a, b) {
      final left = _tierRank(PaymentService.tierForProduct(a.productID));
      final right = _tierRank(PaymentService.tierForProduct(b.productID));
      return left.compareTo(right);
    });
    return ordered;
  }

  int _tierRank(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return 0;
      case UserTier.paid:
        return 1;
      case UserTier.subscriber:
        return 2;
    }
  }

  Future<PurchaseResult?> _handlePurchase(PurchaseDetails purchase) async {
    PurchaseResult? result;
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final localTier = PaymentService.tierForProduct(purchase.productID);
        final effectiveTier = await _applyPurchaseEntitlement(
          purchase,
          fallbackTier: localTier,
        );
        result = effectiveTier == UserTier.free
            ? PurchaseResult.error(
                purchase.status == PurchaseStatus.restored
                    ? '没有可恢复的有效购买'
                    : '购买验证未通过',
              )
            : PurchaseResult.success(effectiveTier);
        _resolvePendingPurchase(result);

        // Complete the purchase on the platform side
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        final message = purchase.error?.message ?? '购买失败';
        result = PurchaseResult.error(message);
        _resolvePendingPurchase(result);
        break;

      case PurchaseStatus.canceled:
        result = const PurchaseResult.error('购买已取消');
        _resolvePendingPurchase(result);
        break;

      case PurchaseStatus.pending:
        // Waiting for platform confirmation — do nothing yet.
        debugPrint('PlayStorePaymentService: purchase pending');
        break;
    }
    notifyListeners();
    return result;
  }

  ProductDetails? _findProductDetails(String productId) {
    return _productDetailsById[productId];
  }

  Future<void> _recordPurchaseTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefKeyLastPurchase,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _resolvePendingPurchase(PurchaseResult result) {
    final pending = _pendingPurchase;
    if (pending == null || pending.isCompleted) return;
    pending.complete(result);
    _pendingPurchase = null;
  }

  Future<UserTier> _applyPurchaseEntitlement(
    PurchaseDetails purchase, {
    required UserTier fallbackTier,
  }) async {
    final trustedTier = await _syncTrustedPurchase(purchase);
    final effectiveTier = trustedTier ?? fallbackTier;
    if (trustedTier == null) {
      await _entitlement.setTier(fallbackTier);
    }
    if (effectiveTier != UserTier.free) {
      await _recordPurchaseTimestamp();
    }
    return effectiveTier;
  }

  Future<UserTier?> _syncTrustedPurchase(PurchaseDetails purchase) async {
    final purchaseToken = purchase.verificationData.serverVerificationData;
    if (_truthRepository == null || purchaseToken.isEmpty) return null;

    final result = await _truthRepository.verifyGooglePlayPurchase(
      productId: purchase.productID,
      purchaseToken: purchaseToken,
      orderId: purchase.purchaseID,
      transactionDateMs: purchase.transactionDate,
    );
    if (result.isAuthoritative && result.snapshot != null) {
      await _entitlement.applyTrustedSnapshot(result.snapshot!);
      debugPrint(
        'PlayStorePaymentService: trusted subscription synced for ${purchase.productID}',
      );
      return result.snapshot!.tier;
    }
    if (result.isAuthoritative) {
      await _entitlement.clearTrustedSnapshot(downgradeSubscriber: true);
      await _entitlement.setTier(UserTier.free);
      debugPrint(
        'PlayStorePaymentService: trusted sync returned no entitlement for ${purchase.productID}',
      );
      return UserTier.free;
    } else if (result.errorMessage != null) {
      debugPrint(
        'PlayStorePaymentService: trusted sync skipped: ${result.errorMessage}',
      );
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
