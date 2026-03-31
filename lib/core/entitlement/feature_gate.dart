import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system/theme.dart';
import '../../feature/subscription/subscription_screen.dart';
import 'entitlement_service.dart';
import 'feature_id.dart';
import 'feature_registry.dart';
import 'user_tier.dart';

/// Widget that conditionally shows its [child] based on the current user tier.
///
/// If the user has access to [feature], [child] is rendered normally.
/// Otherwise, one of the following behaviors applies (based on [mode]):
///  - [FeatureGateMode.hide]: renders nothing (or [placeholder] if provided)
///  - [FeatureGateMode.lock]: renders [child] with a lock overlay + upgrade tap
///  - [FeatureGateMode.replace]: renders [placeholder] (required in this mode)
class FeatureGate extends StatelessWidget {
  final FeatureId feature;
  final Widget child;
  final FeatureGateMode mode;
  final Widget? placeholder;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.mode = FeatureGateMode.lock,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<EntitlementService>();
    if (entitlement.canAccess(feature)) {
      return child;
    }

    switch (mode) {
      case FeatureGateMode.hide:
        return placeholder ?? const SizedBox.shrink();
      case FeatureGateMode.replace:
        return placeholder ?? const SizedBox.shrink();
      case FeatureGateMode.lock:
        return _LockedOverlay(
          feature: feature,
          child: child,
        );
    }
  }
}

enum FeatureGateMode {
  /// Don't render anything (or render [placeholder]).
  hide,

  /// Show the child with a lock overlay; tapping shows upgrade prompt.
  lock,

  /// Replace the child with [placeholder] entirely.
  replace,
}

class _LockedOverlay extends StatelessWidget {
  final FeatureId feature;
  final Widget child;

  const _LockedOverlay({
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showUpgradePrompt(context, feature),
      child: Stack(
        children: [
          Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '升级解锁',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows an upgrade prompt bottom sheet for the given [feature].
///
/// This is also callable directly (not only via FeatureGate) for cases
/// where you want to show the prompt programmatically.
void showUpgradePrompt(BuildContext context, FeatureId feature) {
  final requiredTier = FeatureRegistry.requiredTier(feature);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: JiveTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 32,
                color: JiveTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '此功能需要${requiredTier.label}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _upgradeDescription(requiredTier),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: JiveTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '了解${requiredTier.label}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后再说'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _upgradeDescription(UserTier tier) {
  switch (tier) {
    case UserTier.paid:
      return '升级到专业版即可解锁多币种、云同步、多设备登录等高级功能，且无广告打扰。';
    case UserTier.subscriber:
      return '订阅后可享受投资追踪、高级分析、语音记账等全部功能。';
    case UserTier.free:
      return '';
  }
}
