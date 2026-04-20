import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/payment/alipay_payment_service.dart';
import 'package:jive/core/payment/domestic_payment_order_client.dart';
import 'package:jive/core/payment/domestic_payment_service_base.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/product_ids.dart';
import 'package:jive/core/payment/wechat_pay_payment_service.dart';

class _FakeDomesticPaymentOrderClient implements DomesticPaymentOrderClient {
  DomesticPaymentOrder? nextOrder;
  Object? nextError;
  PaymentProvider? lastProvider;

  @override
  Future<DomesticPaymentOrder> createOrder({
    required PaymentProvider provider,
    required String productId,
    required String planCode,
    required PaymentChannel channel,
  }) async {
    lastProvider = provider;
    if (nextError != null) {
      throw nextError!;
    }
    return nextOrder ??
        DomesticPaymentOrder(
          provider: provider,
          orderId: 'order_123',
          status: 'pending',
          redirectUrl: 'https://pay.example.com/order_123',
          qrCodeUrl: 'https://pay.example.com/order_123/qr.png',
          productId: productId,
          planCode: planCode,
        );
  }
}

void main() {
  group('WechatPayPaymentService', () {
    test(
      'returns pending result after creating domestic payment order',
      () async {
        final service = WechatPayPaymentService(
          orderClient: _FakeDomesticPaymentOrderClient(),
          channel: PaymentChannel.selfHostedWeb,
        );

        await service.init();
        final result = await service.purchase(ProductIds.subscriberMonthly);

        expect(result.success, isFalse);
        expect(result.isPending, isTrue);
        expect(result.provider, PaymentProvider.wechatPay);
        expect(result.orderId, 'order_123');
        expect(result.redirectUrl, isNotNull);
        expect(result.qrCodeUrl, isNotNull);
      },
    );
  });

  group('AlipayPaymentService', () {
    test('surfaces create order failures', () async {
      final client = _FakeDomesticPaymentOrderClient()
        ..nextError = StateError('network failed');
      final service = AlipayPaymentService(
        orderClient: client,
        channel: PaymentChannel.directAndroid,
      );

      await service.init();
      final result = await service.purchase(ProductIds.paidUnlock);

      expect(result.success, isFalse);
      expect(result.status, PurchaseResultStatus.error);
      expect(result.errorMessage, contains('创建支付订单失败'));
    });

    test('restorePurchases is unsupported for domestic providers', () async {
      final service = AlipayPaymentService(
        orderClient: _FakeDomesticPaymentOrderClient(),
        channel: PaymentChannel.directAndroid,
      );

      await service.init();
      final result = await service.restorePurchases();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('暂不支持恢复购买'));
    });
  });

  group('DomesticPaymentService', () {
    test('uses selected provider when creating a payment order', () async {
      final client = _FakeDomesticPaymentOrderClient();
      final service = DomesticPaymentService(
        providers: const [PaymentProvider.wechatPay, PaymentProvider.alipay],
        orderClient: client,
        channel: PaymentChannel.selfHostedWeb,
      );

      await service.init();
      final result = await service.purchase(
        ProductIds.subscriberYearly,
        provider: PaymentProvider.alipay,
      );

      expect(service.availableProviders, const [
        PaymentProvider.wechatPay,
        PaymentProvider.alipay,
      ]);
      expect(client.lastProvider, PaymentProvider.alipay);
      expect(result.isPending, isTrue);
      expect(result.provider, PaymentProvider.alipay);
    });

    test('rejects unavailable provider choices', () async {
      final client = _FakeDomesticPaymentOrderClient();
      final service = DomesticPaymentService(
        providers: const [PaymentProvider.wechatPay],
        orderClient: client,
        channel: PaymentChannel.selfHostedWeb,
      );

      await service.init();
      final result = await service.purchase(
        ProductIds.subscriberMonthly,
        provider: PaymentProvider.alipay,
      );

      expect(result.status, PurchaseResultStatus.error);
      expect(client.lastProvider, isNull);
    });
  });
}
