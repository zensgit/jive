import 'dart:convert';

import 'package:isar/isar.dart';
import '../database/auto_draft_model.dart';
import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import '../service/account_service.dart';
import '../service/auto_account_mapping.dart';
import '../service/auto_rule_engine.dart';
import '../service/auto_settings.dart';
import '../service/tag_service.dart';
import '../service/tag_rule_service.dart';
import '../service/data_reload_bus.dart';
import 'transaction_service.dart';

class AutoCapture {
  final double amount;
  final String source;
  final String? rawText;
  final DateTime timestamp;
  final String? type;
  final String? accountBookName;
  final String? accountName;
  final String? toAccountName;
  final String? parentCategoryName;
  final String? childCategoryName;
  final double? serviceCharge;
  final List<String> tagNames;

  static const _incomeKeywords = ['已收款', '已收到', '到账', '退款', '赔付'];

  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  AutoCapture({
    required this.amount,
    required this.source,
    required this.rawText,
    required this.timestamp,
    required this.type,
    this.accountBookName,
    this.accountName,
    this.toAccountName,
    this.parentCategoryName,
    this.childCategoryName,
    this.serviceCharge,
    this.tagNames = const [],
  });

  factory AutoCapture.fromEvent(Map<String, dynamic> data) {
    final amountValue = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final rawSource = data['source']?.toString().trim() ?? '';
    final source = _normalizeSource(rawSource);
    final rawText = data['raw_text']?.toString();
    final timestamp = _parseTimestamp(data['timestamp']);
    final normalizedType = _normalizeType(data['type']?.toString());
    final inferredType = _inferTypeFromText(rawText);
    final type = _preferType(normalizedType, inferredType);
    return AutoCapture(
      amount: amountValue.abs(),
      source: source.isEmpty ? 'Unknown' : source,
      rawText: rawText?.trim(),
      timestamp: timestamp,
      type: type,
      tagNames: const [],
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
    if (source.contains('com.unionpay')) return 'UnionPay';
    return source;
  }

  static String? _normalizeType(String? rawType) {
    if (rawType == null) return null;
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'expense' ||
        normalized == 'income' ||
        normalized == 'transfer') {
      return normalized;
    }
    return null;
  }

  static String? _inferTypeFromText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return null;
    for (final keyword in _incomeKeywords) {
      if (rawText.contains(keyword)) return 'income';
    }
    for (final keyword in _transferKeywords) {
      if (rawText.contains(keyword)) return 'transfer';
    }
    return null;
  }

  static String? _preferType(String? normalizedType, String? inferredType) {
    if (inferredType == 'transfer' && normalizedType != 'transfer') {
      return 'transfer';
    }
    return normalizedType ?? inferredType;
  }
}

class AutoCaptureResult {
  final bool inserted;
  final bool committed;
  final bool duplicate;
  final bool merged;

  const AutoCaptureResult({
    required this.inserted,
    required this.committed,
    required this.duplicate,
    required this.merged,
  });

  static const ignored = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: false,
    merged: false,
  );
  static const duplicateHit = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: true,
    merged: false,
  );
  static const mergedHit = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: false,
    merged: true,
  );
}

class AutoDraftConfirmException implements Exception {
  const AutoDraftConfirmException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AutoDraftConfirmException($code): $message';
}

class AutoDraftService {
  AutoDraftService(this.isar);

  final Isar isar;
  static const _transferToAccountMetadataKey = 'transferToAccountName';
  static const _transferServiceChargeMetadataKey = 'transferServiceCharge';

  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  Future<AutoCaptureResult> ingestCapture(
    AutoCapture capture, {
    required bool directCommit,
    AutoSettings? settings,
  }) async {
    if (!capture.isValid) return AutoCaptureResult.ignored;
    final effectiveSettings = settings ?? AutoSettingsStore.defaults;
    final dedupKey = _buildDedupKey(capture);
    final duplicate = await _isDuplicate(capture, dedupKey);
    if (duplicate) return AutoCaptureResult.duplicateHit;

    final engine = await AutoRuleEngine.instance();
    final categories = await _buildCategoryIndex();
    final match = engine.match(
      text: capture.rawText ?? '',
      source: capture.source,
    );
    final explicitTagKeys = capture.tagNames.isEmpty
        ? <String>[]
        : await TagService(isar).resolveTagKeysByNames(capture.tagNames);
    final matchedTagKeys = match.tags.isEmpty
        ? <String>[]
        : await TagService(isar).resolveTagKeysByNames(match.tags);
    final tagKeys = <String>{...explicitTagKeys, ...matchedTagKeys}.toList();

    final accounts = await AccountService(isar).getActiveAccounts();
    final mappings = await AutoAccountMappingStore.load();
    final accountId =
        _resolveExplicitAccountId(accounts, capture.accountName) ??
        _resolveAccountIdFromAccounts(
          accounts,
          capture.source,
          capture.rawText,
          mappings,
        );
    final explicitToAccountId = capture.type == 'transfer'
        ? _resolveExplicitAccountId(accounts, capture.toAccountName)
        : null;
    final inferredToAccountId = capture.type == 'transfer'
        ? _resolveToAccountIdFromAccounts(accounts, capture.rawText, mappings)
        : null;
    final toAccountId = capture.type == 'transfer'
        ? (explicitToAccountId ?? inferredToAccountId)
        : null;
    final explicitResolved = categories.resolve(
      capture.parentCategoryName,
      capture.childCategoryName,
    );
    final resolved =
        explicitResolved.parent != null || explicitResolved.child != null
        ? explicitResolved
        : categories.resolve(match.parent, match.sub);

    var parentName = capture.parentCategoryName?.trim().isNotEmpty == true
        ? capture.parentCategoryName!.trim()
        : (resolved.parent?.name ?? match.parent ?? '自动记账');
    var subName = capture.childCategoryName?.trim().isNotEmpty == true
        ? capture.childCategoryName!.trim()
        : (resolved.child?.name ?? match.sub ?? '未分类');
    final hintType = _inferTypeFromCategoryHints(
      capture.parentCategoryName,
      capture.childCategoryName,
    );
    final type = capture.type ?? hintType ?? match.type;

    if (type == 'transfer') {
      parentName = '转账';
      subName = '转账';
    } else if (type == 'expense') {
      final meal = _inferMealSubCategory(
        parentName: parentName,
        subName: subName,
        timestamp: capture.timestamp,
      );
      if (meal != null) {
        subName = meal;
      }
    }

    if (!directCommit && effectiveSettings.autoTransferRecognition) {
      final merged = await _mergeTransferDraftIfNeeded(
        capture: capture,
        matchType: type,
        windowSeconds: effectiveSettings.autoTransferWindowSeconds,
        accounts: accounts,
        accountId: accountId,
        toAccountId: toAccountId,
        categories: categories,
        resolved: resolved,
        parentName: parentName,
        subName: subName,
        tagKeys: tagKeys,
        dedupKey: dedupKey,
      );
      if (merged) return AutoCaptureResult.mergedHit;
    }

    if (directCommit) {
      await _commitTransaction(
        capture: capture,
        type: type,
        categoryKey: type == 'transfer' ? null : resolved.parent?.key,
        subCategoryKey: type == 'transfer'
            ? null
            : _resolveSubKey(
                parentName: parentName,
                subName: subName,
                resolved: resolved,
                categories: categories,
              ),
        categoryName: parentName,
        subCategoryName: subName,
        accountId: accountId,
        toAccountId: toAccountId,
        exchangeFee: capture.serviceCharge,
        tagKeys: tagKeys,
      );
      return const AutoCaptureResult(
        inserted: true,
        committed: true,
        duplicate: false,
        merged: false,
      );
    }

    final subKey = type == 'transfer'
        ? null
        : _resolveSubKey(
            parentName: parentName,
            subName: subName,
            resolved: resolved,
            categories: categories,
          );
    final draft = JiveAutoDraft()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..type = type
      ..category = parentName
      ..subCategory = subName
      ..categoryKey = type == 'transfer' ? null : resolved.parent?.key
      ..subCategoryKey = subKey
      ..accountId = accountId
      ..toAccountId = toAccountId
      ..metadataJson = _buildCaptureMetadataJson(capture)
      ..tagKeys = tagKeys
      ..dedupKey = dedupKey
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveAutoDraft>().put(draft);
    });

    return const AutoCaptureResult(
      inserted: true,
      committed: false,
      duplicate: false,
      merged: false,
    );
  }

  Future<void> confirmDraft(JiveAutoDraft draft) async {
    final explicitType = draft.type;
    final isTransfer =
        explicitType == 'transfer' ||
        (explicitType == null && _looksLikeTransfer(draft));
    final type = explicitType ?? (isTransfer ? 'transfer' : 'expense');
    final categoryKey = isTransfer ? null : draft.categoryKey;
    final subCategoryKey = isTransfer ? null : draft.subCategoryKey;
    final categoryName = isTransfer ? '转账' : draft.category;
    final subCategoryName = isTransfer ? '转账' : draft.subCategory;
    final transferMetadata = _readTransferMetadata(draft.metadataJson);
    final resolvedAccounts = await _resolveDraftAccountIds(
      draft,
      isTransfer: isTransfer,
      transferMetadata: transferMetadata,
    );
    await _commitTransaction(
      capture: AutoCapture(
        amount: draft.amount,
        source: draft.source,
        rawText: draft.rawText,
        timestamp: draft.timestamp,
        type: type,
        toAccountName: transferMetadata.toAccountName,
        serviceCharge: transferMetadata.serviceCharge,
      ),
      type: type,
      categoryKey: categoryKey,
      subCategoryKey: subCategoryKey,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      accountId: resolvedAccounts.accountId,
      toAccountId: resolvedAccounts.toAccountId,
      exchangeFee: transferMetadata.serviceCharge,
      tagKeys: draft.tagKeys,
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
    int? toAccountId,
    double? exchangeFee,
    List<String>? tagKeys,
    int? draftId,
  }) async {
    final account =
        accountId ?? (await AccountService(isar).getDefaultAccount())?.id;
    final normalizedType = type == 'transfer' ? 'transfer' : type;
    if (normalizedType == 'transfer' && toAccountId == null) {
      throw const AutoDraftConfirmException(
        'missing_transfer_target_account',
        '转账草稿缺少可解析的转入账户，无法确认。',
      );
    }
    if (normalizedType == 'transfer' &&
        account != null &&
        account == toAccountId) {
      throw const AutoDraftConfirmException(
        'same_transfer_account',
        '转账草稿的转出账户和转入账户不能相同。',
      );
    }
    final normalizedCategory = normalizedType == 'transfer'
        ? '转账'
        : categoryName;
    final normalizedSub = normalizedType == 'transfer' ? '转账' : subCategoryName;
    final normalizedCategoryKey = normalizedType == 'transfer'
        ? null
        : categoryKey;
    final normalizedSubKey = normalizedType == 'transfer'
        ? null
        : subCategoryKey;
    final tx = JiveTransaction()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..type = normalizedType
      ..categoryKey = normalizedCategoryKey
      ..subCategoryKey = normalizedSubKey
      ..category = normalizedCategory
      ..subCategory = normalizedSub
      ..accountId = account
      ..toAccountId = toAccountId
      ..exchangeFee = normalizedType == 'transfer' ? exchangeFee : null
      ..exchangeFeeType = normalizedType == 'transfer' && exchangeFee != null
          ? 'fixed'
          : null
      ..tagKeys = tagKeys == null ? [] : List<String>.from(tagKeys);

    final smartTags = await TagRuleService(isar).resolveMatchingTags(tx);
    if (smartTags.isNotEmpty) {
      tx.tagKeys = <String>{...tx.tagKeys, ...smartTags}.toList();
      tx.smartTagKeys = List<String>.from(smartTags);
    } else {
      tx.smartTagKeys = [];
    }

    TransactionService.touchSyncMetadata(tx);
    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
      if (draftId != null) {
        await isar.collection<JiveAutoDraft>().delete(draftId);
      }
    });
    if (tx.tagKeys.isNotEmpty) {
      await TagService(isar).markTagsUsed(tx.tagKeys, capture.timestamp);
    }
    DataReloadBus.notify();
  }

  Future<_ResolvedDraftAccountIds> _resolveDraftAccountIds(
    JiveAutoDraft draft, {
    required bool isTransfer,
    required _TransferDraftMetadata transferMetadata,
  }) async {
    if (!isTransfer) {
      return _ResolvedDraftAccountIds(
        accountId: draft.accountId,
        toAccountId: draft.toAccountId,
      );
    }
    final accounts = await AccountService(isar).getActiveAccounts();
    final mappings = await AutoAccountMappingStore.load();
    final resolvedAccountId =
        draft.accountId ??
        _resolveAccountIdFromAccounts(
          accounts,
          draft.source,
          draft.rawText,
          mappings,
        );
    final resolvedToAccountId =
        draft.toAccountId ??
        _resolveExplicitAccountId(accounts, transferMetadata.toAccountName) ??
        _resolveToAccountIdFromAccounts(accounts, draft.rawText, mappings);
    return _ResolvedDraftAccountIds(
      accountId: resolvedAccountId,
      toAccountId: resolvedToAccountId,
    );
  }

  String? _inferMealSubCategory({
    required String parentName,
    required String subName,
    required DateTime timestamp,
  }) {
    if (parentName != '餐饮') return null;
    if (subName == '早餐' || subName == '午餐' || subName == '晚餐') {
      return subName;
    }
    final hour = timestamp.hour;
    if (hour >= 4 && hour < 10) return '早餐';
    if (hour >= 10 && hour < 16) return '午餐';
    return '晚餐';
  }

  String? _resolveSubKey({
    required String parentName,
    required String subName,
    required CategoryMatch resolved,
    required CategoryIndex categories,
  }) {
    if (resolved.child != null && resolved.child!.name == subName) {
      return resolved.child!.key;
    }
    final updated = categories.resolve(parentName, subName);
    return updated.child?.key;
  }

  Future<bool> _mergeTransferDraftIfNeeded({
    required AutoCapture capture,
    required String matchType,
    required int windowSeconds,
    required List<JiveAccount> accounts,
    required int? accountId,
    required int? toAccountId,
    required CategoryIndex categories,
    required CategoryMatch resolved,
    required String parentName,
    required String subName,
    required List<String> tagKeys,
    required String dedupKey,
  }) async {
    final window = Duration(seconds: windowSeconds.clamp(10, 300));
    final start = capture.timestamp.subtract(window);
    final end = capture.timestamp.add(window);
    final candidates = await isar
        .collection<JiveAutoDraft>()
        .filter()
        .timestampBetween(start, end, includeUpper: true)
        .findAll();
    if (candidates.isEmpty) return false;

    final captureIsTransfer =
        matchType == 'transfer' || _looksLikeTransferText(capture.rawText);
    for (final draft in candidates) {
      if (draft.dedupKey == dedupKey) continue;
      if ((draft.amount - capture.amount).abs() > 0.01) continue;

      final draftType = draft.type ?? 'expense';
      final draftIsTransfer =
          draftType == 'transfer' || _looksLikeTransfer(draft);
      final hasIncome = draftType == 'income' || matchType == 'income';
      final hasExpense = draftType == 'expense' || matchType == 'expense';

      if (!hasIncome || !hasExpense) {
        if (!captureIsTransfer || !draftIsTransfer) {
          continue;
        }
      }

      final merged = _mergeDraftWithCapture(
        draft: draft,
        capture: capture,
        matchType: matchType,
        accountId: accountId,
        toAccountId: toAccountId,
        tagKeys: tagKeys,
      );
      if (!merged) continue;

      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });
      return true;
    }
    return false;
  }

  bool _mergeDraftWithCapture({
    required JiveAutoDraft draft,
    required AutoCapture capture,
    required String matchType,
    required int? accountId,
    required int? toAccountId,
    required List<String> tagKeys,
  }) {
    final draftType = draft.type ?? 'expense';
    final fromId = _resolveFromAccountId(
      draftType: draftType,
      draftAccountId: draft.accountId,
      captureType: matchType,
      captureAccountId: accountId,
    );
    final toId = _resolveToAccountId(
      draftType: draftType,
      draftAccountId: draft.accountId,
      draftToAccountId: draft.toAccountId,
      captureType: matchType,
      captureAccountId: accountId,
      captureToAccountId: toAccountId,
    );

    draft.type = 'transfer';
    draft.category = '转账';
    draft.subCategory = '转账';
    draft.categoryKey = null;
    draft.subCategoryKey = null;
    draft.accountId = fromId ?? draft.accountId ?? accountId;
    draft.toAccountId = toId ?? draft.toAccountId ?? toAccountId;
    draft.rawText = _mergeRawText(draft.rawText, capture.rawText);
    if (tagKeys.isNotEmpty) {
      final mergedTags = <String>{...draft.tagKeys, ...tagKeys};
      draft.tagKeys = mergedTags.toList();
    }
    return true;
  }

  int? _resolveFromAccountId({
    required String draftType,
    required int? draftAccountId,
    required String captureType,
    required int? captureAccountId,
  }) {
    if (draftType == 'expense' && draftAccountId != null) return draftAccountId;
    if (captureType == 'expense' && captureAccountId != null) {
      return captureAccountId;
    }
    return draftAccountId ?? captureAccountId;
  }

  int? _resolveToAccountId({
    required String draftType,
    required int? draftAccountId,
    required int? draftToAccountId,
    required String captureType,
    required int? captureAccountId,
    required int? captureToAccountId,
  }) {
    if (draftType == 'income' && draftAccountId != null) return draftAccountId;
    if (captureType == 'income' && captureAccountId != null) {
      return captureAccountId;
    }
    return draftToAccountId ?? captureToAccountId;
  }

  String? _mergeRawText(String? existing, String? incoming) {
    final left = existing?.trim() ?? '';
    final right = incoming?.trim() ?? '';
    if (right.isEmpty) return left.isEmpty ? null : left;
    if (left.isEmpty) return right;
    if (left == right) return left;
    final merged = '$left | $right';
    return merged.length > 420 ? merged.substring(0, 420) : merged;
  }

  Future<bool> _isDuplicate(AutoCapture capture, String dedupKey) async {
    final start = capture.timestamp.subtract(const Duration(minutes: 5));
    final end = capture.timestamp.add(const Duration(minutes: 5));
    final draft = await isar
        .collection<JiveAutoDraft>()
        .filter()
        .dedupKeyEqualTo(dedupKey)
        .timestampBetween(start, end, includeUpper: true)
        .findFirst();
    if (draft != null) return true;

    final txs = await isar
        .collection<JiveTransaction>()
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

    if (_looksLikeBulkText(capture.rawText)) {
      final narrowStart = capture.timestamp.subtract(
        const Duration(seconds: 90),
      );
      final narrowEnd = capture.timestamp.add(const Duration(seconds: 90));
      final nearDraft = await isar
          .collection<JiveAutoDraft>()
          .filter()
          .amountEqualTo(capture.amount)
          .sourceEqualTo(capture.source)
          .timestampBetween(narrowStart, narrowEnd, includeUpper: true)
          .findFirst();
      if (nearDraft != null) return true;
      final nearTx = await isar
          .collection<JiveTransaction>()
          .filter()
          .amountEqualTo(capture.amount)
          .sourceEqualTo(capture.source)
          .timestampBetween(narrowStart, narrowEnd, includeUpper: true)
          .findFirst();
      if (nearTx != null) return true;
    }
    return false;
  }

  String _buildDedupKey(AutoCapture capture) {
    final normalized = _normalizeText(capture.rawText ?? '');
    return '${capture.source}|${capture.amount.toStringAsFixed(2)}|$normalized';
  }

  int? _resolveAccountIdFromAccounts(
    List<JiveAccount> accounts,
    String source,
    String? rawText,
    List<AutoAccountMapping> mappings,
  ) {
    if (accounts.isEmpty) return null;
    final fromHint = _extractFromAccountHint(rawText);
    if (fromHint != null) {
      final mapped = _resolveMappingAccountId(
        accounts,
        mappings,
        fromHint.name,
      );
      if (mapped != null) return mapped;
    }
    if (fromHint != null) {
      final matched = _matchAccountByHint(accounts, fromHint);
      if (matched != null) return matched;
    }
    if (source.contains('WeChat') || source.contains('微信')) {
      return _matchAccountByName(accounts, ['微信', '零钱', '微信钱包']) ??
          accounts.first.id;
    }
    if (source.contains('Alipay') || source.contains('支付宝')) {
      return _matchAccountByName(accounts, ['支付宝', '余额宝']) ?? accounts.first.id;
    }
    if (source.contains('UnionPay') || source.contains('云闪付')) {
      return _matchAccountByName(accounts, ['云闪付']) ?? accounts.first.id;
    }
    return accounts.first.id;
  }

  int? _resolveExplicitAccountId(
    List<JiveAccount> accounts,
    String? accountName,
  ) {
    final normalized = (accountName ?? '').trim();
    if (normalized.isEmpty) return null;
    for (final account in accounts) {
      if (account.name.trim() == normalized) return account.id;
    }
    for (final account in accounts) {
      if (account.name.contains(normalized) ||
          normalized.contains(account.name)) {
        return account.id;
      }
    }
    return null;
  }

  String? _buildCaptureMetadataJson(AutoCapture capture) {
    final payload = <String, dynamic>{};
    final toAccountName = capture.toAccountName?.trim();
    if (toAccountName != null && toAccountName.isNotEmpty) {
      payload[_transferToAccountMetadataKey] = toAccountName;
    }
    final serviceCharge = capture.serviceCharge;
    if (serviceCharge != null && serviceCharge > 0) {
      payload[_transferServiceChargeMetadataKey] = serviceCharge;
    }
    if (payload.isEmpty) return null;
    return jsonEncode(payload);
  }

  _TransferDraftMetadata _readTransferMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.trim().isEmpty) {
      return const _TransferDraftMetadata.empty();
    }
    try {
      final decoded = jsonDecode(metadataJson);
      if (decoded is! Map<String, dynamic>) {
        return const _TransferDraftMetadata.empty();
      }
      final rawName = '${decoded[_transferToAccountMetadataKey] ?? ''}'.trim();
      final rawFee = decoded[_transferServiceChargeMetadataKey];
      final serviceCharge = rawFee is num
          ? rawFee.toDouble()
          : double.tryParse('${rawFee ?? ''}');
      return _TransferDraftMetadata(
        toAccountName: rawName.isEmpty ? null : rawName,
        serviceCharge: serviceCharge,
      );
    } catch (_) {
      return const _TransferDraftMetadata.empty();
    }
  }

  int? _resolveToAccountIdFromAccounts(
    List<JiveAccount> accounts,
    String? rawText,
    List<AutoAccountMapping> mappings,
  ) {
    final hint = _extractToAccountHint(rawText);
    if (hint == null) return null;
    final mapped = _resolveMappingAccountId(accounts, mappings, hint.name);
    if (mapped != null) return mapped;
    return _matchAccountByHint(accounts, hint);
  }

  int? _resolveMappingAccountId(
    List<JiveAccount> accounts,
    List<AutoAccountMapping> mappings,
    String? matchText,
  ) {
    final matched = AutoAccountMappingStore.matchMapping(matchText, mappings);
    if (matched == null) return null;
    for (final account in accounts) {
      if (account.id == matched.accountId) return account.id;
    }
    return null;
  }

  int? _matchAccountByName(List<JiveAccount> accounts, List<String> keywords) {
    for (final keyword in keywords) {
      for (final account in accounts) {
        if (account.name.contains(keyword)) return account.id;
      }
    }
    return null;
  }

  bool _looksLikeTransfer(JiveAutoDraft draft) {
    final text = draft.rawText ?? '';
    if (text.isEmpty) return false;
    for (final keyword in _transferKeywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  String? _inferTypeFromCategoryHints(
    String? parentCategoryName,
    String? childCategoryName,
  ) {
    final parent = (parentCategoryName ?? '').trim();
    final child = (childCategoryName ?? '').trim();
    if (parent == '收入' || child == '收入') {
      return 'income';
    }
    if (parent == '转账' || child == '转账') {
      return 'transfer';
    }
    if (parent.isNotEmpty || child.isNotEmpty) {
      return 'expense';
    }
    return null;
  }

  bool _looksLikeTransferText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    for (final keyword in _transferKeywords) {
      if (rawText.contains(keyword)) return true;
    }
    return false;
  }

  _AccountHint? _extractToAccountHint(String? rawText) {
    if (rawText == null) return null;
    final text = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;
    final patterns = [
      RegExp(
        r'(?:到账银行卡|到账卡|收款银行卡|收款卡|收款账号|收款账户|转入卡|转出卡|银行卡)[:：]?\s*([^\s，,。;；]{2,30})',
      ),
      RegExp(r'(?:转账到|转到|转至|转入至|到账至)[:：]?\s*([^\s，,。;；]{2,30})'),
    ];

    String? name;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        name = match.group(1);
        break;
      }
    }

    final tail =
        RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(text)?.group(1) ??
        RegExp(r'[（(](\d{3,4})[）)]').firstMatch(text)?.group(1);

    if (name == null || name.trim().isEmpty) {
      if (tail == null) {
        return _inferAccountHintFromContext(text, preferWallet: false);
      }
      return _AccountHint(name: tail, tail: tail);
    }

    var cleaned = name.replaceAll(RegExp(r'[，,。\s]+$'), '').trim();
    String? tailFromName;
    final parenMatch = RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(cleaned);
    if (parenMatch != null) {
      tailFromName = parenMatch.group(1);
      cleaned = cleaned.replaceAll(parenMatch.group(0)!, '').trim();
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(cleaned)) {
      tailFromName ??= cleaned;
      cleaned = '';
    } else {
      final tailMatch = RegExp(
        r'^(.*?)(?:尾号|末四位|末尾)\s*(\d{3,4})$',
      ).firstMatch(cleaned);
      if (tailMatch != null) {
        cleaned = tailMatch.group(1)!.trim();
        tailFromName ??= tailMatch.group(2);
      }
    }
    final normalized = _sanitizeHintName(cleaned);
    if (normalized == null || normalized.isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: false);
    }
    final resolvedTail =
        tailFromName ??
        (RegExp(r'^\d{3,4}$').hasMatch(normalized) ? normalized : null);
    return _AccountHint(name: normalized, tail: resolvedTail);
  }

  _AccountHint? _extractFromAccountHint(String? rawText) {
    if (rawText == null) return null;
    final text = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;

    final patterns = [
      RegExp(
        r'(?:付款方式|付款信息|交易方式|退款方式|付款卡|付款方|扣款卡|支付方式|支付账户|付款账户)[:：]?\s*([^\s，,。;；]{2,30})',
      ),
    ];

    String? name;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        name = match.group(1);
        break;
      }
    }

    final tail =
        RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(text)?.group(1) ??
        RegExp(r'[（(](\d{3,4})[）)]').firstMatch(text)?.group(1);

    if (name == null || name.trim().isEmpty) {
      if (tail == null) {
        return _inferAccountHintFromContext(text, preferWallet: true);
      }
      return _AccountHint(name: tail, tail: tail);
    }

    var cleaned = name.replaceAll(RegExp(r'[，,。\s]+$'), '').trim();
    String? tailFromName;
    final parenMatch = RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(cleaned);
    if (parenMatch != null) {
      tailFromName = parenMatch.group(1);
      cleaned = cleaned.replaceAll(parenMatch.group(0)!, '').trim();
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(cleaned)) {
      tailFromName ??= cleaned;
      cleaned = '';
    } else {
      final tailMatch = RegExp(
        r'^(.*?)(?:尾号|末四位|末尾)\s*(\d{3,4})$',
      ).firstMatch(cleaned);
      if (tailMatch != null) {
        cleaned = tailMatch.group(1)!.trim();
        tailFromName ??= tailMatch.group(2);
      }
    }
    final normalized = _sanitizeHintName(cleaned);
    if (normalized == null || normalized.isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: true);
    }
    final resolvedTail =
        tailFromName ??
        (RegExp(r'^\d{3,4}$').hasMatch(normalized) ? normalized : null);
    return _AccountHint(name: normalized, tail: resolvedTail);
  }

  _AccountHint? _inferAccountHintFromContext(
    String text, {
    required bool preferWallet,
  }) {
    final bank = _extractBankName(text);
    String? wallet;
    for (final keyword in _walletHintKeywords) {
      if (text.contains(keyword)) {
        wallet = keyword;
        break;
      }
    }
    final primary = preferWallet ? (wallet ?? bank) : (bank ?? wallet);
    if (primary == null) return null;
    final tail =
        RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(text)?.group(1) ??
        RegExp(r'[（(](\d{3,4})[）)]').firstMatch(text)?.group(1);
    return _AccountHint(name: primary, tail: tail);
  }

  String? _sanitizeHintName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final bank = _extractBankName(trimmed);
    if (bank != null) {
      if (trimmed.contains('信用卡')) return '$bank信用卡';
      if (trimmed.contains('储蓄卡')) return '$bank储蓄卡';
      return bank;
    }
    for (final keyword in _walletHintKeywords) {
      if (trimmed.contains(keyword)) return keyword;
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(trimmed)) return trimmed;
    if (RegExp(
      r'(?:元|今日|今天|昨天|交易|支付|消费|退款|收款|转入|转出|支出|收入|成功|失败|单次|定时|投资|理财)',
    ).hasMatch(trimmed)) {
      return null;
    }
    if (trimmed.length > 12) return null;
    return trimmed;
  }

  static const _walletHintKeywords = [
    '支付宝',
    '微信',
    '余额宝',
    '零钱',
    '云闪付',
    '京东',
    '美团',
    '抖音',
    '拼多多',
    '淘宝',
    'QQ钱包',
    '钱包',
  ];

  int? _matchAccountByHint(List<JiveAccount> accounts, _AccountHint hint) {
    if (accounts.isEmpty) return null;
    final normalizedHint = _cleanAccountName(hint.name);
    final bank = _extractBankName(hint.name);
    final hintHasTail =
        hint.tail != null || RegExp(r'\d{3,4}').hasMatch(hint.name);

    if (hint.tail != null) {
      for (final account in accounts) {
        if (account.name.contains(hint.tail!)) return account.id;
      }
    }

    int? bestId;
    var bestScore = 0;
    var bestDiff = 999;
    for (final account in accounts) {
      if (!hintHasTail && RegExp(r'\d{3,4}').hasMatch(account.name)) {
        continue;
      }
      if (bank != null &&
          account.name.contains('信用卡') &&
          !account.name.contains(bank)) {
        continue;
      }
      final normalizedAccount = _cleanAccountName(account.name);
      final score = _longestCommonSubstring(normalizedAccount, normalizedHint);
      if (score == 0) continue;
      final diff = (normalizedAccount.length - score).abs();
      if (score > bestScore || (score == bestScore && diff < bestDiff)) {
        if (!(score == 2 && normalizedHint.startsWith('中国'))) {
          bestScore = score;
          bestDiff = diff;
          bestId = account.id;
        }
      }
    }

    if (bestScore >= 2) return bestId;
    return null;
  }

  String? _extractBankName(String text) {
    final match = RegExp(r'([\u4e00-\u9fa5]{2,10}银行)').firstMatch(text);
    return match?.group(1);
  }

  String _cleanAccountName(String name) {
    return name
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\([^(（【】）)]*\)'), '')
        .replaceAll(RegExp(r'[卡银行储蓄借记信用账户余额]'), '')
        .replaceAll('支付', '')
        .replaceAll('方式', '')
        .replaceAll('账户', '')
        .trim();
  }

  int _longestCommonSubstring(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final m = a.length;
    final n = b.length;
    final prev = List<int>.filled(n + 1, 0);
    final curr = List<int>.filled(n + 1, 0);
    var best = 0;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          curr[j] = prev[j - 1] + 1;
          if (curr[j] > best) best = curr[j];
        } else {
          curr[j] = 0;
        }
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
        curr[j] = 0;
      }
    }
    return best;
  }

  Future<CategoryIndex> _buildCategoryIndex() async {
    final categories = await isar.collection<JiveCategory>().where().findAll();
    return CategoryIndex(categories);
  }

  String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(
      RegExp(r"[\s`~!@#$%^&*()+=|{}\[\]:;,.<>/?，。！？、【】（）《》“”‘’￥…—-]"),
      '',
    );
  }

  bool _looksLikeBulkText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    final text = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length >= 220) return true;
    const keywords = [
      '交易记录',
      '账单记录',
      '账单列表',
      '账单管理',
      '账单详情',
      '筛选',
      '搜索交易记录',
      '全部账单',
    ];
    var hits = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        hits++;
        if (hits >= 2) return true;
      }
    }
    final currencyHits = RegExp(r'[¥￥]').allMatches(text).length;
    return currencyHits >= 3;
  }
}

class _TransferDraftMetadata {
  final String? toAccountName;
  final double? serviceCharge;

  const _TransferDraftMetadata({
    required this.toAccountName,
    required this.serviceCharge,
  });

  const _TransferDraftMetadata.empty()
    : toAccountName = null,
      serviceCharge = null;
}

class _ResolvedDraftAccountIds {
  final int? accountId;
  final int? toAccountId;

  const _ResolvedDraftAccountIds({
    required this.accountId,
    required this.toAccountId,
  });
}

class _AccountHint {
  final String name;
  final String? tail;

  const _AccountHint({required this.name, this.tail});
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
    JiveCategory? parent = parentName == null
        ? null
        : _parentByName[parentName];
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

  const CategoryMatch({required this.parent, required this.child});
}
