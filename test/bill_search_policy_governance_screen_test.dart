import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/settings/bill_search_policy_governance_screen.dart';

void main() {
  testWidgets('renders controls and evaluates bill search governance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: BillSearchPolicyGovernanceScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('账单搜索策略治理中心'), findsOneWidget);

    await tester.tap(find.text('评估账单搜索策略治理'));
    await tester.pumpAndSettle();
    expect(find.textContaining('status:'), findsOneWidget);

    expect(find.text('复制JSON'), findsOneWidget);
    expect(find.text('复制MD'), findsOneWidget);
    expect(find.text('复制CSV'), findsOneWidget);
  });
}
