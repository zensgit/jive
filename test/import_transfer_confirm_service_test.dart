import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/service/import_service.dart';
import 'package:jive/core/service/import_transfer_confirm_service.dart';

void main() {
  const service = ImportTransferConfirmService();

  test('evaluate blocks missing target account and same-account transfer', () {
    final result = service.evaluate(
      records: [
        ImportParsedRecord(
          amount: 100,
          source: 'Import',
          timestamp: DateTime(2026, 3, 15, 9),
          rawText: '转账到储蓄卡',
          type: 'transfer',
          accountName: '微信',
          lineNumber: 1,
        ),
        ImportParsedRecord(
          amount: 88,
          source: 'Import',
          timestamp: DateTime(2026, 3, 15, 10),
          rawText: '微信零钱互转',
          type: 'transfer',
          accountName: '微信',
          toAccountName: '微信',
          lineNumber: 2,
        ),
      ],
      knownAccountNames: const ['微信', '招商银行'],
    );

    expect(result.transferCount, 2);
    expect(result.blockCount, 2);
    expect(result.reviewCount, 0);
    expect(result.readyCount, 0);
    expect(result.hasBlock, isTrue);
    expect(
      result.issues.map((issue) => issue.code),
      containsAll(['missing_target_account', 'same_account']),
    );
  });

  test('evaluate reviews unresolved accounts and high fee ratio', () {
    final result = service.evaluate(
      records: [
        ImportParsedRecord(
          amount: 50,
          source: 'Import',
          timestamp: DateTime(2026, 3, 15, 11),
          rawText: '从零钱转到储蓄卡',
          type: 'transfer',
          accountName: '微信零钱',
          toAccountName: '建设银行',
          serviceCharge: 50,
          lineNumber: 3,
        ),
      ],
      knownAccountNames: const ['微信', '招商银行'],
    );

    expect(result.transferCount, 1);
    expect(result.blockCount, 0);
    expect(result.reviewCount, 1);
    expect(result.readyCount, 0);
    expect(result.hasReview, isTrue);
    expect(
      result.issues.map((issue) => issue.code),
      containsAll([
        'unknown_source_account',
        'unknown_target_account',
        'high_service_charge',
      ]),
    );
  });

  test('evaluate keeps valid transfer rows ready', () {
    final result = service.evaluate(
      records: [
        ImportParsedRecord(
          amount: 188.8,
          source: 'Import',
          timestamp: DateTime(2026, 3, 15, 12),
          rawText: '转账到储蓄卡',
          type: 'transfer',
          accountName: '微信',
          toAccountName: '招商银行',
          serviceCharge: 1.5,
          lineNumber: 4,
        ),
      ],
      knownAccountNames: const ['微信', '招商银行'],
    );

    expect(result.transferCount, 1);
    expect(result.readyCount, 1);
    expect(result.reviewCount, 0);
    expect(result.blockCount, 0);
    expect(result.issues, isEmpty);
  });
}
