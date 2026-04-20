import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/app/subscription_lifecycle_gate.dart';
import 'package:jive/core/auth/auth_service.dart';
import 'package:jive/core/auth/auth_state.dart';
import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/payment/payment_provider_resolver.dart';
import 'package:jive/core/payment/payment_service.dart';
import 'package:jive/core/payment/subscription_status_service.dart';
import 'package:jive/core/payment/subscription_truth_model.dart';
import 'package:jive/core/payment/subscription_truth_repository.dart';

class FakeAuthService extends AuthService {
  AuthState _state = const AuthGuest();

  @override
  AuthState get state => _state;

  @override
  Future<void> init() async {}

  void setLoggedIn(String uid) {
    _state = AuthLoggedIn(
      AuthUser(uid: uid, provider: AuthProvider.email, email: '$uid@test.dev'),
    );
    notifyListeners();
  }

  void setGuest() {
    _state = const AuthGuest();
    notifyListeners();
  }

  @override
  Future<AuthState> registerWithEmail(String email, String password) async =>
      state;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> requestSmsCode(String phone) async {}

  @override
  Future<void> signOut() async {
    setGuest();
  }

  @override
  Future<AuthState> signInWithEmail(String email, String password) async =>
      state;

  @override
  Future<AuthState> signInWithPhone(String phone, String code) async => state;

  @override
  Future<AuthState> signInWithProvider(AuthProvider provider) async => state;

  @override
  Future<void> deleteAccount() async {}
}

class FakePaymentService extends PaymentService {
  int restoreCallCount = 0;

  @override
  bool get isAvailable => true;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async => const PurchaseResult.error('not implemented');

  @override
  Future<PurchaseResult> restorePurchases() async {
    restoreCallCount += 1;
    return const PurchaseResult(success: true);
  }
}

class FakeSubscriptionTruthRepository implements SubscriptionTruthRepository {
  FakeSubscriptionTruthRepository({
    SubscriptionTruthFetchResult? fetchResult,
    SubscriptionTruthFetchResult? verifyResult,
    SubscriptionTruthFetchResult? appleVerifyResult,
  }) : fetchResult =
           fetchResult ??
           const SubscriptionTruthFetchResult.authoritative(
             snapshot: TrustedSubscriptionSnapshot(
               plan: SubscriptionPlan.subscriber,
               status: SubscriptionStatusKind.active,
               platform: 'google_play',
               productId: 'jive_subscriber_monthly',
             ),
           ),
       verifyResult =
           verifyResult ?? const SubscriptionTruthFetchResult.unavailable(),
       appleVerifyResult =
           appleVerifyResult ??
           const SubscriptionTruthFetchResult.unavailable();

  SubscriptionTruthFetchResult fetchResult;
  SubscriptionTruthFetchResult verifyResult;
  SubscriptionTruthFetchResult appleVerifyResult;
  int fetchCallCount = 0;

  @override
  Future<SubscriptionTruthFetchResult> fetchCurrentSubscription() async {
    fetchCallCount += 1;
    return fetchResult;
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDateMs,
  }) async {
    return verifyResult;
  }

  @override
  Future<SubscriptionTruthFetchResult> verifyAppleAppStorePurchase({
    required String productId,
    required String receiptData,
    String? orderId,
  }) async {
    return appleVerifyResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthService authService;
  late EntitlementService entitlementService;
  late FakePaymentService paymentService;
  late FakeSubscriptionTruthRepository truthRepository;
  late SubscriptionStatusService subscriptionStatusService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    authService = FakeAuthService();
    entitlementService = EntitlementService();
    await entitlementService.init();
    paymentService = FakePaymentService();
    truthRepository = FakeSubscriptionTruthRepository();
    subscriptionStatusService = SubscriptionStatusService(
      paymentService: paymentService,
      entitlementService: entitlementService,
      truthRepository: truthRepository,
    );
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<SubscriptionStatusService>.value(
          value: subscriptionStatusService,
        ),
      ],
      child: const MaterialApp(
        home: SubscriptionLifecycleGate(child: SizedBox.shrink()),
      ),
    );
  }

  testWidgets('auth changes trigger subscription refresh', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(truthRepository.fetchCallCount, equals(0));

    authService.setLoggedIn('user_1');
    await tester.pump();
    await tester.pump();
    expect(truthRepository.fetchCallCount, equals(1));

    authService.setLoggedIn('user_1');
    await tester.pump();
    await tester.pump();
    expect(truthRepository.fetchCallCount, equals(1));

    authService.setGuest();
    await tester.pump();
    await tester.pump();
    expect(truthRepository.fetchCallCount, equals(2));
  });

  testWidgets('resume only refreshes subscription when stale', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(truthRepository.fetchCallCount, equals(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(truthRepository.fetchCallCount, equals(1));
  });
}
