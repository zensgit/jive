import 'package:isar/isar.dart';

import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'auto_rule_engine.dart';

class AutoCategorizeSuggestion {
  final int transactionId;
  final String? rawText;
  final double amount;
  final DateTime timestamp;
  final String parentName;
  final String? subName;
  final String? ruleName;

  AutoCategorizeSuggestion({
    required this.transactionId,
    required this.rawText,
    required this.amount,
    required this.timestamp,
    required this.parentName,
    required this.subName,
    required this.ruleName,
  });
}

class AiAssistantService {
  AiAssistantService(this.isar);

  final Isar isar;

  Future<List<AutoCategorizeSuggestion>> previewAutoCategorize({int limit = 50}) async {
    final txs = await isar.jiveTransactions
        .filter()
        .categoryKeyIsNull()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
    if (txs.isEmpty) return [];

    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return [];

    final parentByName = <String, JiveCategory>{};
    final childByParentAndName = <String, JiveCategory>{};
    for (final cat in categories) {
      if (cat.parentKey == null) {
        parentByName[cat.name] = cat;
      } else {
        childByParentAndName['${cat.parentKey}|${cat.name}'] = cat;
      }
    }

    final engine = await AutoRuleEngine.instance();
    final suggestions = <AutoCategorizeSuggestion>[];

    for (final tx in txs) {
      final text = tx.rawText?.trim();
      if (text == null || text.isEmpty) continue;
      final match = engine.match(text: text, source: tx.source);
      if (match.parent == null) continue;
      final parent = parentByName[match.parent!];
      if (parent == null) continue;
      final sub = match.sub == null ? null : childByParentAndName['${parent.key}|${match.sub}'];
      suggestions.add(
        AutoCategorizeSuggestion(
          transactionId: tx.id,
          rawText: text,
          amount: tx.amount,
          timestamp: tx.timestamp,
          parentName: parent.name,
          subName: sub?.name,
          ruleName: match.ruleName,
        ),
      );
    }

    return suggestions;
  }

  Future<int> applyAutoCategorize(List<AutoCategorizeSuggestion> suggestions) async {
    if (suggestions.isEmpty) return 0;

    final categories = await isar.collection<JiveCategory>().where().findAll();
    if (categories.isEmpty) return 0;

    final parentByName = <String, JiveCategory>{};
    final childByParentAndName = <String, JiveCategory>{};
    for (final cat in categories) {
      if (cat.parentKey == null) {
        parentByName[cat.name] = cat;
      } else {
        childByParentAndName['${cat.parentKey}|${cat.name}'] = cat;
      }
    }

    final ids = suggestions.map((s) => s.transactionId).toList();
    final txs = await isar.jiveTransactions.getAll(ids);
    final toUpdate = <JiveTransaction>[];

    for (final tx in txs) {
      if (tx == null) continue;
      if (tx.categoryKey != null && tx.categoryKey!.isNotEmpty) continue;
      final suggestion = suggestions.firstWhere(
        (s) => s.transactionId == tx.id,
        orElse: () => AutoCategorizeSuggestion(
          transactionId: tx.id,
          rawText: tx.rawText,
          amount: tx.amount,
          timestamp: tx.timestamp,
          parentName: '',
          subName: null,
          ruleName: null,
        ),
      );
      if (suggestion.parentName.isEmpty) continue;
      final parent = parentByName[suggestion.parentName];
      if (parent == null) continue;
      tx.categoryKey = parent.key;
      tx.category = parent.name;
      if (suggestion.subName != null) {
        final sub = childByParentAndName['${parent.key}|${suggestion.subName}'];
        if (sub != null) {
          tx.subCategoryKey = sub.key;
          tx.subCategory = sub.name;
        }
      }
      if (tx.type == null || tx.type!.isEmpty) {
        tx.type = 'expense';
      }
      toUpdate.add(tx);
    }

    if (toUpdate.isEmpty) return 0;

    await isar.writeTxn(() async {
      await isar.jiveTransactions.putAll(toUpdate);
    });

    return toUpdate.length;
  }
}
