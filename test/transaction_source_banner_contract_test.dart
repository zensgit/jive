import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/feature/transactions/transaction_entry_params.dart';
import 'package:jive/feature/transactions/widgets/transaction_source_banner.dart';

void main() {
  group('TransactionSourceBanner contracts', () {
    testWidgets('hides banner for manual and edit sources', (tester) async {
      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(source: TransactionEntrySource.manual),
        ),
      );

      expect(find.text('来自快速动作'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);

      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(source: TransactionEntrySource.edit),
        ),
      );

      expect(find.text('编辑交易'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('shows explicit quick action source banner', (tester) async {
      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(
            source: TransactionEntrySource.quickAction,
            sourceLabel: '来自快速动作「午餐」',
          ),
        ),
      );

      expect(find.text('来自快速动作「午餐」'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('shows default external entry source banners', (tester) async {
      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(source: TransactionEntrySource.deepLink),
        ),
      );

      expect(find.text('来自外部链接'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);

      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(
            source: TransactionEntrySource.shareReceive,
          ),
        ),
      );

      expect(find.text('来自分享接收'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('shows recognition source banners', (tester) async {
      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(source: TransactionEntrySource.voice),
        ),
      );

      expect(find.text('来自语音输入'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.pumpWidget(
        _buildBanner(
          const TransactionEntryParams(
            source: TransactionEntrySource.ocrScreenshot,
          ),
        ),
      );

      expect(find.text('来自截图识别'), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
    });
  });
}

Widget _buildBanner(TransactionEntryParams params) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TransactionSourceBanner(params: params),
      ),
    ),
  );
}
