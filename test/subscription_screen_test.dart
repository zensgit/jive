import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/feature/subscription/subscription_screen.dart';

class _FakePaymentService extends PaymentService {
  _FakePaymentService({
    this.purchaseResult = const PurchaseResult.error('not implemented'),
  });

  final PurchaseResult purchaseResult;

  @override
  bool get isAvailable => true;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<PurchaseResult> purchase(String productId) async => purchaseResult;

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult(success: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('subscriber plan owns cloud sync and multi-device copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final entitlement = EntitlementService();
    await entitlement.init();
    final payment = _FakePaymentService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
          ChangeNotifierProvider<PaymentService>.value(value: payment),
        ],
        child: const MaterialApp(home: SubscriptionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('云同步与多设备使用'), 300);
    expect(find.text('云同步与多设备使用'), findsOneWidget);
    expect(find.text('登录后可在多设备间同步数据'), findsNothing);
  });

  testWidgets(
    'pending domestic payment shows order details and payment links',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final entitlement = EntitlementService();
      await entitlement.init();
      final payment = _FakePaymentService(
        purchaseResult: const PurchaseResult.pending(
          provider: PaymentProvider.wechatPay,
          orderId: 'order_123',
          redirectUrl: 'https://pay.example.com/order_123',
          qrCodeUrl: 'https://pay.example.com/order_123/qr.png',
          errorMessage: '微信支付订单已创建，请完成支付后刷新权益',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<EntitlementService>.value(
              value: entitlement,
            ),
            ChangeNotifierProvider<PaymentService>.value(value: payment),
          ],
          child: const MaterialApp(home: SubscriptionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final upgradeButton = find.widgetWithText(FilledButton, '¥28 升级到专业版');
      await tester.ensureVisible(upgradeButton);
      await tester.pumpAndSettle();
      await tester.tap(upgradeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('支付订单已创建'), findsOneWidget);
      expect(find.text('微信支付订单已创建，请完成支付后刷新权益'), findsOneWidget);
      expect(find.text('订单号'), findsOneWidget);
      expect(find.text('order_123'), findsOneWidget);
      expect(find.text('支付链接'), findsOneWidget);
      expect(find.text('https://pay.example.com/order_123'), findsOneWidget);
      expect(find.text('二维码链接'), findsOneWidget);
      expect(
        find.text('https://pay.example.com/order_123/qr.png'),
        findsOneWidget,
      );
    },
  );
}
