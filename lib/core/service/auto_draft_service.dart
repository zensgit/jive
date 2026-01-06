import 'package:isar/isar.dart';
import '../database/auto_draft_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import '../service/account_service.dart';
import '../service/auto_rule_engine.dart';

class AutoCapture {
  final double amount;
  final String source;
  final String? rawText;
  final DateTime timestamp;
  final String? type;

  AutoCapture({
    required this.amount,
    required this.source,
    required this.rawText,
    required this.timestamp,
    required this.type,
  });

  factory AutoCapture.fromEvent(Map<String, dynamic> data) {
    final amountValue = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final rawSource = data['source']?.toString().trim() ?? '';
    final source = _normalizeSource(rawSource);
    final rawText = data['raw_text']?.toString();
    final timestamp = _parseTimestamp(data['timestamp']);
    final type = _normalizeType(data['type']?.toString());
    return AutoCapture(
      amount: amountValue.abs(),
      source: source.isEmpty ? 'Unknown' : source,
      rawText: rawText?.trim(),
      timestamp: timestamp,
      type: type,
    );
  }

  bool get isValid => amount > 0;

  static DateTime _parseTimestamp(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsed);
    }
    return DateTime.now();
  }

  static String _normalizeSource(String source) {
    if (source.contains('com.tencent.mm')) return 'WeChat';
    if (source.contains('com.eg.android.AlipayGphone')) return 'Alipay';
    return source;
  }

  static String? _normalizeType(String? rawType) {
    if (rawType == null) return null;
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'expense' || normalized == 'income' || normalized == 'transfer') {
      return normalized;
    }
    return null;
  }
}

class AutoCaptureResult {
  final bool inserted;
  final bool committed;
  final bool duplicate;

  const AutoCaptureResult({
    required this.inserted,
    required this.committed,
    required this.duplicate,
  });

  static const ignored = AutoCaptureResult(inserted: false, committed: false, duplicate: false);
  static const duplicateHit = AutoCaptureResult(inserted: false, committed: false, duplicate: true);
}

class AutoDraftService {
  AutoDraftService(this.isar);

  final Isar isar;

  Future<AutoCaptureResult> ingestCapture(
    AutoCapture capture, {
    required bool directCommit,
  }) async {
    if (!capture.isValid) return AutoCaptureResult.ignored;
    final dedupKey = _buildDedupKey(capture);
    final duplicate = await _isDuplicate(capture, dedupKey);
    if (duplicate) return AutoCaptureResult.duplicateHit;

    final engine = await AutoRuleEngine.instance();
    final categories = await _buildCategoryIndex();
    final match = engine.match(text: capture.rawText ?? '', source: capture.source);

    final accountId = await _resolveAccountId(capture.source);
    final resolved = categories.resolve(match.parent, match.sub);

    final parentName = resolved.parent?.name ?? match.parent ?? '自动记账';
    final subName = resolved.child?.name ?? match.sub ?? '未分类';
    final type = capture.type ?? match.type;

    if (directCommit) {
      await _commitTransaction(
        capture: capture,
        type: type,
        categoryKey: resolved.parent?.key,
        subCategoryKey: resolved.child?.key,
        categoryName: parentName,
        subCategoryName: subName,
        accountId: accountId,
      );
      return const AutoCaptureResult(inserted: true, committed: true, duplicate: false);
    }

    final draft = JiveAutoDraft()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..type = type
      ..category = parentName
      ..subCategory = subName
      ..categoryKey = resolved.parent?.key
      ..subCategoryKey = resolved.child?.key
      ..accountId = accountId
      ..dedupKey = dedupKey
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveAutoDraft>().put(draft);
    });

    return const AutoCaptureResult(inserted: true, committed: false, duplicate: false);
  }

  Future<void> confirmDraft(JiveAutoDraft draft) async {
    await _commitTransaction(
      capture: AutoCapture(
        amount: draft.amount,
        source: draft.source,
        rawText: draft.rawText,
        timestamp: draft.timestamp,
        type: draft.type,
      ),
      type: draft.type ?? 'expense',
      categoryKey: draft.categoryKey,
      subCategoryKey: draft.subCategoryKey,
      categoryName: draft.category,
      subCategoryName: draft.subCategory,
      accountId: draft.accountId,
      draftId: draft.id,
    );
  }

  Future<void> discardDraft(JiveAutoDraft draft) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveAutoDraft>().delete(draft.id);
    });
  }

  Future<void> _commitTransaction({
    required AutoCapture capture,
    required String type,
    required String? categoryKey,
    required String? subCategoryKey,
    required String? categoryName,
    required String? subCategoryName,
    required int? accountId,
    int? draftId,
  }) async {
    final account = accountId ?? (await AccountService(isar).getDefaultAccount())?.id;
    final tx = JiveTransaction()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..type = type
      ..categoryKey = categoryKey
      ..subCategoryKey = subCategoryKey
      ..category = categoryName
      ..subCategory = subCategoryName
      ..accountId = account;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
      if (draftId != null) {
        await isar.collection<JiveAutoDraft>().delete(draftId);
      }
    });
  }

  Future<bool> _isDuplicate(AutoCapture capture, String dedupKey) async {
    final start = capture.timestamp.subtract(const Duration(minutes: 5));
    final end = capture.timestamp.add(const Duration(minutes: 5));
    final draft = await isar.collection<JiveAutoDraft>()
        .filter()
        .dedupKeyEqualTo(dedupKey)
        .timestampBetween(start, end, includeUpper: true)
        .findFirst();
    if (draft != null) return true;

    final txs = await isar.collection<JiveTransaction>()
        .filter()
        .timestampBetween(start, end, includeUpper: true)
        .findAll();
    final normalizedRaw = _normalizeText(capture.rawText ?? '');
    for (final tx in txs) {
      if (tx.amount != capture.amount) continue;
      if (tx.source != capture.source) continue;
      if (_normalizeText(tx.rawText ?? '') != normalizedRaw) continue;
      return true;
    }
    return false;
  }

  String _buildDedupKey(AutoCapture capture) {
    final normalized = _normalizeText(capture.rawText ?? '');
    return '${capture.source}|${capture.amount.toStringAsFixed(2)}|$normalized';
  }

  Future<int?> _resolveAccountId(String source) async {
    final service = AccountService(isar);
    final accounts = await service.getActiveAccounts();
    if (accounts.isEmpty) return null;

    if (source.contains('WeChat') || source.contains('微信')) {
      final match = accounts.firstWhere(
        (acc) => acc.name.contains('微信'),
        orElse: () => accounts.first,
      );
      return match.id;
    }
    if (source.contains('Alipay') || source.contains('支付宝')) {
      final match = accounts.firstWhere(
        (acc) => acc.name.contains('支付宝'),
        orElse: () => accounts.first,
      );
      return match.id;
    }
    return (await service.getDefaultAccount())?.id ?? accounts.first.id;
  }

  Future<CategoryIndex> _buildCategoryIndex() async {
    final categories = await isar.collection<JiveCategory>().where().findAll();
    return CategoryIndex(categories);
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[\s`~!@#$%^&*()+=|{}\[\]:;,.<>/?，。！？、【】（）《》“”‘’￥…—-]"), '');
  }
}

class CategoryIndex {
  final Map<String, JiveCategory> _parentByName = {};
  final Map<String, JiveCategory> _childByName = {};
  final Map<String, JiveCategory> _childByParentAndName = {};
  final Map<String, JiveCategory> _parentByKey = {};

  CategoryIndex(List<JiveCategory> categories) {
    for (final cat in categories) {
      if (cat.parentKey == null) {
        _parentByKey[cat.key] = cat;
        final existing = _parentByName[cat.name];
        if (existing == null || (cat.isSystem && !existing.isSystem)) {
          _parentByName[cat.name] = cat;
        }
      }
    }
    for (final cat in categories) {
      if (cat.parentKey == null) continue;
      final parent = _parentByKey[cat.parentKey!];
      if (parent == null) continue;
      final key = '${parent.name}|${cat.name}';
      final existing = _childByParentAndName[key];
      if (existing == null || (cat.isSystem && !existing.isSystem)) {
        _childByParentAndName[key] = cat;
      }
      final childExisting = _childByName[cat.name];
      if (childExisting == null || (cat.isSystem && !childExisting.isSystem)) {
        _childByName[cat.name] = cat;
      }
    }
  }

  CategoryMatch resolve(String? parentName, String? subName) {
    JiveCategory? parent = parentName == null ? null : _parentByName[parentName];
    JiveCategory? child;

    if (parent != null && subName != null) {
      child = _childByParentAndName['${parent.name}|$subName'];
    }
    child ??= subName == null ? null : _childByName[subName];
    if (child != null && parent == null && child.parentKey != null) {
      parent = _parentByKey[child.parentKey!];
    }
    return CategoryMatch(parent: parent, child: child);
  }
}

class CategoryMatch {
  final JiveCategory? parent;
  final JiveCategory? child;

  const CategoryMatch({
    required this.parent,
    required this.child,
  });
}
