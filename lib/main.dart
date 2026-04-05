import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app/jive_app.dart';
import 'core/ads/ad_service.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/guest_auth_service.dart';
import 'core/auth/supabase_auth_service.dart';
import 'core/entitlement/entitlement_service.dart';
import 'core/sync/sync_config.dart';
import 'core/payment/payment_service.dart';
import 'core/payment/subscription_status_service.dart';
import 'core/payment/supabase_subscription_truth_repository.dart';
import 'core/service/database_service.dart';
import 'core/sync/sync_engine.dart';
import 'core/payment/play_store_payment_service.dart';
import 'core/service/category_icon_style.dart';
import 'core/utils/logger_util.dart';
import 'core/service/locale_service.dart';
import 'feature/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await JiveLogger.init();
  final iconStyle = await CategoryIconStyleStore.load();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  final localeService = LocaleService();
  await localeService.init();
  CategoryIconStyleConfig.current = iconStyle;

  // Auth: use Supabase when configured, otherwise guest mode
  final AuthService authService = SyncConfig.isConfigured
      ? SupabaseAuthService()
      : GuestAuthService();
  await authService.init();
  final entitlementService = EntitlementService();
  await entitlementService.init();
  final subscriptionTruthRepository = SyncConfig.isConfigured
      ? SupabaseSubscriptionTruthRepository()
      : null;

  // Payment service
  final paymentService = PlayStorePaymentService(
    entitlement: entitlementService,
    truthRepository: subscriptionTruthRepository,
  );
  await paymentService.init();

  final subscriptionStatusService = SubscriptionStatusService(
    paymentService: paymentService,
    entitlementService: entitlementService,
    truthRepository: subscriptionTruthRepository,
  );
  await subscriptionStatusService.checkAndSync();

  // Ad service
  final adService = AdService(entitlementService);
  await adService.init();

  // SyncEngine — init deferred until screen opens
  final isar = await DatabaseService.getInstance();
  final syncEngine = SyncEngine(isar: isar, entitlement: entitlementService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<EntitlementService>.value(
          value: entitlementService,
        ),
        ChangeNotifierProvider<PaymentService>.value(value: paymentService),
        Provider<SubscriptionStatusService>.value(
          value: subscriptionStatusService,
        ),
        ChangeNotifierProvider<AdService>.value(value: adService),
        ChangeNotifierProvider<SyncEngine>.value(value: syncEngine),
        ChangeNotifierProvider<LocaleService>.value(value: localeService),
      ],
      child: const JiveApp(),
    ),
  );
}
