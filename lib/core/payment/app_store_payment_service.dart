import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entitlement/entitlement_service.dart';
import '../entitlement/user_tier.dart';
import 'payment_provider_resolver.dart';
import 'payment_service.dart';
import 'product_ids.dart';
import 'subscription_truth_model.dart';
import 'subscription_truth_repository.dart';

abstract class AppStorePurchaseClient {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases({String? applicationUserName});
  Future<void> completePurchase(PurchaseDetails purchase);
}

class _InAppPurchaseClient implements AppStorePurchaseClient {
  final InAppPurchase _iap;

  _InAppPurchaseClient(this._iap);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases({String? applicationUserName}) =>
      _iap.restorePurchases(applicationUserName: applicationUserName);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

class AppStorePaymentService extends PaymentService {
  static const _prefKeyLastPurchase = 'last_purchase_timestamp';
  static const _defaultRestoreTimeout = Duration(seconds: 5);
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final AppStorePurchaseClient _iap;
  final EntitlementService _entitlement;
  final SubscriptionTruthRepository? _truthRepository;
  final String? Function()? _applicationUserNameProvider;
  final Duration _restoreTimeout;

  bool _isAvailable = false;
  bool _isReady = false;
  List<StoreProduct> _products = [];
  Map<String, ProductDetails> _productDetailsById = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseResult>? _pendingPurchase;
  Completer<PurchaseResult>? _pendingRestore;

  AppStorePaymentService({
    required EntitlementService entitlement,
    SubscriptionTruthRepository? truthRepository,
    String? Function()? applicationUserNameProvider,
    Duration restoreTimeout = _defaultRestoreTimeout,
    AppStorePurchaseClient? iapClient,
    InAppPurchase? iap,
  }) : _entitlement = entitlement,
       _truthRepository = truthRepository,
       _applicationUserNameProvider = applicationUserNameProvider,
       _restoreTimeout = restoreTimeout,
       _iap = iapClient ?? _InAppPurchaseClient(iap ?? InAppPurchase.instance);

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isReady => _isReady;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  List<PaymentProvider> get availableProviders => const [
    PaymentProvider.appleAppStore,
  ];

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
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async {
    if (provider != null && provider != PaymentProvider.appleAppStore) {
      return PurchaseResult.error(
        'App Store 不支持${provider.label}',
        provider: provider,
      );
    }
    if (!_isAvailable || !_isReady) {
      return const PurchaseResult.error('支付服务不可用');
    }

    final product = _productDetailsById[productId];
    if (product == null) {
      return PurchaseResult.error('未找到商品: $productId');
    }

    final pending = Completer<PurchaseResult>();
    _pendingPurchase = pending;
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: appStoreAccountTokenForUser(
        _applicationUserNameProvider?.call(),
      ),
    );

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (!pending.isCompleted) {
        pending.complete(PurchaseResult.error('购买发起失败: $e'));
      }
    }

    return pending.future.whenComplete(() {
      if (identical(_pendingPurchase, pending)) {
        _pendingPurchase = null;
      }
    });
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      return const PurchaseResult.error('支付服务不可用');
    }

    final pending = Completer<PurchaseResult>();
    _pendingRestore = pending;

    try {
      await _iap.restorePurchases(
        applicationUserName: appStoreAccountTokenForUser(
          _applicationUserNameProvider?.call(),
        ),
      );
    } catch (e) {
      if (!pending.isCompleted) {
        pending.complete(PurchaseResult.error('恢复购买失败: $e'));
      }
    }

    return pending.future
        .timeout(
          _restoreTimeout,
          onTimeout: () => const PurchaseResult.error('没有可恢复的有效购买'),
        )
        .whenComplete(() {
          if (identical(_pendingRestore, pending)) {
            _pendingRestore = null;
          }
        });
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    unawaited(_processPurchaseUpdates(purchases));
  }

  Future<void> _processPurchaseUpdates(List<PurchaseDetails> purchases) async {
    PurchaseResult? restoreResult;
    for (final purchase in _sortPurchasesForEntitlement(purchases)) {
      final result = await _handlePurchase(purchase);
      if (_pendingRestore != null && result != null) {
        restoreResult = _preferRestoreResult(restoreResult, result);
      }
    }
    if (restoreResult != null) {
      _resolvePendingRestore(restoreResult);
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

  void _resolvePendingRestore(PurchaseResult result) {
    final pending = _pendingRestore;
    if (pending == null || pending.isCompleted) return;
    pending.complete(result);
    _pendingRestore = null;
  }

  PurchaseResult _preferRestoreResult(
    PurchaseResult? existing,
    PurchaseResult candidate,
  ) {
    if (existing == null) return candidate;
    if (candidate.success && !existing.success) return candidate;
    if (!candidate.success && existing.success) return existing;
    if (!candidate.success && !existing.success) return existing;

    final existingTier = existing.grantedTier ?? UserTier.free;
    final candidateTier = candidate.grantedTier ?? UserTier.free;
    return _tierRank(candidateTier) >= _tierRank(existingTier)
        ? candidate
        : existing;
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
    return syncTrustedReceipt(
      productId: purchase.productID,
      receiptData: purchase.verificationData.serverVerificationData,
      orderId: purchase.purchaseID,
    );
  }

  @visibleForTesting
  Future<UserTier?> syncTrustedReceipt({
    required String productId,
    String? receiptData,
    String? orderId,
  }) async {
    if (_truthRepository == null) return null;

    final normalizedReceipt = receiptData?.trim();
    if (normalizedReceipt != null && normalizedReceipt.isNotEmpty) {
      final verifyResult = await _truthRepository.verifyAppleAppStorePurchase(
        productId: productId,
        receiptData: normalizedReceipt,
        orderId: orderId,
      );
      final verifiedTier = await _applyTrustedResult(
        verifyResult,
        productId: productId,
        logPrefix: 'verified',
      );
      if (verifiedTier != null) {
        return verifiedTier;
      }
    }

    final fetchResult = await _truthRepository.fetchCurrentSubscription();
    return _applyTrustedResult(
      fetchResult,
      productId: productId,
      logPrefix: 'fetched',
    );
  }

  Future<UserTier?> _applyTrustedResult(
    SubscriptionTruthFetchResult result, {
    required String productId,
    required String logPrefix,
  }) async {
    if (result.isAuthoritative && result.snapshot != null) {
      final snapshot = result.snapshot!;
      if (snapshot.platform == 'apple_app_store' &&
          (snapshot.productId == null || snapshot.productId == productId)) {
        await _entitlement.applyTrustedSnapshot(snapshot);
        debugPrint(
          'AppStorePaymentService: $logPrefix trusted subscription synced for $productId',
        );
        return snapshot.tier;
      }
    } else if (result.errorMessage != null) {
      debugPrint(
        'AppStorePaymentService: $logPrefix trusted sync skipped: ${result.errorMessage}',
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
