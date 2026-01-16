import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import '../data/account_constants.dart';
import '../data/account_type_catalog.dart';
import '../database/account_model.dart';
import '../database/transaction_model.dart';
import 'category_service.dart';

class AccountTotals {
  final double assets;
  final double liabilities;

  const AccountTotals({required this.assets, required this.liabilities});

  double get net => assets - liabilities;
}

class AccountService {
  static const String typeAsset = accountTypeAsset;
  static const String typeLiability = accountTypeLiability;
  static const String groupAssets = accountGroupAssets;
  static const String groupCredit = accountGroupCredit;
  static const String groupRecharge = accountGroupRecharge;
  static const String groupInvest = accountGroupInvest;
  static const String groupDebt = accountGroupDebt;
  static const String groupReimburse = accountGroupReimburse;
  static const String groupOther = accountGroupOther;

  static const List<String> groupOrder = accountGroupOrder;

  final Isar isar;

  AccountService(this.isar);

  static const _presetAccounts = <_AccountPreset>[
    _AccountPreset(
      key: 'acct_cash',
      name: '现金',
      type: typeAsset,
      subType: 'cash',
      groupName: groupAssets,
      iconName: 'payments',
      colorHex: '#43A047',
    ),
    _AccountPreset(
      key: 'acct_bank',
      name: '银行卡',
      type: typeAsset,
      subType: 'bank',
      groupName: groupAssets,
      iconName: 'brands/bank.png',
      colorHex: '#1E88E5',
    ),
    _AccountPreset(
      key: 'acct_wechat',
      name: '微信',
      type: typeAsset,
      subType: 'wechat',
      groupName: groupAssets,
      iconName: 'brands/wechat.png',
      colorHex: '#2E7D32',
    ),
    _AccountPreset(
      key: 'acct_alipay',
      name: '支付宝',
      type: typeAsset,
      subType: 'alipay',
      groupName: groupAssets,
      iconName: 'brands/alipay.png',
      colorHex: '#0277BD',
    ),
    _AccountPreset(
      key: 'acct_credit',
      name: '信用卡',
      type: typeLiability,
      subType: 'credit',
      groupName: groupCredit,
      iconName: 'credit_card',
      colorHex: '#EF5350',
    ),
    _AccountPreset(
      key: 'acct_loan',
      name: '借入',
      type: typeLiability,
      subType: 'loan',
      groupName: groupDebt,
      iconName: 'request_page',
      colorHex: '#FF7043',
    ),
  ];

  static const _subTypeStyles = <String, _AccountStyle>{
    'cash': _AccountStyle(iconName: 'payments', colorHex: '#43A047'),
    'bank': _AccountStyle(iconName: 'brands/bank.png', colorHex: '#1E88E5'),
    'wallet': _AccountStyle(
      iconName: 'account_balance_wallet',
      colorHex: '#2E7D32',
    ),
    'wechat': _AccountStyle(iconName: 'brands/wechat.png', colorHex: '#2E7D32'),
    'wechat_balance': _AccountStyle(
      iconName: 'brands/wechat_balance.png',
      colorHex: '#2E7D32',
    ),
    'alipay': _AccountStyle(iconName: 'brands/alipay.png', colorHex: '#0277BD'),
    'yuebao': _AccountStyle(iconName: 'brands/yuebao.png', colorHex: '#26A69A'),
    'unionpay': _AccountStyle(
      iconName: 'brands/unionpay.png',
      colorHex: '#1565C0',
    ),
    'public_fund': _AccountStyle(
      iconName: 'brands/public_fund.png',
      colorHex: '#7CB342',
    ),
    'qq_wallet': _AccountStyle(
      iconName: 'brands/qq_wallet.png',
      colorHex: '#5E35B1',
    ),
    'jd_finance': _AccountStyle(
      iconName: 'brands/jd_finance.png',
      colorHex: '#D32F2F',
    ),
    'medical_insurance': _AccountStyle(
      iconName: 'medical_services',
      colorHex: '#EF5350',
    ),
    'digital_cny': _AccountStyle(
      iconName: 'brands/digital_cny.png',
      colorHex: '#FF7043',
    ),
    'huawei_wallet': _AccountStyle(
      iconName: 'brands/huawei.png',
      colorHex: '#546E7A',
    ),
    'pdd_wallet': _AccountStyle(
      iconName: 'account_balance_wallet',
      colorHex: '#E53935',
    ),
    'paypal': _AccountStyle(
      iconName: 'brands/paypal.png',
      colorHex: '#1565C0',
    ),
    'credit': _AccountStyle(iconName: 'credit_card', colorHex: '#EF5350'),
    'loan': _AccountStyle(iconName: 'request_page', colorHex: '#FF7043'),
    'other_asset': _AccountStyle(iconName: 'savings', colorHex: '#607D8B'),
    'other_liability': _AccountStyle(iconName: 'report', colorHex: '#FFB300'),
  };

  static const _legacyWalletSubtypeMap = <String, String>{
    '微信': 'wechat',
    '微信钱包': 'wechat',
    '微信零钱通': 'wechat_balance',
    '支付宝': 'alipay',
    '支付宝钱包': 'alipay',
    '余额宝': 'yuebao',
    '云闪付': 'unionpay',
    'qq钱包': 'qq_wallet',
    '京东金融': 'jd_finance',
    '医保': 'medical_insurance',
    '数字人民币': 'digital_cny',
    '华为钱包': 'huawei_wallet',
    '多多钱包': 'pdd_wallet',
    'paypal': 'paypal',
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
    final toUpdate = <JiveAccount>[];
    for (final account in existing) {
      if (account.subType != 'wallet') continue;
      final normalized = account.name.trim().toLowerCase();
      final mapped = _legacyWalletSubtypeMap[normalized];
      if (mapped == null || mapped == account.subType) continue;
      account
        ..subType = mapped
        ..groupName = resolveGroupName(account.type, mapped, account.groupName)
        ..updatedAt = now;
      toUpdate.add(account);
    }
    for (final preset in _presetAccounts) {
      if (existingKeys.contains(preset.key)) continue;
      maxOrder += 1;
      final account = JiveAccount()
        ..key = preset.key
        ..name = preset.name
        ..type = preset.type
        ..subType = preset.subType
        ..groupName =
            preset.groupName ??
            resolveGroupName(preset.type, preset.subType, null)
        ..currency = 'CNY'
        ..iconName = preset.iconName
        ..colorHex = preset.colorHex
        ..order = maxOrder
        ..includeInBalance = true
        ..isHidden = false
        ..isArchived = false
        ..billingDay = preset.billingDay
        ..repaymentDay = preset.repaymentDay
        ..creditLimit = preset.creditLimit
        ..openingBalance = 0
        ..updatedAt = now;
      toInsert.add(account);
    }

    if (toInsert.isEmpty && toUpdate.isEmpty) return;
    await isar.writeTxn(() async {
      if (toUpdate.isNotEmpty) {
        await isar.collection<JiveAccount>().putAll(toUpdate);
      }
      if (toInsert.isNotEmpty) {
        await isar.collection<JiveAccount>().putAll(toInsert);
      }
    });
  }

  Future<List<JiveAccount>> getActiveAccounts() async {
    return await isar
        .collection<JiveAccount>()
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

  Future<Map<int, double>> computeBalances({
    List<JiveAccount>? accounts,
  }) async {
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

  AccountTotals calculateTotals(
    List<JiveAccount> accounts,
    Map<int, double> balances,
  ) {
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
    String? iconName,
    String? colorHex,
    String? groupName,
    int? billingDay,
    int? repaymentDay,
    double? creditLimit,
    bool includeInBalance = true,
  }) async {
    final accounts = await isar
        .collection<JiveAccount>()
        .where()
        .sortByOrder()
        .findAll();
    final order = accounts.isEmpty ? 0 : (accounts.last.order + 1);
    final option = AccountTypeCatalog.optionFor(subType);
    final style = _subTypeStyles[subType];
    final now = DateTime.now();
    final account = JiveAccount()
      ..key = 'acct_${DateTime.now().microsecondsSinceEpoch}'
      ..name = name
      ..type = type
      ..subType = subType
      ..groupName = resolveGroupName(type, subType, groupName ?? option?.group)
      ..currency = 'CNY'
      ..iconName =
          iconName ??
          option?.icon ??
          style?.iconName ??
          'account_balance_wallet'
      ..colorHex = colorHex ?? option?.colorHex ?? style?.colorHex ?? '#66BB6A'
      ..order = order
      ..includeInBalance = includeInBalance
      ..isHidden = false
      ..isArchived = false
      ..billingDay = billingDay
      ..repaymentDay = repaymentDay
      ..creditLimit = creditLimit
      ..openingBalance = openingBalance
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().put(account);
    });

    return account;
  }

  Future<JiveAccount> updateAccount(
    JiveAccount account, {
    required String name,
    required String type,
    required String subType,
    required double openingBalance,
    required String iconName,
    String? colorHex,
    String? groupName,
    int? billingDay,
    int? repaymentDay,
    double? creditLimit,
    bool includeInBalance = true,
  }) async {
    account
      ..name = name
      ..type = type
      ..subType = subType
      ..groupName = resolveGroupName(type, subType, groupName)
      ..iconName = iconName
      ..colorHex = colorHex
      ..billingDay = billingDay
      ..repaymentDay = repaymentDay
      ..creditLimit = creditLimit
      ..openingBalance = openingBalance
      ..includeInBalance = includeInBalance
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveAccount>().put(account);
    });

    return account;
  }

  static String resolveGroupName(
    String type,
    String? subType,
    String? current,
  ) {
    if (current != null && current.trim().isNotEmpty) {
      final trimmed = current.trim();
      if (trimmed == '信用账户') return groupCredit;
      return trimmed;
    }
    final option = AccountTypeCatalog.optionFor(subType);
    if (option != null) return option.group;
    if (type == typeAsset) return groupAssets;
    if (type == typeLiability) return groupDebt;
    return groupOther;
  }

  static String displayGroupName(JiveAccount account) {
    return resolveGroupName(account.type, account.subType, account.groupName);
  }

  static bool isCreditAccount(JiveAccount account) {
    return account.type == typeLiability && account.subType == 'credit';
  }

  static bool isFileIcon(String name) {
    return name.startsWith('file:');
  }

  static bool _isAssetIcon(String name) {
    if (isFileIcon(name)) return false;
    return name.endsWith('.png') ||
        name.endsWith('.svg') ||
        name.startsWith('assets/');
  }

  static String _assetIconPath(String name) {
    if (name.startsWith('assets/')) return name;
    return 'assets/account_icons/$name';
  }

  static int _cacheWidth(double size) {
    final views = ui.PlatformDispatcher.instance.views;
    final ratio = views.isEmpty ? 1.0 : views.first.devicePixelRatio;
    final pixelSize = (size * ratio).round();
    return pixelSize <= 0 ? size.round() : pixelSize;
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
      case 'apartment':
        return Icons.apartment;
      case 'medical_services':
        return Icons.medical_services;
      case 'currency_yuan':
        return Icons.currency_yuan;
      case 'phone_android':
        return Icons.phone_android;
      case 'power':
        return Icons.power;
      case 'restaurant':
        return Icons.restaurant;
      case 'lock':
        return Icons.lock;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'card_membership':
        return Icons.card_membership;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'show_chart':
        return Icons.show_chart;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'trending_up':
        return Icons.trending_up;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      default:
        return CategoryService.getIcon(name);
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
    if (isFileIcon(name)) {
      final path = name.substring(5);
      final cacheWidth = _cacheWidth(size);
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.account_balance_wallet, size: size, color: color),
      );
    }
    if (_isAssetIcon(name)) {
      final path = _assetIconPath(name);
      if (path.endsWith('.svg')) {
        return SvgPicture.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
      final cacheWidth = _cacheWidth(size);
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.account_balance_wallet, size: size, color: color),
      );
    }
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
  final String? groupName;
  final String iconName;
  final String colorHex;
  final int? billingDay;
  final int? repaymentDay;
  final double? creditLimit;

  const _AccountPreset({
    required this.key,
    required this.name,
    required this.type,
    required this.subType,
    this.groupName,
    required this.iconName,
    required this.colorHex,
    this.billingDay,
    this.repaymentDay,
    this.creditLimit,
  });
}
