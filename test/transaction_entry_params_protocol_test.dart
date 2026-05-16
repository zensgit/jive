import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/transaction_entry_params.dart';

void main() {
  group('TransactionEntryParams protocol', () {
    test('keeps the fixed highlight field contract', () {
      expect(
        const [
          TransactionHighlightField.amount,
          TransactionHighlightField.category,
          TransactionHighlightField.account,
          TransactionHighlightField.transferAccount,
          TransactionHighlightField.time,
          TransactionHighlightField.note,
          TransactionHighlightField.tags,
        ],
        [
          'amount',
          'category',
          'account',
          'transferAccount',
          'time',
          'note',
          'tags',
        ],
      );
    });

    test('source banners use explicit labels when provided', () {
      const cases = {
        TransactionEntrySource.quickAction: '来自快速动作「午餐」',
        TransactionEntrySource.voice: '来自语音「午餐 35」',
        TransactionEntrySource.ocrScreenshot: '来自截图识别「账单截图」',
        TransactionEntrySource.shareReceive: '来自系统分享',
        TransactionEntrySource.deepLink: '来自外部链接「Widget」',
      };

      for (final entry in cases.entries) {
        final params = TransactionEntryParams(
          source: entry.key,
          sourceLabel: entry.value,
        );

        expect(params.sourceBannerText, entry.value);
      }
    });

    test('manual and edit entries do not show source banners', () {
      const manual = TransactionEntryParams();
      const edit = TransactionEntryParams(source: TransactionEntrySource.edit);

      expect(manual.sourceBannerText, isNull);
      expect(edit.sourceBannerText, isNull);
    });

    test('submit labels preserve entry source intent', () {
      expect(const TransactionEntryParams().submitButtonLabel, '保存');
      expect(
        const TransactionEntryParams(
          source: TransactionEntrySource.quickAction,
        ).submitButtonLabel,
        '立即记录',
      );
      expect(
        const TransactionEntryParams(
          source: TransactionEntrySource.voice,
        ).submitButtonLabel,
        '确认入账',
      );
      expect(
        const TransactionEntryParams(
          source: TransactionEntrySource.edit,
        ).submitButtonLabel,
        '保存修改',
      );
    });

    test(
      'highlights missing transfer fields without dropping prefill data',
      () {
        final params = TransactionEntryParams(
          source: TransactionEntrySource.deepLink,
          prefillType: 'transfer',
          prefillAmount: 188,
          prefillAccountId: 1,
          prefillToAccountId: 2,
          prefillBookId: 3,
          prefillNote: '信用卡还款',
          prefillTagKeys: const ['tag_credit_card'],
          prefillRawText: '从微信零钱转到招商银行 188',
          prefillExchangeFee: 1.5,
          prefillExchangeFeeType: 'fixed',
          highlightFields: const [
            TransactionHighlightField.transferAccount,
            TransactionHighlightField.time,
            TransactionHighlightField.tags,
          ],
        );

        expect(
          params.shouldHighlight(TransactionHighlightField.amount),
          isFalse,
        );
        expect(
          params.shouldHighlight(TransactionHighlightField.transferAccount),
          isTrue,
        );
        expect(params.shouldHighlight(TransactionHighlightField.time), isTrue);
        expect(params.shouldHighlight(TransactionHighlightField.tags), isTrue);
        expect(params.prefillType, 'transfer');
        expect(params.prefillAccountId, 1);
        expect(params.prefillToAccountId, 2);
        expect(params.prefillBookId, 3);
        expect(params.prefillTagKeys, ['tag_credit_card']);
        expect(params.prefillExchangeFee, 1.5);
        expect(params.prefillExchangeFeeType, 'fixed');
      },
    );

    test(
      'copyWith overrides protocol fields while preserving unspecified data',
      () {
        final original = TransactionEntryParams(
          source: TransactionEntrySource.shareReceive,
          sourceLabel: '来自系统分享',
          prefillAmount: 35,
          prefillType: 'expense',
          prefillAccountId: 8,
          prefillNote: '午餐',
          highlightFields: const [TransactionHighlightField.category],
        );

        final updated = original.copyWith(
          source: TransactionEntrySource.quickAction,
          quickActionId: 'template:42',
          highlightFields: const [
            TransactionHighlightField.amount,
            TransactionHighlightField.account,
          ],
        );

        expect(updated.source, TransactionEntrySource.quickAction);
        expect(updated.sourceLabel, '来自系统分享');
        expect(updated.quickActionId, 'template:42');
        expect(updated.prefillAmount, 35);
        expect(updated.prefillType, 'expense');
        expect(updated.prefillAccountId, 8);
        expect(updated.prefillNote, '午餐');
        expect(
          updated.shouldHighlight(TransactionHighlightField.category),
          isFalse,
        );
        expect(
          updated.shouldHighlight(TransactionHighlightField.amount),
          isTrue,
        );
        expect(
          updated.shouldHighlight(TransactionHighlightField.account),
          isTrue,
        );
      },
    );
  });
}
