import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/feature/transactions/transaction_detail_screen.dart';

void main() {
  test(
    'transaction detail account label includes custom account group path',
    () {
      final account = JiveAccount()
        ..name = '活期'
        ..type = 'asset'
        ..groupName = '中国银行'
        ..currency = 'CNY';

      expect(transactionDetailAccountDisplayName(account), '中国银行 / 活期 / CNY');
    },
  );

  test(
    'transaction detail account label keeps broad legacy groups compact',
    () {
      final account = JiveAccount()
        ..name = '微信零钱'
        ..type = 'asset'
        ..groupName = '资金账户'
        ..currency = 'CNY';

      expect(transactionDetailAccountDisplayName(account), '微信零钱');
    },
  );

  test('transaction detail account label falls back for missing account', () {
    expect(transactionDetailAccountDisplayName(null), '未指定');
  });
}
