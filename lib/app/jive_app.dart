import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_lifecycle_gate.dart';
import '../core/auth/auth_service.dart';
import '../core/l10n/app_localizations.dart';
import '../core/service/category_icon_style.dart';
import '../core/service/locale_service.dart';
import '../core/sync/sync_config.dart';
import '../feature/auth/auth_screen.dart';
import '../feature/home/main_screen.dart';
import '../core/service/onboarding_progress_service.dart';
import '../feature/onboarding/guided_setup_screen.dart';
import '../feature/onboarding/onboarding_screen.dart';
import '../feature/security/lock_gate.dart';
import '../feature/theme/theme_provider.dart';

class JiveApp extends StatelessWidget {
  const JiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleService>(
      builder: (context, themeProvider, localeService, _) {
        return ValueListenableBuilder<CategoryIconStyle>(
          valueListenable: CategoryIconStyleConfig.notifier,
          builder: (context, _, __) {
            return MaterialApp(
              title: 'Jive 积叶',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: localeService.currentLocale,
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: localeService.getSupportedLocales(),
              home: const SubscriptionLifecycleGate(
                child: LockGate(child: _AppEntry()),
              ),
            );
          },
        );
      },
    );
  }
}

/// 应用入口门控 — 引导页 → 登录页 → 首页
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  static const _prefKeyAuthSkipped = 'auth_skipped_as_guest';

  bool? _onboardingComplete;
  bool? _guidedSetupComplete;
  bool _authSkipped = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final onboarding = await OnboardingScreen.isComplete();
    final guided = await OnboardingProgressService.isGuidedSetupComplete();
    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getBool(_prefKeyAuthSkipped) ?? false;
    if (mounted) {
      setState(() {
        _onboardingComplete = onboarding;
        _guidedSetupComplete = guided;
        _authSkipped = skipped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboardingComplete == false) {
      return OnboardingScreen(
        onComplete: () {
          if (mounted) setState(() => _onboardingComplete = true);
        },
      );
    }
    if (_guidedSetupComplete == false) {
      return GuidedSetupScreen(
        onComplete: () {
          if (mounted) setState(() => _guidedSetupComplete = true);
        },
      );
    }

    // If Supabase is configured, show auth gate
    if (SyncConfig.isConfigured && !_authSkipped) {
      final auth = context.watch<AuthService>();
      if (auth.isGuest) {
        return AuthScreen(
          onSkip: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_prefKeyAuthSkipped, true);
            if (mounted) setState(() => _authSkipped = true);
          },
        );
      }
    }

    return const MainScreen();
  }
}
