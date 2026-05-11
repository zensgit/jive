import '../data/scene_templates.dart';
import '../database/account_model.dart';
import '../database/category_model.dart';
import 'account_service.dart';

/// Resolves scene-aware candidates without mutating books, categories, or accounts.
class SceneCandidateService {
  const SceneCandidateService();

  List<JiveCategory> categoryCandidates({
    required SceneTemplate template,
    required Iterable<JiveCategory> categories,
    bool? isIncome,
    bool includeRemainder = true,
  }) {
    final visible = categories.where((category) {
      if (category.isHidden) return false;
      if (isIncome != null && category.isIncome != isIncome) return false;
      return true;
    }).toList()..sort(_compareCategoryOrder);

    final selected = <JiveCategory>[];
    final selectedKeys = <String>{};
    final byTemplateKey = _indexCategoriesByTemplateKey(visible);

    for (final key in template.categoryKeys) {
      final matches = byTemplateKey[_normalize(key)] ?? const <JiveCategory>[];
      for (final category in matches) {
        if (selectedKeys.add(category.key)) {
          selected.add(category);
        }
      }
    }

    if (!includeRemainder) return selected;

    for (final category in visible) {
      if (selectedKeys.add(category.key)) {
        selected.add(category);
      }
    }
    return selected;
  }

  List<JiveAccount> accountCandidates({
    required int? bookId,
    required Iterable<JiveAccount> accounts,
    bool includeDefaultBookFallback = true,
  }) {
    final visible = accounts.where((account) {
      return !account.isHidden && !account.isArchived;
    }).toList()..sort((a, b) => a.order.compareTo(b.order));

    final selected = <JiveAccount>[];
    final selectedKeys = <String>{};

    void addWhere(bool Function(JiveAccount account) test) {
      for (final account in visible) {
        if (!test(account)) continue;
        if (selectedKeys.add(account.key)) {
          selected.add(account);
        }
      }
    }

    if (bookId == null) {
      addWhere((account) => account.bookId == null);
    } else {
      addWhere((account) => account.bookId == bookId);
      if (includeDefaultBookFallback) {
        addWhere((account) => account.bookId == null);
      }
    }

    return selected;
  }

  JiveCategory? defaultCategoryCandidate({
    required SceneTemplate template,
    required Iterable<JiveCategory> categories,
    bool? isIncome,
  }) {
    final candidates = categoryCandidates(
      template: template,
      categories: categories,
      isIncome: isIncome,
      includeRemainder: false,
    );
    return candidates.isEmpty ? null : candidates.first;
  }

  JiveAccount? defaultAccountCandidate({
    required int? bookId,
    required Iterable<JiveAccount> accounts,
    bool includeDefaultBookFallback = true,
  }) {
    final candidates = accountCandidates(
      bookId: bookId,
      accounts: accounts,
      includeDefaultBookFallback: includeDefaultBookFallback,
    );
    for (final account in candidates) {
      if (account.type == AccountService.typeAsset &&
          account.includeInBalance) {
        return account;
      }
    }
    return candidates.isEmpty ? null : candidates.first;
  }

  Map<String, List<JiveCategory>> _indexCategoriesByTemplateKey(
    List<JiveCategory> categories,
  ) {
    final index = <String, List<JiveCategory>>{};
    for (final category in categories) {
      for (final key in {_normalize(category.key), _normalize(category.name)}) {
        if (key.isEmpty) continue;
        (index[key] ??= <JiveCategory>[]).add(category);
      }
    }
    return index;
  }

  static int _compareCategoryOrder(JiveCategory a, JiveCategory b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    return a.name.compareTo(b.name);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
