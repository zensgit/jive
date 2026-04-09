import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/auth/auth_state.dart';
import 'package:jive/core/auth/guest_auth_service.dart';

void main() {
  group('AuthState', () {
    test('AuthGuest is sealed correctly', () {
      const state = AuthGuest();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthGuest>());
    });

    test('AuthLoggedIn carries user', () {
      const user = AuthUser(
        uid: 'test-123',
        displayName: 'Test',
        provider: AuthProvider.email,
      );
      const state = AuthLoggedIn(user);
      expect(state.user.uid, equals('test-123'));
      expect(state.user.provider, equals(AuthProvider.email));
    });

    test('AuthProvider labels are non-empty', () {
      for (final p in AuthProvider.values) {
        expect(p.label.isNotEmpty, isTrue);
      }
    });
  });

  group('GuestAuthService', () {
    late GuestAuthService service;

    setUp(() {
      service = GuestAuthService();
    });

    test('starts as guest', () {
      expect(service.state, isA<AuthGuest>());
      expect(service.isGuest, isTrue);
      expect(service.isLoggedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('init remains guest', () async {
      await service.init();
      expect(service.isGuest, isTrue);
    });

    test('signInWithEmail is no-op', () async {
      final result = await service.signInWithEmail('a@b.com', 'pass');
      expect(result, isA<AuthGuest>());
    });

    test('signInWithPhone is no-op', () async {
      final result = await service.signInWithPhone('+86123', '1234');
      expect(result, isA<AuthGuest>());
    });

    test('signInWithProvider is no-op', () async {
      final result = await service.signInWithProvider(AuthProvider.wechat);
      expect(result, isA<AuthGuest>());
    });

    test('registerWithEmail is no-op', () async {
      final result = await service.registerWithEmail('a@b.com', 'pass');
      expect(result, isA<AuthGuest>());
    });

    test('sendPasswordResetEmail is no-op', () async {
      await service.sendPasswordResetEmail('a@b.com');
      expect(service.isGuest, isTrue);
    });

    test('signOut stays guest', () async {
      await service.signOut();
      expect(service.isGuest, isTrue);
    });

    test('deleteAccount is no-op', () async {
      await service.deleteAccount();
      expect(service.isGuest, isTrue);
    });

    test('notifies on init', () async {
      var notified = false;
      service.addListener(() => notified = true);
      await service.init();
      expect(notified, isTrue);
    });
  });
}
