import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/guest_auth_service.dart';
import '../../core/auth/supabase_auth_service.dart';
import '../../core/design_system/theme.dart';

enum _AuthMode { email, phone }

/// Login / register screen.
///
/// Supports email sign-in/register, optional phone OTP, optional third-party OAuth, and guest skip.
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
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9\s-]{5,}$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  _AuthMode _authMode = _AuthMode.email;
  bool _isLogin = true;
  bool _smsRequested = false;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _switchAuthMode(_AuthMode mode) {
    if (_loading || _authMode == mode) return;
    setState(() {
      _authMode = mode;
      _error = null;
      _notice = null;
      _smsRequested = false;
      _smsCodeController.clear();
    });
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
        _notice = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isLogin ? '登录失败，请稍后重试' : '注册失败，请稍后重试';
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = '请输入邮箱后再发送重置邮件');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = '请输入有效的邮箱地址');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    final auth = context.read<AuthService>();
    try {
      await auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notice = '重置邮件已发送，请查收邮箱并按邮件提示操作';
      });
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
        _error = '发送重置邮件失败，请稍后重试';
      });
    }
  }

  Future<void> _handlePhoneAuth() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthService>();
    if (auth is GuestAuthService) {
      setState(() {
        _error = '当前环境未配置手机号登录';
        _notice = null;
      });
      return;
    }

    final phone = _phoneController.text.trim();
    if (!_phonePattern.hasMatch(phone)) {
      setState(() {
        _error = '请输入有效的手机号';
        _notice = null;
      });
      return;
    }

    if (!_smsRequested) {
      setState(() {
        _loading = true;
        _error = null;
        _notice = null;
      });

      try {
        await auth.requestSmsCode(phone);
        if (!mounted) return;
        setState(() {
          _loading = false;
          _smsRequested = true;
          _notice = '验证码已发送，请查收短信';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '验证码发送失败，请稍后重试';
          _notice = null;
        });
      }
      return;
    }

    final code = _smsCodeController.text.trim();
    if (code.length < 4) {
      setState(() {
        _error = '请输入短信验证码';
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
      final result = await auth.signInWithPhone(phone, code);
      if (!mounted) return;

      final loggedIn = result is AuthLoggedIn;
      setState(() {
        _loading = false;
        if (!loggedIn) {
          _error = '验证码登录未完成，请检查验证码后重试';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '手机号登录失败，请稍后重试';
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

  Future<void> _handleProviderSignIn(AuthProvider provider) async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthService>();
    if (auth is GuestAuthService) {
      setState(() {
        _error = '当前环境未配置 ${provider.label} 登录';
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
      final result = await auth.signInWithProvider(provider);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _notice = result is AuthLoggedIn
            ? null
            : '已打开 ${provider.label} 登录，请完成授权后返回应用';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '${provider.label} 登录失败，请稍后重试';
        _notice = null;
      });
    }
  }

  Widget _buildModeButton({required _AuthMode mode, required String label}) {
    final selected = _authMode == mode;
    final style = selected
        ? FilledButton.styleFrom(
            backgroundColor: JiveTheme.primaryGreen,
            foregroundColor: Colors.white,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(color: Theme.of(context).dividerColor),
          );

    final child = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (selected) {
      return SizedBox(
        height: 44,
        child: FilledButton(
          onPressed: () => _switchAuthMode(mode),
          style: style,
          child: child,
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () => _switchAuthMode(mode),
        style: style,
        child: child,
      ),
    );
  }

  Widget _buildMessageBlock() {
    if (_error == null && _notice == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          if (_notice != null)
            Padding(
              padding: EdgeInsets.only(top: _error == null ? 0 : 6),
              child: Text(
                _notice!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final label = switch (_authMode) {
      _AuthMode.email => _isLogin ? '登录' : '注册',
      _AuthMode.phone => _smsRequested ? '验证码登录' : '发送验证码',
    };
    final handler = switch (_authMode) {
      _AuthMode.email => _handleEmailAuth,
      _AuthMode.phone => _handlePhoneAuth,
    };

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : handler,
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
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildProviderButton({
    required AuthProvider provider,
    required Widget icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : () => _handleProviderSignIn(provider),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        icon: icon,
        label: Text(
          '使用 ${provider.label} 登录',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
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
                '邮箱登录可用于云端同步；手机号和第三方登录仅在对应能力已配置时可用。游客模式仅保留本机数据。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      mode: _AuthMode.email,
                      label: '邮箱登录',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeButton(
                      mode: _AuthMode.phone,
                      label: '手机号登录',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_authMode == _AuthMode.email) ...[
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
              ] else ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  textInputAction: _smsRequested
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '手机号',
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_smsRequested) {
                      _handlePhoneAuth();
                    }
                  },
                ),
                if (_smsRequested) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsCodeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '验证码',
                      prefixIcon: const Icon(Icons.password_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _handlePhoneAuth(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _smsRequested = false;
                                _error = null;
                                _notice = null;
                                _smsCodeController.clear();
                              });
                            },
                      child: const Text('重新发送验证码'),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              _buildMessageBlock(),
              _buildPrimaryButton(),
              const SizedBox(height: 12),

              if (_authMode == _AuthMode.email)
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

              if (_authMode == _AuthMode.email && _isLogin)
                TextButton(
                  onPressed: _loading ? null : _handlePasswordReset,
                  child: Text(
                    '忘记密码？发送重置邮件',
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

              _buildProviderButton(
                provider: AuthProvider.google,
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildProviderButton(
                provider: AuthProvider.apple,
                icon: const Icon(Icons.apple),
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
