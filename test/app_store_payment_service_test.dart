import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/payment/app_store_payment_service.dart';
import 'package:jive/core/payment/product_ids.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('purchase preserves the specific store error when buyNonConsumable throws', () async {
    final client = _FakeAppStorePurchaseClient()
      ..buyNonConsumableError = StateError('store unavailable');

    final service = AppStorePaymentService(
      entitlement: EntitlementService(),
      iapClient: client,
    );
    await service.init();

    final result = await service.purchase(ProductIds.paidUnlock);

    expect(result.success, isFalse);
    expect(result.errorMessage, contains('购买发起失败'));
    expect(result.errorMessage, contains('store unavailable'));

    service.dispose();
    await client.dispose();
  });

  test('restorePurchases waits for restored purchase stream outcome', () async {
    final entitlement = EntitlementService();
    final client = _FakeAppStorePurchaseClient();
    client.onRestorePurchases = (_) async {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 10), () {
          client.emitPurchases([
            _purchaseDetails(
              productId: ProductIds.paidUnlock,
              status: PurchaseStatus.restored,
              pendingCompletePurchase: true,
            ),
          ]);
        }),
      );
    };

    final service = AppStorePaymentService(
      entitlement: entitlement,
      restoreTimeout: const Duration(milliseconds: 200),
      iapClient: client,
    );
    await service.init();

    var completed = false;
    final future = service.restorePurchases().then((result) {
      completed = true;
      return result;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(completed, isFalse);

    final result = await future;
    expect(result.success, isTrue);
    expect(result.grantedTier, UserTier.paid);
    expect(entitlement.tier, UserTier.paid);
    expect(client.completedPurchases, hasLength(1));

    service.dispose();
    await client.dispose();
  });

  test('restorePurchases returns a bounded error when nothing is restored', () async {
    final client = _FakeAppStorePurchaseClient();
    client.onRestorePurchases = (_) async {};

    final service = AppStorePaymentService(
      entitlement: EntitlementService(),
      restoreTimeout: const Duration(milliseconds: 20),
      iapClient: client,
    );
    await service.init();

    final result = await service.restorePurchases();

    expect(result.success, isFalse);
    expect(result.errorMessage, '没有可恢复的有效购买');

    service.dispose();
    await client.dispose();
  });
}

class _FakeAppStorePurchaseClient implements AppStorePurchaseClient {
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  Object? buyNonConsumableError;
  Future<void> Function(String? applicationUserName)? onRestorePurchases;
  final List<PurchaseDetails> completedPurchases = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: identifiers
          .map(
            (id) => ProductDetails(
              id: id,
              title: id,
              description: '$id description',
              price: '¥1.00',
              rawPrice: 1,
              currencyCode: 'CNY',
            ),
          )
          .toList(),
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    if (buyNonConsumableError != null) {
      throw buyNonConsumableError!;
    }
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    await onRestorePurchases?.call(applicationUserName);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  void emitPurchases(List<PurchaseDetails> purchases) {
    _purchaseController.add(purchases);
  }

  Future<void> dispose() async {
    await _purchaseController.close();
  }
}

PurchaseDetails _purchaseDetails({
  required String productId,
  required PurchaseStatus status,
  bool pendingCompletePurchase = false,
}) {
  final purchase = PurchaseDetails(
    productID: productId,
    purchaseID: 'purchase-$productId',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'app_store',
    ),
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    status: status,
  );
  purchase.pendingCompletePurchase = pendingCompletePurchase;
  return purchase;
}
