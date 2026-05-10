import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';
import 'package:jive/feature/transactions/widgets/transaction_footer_bar.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(setupGoogleFontsForTests);

  Widget wrapFooter({
    required TransactionEntrySource source,
    String transactionType = 'expense',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: TransactionFooterBar(
            source: source,
            onSave: () {},
            onSaveAndNew: () {},
            onToggleContinuous: () {},
            transactionType: transactionType,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'manual source keeps save, save-and-new, and continuous actions',
    (tester) async {
      await tester.pumpWidget(
        wrapFooter(source: TransactionEntrySource.manual),
      );

      expect(find.text('保存'), findsOneWidget);
      expect(find.text('保存并新建'), findsOneWidget);
      expect(find.text('连续记账'), findsOneWidget);
    },
  );

  testWidgets('external sources keep unified primary action labels', (
    tester,
  ) async {
    const sourceContracts = <TransactionEntrySource, String>{
      TransactionEntrySource.quickAction: '立即记录',
      TransactionEntrySource.voice: '确认入账',
      TransactionEntrySource.conversation: '确认入账',
      TransactionEntrySource.autoDraft: '确认入账',
      TransactionEntrySource.ocrScreenshot: '确认入账',
      TransactionEntrySource.shareReceive: '确认入账',
      TransactionEntrySource.deepLink: '确认入账',
    };

    for (final contract in sourceContracts.entries) {
      await tester.pumpWidget(wrapFooter(source: contract.key));

      expect(
        find.text(contract.value),
        findsOneWidget,
        reason: '${contract.key} should show ${contract.value}',
      );
      expect(find.text('保存并新建'), findsOneWidget);
      expect(find.text('连续记账'), findsOneWidget);
    }
  });

  testWidgets('edit source keeps save-modification action only', (
    tester,
  ) async {
    await tester.pumpWidget(wrapFooter(source: TransactionEntrySource.edit));

    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('保存并新建'), findsNothing);
    expect(find.text('连续记账'), findsNothing);
  });

  testWidgets('transaction type variants still render footer buttons', (
    tester,
  ) async {
    for (final transactionType in ['expense', 'income', 'transfer']) {
      await tester.pumpWidget(
        wrapFooter(
          source: TransactionEntrySource.manual,
          transactionType: transactionType,
        ),
      );

      expect(
        find.text('保存'),
        findsOneWidget,
        reason: '$transactionType should render primary save button',
      );
      expect(
        find.text('保存并新建'),
        findsOneWidget,
        reason: '$transactionType should render secondary save button',
      );
    }
  });
}
