import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'entitlement_service.dart';
import 'feature_gate.dart';
import 'feature_id.dart';

/// A ListTile that checks entitlement before executing [onTap].
///
/// If the user lacks access, tapping shows the upgrade prompt instead.
/// A small lock icon is appended to the trailing position when locked.
class GatedListTile extends StatelessWidget {
  final FeatureId feature;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  const GatedListTile({
    super.key,
    required this.feature,
    this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<EntitlementService>();
    final hasAccess = entitlement.canAccess(feature);

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: hasAccess
          ? null
          : Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
      onTap: hasAccess
          ? onTap
          : () => showUpgradePrompt(context, feature),
    );
  }
}

/// A SwitchListTile that checks entitlement before allowing toggle.
///
/// When locked, the switch is disabled and tapping shows upgrade prompt.
class GatedSwitchListTile extends StatelessWidget {
  final FeatureId feature;
  final Widget? secondary;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const GatedSwitchListTile({
    super.key,
    required this.feature,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<EntitlementService>();
    final hasAccess = entitlement.canAccess(feature);

    if (hasAccess) {
      return SwitchListTile(
        secondary: secondary,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
      );
    }

    return ListTile(
      leading: secondary,
      title: title,
      subtitle: subtitle,
      trailing: Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
      onTap: () => showUpgradePrompt(context, feature),
    );
  }
}
