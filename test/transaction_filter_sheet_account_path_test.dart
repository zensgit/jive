import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/widgets/transaction_filter_sheet.dart';

void main() {
  group('transactionFilterAccountLabel', () {
    test('uses grouped account display path without changing account id', () {
      final account = _account(
        id: 7,
        name: '活期',
        groupName: '中国银行',
        currency: 'CNY',
      );

      expect(transactionFilterAccountLabel(account), '中国银行 / 活期 / CNY');
      expect(account.id, 7);
    });

    test('keeps broad legacy account groups as plain account names', () {
      final account = _account(id: 8, name: '现金', groupName: '资金账户');

      expect(transactionFilterAccountLabel(account), '现金');
    });
  });
}

JiveAccount _account({
  required int id,
  required String name,
  String? groupName,
  String currency = 'CNY',
}) {
  return JiveAccount()
    ..id = id
    ..key = 'acct_$id'
    ..name = name
    ..type = 'asset'
    ..groupName = groupName
    ..currency = currency
    ..iconName = 'account_balance_wallet'
    ..order = id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..updatedAt = DateTime(2026, 5, 12);
}
