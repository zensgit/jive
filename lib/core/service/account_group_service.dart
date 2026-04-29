import '../data/account_constants.dart';
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
        accountGroupOrder.contains(groupName)) {
      return account.name;
    }
    final subtype = account.subType?.trim();
    final suffix = subtype == null || subtype.isEmpty
        ? account.currency
        : '$subtype ${account.currency}';
    return '$groupName / ${account.name} / $suffix';
  }

  static String _groupNameFor(JiveAccount account) {
    final groupName = account.groupName?.trim();
    if (groupName == null ||
        groupName.isEmpty ||
        groupName == account.name ||
        accountGroupOrder.contains(groupName)) {
      return account.name;
    }
    return groupName;
  }
}
