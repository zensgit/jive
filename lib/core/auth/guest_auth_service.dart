import 'auth_service.dart';
import 'auth_state.dart';

/// Auth service for local-only / guest mode.
///
/// This is the default implementation. All auth operations are no-ops
/// that return guest state, preserving the current app behavior exactly.
/// Replace with a real auth service when backend is ready.
class GuestAuthService extends AuthService {
  AuthState _state = const AuthGuest();

  @override
  AuthState get state => _state;

  @override
  Future<void> init() async {
    // No session to restore in guest mode.
    _state = const AuthGuest();
    notifyListeners();
  }

  @override
  Future<AuthState> signInWithEmail(String email, String password) async {
    // Guest mode does not support email sign-in.
    return _state;
  }

  @override
  Future<AuthState> signInWithPhone(String phone, String code) async {
    return _state;
  }

  @override
  Future<void> requestSmsCode(String phone) async {
    // No-op in guest mode.
  }

  @override
  Future<AuthState> signInWithProvider(AuthProvider provider) async {
    return _state;
  }

  @override
  Future<AuthState> registerWithEmail(String email, String password) async {
    return _state;
  }

  @override
  Future<void> signOut() async {
    _state = const AuthGuest();
    notifyListeners();
  }

  @override
  Future<void> deleteAccount() async {
    // Nothing to delete in guest mode.
  }
}
