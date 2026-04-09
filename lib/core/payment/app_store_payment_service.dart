import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entitlement/entitlement_service.dart';
import '../entitlement/user_tier.dart';
import 'payment_service.dart';
import 'product_ids.dart';
import 'subscription_truth_repository.dart';

class AppStorePaymentService extends PaymentService {
  static const _prefKeyLastPurchase = 'last_purchase_timestamp';
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final InAppPurchase _iap;
  final EntitlementService _entitlement;
  final SubscriptionTruthRepository? _truthRepository;
  final String? Function()? _applicationUserNameProvider;

  bool _isAvailable = false;
  bool _isReady = false;
  List<StoreProduct> _products = [];
  Map<String, ProductDetails> _productDetailsById = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseResult>? _pendingPurchase;

  AppStorePaymentService({
    required EntitlementService entitlement,
    SubscriptionTruthRepository? truthRepository,
    String? Function()? applicationUserNameProvider,
    InAppPurchase? iap,
  }) : _entitlement = entitlement,
       _truthRepository = truthRepository,
       _applicationUserNameProvider = applicationUserNameProvider,
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
      debugPrint('AppStorePaymentService: store not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('AppStorePaymentService: purchase stream error: $error');
      },
    );

    final response = await _iap.queryProductDetails(ProductIds.all);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'AppStorePaymentService: products not found: ${response.notFoundIDs}',
      );
    }

    _productDetailsById = {for (final pd in response.productDetails) pd.id: pd};
    _products = response.productDetails
        .map(
          (pd) => StoreProduct(
            id: pd.id,
            title: pd.title,
            description: pd.description,
            price: pd.price,
            isSubscription: ProductIds.isSubscription(pd.id),
          ),
        )
        .toList();

    _isReady = true;
    notifyListeners();
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    if (!_isAvailable || !_isReady) {
      return const PurchaseResult.error('支付服务不可用');
    }

    final product = _productDetailsById[productId];
    if (product == null) {
      return PurchaseResult.error('未找到商品: $productId');
    }

    _pendingPurchase = Completer<PurchaseResult>();
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: appStoreAccountTokenForUser(
        _applicationUserNameProvider?.call(),
      ),
    );

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _pendingPurchase?.complete(PurchaseResult.error('购买发起失败: $e'));
      _pendingPurchase = null;
    }

    return _pendingPurchase?.future ?? const PurchaseResult.error('购买状态未知');
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      return const PurchaseResult.error('支付服务不可用');
    }

    try {
      await _iap.restorePurchases(
        applicationUserName: appStoreAccountTokenForUser(
          _applicationUserNameProvider?.call(),
        ),
      );
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
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
      case PurchaseStatus.error:
        result = PurchaseResult.error(purchase.error?.message ?? '购买失败');
        _resolvePendingPurchase(result);
        break;
      case PurchaseStatus.canceled:
        result = const PurchaseResult.error('购买已取消');
        _resolvePendingPurchase(result);
        break;
      case PurchaseStatus.pending:
        debugPrint('AppStorePaymentService: purchase pending');
        break;
    }
    notifyListeners();
    return result;
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
    if (_truthRepository == null) return null;

    final result = await _truthRepository.fetchCurrentSubscription();
    if (result.isAuthoritative && result.snapshot != null) {
      final snapshot = result.snapshot!;
      if (
        snapshot.platform == 'apple_app_store' &&
        (snapshot.productId == null || snapshot.productId == purchase.productID)
      ) {
        await _entitlement.applyTrustedSnapshot(snapshot);
        debugPrint(
          'AppStorePaymentService: trusted subscription synced for ${purchase.productID}',
        );
        return snapshot.tier;
      }
    } else if (result.errorMessage != null) {
      debugPrint(
        'AppStorePaymentService: trusted sync skipped: ${result.errorMessage}',
      );
    }

    return null;
  }

  Future<void> _recordPurchaseTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefKeyLastPurchase,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static String? appStoreAccountTokenForUser(String? userId) {
    if (userId == null || !_uuidPattern.hasMatch(userId)) {
      return null;
    }
    return userId.toLowerCase();
  }
}
