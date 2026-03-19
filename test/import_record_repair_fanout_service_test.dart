import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/import_record_repair_fanout_service.dart';
import 'package:jive/core/service/import_service.dart';

void main() {
  final service = ImportRecordRepairFanoutService();

  test('apply updates only target when no similar record matches', () {
    final records = [
      _record(
        lineNumber: 1,
        source: 'WeChat',
        rawText: '早餐',
        accountName: '微信',
      ),
      _record(
        lineNumber: 2,
        source: 'Alipay',
        rawText: '午餐',
        accountName: '支付宝',
      ),
    ];

    final result = service.apply(
      records: records,
      targetIndex: 0,
      baselineRecord: records.first,
      patchedRecord: records.first.copyWith(accountName: '银行卡'),
    );

    expect(result.affectedIndices, [0]);
    expect(result.updatedRecords[0].accountName, '银行卡');
    expect(result.updatedRecords[1].accountName, '支付宝');
  });

  test('apply fans out structured repair to similar rows', () {
    final records = [
      _record(
        lineNumber: 1,
        source: 'WeChat',
        rawText: '麦当劳早餐',
        accountName: '微信',
        parentCategoryName: '其他',
        childCategoryName: null,
      ),
      _record(
        lineNumber: 2,
        source: 'WeChat',
        rawText: '麦当劳早餐(重复)',
        accountName: '微信',
        parentCategoryName: '其他',
        childCategoryName: null,
      ),
      _record(
        lineNumber: 3,
        source: 'WeChat',
        rawText: '晚餐',
        accountName: '微信',
        parentCategoryName: '其他',
      ),
    ];

    final patched = records.first.copyWith(
      accountName: '银行卡',
      parentCategoryName: '餐饮',
      childCategoryName: '早餐',
      tagNames: ['快餐', '工作日'],
    );
    final result = service.apply(
      records: records,
      targetIndex: 0,
      baselineRecord: records.first,
      patchedRecord: patched,
    );

    expect(result.affectedIndices, [0, 1]);
    expect(result.updatedRecords[1].accountName, '银行卡');
    expect(result.updatedRecords[1].parentCategoryName, '餐饮');
    expect(result.updatedRecords[1].childCategoryName, '早餐');
    expect(result.updatedRecords[1].tagNames, ['快餐', '工作日']);
    expect(result.updatedRecords[2].parentCategoryName, '其他');
  });

  test('apply does not cross source or type boundaries', () {
    final records = [
      _record(
        lineNumber: 1,
        source: 'WeChat',
        rawText: '转账给小明',
        type: 'expense',
      ),
      _record(
        lineNumber: 2,
        source: 'WeChat',
        rawText: '转账给小明',
        type: 'transfer',
      ),
      _record(
        lineNumber: 3,
        source: 'Alipay',
        rawText: '转账给小明',
        type: 'expense',
      ),
    ];

    final patched = records.first.copyWith(
      parentCategoryName: '转账',
      childCategoryName: '转账',
    );
    final result = service.apply(
      records: records,
      targetIndex: 0,
      baselineRecord: records.first,
      patchedRecord: patched,
    );

    expect(result.affectedIndices, [0]);
    expect(result.updatedRecords[1].parentCategoryName, isNull);
    expect(result.updatedRecords[2].parentCategoryName, isNull);
  });

  test('apply propagates parent and child category together', () {
    final records = [
      _record(
        lineNumber: 1,
        source: 'WeChat',
        rawText: '滴滴出行',
        parentCategoryName: null,
        childCategoryName: null,
      ),
      _record(
        lineNumber: 2,
        source: 'WeChat',
        rawText: '滴滴出行·订单2',
        parentCategoryName: null,
        childCategoryName: null,
      ),
    ];

    final patched = records.first.copyWith(
      parentCategoryName: '交通',
      childCategoryName: '打车',
    );
    final result = service.apply(
      records: records,
      targetIndex: 0,
      baselineRecord: records.first,
      patchedRecord: patched,
    );

    expect(result.updatedRecords[1].parentCategoryName, '交通');
    expect(result.updatedRecords[1].childCategoryName, '打车');
  });

  test('apply propagates transfer target account and service charge', () {
    final records = [
      _record(
        lineNumber: 1,
        source: 'Import',
        rawText: '转账到储蓄卡',
        type: 'transfer',
        accountName: '微信',
      ),
      _record(
        lineNumber: 2,
        source: 'Import',
        rawText: '转账到储蓄卡(重复)',
        type: 'transfer',
        accountName: '微信',
      ),
    ];

    final patched = records.first.copyWith(
      toAccountName: '招商银行',
      serviceCharge: 1.5,
    );
    final result = service.apply(
      records: records,
      targetIndex: 0,
      baselineRecord: records.first,
      patchedRecord: patched,
    );

    expect(result.updatedRecords[1].toAccountName, '招商银行');
    expect(result.updatedRecords[1].serviceCharge, 1.5);
  });
}

ImportParsedRecord _record({
  required int lineNumber,
  required String source,
  required String rawText,
  String? type = 'expense',
  String? accountName,
  String? parentCategoryName,
  String? childCategoryName,
}) {
  return ImportParsedRecord(
    amount: 18.8,
    source: source,
    timestamp: DateTime(2026, 3, 15, 9, lineNumber),
    rawText: rawText,
    type: type,
    accountName: accountName,
    parentCategoryName: parentCategoryName,
    childCategoryName: childCategoryName,
    lineNumber: lineNumber,
  );
}
