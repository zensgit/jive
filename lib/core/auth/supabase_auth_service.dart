import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../sync/sync_config.dart';
import 'auth_service.dart';
import 'auth_state.dart' as app;

class EmailAuthFlowException implements Exception {
  const EmailAuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmailConfirmationRequiredException extends EmailAuthFlowException {
  const EmailConfirmationRequiredException(super.message);
}

class OAuthAuthFlowException implements Exception {
  const OAuthAuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Supabase implementation of [AuthService].
///
/// Supports email/password, OTP (phone), and OAuth sign-in.
class SupabaseAuthService extends AuthService {
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9-]{2,}(\.[a-zA-Z0-9-]{2,})*\.[a-zA-Z]{2,}$',
  );

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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
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
      _state = app.AuthLoggedIn(
        app.AuthUser(
          uid: user.id,
          displayName: user.userMetadata?['display_name'] as String?,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
          provider: _mapProvider(user),
        ),
      );
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
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      if (response.session == null) {
        throw const EmailAuthFlowException('登录未完成，请稍后重试');
      }
      _syncState(response.session);
      return _state;
    } on AuthWeakPasswordException catch (e) {
      final message = e.reasons.isEmpty
          ? '密码强度不足，请更换更安全的密码'
          : '密码强度不足：${e.reasons.join('；')}';
      if (kDebugMode) debugPrint('SupabaseAuth: email sign-in weak password');
      throw EmailAuthFlowException(message);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: email sign-in failed (${e.statusCode})');
      }
      throw EmailAuthFlowException(_mapEmailAuthError(e, isLogin: true));
    }
  }

  @override
  Future<app.AuthState> registerWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      if (response.session != null) {
        _syncState(response.session);
        return _state;
      }
      if (response.user != null) {
        throw const EmailConfirmationRequiredException(
          '注册成功，请先前往邮箱完成验证，再使用邮箱密码登录',
        );
      }
      throw const EmailAuthFlowException('注册未完成，请稍后重试');
    } on AuthWeakPasswordException catch (e) {
      final message = e.reasons.isEmpty
          ? '密码强度不足，请更换更安全的密码'
          : '密码强度不足：${e.reasons.join('；')}';
      if (kDebugMode) debugPrint('SupabaseAuth: email register weak password');
      throw EmailAuthFlowException(message);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: email register failed (${e.statusCode})');
      }
      throw EmailAuthFlowException(_mapEmailAuthError(e, isLogin: false));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const EmailAuthFlowException('请输入邮箱地址');
    }
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      throw const EmailAuthFlowException('请输入有效的邮箱地址');
    }

    try {
      await _client.auth.resetPasswordForEmail(normalizedEmail);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: password reset failed (${e.statusCode})');
      }
      throw EmailAuthFlowException(_mapPasswordResetError(e));
    }
  }

  @override
  Future<void> requestSmsCode(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: SMS request failed (${e.statusCode})');
      }
      throw EmailAuthFlowException(_mapSmsOtpError(e));
    }
  }

  @override
  Future<app.AuthState> signInWithPhone(String phone, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
      final session = response.session;
      if (session == null) {
        throw const EmailAuthFlowException('验证码验证失败，请稍后重试');
      }
      _syncState(session);
      return _state;
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: phone sign-in failed (${e.statusCode})');
      }
      throw EmailAuthFlowException(_mapPhoneOtpError(e));
    }
  }

  @override
  Future<app.AuthState> signInWithProvider(app.AuthProvider provider) async {
    final oauthProvider = _toOAuthProvider(provider);
    if (oauthProvider == null) {
      throw OAuthAuthFlowException('${provider.label} 登录暂未开放');
    }

    try {
      final launched = await _client.auth.signInWithOAuth(oauthProvider);
      if (!launched) {
        throw OAuthAuthFlowException('无法打开 ${provider.label} 登录页面，请稍后重试');
      }
      return _state;
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('SupabaseAuth: OAuth sign-in failed (${e.statusCode})');
      }
      throw OAuthAuthFlowException(_mapOAuthError(e, provider: provider));
    } on PlatformException {
      if (kDebugMode) debugPrint('SupabaseAuth: OAuth launch failed');
      throw OAuthAuthFlowException('无法打开 ${provider.label} 登录页面，请检查系统浏览器后重试');
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
      if (kDebugMode) {
        debugPrint('SupabaseAuth: sign-out failed (${e.statusCode})');
      }
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

  String _mapEmailAuthError(AuthException error, {required bool isLogin}) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return '邮箱尚未验证，请先前往邮件完成验证';
    }
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return '邮箱或密码错误';
    }
    if (code == 'user_already_exists' ||
        message.contains('user already registered') ||
        message.contains('already been registered')) {
      return '该邮箱已注册，请直接登录';
    }
    if (message.contains('password should be at least') ||
        message.contains('password must be at least')) {
      return '密码至少 6 位';
    }
    if (message.contains('email address') && message.contains('invalid')) {
      return '邮箱格式不正确';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return '网络异常，请稍后重试';
    }

    return '${isLogin ? '登录失败' : '注册失败'}：${error.message}';
  }

  String _mapOAuthError(
    AuthException error, {
    required app.AuthProvider provider,
  }) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();

    if (message.contains('provider is not enabled') ||
        message.contains('unsupported provider') ||
        (code == 'validation_failed' && message.contains('provider'))) {
      return '${provider.label} 登录暂未配置完成';
    }
    if (message.contains('redirect') && message.contains('not allowed')) {
      return '${provider.label} 登录回调地址未配置完成';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return '网络异常，请稍后重试';
    }

    return '${provider.label} 登录失败：${error.message}';
  }

  String _mapPasswordResetError(AuthException error) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();

    if (code == 'user_not_found' || message.contains('user not found')) {
      return '未找到该邮箱对应的账号';
    }
    if (message.contains('email') && message.contains('invalid')) {
      return '邮箱格式不正确';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return '网络异常，请稍后重试';
    }

    return '发送重置邮件失败：${error.message}';
  }

  String _mapSmsOtpError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return '网络异常，请稍后重试';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return '请求过于频繁，请稍后再试';
    }

    return '验证码发送失败，请稍后重试';
  }

  String _mapPhoneOtpError(AuthException error) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();

    if (code == 'otp_expired' ||
        message.contains('expired') ||
        message.contains('invalid otp')) {
      return '验证码已过期或无效，请重新获取';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return '网络异常，请稍后重试';
    }

    return '验证码验证失败，请稍后重试';
  }
}
