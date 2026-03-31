import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_service.dart';
import '../core/service/category_icon_style.dart';
import '../core/sync/sync_config.dart';
import '../feature/auth/auth_screen.dart';
import '../feature/home/main_screen.dart';
import '../feature/onboarding/onboarding_screen.dart';
import '../feature/security/lock_gate.dart';
import '../feature/theme/theme_provider.dart';

class JiveApp extends StatelessWidget {
  const JiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ValueListenableBuilder<CategoryIconStyle>(
          valueListenable: CategoryIconStyleConfig.notifier,
          builder: (context, _, __) {
            return MaterialApp(
              title: 'Jive 积叶',
              debugShowCheckedModeBanner: false,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale == null) return supportedLocales.first;
                for (final supported in supportedLocales) {
                  if (supported.languageCode == locale.languageCode) {
                    return supported;
                  }
                }
                return supportedLocales.first;
              },
              home: const LockGate(child: _AppEntry()),
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
  bool? _onboardingComplete;
  bool _authSkipped = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final complete = await OnboardingScreen.isComplete();
    if (mounted) {
      setState(() => _onboardingComplete = complete);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboardingComplete == false) {
      return OnboardingScreen(onComplete: () {
        if (mounted) setState(() => _onboardingComplete = true);
      });
    }

    // If Supabase is configured, show auth gate
    if (SyncConfig.isConfigured && !_authSkipped) {
      final auth = context.watch<AuthService>();
      if (auth.isGuest) {
        return AuthScreen(
          onSkip: () {
            if (mounted) setState(() => _authSkipped = true);
          },
        );
      }
    }

    return const MainScreen();
  }
}
