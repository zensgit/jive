import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../database/account_model.dart';
import '../database/transaction_model.dart';

class AccountTotals {
  final double assets;
  final double liabilities;

  const AccountTotals({required this.assets, required this.liabilities});

  double get net => assets - liabilities;
}

class AccountService {
  static const String typeAsset = 'asset';
  static const String typeLiability = 'liability';

  final Isar isar;

  AccountService(this.isar);

  static const _presetAccounts = <_AccountPreset>[
    _AccountPreset(
      key: 'acct_cash',
      name: '现金',
      type: typeAsset,
      subType: 'cash',
      iconName: 'payments',
      colorHex: '#43A047',
    ),
    _AccountPreset(
      key: 'acct_bank',
      name: '银行卡',
      type: typeAsset,
      subType: 'bank',
      iconName: 'account_balance',
      colorHex: '#1E88E5',
    ),
    _AccountPreset(
      key: 'acct_wechat',
      name: '微信钱包',
      type: typeAsset,
      subType: 'wallet',
      iconName: 'account_balance_wallet',
      colorHex: '#2E7D32',
    ),
    _AccountPreset(
      key: 'acct_alipay',
      name: '支付宝',
      type: typeAsset,
      subType: 'wallet',
      iconName: 'account_balance_wallet',
      colorHex: '#0277BD',
    ),
    _AccountPreset(
      key: 'acct_credit',
      name: '信用卡',
      type: typeLiability,
      subType: 'credit',
      iconName: 'credit_card',
      colorHex: '#EF5350',
    ),
    _AccountPreset(
      key: 'acct_loan',
      name: '借入',
      type: typeLiability,
      subType: 'loan',
      iconName: 'request_page',
      colorHex: '#FF7043',
    ),
  ];

  static const _subTypeStyles = <String, _AccountStyle>{
    'cash': _AccountStyle(iconName: 'payments', colorHex: '#43A047'),
    'bank': _AccountStyle(iconName: 'account_balance', colorHex: '#1E88E5'),
    'wallet': _AccountStyle(iconName: 'account_balance_wallet', colorHex: '#2E7D32'),
    'credit': _AccountStyle(iconName: 'credit_card', colorHex: '#EF5350'),
    'loan': _AccountStyle(iconName: 'request_page', colorHex: '#FF7043'),
    'other_asset': _AccountStyle(iconName: 'savings', colorHex: '#607D8B'),
    'other_liability': _AccountStyle(iconName: 'report', colorHex: '#FFB300'),
  };

  Future<void> initDefaultAccounts() async {
    final existing = await isar.collection<JiveAccount>().where().findAll();
    final existingKeys = {for (final account in existing) account.key};
    var maxOrder = -1;
    for (final account in existing) {
      if (account.order > maxOrder) maxOrder = account.order;
    }

    final now = DateTime.now();
    final toInsert = <JiveAccount>[];
    for (final preset in _presetAccounts) {
      if (existingKeys.contains(preset.key)) continue;
      maxOrder += 1;
      final account = JiveAccount()
        ..key = preset.key
        ..name = preset.name
        ..type = preset.type
        ..subType = preset.subType
        ..currency = 'CNY'
        ..iconName = preset.iconName
        ..colorHex = preset.colorHex
        ..order = maxOrder
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..openingBalance = 0
        ..updatedAt = now;
      toInsert.add(account);
    }

    if (toInsert.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().putAll(toInsert);
    });
  }

  Future<List<JiveAccount>> getActiveAccounts() async {
    return await isar.collection<JiveAccount>()
        .filter()
        .isHiddenEqualTo(false)
        .isArchivedEqualTo(false)
        .sortByOrder()
        .findAll();
  }

  Future<JiveAccount?> getDefaultAccount() async {
    final accounts = await getActiveAccounts();
    if (accounts.isEmpty) return null;
    for (final account in accounts) {
      if (account.type == typeAsset && account.includeInBalance) return account;
    }
    return accounts.first;
  }

  Future<Map<int, double>> computeBalances({List<JiveAccount>? accounts}) async {
    final accountList = accounts ?? await getActiveAccounts();
    final balances = <int, double>{};
    for (final account in accountList) {
      balances[account.id] = account.openingBalance;
    }

    final txs = await isar.jiveTransactions.where().findAll();
    for (final tx in txs) {
      final type = tx.type ?? 'expense';
      final amount = tx.amount;
      final fromId = tx.accountId;
      final toId = tx.toAccountId;

      if (fromId != null && balances.containsKey(fromId)) {
        if (type == 'income') {
          balances[fromId] = (balances[fromId] ?? 0) + amount;
        } else if (type == 'expense') {
          balances[fromId] = (balances[fromId] ?? 0) - amount;
        } else if (type == 'transfer') {
          balances[fromId] = (balances[fromId] ?? 0) - amount;
        }
      }

      if (type == 'transfer' && toId != null && balances.containsKey(toId)) {
        balances[toId] = (balances[toId] ?? 0) + amount;
      }
    }

    return balances;
  }

  AccountTotals calculateTotals(List<JiveAccount> accounts, Map<int, double> balances) {
    double totalAssets = 0;
    double totalLiabilities = 0;

    for (final account in accounts) {
      if (!account.includeInBalance) continue;
      final balance = balances[account.id] ?? account.openingBalance;
      if (account.type == typeLiability) {
        totalLiabilities += balance.abs();
      } else {
        totalAssets += balance;
      }
    }

    return AccountTotals(assets: totalAssets, liabilities: totalLiabilities);
  }

  Future<JiveAccount> createAccount({
    required String name,
    required String type,
    required String subType,
    required double openingBalance,
    bool includeInBalance = true,
  }) async {
    final accounts = await isar.collection<JiveAccount>().where().sortByOrder().findAll();
    final order = accounts.isEmpty ? 0 : (accounts.last.order + 1);
    final style = _subTypeStyles[subType];
    final now = DateTime.now();
    final account = JiveAccount()
      ..key = 'acct_${DateTime.now().microsecondsSinceEpoch}'
      ..name = name
      ..type = type
      ..subType = subType
      ..currency = 'CNY'
      ..iconName = style?.iconName ?? 'account_balance_wallet'
      ..colorHex = style?.colorHex ?? '#66BB6A'
      ..order = order
      ..includeInBalance = includeInBalance
      ..isHidden = false
      ..isArchived = false
      ..openingBalance = openingBalance
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().put(account);
    });

    return account;
  }

  static IconData getIcon(String name) {
    switch (name) {
      case 'payments':
        return Icons.payments;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'request_page':
        return Icons.request_page;
      case 'savings':
        return Icons.savings;
      case 'report':
        return Icons.report;
      default:
        return Icons.account_balance_wallet;
    }
  }

  static Color? parseColorHex(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    var hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length != 8) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  static Widget buildIcon(String name, {double size = 20, Color? color}) {
    return Icon(getIcon(name), size: size, color: color);
  }

}

class _AccountStyle {
  final String iconName;
  final String colorHex;

  const _AccountStyle({required this.iconName, required this.colorHex});
}

class _AccountPreset {
  final String key;
  final String name;
  final String type;
  final String subType;
  final String iconName;
  final String colorHex;

  const _AccountPreset({
    required this.key,
    required this.name,
    required this.type,
    required this.subType,
    required this.iconName,
    required this.colorHex,
  });
}
