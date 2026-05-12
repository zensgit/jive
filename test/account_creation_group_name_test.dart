import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/account_group_service.dart';
import 'package:jive/core/service/account_service.dart';

void main() {
  group('AccountService.defaultGroupNameForCreation', () {
    test('uses selected bank name for bank asset templates', () {
      final groupName = AccountService.defaultGroupNameForCreation(
        type: AccountService.typeAsset,
        subType: 'bank_cny_current',
        selectedBankName: ' 中国银行 ',
        fallbackGroupName: AccountService.groupAssets,
      );

      expect(groupName, '中国银行');
    });

    test('falls back to catalog groups when bank name is absent', () {
      final groupName = AccountService.defaultGroupNameForCreation(
        type: AccountService.typeAsset,
        subType: 'bank_usd_fixed',
        fallbackGroupName: AccountService.groupAssets,
      );

      expect(groupName, AccountService.groupAssets);
    });

    test('does not group liability credit cards by bank by default', () {
      final groupName = AccountService.defaultGroupNameForCreation(
        type: AccountService.typeLiability,
        subType: 'credit',
        selectedBankName: '招商银行',
        fallbackGroupName: AccountService.groupCredit,
      );

      expect(groupName, AccountService.groupCredit);
    });

    test(
      'creates account groups that keep concrete child account identity',
      () {
        final accounts = [
          _account(id: 1, name: '活期', groupName: '中国银行', currency: 'CNY'),
          _account(id: 2, name: '定期', groupName: '中国银行', currency: 'USD'),
        ];

        final groups = const AccountGroupService().groupAccounts(accounts);

        expect(groups.single.name, '中国银行');
        expect(groups.single.accounts.map((account) => account.id), [1, 2]);
        expect(groups.single.currencies, {'CNY', 'USD'});
      },
    );
  });
}

JiveAccount _account({
  required int id,
  required String name,
  required String groupName,
  required String currency,
}) {
  return JiveAccount()
    ..id = id
    ..key = 'acct_$id'
    ..name = name
    ..type = AccountService.typeAsset
    ..subType = 'bank_cny_current'
    ..groupName = groupName
    ..currency = currency
    ..iconName = 'brands/bank.png'
    ..order = id
    ..includeInBalance = true
    ..isHidden = false
    ..isArchived = false
    ..updatedAt = DateTime(2026, 5, 12);
}
