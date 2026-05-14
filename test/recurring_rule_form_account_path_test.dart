import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/feature/recurring/recurring_rule_form_screen.dart';

void main() {
  test('recurring rule account labels show account group display paths', () {
    final account = _account(name: '活期', groupName: '中国银行', currency: 'CNY');

    expect(recurringRuleAccountDisplayLabel(account), '中国银行 / 活期 / CNY');
  });

  test('recurring rule keeps broad built-in account group labels compact', () {
    final account = _account(
      name: 'Visa 尾号 8899',
      groupName: '信用卡账户',
      currency: 'CNY',
    );

    expect(recurringRuleAccountDisplayLabel(account), 'Visa 尾号 8899');
  });
}

JiveAccount _account({
  required String name,
  String? groupName,
  String currency = 'CNY',
}) {
  return JiveAccount()
    ..name = name
    ..groupName = groupName
    ..currency = currency
    ..type = 'asset';
}
