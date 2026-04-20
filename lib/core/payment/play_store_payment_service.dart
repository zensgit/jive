import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entitlement/entitlement_service.dart';
import 'payment_provider_resolver.dart';
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
  List<PaymentProvider> get availableProviders => const [
    PaymentProvider.googlePlay,
  ];

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
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async {
    if (provider != null && provider != PaymentProvider.googlePlay) {
      return PurchaseResult.error(
        'Google Play 不支持${provider.label}',
        provider: provider,
      );
    }
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
      await _iap.restorePurchases();
      return const PurchaseResult(success: true);
    } catch (e) {
      return PurchaseResult.error('恢复购买失败: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Grant the tier
        final tier = PaymentService.tierForProduct(purchase.productID);
        await _entitlement.setTier(tier);
        await _recordPurchaseTimestamp();
        await _syncTrustedPurchase(purchase);
        _pendingPurchase?.complete(PurchaseResult.success(tier));
        _pendingPurchase = null;

        // Complete the purchase on the platform side
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        final message = purchase.error?.message ?? '购买失败';
        _pendingPurchase?.complete(PurchaseResult.error(message));
        _pendingPurchase = null;
        break;

      case PurchaseStatus.canceled:
        _pendingPurchase?.complete(const PurchaseResult.error('购买已取消'));
        _pendingPurchase = null;
        break;

      case PurchaseStatus.pending:
        // Waiting for platform confirmation — do nothing yet.
        debugPrint('PlayStorePaymentService: purchase pending');
        break;
    }
    notifyListeners();
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

  Future<void> _syncTrustedPurchase(PurchaseDetails purchase) async {
    final purchaseToken = purchase.verificationData.serverVerificationData;
    if (_truthRepository == null || purchaseToken.isEmpty) return;

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
    } else if (result.errorMessage != null) {
      debugPrint(
        'PlayStorePaymentService: trusted sync skipped: ${result.errorMessage}',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
