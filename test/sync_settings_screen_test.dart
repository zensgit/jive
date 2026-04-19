import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/auth/auth_service.dart';
import 'package:jive/core/auth/auth_state.dart';
import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/user_tier.dart';
import 'package:jive/core/sync/sync_conflict_service.dart';
import 'package:jive/core/sync/sync_engine.dart';
import 'package:jive/core/sync/sync_state.dart';
import 'package:jive/feature/settings/sync_settings_screen.dart';

class _FakeAuthService extends AuthService {
  AuthState _state = const AuthGuest();

  @override
  AuthState get state => _state;

  @override
  Future<void> init() async {}

  @override
  Future<AuthState> registerWithEmail(String email, String password) async =>
      state;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> requestSmsCode(String phone) async {}

  @override
  Future<void> signOut() async {
    _state = const AuthGuest();
    notifyListeners();
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

class _FakeSyncEngine extends ChangeNotifier implements SyncEngine {
  _FakeSyncEngine(this._state);

  final SyncState _state;

  @override
  SyncState get state => _state;

  @override
  SyncConflictService get conflictService => throw UnimplementedError();

  @override
  bool get isAvailable => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> refreshConflictCount() async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> sync() async {}

  @override
  void cancelPendingSync() {}

  @override
  void onAppResumed() {}

  @override
  void scheduleSync() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('subscriber without sync config sees prerequisite and disabled controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final entitlement = EntitlementService();
    await entitlement.init();
    await entitlement.setTier(UserTier.subscriber);
    final authService = _FakeAuthService();
    final syncEngine = _FakeSyncEngine(const SyncState.disabled());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<SyncEngine>.value(value: syncEngine),
        ],
        child: const MaterialApp(home: SyncSettingsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('当前构建未配置云同步'), findsOneWidget);
    expect(find.text('当前构建未配置同步服务'), findsNWidgets(2));
    expect(find.text('立即同步'), findsOneWidget);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.onChanged, isNull);
  });
}
