import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/feature/investment/investment_screen.dart';

void main() {
  test('investment labels show account group display paths', () {
    final account = _account(
      id: 7,
      name: '证券资金',
      groupName: '招商银行',
      currency: 'CNY',
    );

    expect(
      investmentAccountDisplayLabel(account, account.id),
      '招商银行 / 证券资金 / CNY',
    );
  });

  test('investment labels preserve unlinked and missing account fallbacks', () {
    expect(investmentAccountDisplayLabel(null, null), '未关联账户');
    expect(investmentAccountDisplayLabel(null, 42), '账户 #42');
  });

  test('investment labels keep broad built-in groups compact', () {
    final account = _account(
      id: 8,
      name: '余额宝',
      groupName: '资金账户',
      currency: 'CNY',
    );

    expect(investmentAccountDisplayLabel(account, account.id), '余额宝');
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
    ..name = name
    ..groupName = groupName
    ..currency = currency
    ..type = 'asset';
}
