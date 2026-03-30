/// Represents the current authentication state.
sealed class AuthState {
  const AuthState();
}

/// No user session — app operates in local-only mode.
class AuthGuest extends AuthState {
  const AuthGuest();
}

/// User is authenticated.
class AuthLoggedIn extends AuthState {
  final AuthUser user;
  const AuthLoggedIn(this.user);
}

/// Authentication is in progress (e.g. verifying token on app start).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Minimal user profile returned by auth providers.
class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final AuthProvider provider;

  const AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.provider,
  });
}

/// Supported authentication providers.
enum AuthProvider {
  guest,
  email,
  phone,
  wechat,
  google,
  apple;

  String get label {
    switch (this) {
      case guest:
        return '游客';
      case email:
        return '邮箱';
      case phone:
        return '手机号';
      case wechat:
        return '微信';
      case google:
        return 'Google';
      case apple:
        return 'Apple';
    }
  }
}
