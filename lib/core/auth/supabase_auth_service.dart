import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../sync/sync_config.dart';
import 'auth_service.dart';
import 'auth_state.dart' as app;

/// Supabase implementation of [AuthService].
///
/// Supports email/password and OTP (phone) sign-in.
/// OAuth providers (Google, Apple, WeChat) can be added later.
class SupabaseAuthService extends AuthService {
  app.AuthState _state = const app.AuthLoading();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  app.AuthState get state => _state;

  @override
  Future<void> init() async {
    if (!SyncConfig.isConfigured) {
      _state = const app.AuthGuest();
      notifyListeners();
      return;
    }

    try {
      await Supabase.initialize(
        url: SyncConfig.supabaseUrl,
        anonKey: SyncConfig.supabaseAnonKey,
      );
    } catch (e) {
      // Already initialized (hot restart) — ignore
      debugPrint('SupabaseAuthService: init (may already exist): $e');
    }

    // Listen to auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
      _syncState(data.session);
    });

    // Check current session
    _syncState(Supabase.instance.client.auth.currentSession);
  }

  void _syncState(Session? session) {
    if (session == null) {
      _state = const app.AuthGuest();
    } else {
      final user = session.user;
      _state = app.AuthLoggedIn(app.AuthUser(
        uid: user.id,
        displayName: user.userMetadata?['display_name'] as String?,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        provider: _mapProvider(user),
      ));
    }
    notifyListeners();
  }

  app.AuthProvider _mapProvider(User user) {
    final provider = user.appMetadata['provider'] as String?;
    switch (provider) {
      case 'email':
        return app.AuthProvider.email;
      case 'phone':
        return app.AuthProvider.phone;
      case 'google':
        return app.AuthProvider.google;
      case 'apple':
        return app.AuthProvider.apple;
      default:
        return app.AuthProvider.email;
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<app.AuthState> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return _state;
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: email sign-in failed: ${e.message}');
      return _state;
    }
  }

  @override
  Future<app.AuthState> registerWithEmail(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return _state;
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: email register failed: ${e.message}');
      return _state;
    }
  }

  @override
  Future<void> requestSmsCode(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: SMS request failed: ${e.message}');
    }
  }

  @override
  Future<app.AuthState> signInWithPhone(String phone, String code) async {
    try {
      await _client.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
      return _state;
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: phone sign-in failed: ${e.message}');
      return _state;
    }
  }

  @override
  Future<app.AuthState> signInWithProvider(app.AuthProvider provider) async {
    try {
      final oauthProvider = _toOAuthProvider(provider);
      if (oauthProvider == null) return _state;
      await _client.auth.signInWithOAuth(oauthProvider);
      return _state;
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: OAuth sign-in failed: ${e.message}');
      return _state;
    }
  }

  OAuthProvider? _toOAuthProvider(app.AuthProvider provider) {
    switch (provider) {
      case app.AuthProvider.google:
        return OAuthProvider.google;
      case app.AuthProvider.apple:
        return OAuthProvider.apple;
      default:
        return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      debugPrint('SupabaseAuth: sign-out failed: ${e.message}');
    }
    _state = const app.AuthGuest();
    notifyListeners();
  }

  @override
  Future<void> deleteAccount() async {
    // Supabase admin API required for account deletion.
    // For now, just sign out. Full deletion needs Edge Function.
    await signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
