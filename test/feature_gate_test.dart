import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jive/core/entitlement/entitlement_service.dart';
import 'package:jive/core/entitlement/feature_gate.dart';
import 'package:jive/core/entitlement/feature_id.dart';
import 'package:jive/core/entitlement/user_tier.dart';

Widget _buildApp({
  required EntitlementService service,
  required Widget child,
}) {
  return ChangeNotifierProvider<EntitlementService>.value(
    value: service,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeatureGate', () {
    testWidgets('shows child when user has access', (tester) async {
      SharedPreferences.setMockInitialValues({'user_tier': 'subscriber'});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.cloudSync,
          child: const Text('Cloud Feature'),
        ),
      ));

      expect(find.text('Cloud Feature'), findsOneWidget);
      expect(find.text('升级解锁'), findsNothing);
    });

    testWidgets('shows lock overlay when user lacks access', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.autoBookkeeping,
          child: const Text('Paid Feature'),
        ),
      ));

      expect(find.text('Paid Feature'), findsOneWidget);
      expect(find.text('升级解锁'), findsOneWidget);
    });

    testWidgets('hide mode renders nothing when locked', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.cloudSync,
          mode: FeatureGateMode.hide,
          child: const Text('Hidden Feature'),
        ),
      ));

      expect(find.text('Hidden Feature'), findsNothing);
    });

    testWidgets('replace mode shows placeholder', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.investmentTracking,
          mode: FeatureGateMode.replace,
          placeholder: const Text('Upgrade to unlock'),
          child: const Text('Investment'),
        ),
      ));

      expect(find.text('Investment'), findsNothing);
      expect(find.text('Upgrade to unlock'), findsOneWidget);
    });

    testWidgets('lock overlay tap shows upgrade prompt', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.autoBookkeeping,
          child: const SizedBox(width: 200, height: 100),
        ),
      ));

      await tester.tap(find.text('升级解锁'));
      await tester.pumpAndSettle();

      expect(find.text('此功能需要专业版'), findsOneWidget);
      expect(find.text('稍后再说'), findsOneWidget);
    });

    testWidgets('reacts to tier change', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = EntitlementService();
      await service.init();

      await tester.pumpWidget(_buildApp(
        service: service,
        child: FeatureGate(
          feature: FeatureId.autoBookkeeping,
          child: const Text('Auto Feature'),
        ),
      ));

      // Initially locked
      expect(find.text('升级解锁'), findsOneWidget);

      // Upgrade to paid
      await service.setTier(UserTier.paid);
      await tester.pump();

      // Now unlocked
      expect(find.text('升级解锁'), findsNothing);
      expect(find.text('Auto Feature'), findsOneWidget);
    });
  });
}
