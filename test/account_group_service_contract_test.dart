import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/account_group_service.dart';

void main() {
  group('AccountGroupService contracts', () {
    test(
      'groups subaccounts by custom groupName without changing identities',
      () {
        final accounts = [
          _account(
            id: 3,
            name: '定期',
            groupName: '中国银行',
            subType: '定期',
            currency: 'USD',
            order: 2,
            openingBalance: 100,
          ),
          _account(
            id: 1,
            name: '活期',
            groupName: '中国银行',
            subType: '活期',
            currency: 'CNY',
            order: 1,
            openingBalance: 200,
          ),
          _account(id: 9, name: '微信钱包', currency: 'CNY', order: 9),
        ];

        final groups = const AccountGroupService().groupAccounts(accounts);
        final bankGroup = groups.singleWhere((group) => group.name == '中国银行');

        expect(groups.map((group) => group.name), ['中国银行', '微信钱包']);
        expect(bankGroup.isSingleAccount, isFalse);
        expect(bankGroup.accounts.map((account) => account.id), [1, 3]);
        expect(bankGroup.accounts.map((account) => account.name), ['活期', '定期']);
        expect(bankGroup.currencies, {'CNY', 'USD'});
        expect(bankGroup.openingBalanceTotal, 300);
      },
    );

    test('keeps broad legacy group names as individual account rows', () {
      final accounts = [
        _account(id: 1, name: '现金', groupName: '资金账户', order: 1),
        _account(id: 2, name: '微信零钱', groupName: '资金账户', order: 2),
        _account(id: 3, name: '信用卡', groupName: '信用账户', order: 3),
      ];

      final groups = const AccountGroupService().groupAccounts(accounts);

      expect(groups.map((group) => group.name), ['现金', '微信零钱', '信用卡']);
      expect(groups.every((group) => group.isSingleAccount), isTrue);
      expect(groups.expand((group) => group.accounts).map((a) => a.id), [
        1,
        2,
        3,
      ]);
    });

    test('uses grouped display paths only for real subaccount groups', () {
      final service = const AccountGroupService();
      final grouped = _account(
        id: 1,
        name: '活期',
        groupName: '招商银行',
        subType: '储蓄卡',
        currency: 'CNY',
      );
      final legacy = _account(id: 2, name: '现金', groupName: '资金账户');
      final selfGrouped = _account(id: 3, name: '支付宝', groupName: '支付宝');

      expect(service.displayPath(grouped), '招商银行 / 活期 / 储蓄卡 CNY');
      expect(service.displayPath(legacy), '现金');
      expect(service.displayPath(selfGrouped), '支付宝');
    });

    test('ignores archived accounts in presentation grouping', () {
      final groups = const AccountGroupService().groupAccounts([
        _account(id: 1, name: '活期', groupName: '中国银行', order: 1),
        _account(
          id: 2,
          name: '旧卡',
          groupName: '中国银行',
          order: 2,
          isArchived: true,
        ),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.name, '中国银行');
      expect(groups.single.accounts.map((account) => account.id), [1]);
    });
  });
}

JiveAccount _account({
  required int id,
  required String name,
  String? groupName,
  String? subType,
  String currency = 'CNY',
  int order = 0,
  double openingBalance = 0,
  bool isArchived = false,
}) {
  return JiveAccount()
    ..id = id
    ..key = 'account_$id'
    ..name = name
    ..type = 'asset'
    ..subType = subType
    ..groupName = groupName
    ..currency = currency
    ..iconName = 'wallet'
    ..order = order
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = isArchived
    ..openingBalance = openingBalance
    ..updatedAt = DateTime(2026);
}
