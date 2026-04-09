import 'package:flutter/foundation.dart';

import 'auth_state.dart';

/// Abstract authentication service.
///
/// Concrete implementations:
///  - [GuestAuthService]: local-only, no real auth (current default)
///  - Future: SupabaseAuthService, FirebaseAuthService, etc.
abstract class AuthService extends ChangeNotifier {
  /// Current authentication state.
  AuthState get state;

  /// Convenience getters.
  bool get isGuest => state is AuthGuest;
  bool get isLoggedIn => state is AuthLoggedIn;
  bool get isLoading => state is AuthLoading;

  /// The current user, or null if not logged in.
  AuthUser? get currentUser {
    final s = state;
    return s is AuthLoggedIn ? s.user : null;
  }

  /// Initialize the service (check persisted session, refresh token, etc.).
  Future<void> init();

  /// Sign in with email + password.
  Future<AuthState> signInWithEmail(String email, String password);

  /// Sign in with phone + SMS verification code.
  Future<AuthState> signInWithPhone(String phone, String code);

  /// Request SMS verification code for [phone].
  Future<void> requestSmsCode(String phone);

  /// Sign in with a third-party provider.
  Future<AuthState> signInWithProvider(AuthProvider provider);

  /// Register a new account with email + password.
  Future<AuthState> registerWithEmail(String email, String password);

  /// Send a password reset email for [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out and return to guest state.
  Future<void> signOut();

  /// Delete the current account and all remote data.
  Future<void> deleteAccount();
}
