import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/product_ids.dart';

void main() {
  group('ProductIds', () {
    test('all contains 3 products', () {
      expect(ProductIds.all.length, equals(3));
    });

    test('subscriptions are subset of all', () {
      expect(ProductIds.all.containsAll(ProductIds.subscriptions), isTrue);
    });

    test('isSubscription identifies correctly', () {
      expect(ProductIds.isSubscription(ProductIds.subscriberMonthly), isTrue);
      expect(ProductIds.isSubscription(ProductIds.subscriberYearly), isTrue);
      expect(ProductIds.isSubscription(ProductIds.paidUnlock), isFalse);
    });
  });

  group('PaymentService.tierForProduct', () {
    test('maps paid unlock to paid tier', () {
      expect(
        PaymentService.tierForProduct(ProductIds.paidUnlock),
        equals(UserTier.paid),
      );
    });

    test('maps monthly subscription to subscriber tier', () {
      expect(
        PaymentService.tierForProduct(ProductIds.subscriberMonthly),
        equals(UserTier.subscriber),
      );
    });

    test('maps yearly subscription to subscriber tier', () {
      expect(
        PaymentService.tierForProduct(ProductIds.subscriberYearly),
        equals(UserTier.subscriber),
      );
    });

    test('unknown product maps to free tier', () {
      expect(
        PaymentService.tierForProduct('unknown_product'),
        equals(UserTier.free),
      );
    });
  });

  group('PurchaseResult', () {
    test('success constructor', () {
      const result = PurchaseResult.success(UserTier.paid);
      expect(result.success, isTrue);
      expect(result.status, PurchaseResultStatus.success);
      expect(result.grantedTier, equals(UserTier.paid));
      expect(result.errorMessage, isNull);
    });

    test('pending constructor', () {
      const result = PurchaseResult.pending(
        orderId: 'order_123',
        redirectUrl: 'https://pay.example.com/order_123',
      );
      expect(result.success, isFalse);
      expect(result.isPending, isTrue);
      expect(result.status, PurchaseResultStatus.pending);
      expect(result.orderId, 'order_123');
      expect(result.redirectUrl, 'https://pay.example.com/order_123');
    });

    test('error constructor', () {
      const result = PurchaseResult.error('Something failed');
      expect(result.success, isFalse);
      expect(result.status, PurchaseResultStatus.error);
      expect(result.grantedTier, isNull);
      expect(result.errorMessage, equals('Something failed'));
    });
  });

  group('StoreProduct', () {
    test('holds product info', () {
      const product = StoreProduct(
        id: 'test',
        title: 'Test Product',
        description: 'A test',
        price: '¥30',
        isSubscription: false,
      );
      expect(product.id, equals('test'));
      expect(product.price, equals('¥30'));
      expect(product.isSubscription, isFalse);
    });
  });
}
