import 'package:flutter/material.dart';

import '../../core/auth/auth_state.dart';
import '../../core/design_system/theme.dart';

/// Placeholder login/register screen.
///
/// Currently shows available auth methods as disabled buttons.
/// Will be wired to real auth providers in Phase S3.
class AuthScreen extends StatelessWidget {
  final VoidCallback onSkip;

  const AuthScreen({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.spa,
                size: 72,
                color: JiveTheme.primaryGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Jive 积叶',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '轻松记账，积少成多',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              _AuthMethodButton(
                icon: Icons.phone_android,
                label: '手机号登录',
                provider: AuthProvider.phone,
              ),
              const SizedBox(height: 12),
              _AuthMethodButton(
                icon: Icons.email_outlined,
                label: '邮箱登录',
                provider: AuthProvider.email,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AuthMethodButton(
                      icon: Icons.chat_bubble_outline,
                      label: '微信',
                      provider: AuthProvider.wechat,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AuthMethodButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      provider: AuthProvider.google,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AuthMethodButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      provider: AuthProvider.apple,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  '跳过，以游客身份使用',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final AuthProvider provider;
  final bool compact;

  const _AuthMethodButton({
    required this.icon,
    required this.label,
    required this.provider,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // All buttons disabled until real auth providers are connected.
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 12 : 14,
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icon, size: compact ? 18 : 20),
          SizedBox(width: compact ? 4 : 8),
          Text(label, style: TextStyle(fontSize: compact ? 13 : 15)),
        ],
      ),
    );
  }
}
