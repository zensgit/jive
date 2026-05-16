import '../data/account_constants.dart';
import '../data/account_type_catalog.dart';
import '../database/account_model.dart';

class AccountGroupSummary {
  final String name;
  final List<JiveAccount> accounts;

  const AccountGroupSummary({required this.name, required this.accounts});

  bool get isSingleAccount => accounts.length == 1;

  double get openingBalanceTotal {
    return accounts.fold<double>(
      0,
      (sum, account) => sum + account.openingBalance,
    );
  }

  Set<String> get currencies => accounts.map((a) => a.currency).toSet();
}

/// MoneyThings-style account grouping without changing the transaction FK.
///
/// Every child account remains a normal [JiveAccount]; [groupName] only affects
/// presentation and summaries.
class AccountGroupService {
  const AccountGroupService();

  static const _legacyBroadGroupNames = {'信用账户'};

  String sectionNameFor(JiveAccount account) {
    final option = AccountTypeCatalog.optionFor(account.subType);
    if (option != null) return option.group;
    if (account.type == accountTypeAsset) return accountGroupAssets;
    if (account.type == accountTypeLiability) return accountGroupDebt;
    return accountGroupOther;
  }

  List<AccountGroupSummary> groupAccounts(Iterable<JiveAccount> accounts) {
    final buckets = <String, List<JiveAccount>>{};
    for (final account in accounts.where((a) => !a.isArchived)) {
      final name = _groupNameFor(account);
      buckets.putIfAbsent(name, () => <JiveAccount>[]).add(account);
    }

    final groups = buckets.entries.map((entry) {
      final children = entry.value
        ..sort((a, b) {
          final order = a.order.compareTo(b.order);
          if (order != 0) return order;
          return a.name.compareTo(b.name);
        });
      return AccountGroupSummary(name: entry.key, accounts: children);
    }).toList();

    groups.sort((a, b) {
      final firstOrder = (a.accounts.firstOrNull?.order ?? 0).compareTo(
        b.accounts.firstOrNull?.order ?? 0,
      );
      if (firstOrder != 0) return firstOrder;
      return a.name.compareTo(b.name);
    });
    return groups;
  }

  String displayPath(JiveAccount account) {
    final groupName = account.groupName?.trim();
    if (groupName == null ||
        groupName.isEmpty ||
        groupName == account.name ||
        _isBroadGroupName(groupName)) {
      return account.name;
    }
    final suffixParts = <String>[];
    final subtype = account.subType?.trim();
    if (subtype != null &&
        subtype.isNotEmpty &&
        !_containsDisplayToken(account.name, subtype)) {
      suffixParts.add(subtype);
    }
    if (!_containsDisplayToken(account.name, account.currency)) {
      suffixParts.add(account.currency);
    }
    final suffix = suffixParts.join(' ');
    if (suffix.isEmpty) return '$groupName / ${account.name}';
    return '$groupName / ${account.name} / $suffix';
  }

  String collapseKey(AccountGroupSummary group, {String? section}) {
    final groupName = group.name.trim();
    final sectionName = section?.trim();
    if (sectionName == null || sectionName.isEmpty) {
      return groupName;
    }
    return '$sectionName::$groupName';
  }

  bool isCollapsed(
    AccountGroupSummary group,
    Set<String> collapsedKeys, {
    String? section,
  }) {
    return collapsedKeys.contains(collapseKey(group, section: section));
  }

  Set<String> toggledCollapsedKeys(
    AccountGroupSummary group,
    Set<String> collapsedKeys, {
    String? section,
  }) {
    final key = collapseKey(group, section: section);
    final next = <String>{...collapsedKeys};
    if (!next.add(key)) {
      next.remove(key);
    }
    return next;
  }

  static String _groupNameFor(JiveAccount account) {
    final groupName = account.groupName?.trim();
    if (groupName == null ||
        groupName.isEmpty ||
        groupName == account.name ||
        _isBroadGroupName(groupName)) {
      return account.name;
    }
    return groupName;
  }

  static bool _isBroadGroupName(String groupName) {
    return accountGroupOrder.contains(groupName) ||
        _legacyBroadGroupNames.contains(groupName);
  }

  static bool _containsDisplayToken(String text, String token) {
    final normalizedText = text.trim().toLowerCase();
    final normalizedToken = token.trim().toLowerCase();
    return normalizedToken.isEmpty || normalizedText.contains(normalizedToken);
  }
}
