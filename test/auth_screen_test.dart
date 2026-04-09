import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jive/core/auth/auth_service.dart';
import 'package:jive/core/auth/auth_state.dart';
import 'package:jive/core/auth/supabase_auth_service.dart';
import 'package:jive/feature/auth/auth_screen.dart';

class FakeAuthService extends AuthService {
  AuthState _state = const AuthGuest();

  String? lastSmsPhone;
  String? lastPhoneSignInPhone;
  String? lastPhoneSignInCode;
  String? lastPasswordResetEmail;
  AuthProvider? lastProvider;
  int smsRequestCount = 0;
  bool phoneSignInSucceeds = false;
  Exception? signInWithEmailException;
  Exception? registerWithEmailException;

  @override
  AuthState get state => _state;

  @override
  Future<void> init() async {}

  @override
  Future<AuthState> registerWithEmail(String email, String password) async {
    if (registerWithEmailException != null) {
      throw registerWithEmailException!;
    }
    return _state;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> requestSmsCode(String phone) async {
    smsRequestCount += 1;
    lastSmsPhone = phone;
  }

  @override
  Future<void> signOut() async {
    _state = const AuthGuest();
    notifyListeners();
  }

  @override
  Future<AuthState> signInWithEmail(String email, String password) async {
    if (signInWithEmailException != null) {
      throw signInWithEmailException!;
    }
    return _state;
  }

  @override
  Future<AuthState> signInWithPhone(String phone, String code) async {
    lastPhoneSignInPhone = phone;
    lastPhoneSignInCode = code;
    if (phoneSignInSucceeds) {
      _state = const AuthLoggedIn(
        AuthUser(
          uid: 'user_1',
          provider: AuthProvider.phone,
          phone: '13800138000',
        ),
      );
      notifyListeners();
    }
    return _state;
  }

  @override
  Future<AuthState> signInWithProvider(AuthProvider provider) async {
    lastProvider = provider;
    return _state;
  }

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  Widget buildScreen(FakeAuthService auth) {
    return ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: MaterialApp(home: AuthScreen(onSkip: () {})),
    );
  }

  testWidgets('phone auth requests SMS code and submits verification code', (
    tester,
  ) async {
    final auth = FakeAuthService()..phoneSignInSucceeds = true;

    await tester.pumpWidget(buildScreen(auth));
    await tester.tap(find.text('手机号登录'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '13800138000');
    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(auth.smsRequestCount, 1);
    expect(auth.lastSmsPhone, '13800138000');
    expect(find.text('验证码已发送，请查收短信'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('验证码登录'));
    await tester.pumpAndSettle();

    expect(auth.lastPhoneSignInPhone, '13800138000');
    expect(auth.lastPhoneSignInCode, '123456');
    expect(auth.isLoggedIn, isTrue);
  });

  testWidgets('email auth can request password reset', (tester) async {
    final auth = FakeAuthService();

    await tester.pumpWidget(buildScreen(auth));
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    final resetButton = find.text('忘记密码？发送重置邮件');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(auth.lastPasswordResetEmail, 'user@example.com');
    expect(find.text('重置邮件已发送，请查收邮箱并按邮件提示操作'), findsOneWidget);
  });

  testWidgets('email auth shows specific EmailAuthFlowException message', (
    tester,
  ) async {
    final auth = FakeAuthService()
      ..signInWithEmailException = const EmailAuthFlowException('邮箱或密码错误');

    await tester.pumpWidget(buildScreen(auth));
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('邮箱或密码错误'), findsOneWidget);
  });

  testWidgets(
    'email registration shows confirmation notice and switches back to login',
    (tester) async {
      final auth = FakeAuthService()
        ..registerWithEmailException = const EmailConfirmationRequiredException(
          '注册成功，请先前往邮箱完成验证，再使用邮箱密码登录',
        );

      await tester.pumpWidget(buildScreen(auth));
      await tester.tap(find.text('没有账号？注册'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      expect(find.text('注册成功，请先前往邮箱完成验证，再使用邮箱密码登录'), findsOneWidget);
      expect(find.text('登录'), findsOneWidget);
      expect(find.text('没有账号？注册'), findsOneWidget);
    },
  );

  testWidgets('apple sign-in button calls provider auth', (tester) async {
    final auth = FakeAuthService();

    await tester.pumpWidget(buildScreen(auth));
    final appleButton = find.text('使用 Apple 登录');
    await tester.ensureVisible(appleButton);
    await tester.tap(appleButton);
    await tester.pumpAndSettle();

    expect(auth.lastProvider, AuthProvider.apple);
  });
}
