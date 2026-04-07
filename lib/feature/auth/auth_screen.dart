import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/supabase_auth_service.dart';
import '../../core/design_system/theme.dart';

/// Login / register screen.
///
/// Supports email sign-in/register, Google OAuth, and guest skip.
class AuthScreen extends StatefulWidget {
  final VoidCallback onSkip;

  const AuthScreen({super.key, required this.onSkip});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // RFC 5322 simplified: local part 1-64 chars, domain with at least one dot,
  // each domain label 2+ chars, TLD 2+ alpha chars (rejects a@b.c style invalid emails).
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9-]{2,}(\.[a-zA-Z0-9-]{2,})*\.[a-zA-Z]{2,}$',
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = '请输入有效的邮箱地址');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    final auth = context.read<AuthService>();
    try {
      final result = _isLogin
          ? await auth.signInWithEmail(email, password)
          : await auth.registerWithEmail(email, password);

      if (!mounted) return;
      setState(() => _loading = false);

      if (result is AuthLoggedIn) {
        return;
      }

      setState(() {
        _error = _isLogin ? '登录未完成，请稍后重试' : '注册未完成，请稍后重试';
      });
    } on EmailConfirmationRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isLogin = true;
        _error = null;
        _notice = e.message;
      });
      _passwordController.clear();
    } on EmailAuthFlowException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isLogin ? '登录失败，请稍后重试' : '注册失败，请稍后重试';
      });
    }
  }

  Future<void> _handleGuestMode() async {
    if (_loading) return;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('以游客身份继续'),
          content: const Text('游客模式仅保存在当前设备，不会同步到云端，也无法多设备共享。确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('继续登录'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('进入游客模式'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true) {
      widget.onSkip();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthService>();
    if (auth is! SupabaseAuthService) {
      setState(() {
        _error = '当前环境未配置 Google 登录';
        _notice = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    try {
      final result = await auth.signInWithProvider(AuthProvider.google);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _notice = result is AuthLoggedIn ? null : '已打开 Google 登录，请完成授权后返回应用';
      });
    } on OAuthAuthFlowException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _notice = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Google 登录失败，请稍后重试';
        _notice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Icon(Icons.spa, size: 72, color: JiveTheme.primaryGreen),
              const SizedBox(height: 16),
              const Text(
                'Jive 积叶',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '轻松记账，积少成多',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '使用邮箱或 Google 登录后可同步云端数据；游客模式仅保留本机数据。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _handleEmailAuth(),
              ),
              const SizedBox(height: 8),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _notice!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Login / Register button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _handleEmailAuth,
                  style: FilledButton.styleFrom(
                    backgroundColor: JiveTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? '登录' : '注册',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle login/register
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                        _notice = null;
                      }),
                child: Text(
                  _isLogin ? '没有账号？注册' : '已有账号？登录',
                  style: TextStyle(color: JiveTheme.primaryGreen),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '或',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  label: const Text(
                    '使用 Google 登录',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: _loading ? null : _handleGuestMode,
                child: Text(
                  '跳过，以游客身份使用',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
