import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/feature/subscription/subscription_screen.dart';

class _FakePaymentService extends PaymentService {
  @override
  bool get isAvailable => true;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<PurchaseResult> purchase(String productId) async =>
      const PurchaseResult.error('not implemented');

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
}
