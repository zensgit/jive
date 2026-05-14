import '../database/account_model.dart';
import 'account_group_service.dart';

/// Builds speech-friendly account aliases without changing account identity.
///
/// MoneyThings-style sub-account paths are useful in spoken text, but users
/// rarely say the visual separators. This service keeps the UI path and compact
/// path together so parsers and editor builders resolve the same account.
class AccountSpeechAliasService {
  const AccountSpeechAliasService({
    AccountGroupService accountGroupService = const AccountGroupService(),
  }) : _accountGroupService = accountGroupService;

  static final RegExp _separatorPattern = RegExp(r'[\s/_\-·•]+');
  static final RegExp _accountSuffixPattern = RegExp(r'(钱包|账户|帐户)$');

  final AccountGroupService _accountGroupService;

  List<String> parserAccountNames(Iterable<JiveAccount> accounts) {
    final names = <String>{};
    for (final account in accounts) {
      names.addAll(aliasesFor(account));
    }
    return names
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<String> aliasesFor(JiveAccount account) {
    final aliases = <String>{};
    _add(aliases, account.name);

    final trimmedName = account.name.replaceAll(_accountSuffixPattern, '');
    if (trimmedName.length >= 2 && trimmedName != account.name) {
      _add(aliases, trimmedName);
    }

    final groupName = account.groupName?.trim();
    if (groupName != null &&
        groupName.isNotEmpty &&
        groupName != account.name) {
      _add(aliases, '$groupName / ${account.name}');
      _add(aliases, '$groupName${account.name}');
      _add(aliases, '$groupName${account.name}${account.currency}');
    }

    final displayPath = _accountGroupService.displayPath(account);
    _add(aliases, displayPath);
    _add(aliases, displayPath.replaceAll(_separatorPattern, ''));

    if (account.name.contains('微信')) _add(aliases, '微信');
    if (account.name.contains('支付宝')) _add(aliases, '支付宝');
    if (account.name.contains('现金')) _add(aliases, '现金');
    if (account.name.contains('银行卡') || account.name.contains('银行')) {
      _add(aliases, '银行卡');
    }
    if (account.name.contains('信用卡')) _add(aliases, '信用卡');

    return aliases.toList(growable: false);
  }

  void _add(Set<String> aliases, String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return;
    aliases.add(normalized);
  }
}
