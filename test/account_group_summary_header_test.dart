import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/account_group_service.dart';
import 'package:jive/feature/accounts/widgets/account_group_summary_header.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(setupGoogleFontsForTests);

  testWidgets('renders account group subaccount contract', (tester) async {
    final group = AccountGroupSummary(
      name: '中国银行',
      accounts: [
        _account(id: 1, name: '活期', currency: 'CNY'),
        _account(id: 2, name: '美元户', currency: 'USD'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountGroupSummaryHeader(group: group)),
      ),
    );

    expect(find.text('中国银行'), findsOneWidget);
    expect(find.text('2 个子账户 · CNY / USD'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
  });
}

JiveAccount _account({
  required int id,
  required String name,
  required String currency,
}) {
  return JiveAccount()
    ..id = id
    ..key = 'account_$id'
    ..name = name
    ..type = 'asset'
    ..currency = currency
    ..iconName = 'wallet'
    ..order = id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..updatedAt = DateTime(2026);
}
