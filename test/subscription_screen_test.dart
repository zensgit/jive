import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/subscription_status_service.dart';
import 'package:jive/core/payment/subscription_truth_model.dart';
import 'package:jive/core/payment/subscription_truth_repository.dart';
import 'package:jive/feature/subscription/subscription_screen.dart';

class _FakePaymentService extends PaymentService {
  _FakePaymentService({
    this.purchaseResult = const PurchaseResult.error('not implemented'),
    this.providers = const [],
  });

  final PurchaseResult purchaseResult;
  final List<PaymentProvider> providers;
  PaymentProvider? lastPurchaseProvider;

  @override
  bool get isAvailable => true;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => const [];

  @override
  List<PaymentProvider> get availableProviders => providers;

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async {
    lastPurchaseProvider = provider;
    return purchaseResult;
  }

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult(success: true);
}

class _FakeSubscriptionTruthRepository implements SubscriptionTruthRepository {
  _FakeSubscriptionTruthRepository(this.fetchResult);

  SubscriptionTruthFetchResult fetchResult;

  @override
  Future<SubscriptionTruthFetchResult> fetchCurrentSubscription() async {
    return fetchResult;
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyAppleAppStorePurchase({
    required String productId,
    required String receiptData,
    String? orderId,
  }) async {
    return const SubscriptionTruthFetchResult.unavailable();
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDateMs,
  }) async {
    return const SubscriptionTruthFetchResult.unavailable();
  }
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
      expect(find.text('刷新权益'), findsOneWidget);
      expect(find.text('完成支付后，请回到 App 并点击“刷新权益”。'), findsOneWidget);
    },
  );

  testWidgets('domestic checkout lets the user choose Alipay', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final entitlement = EntitlementService();
    await entitlement.init();
    final payment = _FakePaymentService(
      providers: const [PaymentProvider.wechatPay, PaymentProvider.alipay],
      purchaseResult: const PurchaseResult.pending(
        provider: PaymentProvider.alipay,
        orderId: 'alipay_order',
        redirectUrl: 'https://pay.example.com/alipay_order',
        errorMessage: '支付宝订单已创建，请完成支付后刷新权益',
      ),
    );

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

    final alipayChip = find.widgetWithText(ChoiceChip, '支付宝').first;
    await tester.ensureVisible(alipayChip);
    await tester.pumpAndSettle();
    await tester.tap(alipayChip);
    await tester.pumpAndSettle();

    final upgradeButton = find.widgetWithText(FilledButton, '¥28 升级到专业版');
    await tester.ensureVisible(upgradeButton);
    await tester.pumpAndSettle();
    await tester.tap(upgradeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(payment.lastPurchaseProvider, PaymentProvider.alipay);
    expect(find.text('支付宝订单已创建，请完成支付后刷新权益'), findsOneWidget);
  });

  testWidgets('pending domestic payment can refresh trusted entitlement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final entitlement = EntitlementService();
    await entitlement.init();
    final payment = _FakePaymentService(
      providers: const [PaymentProvider.wechatPay],
      purchaseResult: const PurchaseResult.pending(
        provider: PaymentProvider.wechatPay,
        orderId: 'paid_order',
        redirectUrl: 'https://pay.example.com/paid_order',
        errorMessage: '微信支付订单已创建，请完成支付后刷新权益',
      ),
    );
    final truth = _FakeSubscriptionTruthRepository(
      SubscriptionTruthFetchResult.authoritative(
        snapshot: TrustedSubscriptionSnapshot(
          plan: SubscriptionPlan.paid,
          status: SubscriptionStatusKind.active,
          platform: 'wechat_pay',
          productId: 'jive_paid_unlock',
          lastVerifiedAt: DateTime(2026, 4, 20, 12),
        ),
      ),
    );
    final statusService = SubscriptionStatusService(
      paymentService: payment,
      entitlementService: entitlement,
      truthRepository: truth,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
          ChangeNotifierProvider<PaymentService>.value(value: payment),
          Provider<SubscriptionStatusService>.value(value: statusService),
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

    await tester.tap(find.widgetWithText(TextButton, '刷新权益'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(entitlement.tier, UserTier.paid);
    expect(find.text('权益已刷新为专业版'), findsOneWidget);
  });
}
